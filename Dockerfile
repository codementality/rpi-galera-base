FROM resin/rpi-raspbian:jessie

MAINTAINER "Lisa Ridley, lhridley@gmail.com"

## Dockerized version of https://gist.github.com/Lewiscowles1986/27cfeda001bb75a9151b5c974c2318bc

RUN echo "deb http://mirrordirector.raspbian.org/raspbian/ stretch main contrib non-free rpi" > /etc/apt/sources.list.d/stretch.list \
 && echo "APT::Default-Release \"jessie\";" > /etc/apt/apt.conf.d/99-default-release \

 && apt-get update -y && apt-get upgrade -y \
 && apt-get dist-upgrade -y \
 && apt-get install -y \
    build-essential \
    git \
    cmake \
    scons \
    rpi-update \
    libarchive-dev \
    libevent-dev \
    libssl-dev \
    libboost-dev \
 && apt-get install -t stretch -y \
    libncurses5-dev \
    libbison-dev \
    bison
