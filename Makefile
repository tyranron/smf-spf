VERSION ?= 2.3

CC = gcc
PREFIX = /usr/local
SBINDIR = $(PREFIX)/sbin
DATADIR = /var/run/smfs
CONFDIR = /etc/mail/smfs
USER = smfs
GROUP = smfs
CFLAGS = -O2 -D_REENTRANT -fomit-frame-pointer -I/usr/local/include 

# Linux
LDFLAGS = -lmilter -lpthread -L/usr/lib/libmilter -L/usr/local/lib -lspf2

# FreeBSD
#LDFLAGS = -lmilter -pthread -L/usr/local/lib -lspf2

# Solaris
#LDFLAGS = -lmilter -lpthread -lsocket -lnsl -lresolv -lspf2

# Sendmail v8.11
#LDFLAGS += -lsmutil

all: smf-spf

smf-spf: smf-spf.o
	$(CC) -o smf-spf smf-spf.o $(LDFLAGS)
	strip smf-spf

smf-spf.o: smf-spf.c
	$(CC) $(CFLAGS) -c smf-spf.c

coverage:
	$(CC) $(CFLAGS) -c smf-spf.c -coverage
	$(CC) -o smf-spf smf-spf.o $(LDFLAGS)  -lgcov
	strip smf-spf
clean:
	rm -f smf-spf.o smf-spf smf.spf.gcno sample coverage.info smf-spf.gcno

install:
	@./install.sh
	@cp -f -p smf-spf $(SBINDIR)
	@if test ! -d $(DATADIR); then \
	mkdir -m 700 $(DATADIR); \
	chown $(USER):$(GROUP) $(DATADIR); \
	fi
	@if test ! -d $(CONFDIR); then \
	mkdir -m 755 $(CONFDIR); \
	fi
	@if test ! -f $(CONFDIR)/smf-spf.conf; then \
	cp -p smf-spf.conf $(CONFDIR)/smf-spf.conf; \
	else \
	cp -p smf-spf.conf $(CONFDIR)/smf-spf.conf.new; \
	fi
	@echo Please, inspect and edit the $(CONFDIR)/smf-spf.conf file.




#
# Docker stuff.
#

DOCKER_IMAGE_NAME := smf-spf/smf-spf
DOCKER_TAGS ?= 2.3,2,latest


# Helper definitions
comma := ,
empty :=
space := $(empty) $(empty)
eq = $(if $(or $(1),$(2)),$(and $(findstring $(1),$(2)),\
                                $(findstring $(2),$(1))),1)


# Build Docker image.
#
# Usage:
#	make docker-image [no-cache=(yes|no)] [VERSION=]

no-cache ?= no

docker-image:
	docker build $(if $(call eq, $(no-cache), yes), --no-cache, $(empty)) \
		-t $(DOCKER_IMAGE_NAME):$(VERSION) .


# Tag Docker image with given tags.
#
# Usage:
#	make docker-tags [VERSION=] [DOCKER_TAGS=t1,t2,...]

docker-tags:
	(set -e ; $(foreach tag, $(subst $(comma), $(space), $(DOCKER_TAGS)), \
		docker tag $(DOCKER_IMAGE_NAME):$(VERSION) \
		           $(DOCKER_IMAGE_NAME):$(tag) ; \
	))


# Manually push Docker images to Docker Hub.
#
# Usage:
#	make docker-push [DOCKER_TAGS=t1,t2,...]

docker-push:
	(set -e ; $(foreach tag, $(subst $(comma), $(space), $(DOCKER_TAGS)), \
		docker push $(DOCKER_IMAGE_NAME):$(tag) ; \
	))




#
# Testing stuff.
#


# Run milter tests.
#
# Usage:
#	make test-milter

test-milter:
	for testfile in tests/* ; do \
		miltertest -vv -s $$testfile ; \
	done


# Run tests for Docker image.
#
# Usage:
#	make test-docker [VERSION=]

BATS_VER ?= 0.4.0

test-docker:
ifeq ($(wildcard $(PWD)/tests/docker/bats),)
	mkdir -p $(PWD)/tests/docker/bats/vendor
	curl -L -o $(PWD)/tests/docker/bats/vendor/bats.tar.gz \
		https://github.com/sstephenson/bats/archive/v$(BATS_VER).tar.gz
	tar -xzf $(PWD)/tests/docker/bats/vendor/bats.tar.gz \
		-C $(PWD)/tests/docker/bats/vendor
	rm -f $(PWD)/tests/docker/bats/vendor/bats.tar.gz
	ln -s $(PWD)/tests/docker/bats/vendor/bats-$(BATS_VER)/libexec/* \
		$(PWD)/tests/docker/bats/
endif
	IMAGE=$(DOCKER_IMAGE_NAME):$(VERSION) \
		./tests/docker/bats/bats tests/docker/suite.bats




.PHONY: docker-image docker-tags docker-push \
        test-milter test-docker
