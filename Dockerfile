# Pull base image.
FROM ubuntu:14.04

MAINTAINER Tomas Korcak "korczis@gmail.com"

# Update system
RUN apt-get update

# Install sudo
RUN apt-get install sudo

COPY etc/sudoers /etc/sudoers

ENV USER docker

# Create docker user
RUN useradd docker && echo "docker:docker" | chpasswd && adduser docker sudo
RUN mkdir -p /home/docker && chown -R docker:docker /home/docker

# Impersonate as docker usr
USER docker

# Set home directory
WORKDIR /home/docker

# Install required packages
RUN sudo apt-get install -qy curl git python python3 python-dev \
	gfortran python3-dev wget llvm-gcc build-essential libc-dev \
	software-properties-common unzip p7zip-full openssl libreadline6 \
	libreadline6-dev curl zlib1g zlib1g-dev libssl-dev libyaml-dev \
	libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev \
	ncurses-dev automake libtool bison subversion pkg-config libffi-dev

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN bash -l -c "curl -L get.rvm.io | bash -s stable --rails"
RUN bash -l -c "rvm install 2.1"
RUN bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
RUN bash -l -c "gem install bundler --no-ri --no-rdoc"
RUN source /home/docker/.rvm/scripts/rvm

ONBUILD RUN source /home/docker/.rvm/scripts/rvm

RUN git clone https://github.com/petewarden/dstk

RUN sudo ./dstk/python/install
