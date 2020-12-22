FROM alpine:latest
MAINTAINER RaphaelHuan

RUN apk add --virtual build-deps --update \
  autoconf \
  automake \
  cmake \
  ncurses ncurses-dev ncurses-libs ncurses-terminfo \
  gcc \
  g++ \
  libtool \
  libuv \
  linux-headers \
  lua5.3-dev \
  m4 \
  unzip \
  make 


RUN apk add --update \
  curl \
  git \
  python \
  py-pip \
  python-dev \
  python3-dev \
  python3 &&\
  python3 -m ensurepip && \
  rm -r /usr/lib/python*/ensurepip && \
  pip3 install --upgrade pip setuptools && \
  rm -r /root/.cache

ENV CMAKE_EXTRA_FLAGS=-DENABLE_JEMALLOC=OFF
WORKDIR /tmp

RUN git clone https://github.com/neovim/libtermkey.git && \
  cd libtermkey && \
  make && \
  make install && \
  cd ../ && rm -rf libtermkey

RUN git clone https://github.com/neovim/libvterm.git && \
  cd libvterm && \
  make && \
  make install && \
  cd ../ && rm -rf libvterm

RUN git clone https://github.com/neovim/unibilium.git && \
  cd unibilium && \
  make && \
  make install && \
  cd ../ && rm -rf unibilium

RUN curl -L https://github.com/neovim/neovim/archive/nightly.tar.gz | tar xz && \
  cd neovim-nightly && \
  make && \
  make install && \
  cd ../ && rm -rf neovim-nightly

# # Install neovim python support
RUN pip3 install neovim
RUN pip2 install neovim

RUN apk del build-deps &&\
  rm -rf /var/cache/apk/*

# # install all plugins
RUN make install

WORKDIR /root/.config/nvim

COPY $HOME/.config/nvim  /root/.config/nvim

