#!/bin/bash
# start the tests inside a docker container
# or, if arguments are given, start the specified program
# in the development container
docker build -t obnam .
docker run --rm -it --privileged obnam "$@"
