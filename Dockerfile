FROM ubuntu:xenial
MAINTAINER Phillip Richmond <prichmond@bcchr.ca>

LABEL \
  description="image to run STIX https://github.com/ryanlayer/stix. Used version with modifications from Alexander Paul <alex.paul@wustl.edu>, https://github.com/apaul7/docker-stix"

# Get libraries and compilers  
RUN apt-get update && apt-get install -y \
  autoconf \
  bzip2 \
  gcc \
  g++ \
  git \
  libbz2-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  liblzma-dev \
  make \
  ncurses-dev \
  ruby \
  wget \
  zlib1g-dev

############
# Samtools #
############

# Add samtools, from here: https://github.com/samtools/samtools
ENV SAMTOOLS_INSTALL_DIR=/opt/samtools

WORKDIR /tmp
# This one has both samtools + htslib
RUN wget https://github.com/samtools/samtools/releases/download/1.15.1/samtools-1.15.1.tar.bz2 && \
  tar --bzip2 -xf samtools-1.15.1.tar.bz2

WORKDIR /tmp/samtools-1.15.1
RUN ./configure --enable-plugins --prefix=$SAMTOOLS_INSTALL_DIR && \
  make all all-htslib && \
  make install install-htslib

WORKDIR /
RUN ln -s $SAMTOOLS_INSTALL_DIR/bin/samtools /usr/bin/samtools && \
  rm -rf /tmp/samtools-1.15.1

##########
# Excord #
##########

# Add excord, from here: https://github.com/brentp/excord
# Workdir here is /opt/ because stix relies on this organization
WORKDIR /opt
RUN wget -O excord https://github.com/brentp/excord/releases/download/v0.2.2/excord_linux64 \
 && chmod +x /opt/excord && \
 ln -s /opt/excord /usr/bin/

##########
# Giggle #
##########

WORKDIR /opt
## Add giggle (v0.6.3)
RUN git clone https://github.com/ryanlayer/giggle.git \
  && cd giggle \
  && make \
  && ln -s /opt/giggle/bin/giggle /usr/bin/

RUN wget http://www.sqlite.org/2017/sqlite-amalgamation-3170000.zip \
  && unzip sqlite-amalgamation-3170000.zip

########
# STIX #
########

WORKDIR /opt
## install stix
RUN git clone https://github.com/ryanlayer/stix \
  && cd stix \
  && make \
  && ln -s /opt/stix/bin/stix /usr/bin/

