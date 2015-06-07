# Pull base image.
FROM ubuntu:14.04

MAINTAINER Tomas Korcak "korczis@gmail.com"

# Use bash instead of sh
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Update system
RUN apt-get update

# Install sudo
RUN apt-get install -qy sudo software-properties-common python-software-properties

COPY etc/sudoers /etc/sudoers

ENV USER docker

# Create docker user
RUN useradd docker && echo "docker:docker" | chpasswd && adduser docker sudo
RUN mkdir -p /home/docker && chown -R docker:docker /home/docker

# Install Oracle Java 8 - https://github.com/dockerfile/java/blob/master/oracle-java8/Dockerfile
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Install required packages
RUN apt-get update && apt-get install -qy curl git python python3 python-dev \
	gfortran python3-dev wget llvm-gcc build-essential libc-dev \
	software-properties-common unzip p7zip-full openssl libreadline6 \
	libreadline6-dev curl zlib1g zlib1g-dev libssl-dev libyaml-dev \
	libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev \
	ncurses-dev automake libtool bison subversion pkg-config libffi-dev

# Install postgresql stuff
RUN apt-get -qy install postgresql-server-dev-9.3 postgresql-9.3 libpq-dev

# Install geoip stuff
# RUN add-apt-repository ppa:maxmind/ppa
RUN apt-get update && apt-get install -qy geoip-bin geoip-database libgeoip-dev libcurl4-openssl-dev # geoipupdate

# Impersonate as docker usr
USER docker

# Set home directory
WORKDIR /home/docker

RUN git clone https://github.com/maxmind/geoipupdate
RUN cd geoipupdate && ./bootstrap && ./configure && make && sudo make install

RUN git clone https://github.com/korczis/GeoIP.git
RUN cd GeoIP && ./bootstrap && ./configure && make; sudo make install; true

RUN sudo ldconfig -vv

RUN bash -l -c "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"
RUN bash -l -c "curl -L get.rvm.io | bash -s stable"
RUN bash -l -c "rvm install 2.1"
RUN bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
RUN bash -l -c "gem install bundler --no-ri --no-rdoc"

RUN echo "source /home/$USER/.rvm/scripts/rvm" >> /home/$USER/.bashrc

RUN git clone https://github.com/korczis/dstk # SHA: eae7d8daeeb9e31ded19eabfa2b7201605f993ca

RUN git clone https://github.com/foursquare/twofishes.git
RUN bash -l -c "cd twofishes && ./download-world.sh && ./parse.py -w ./serve.py latest"
RUN sudo ./dstk/python/install

RUN bash -l -c "cd dstk && bundle install"

EXPOSE 4567

WORKDIR dstk

COPY run.sh run.sh

# ENTRYPOINT ./run.sh
