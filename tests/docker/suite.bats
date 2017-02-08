#!/usr/bin/env bats


@test "post_push hook is up-to-date" {
  run sh -c "cat Makefile | grep 'DOCKER_TAGS ?= ' | cut -d ' ' -f 3"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  expected="$output"

  run sh -c "cat hooks/post_push | grep 'for tag in' \
                                 | cut -d '{' -f 2 \
                                 | cut -d '}' -f 1"
  [ "$status" -eq 0 ]
  [ ! "$output" = '' ]
  actual="$output"

  [ "$actual" = "$expected" ]
}


@test "smf-spf is installed" {
  run docker run --rm $IMAGE which smf-spf
  [ "$status" -eq 0 ]
}

@test "smf-spf runs ok" {
  run docker run --rm $IMAGE smf-spf --help
  [ "$status" -eq 0 ]
}
