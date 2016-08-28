# Dockerfile for building a debian testing development environment for obnam

# Usage:
# (you may need to use `sudo` or add your user to the `docker` group)
# Build:
# docker build -t obnam .
# Run tests (safe separation between container and host, but FUSE will fail):
# docker run --rm -it obnam
# Run tests (with FUSE, but no real separation between container and host):
# docker run --privileged --rm -it obnam

# to get a shell in the obnam directory:
# docker run --rm [--privileged] -it obnam bash

###########
# Debian stretch base
###########

FROM debian:stretch
RUN echo "deb-src http://httpredir.debian.org/debian stretch main" \
    >> /etc/apt/sources.list
RUN apt-get update

# test as non-root
RUN adduser --uid=3456 testuser --disabled-password --gecos ""

###########
# obnam dependencies
###########

# dependencies, but not obnam itself
RUN apt-get -y --no-install-recommends install obnam
RUN apt-get -y remove obnam
# build dependencies
RUN apt-get -y build-dep obnam
# non-explicit dependencies for tests
RUN apt-get --no-install-recommends -y install pylint gnupg fuse

###########
# SSH server running in the background
###########

RUN apt-get -y --no-install-recommends install openssh-client openssh-server
RUN su testuser -s '/bin/bash' -- -c 'ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""'
RUN cp -a /home/testuser/.ssh/id_rsa.pub /home/testuser/.ssh/authorized_keys
RUN mkdir /var/run/sshd

# the server is started via an entrypoint script, so that it is started before
# the actual command

RUN echo \
'#!/bin/bash \n\
echo starting SSH server \n\
/usr/sbin/sshd \n\
ssh-keyscan localhost > /etc/ssh/known_hosts \n\
echo starting command: "$@" \n\
exec "$@"' > /entrypoint.sh

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

###########
# obnam itself
###########

ENV PATH="${PATH}:/opt/obnam/"
ADD . /opt/obnam
RUN chmod -R a+w /opt/obnam
WORKDIR /opt/obnam
RUN  su testuser -c 'python setup.py --quiet build_ext -i'
CMD  su testuser -c ./check
