# syntax=docker/dockerfile:1
FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie AS dolphin

ARG DOLPHIN_VERSION

RUN \
  echo "**** install build deps ****" && \
  apt-get update && \
  apt-get install -y \
    build-essential \
    cmake \
    git \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libcurl4-openssl-dev \
    libegl1-mesa-dev \
    libevdev-dev \
    libpulse-dev \
    libqt6svg6-dev \
    libswscale-dev \
    libudev-dev \
    libvulkan-dev \
    libx11-dev \
    libxi-dev \
    libxrandr-dev \
    pkg-config \
    qt6-base-dev \
    qt6-base-private-dev \
    qt6-wayland-dev \
    qt6-wayland-private-dev

RUN \
  echo "**** build dolphin ****" && \
  if [ -z ${DOLPHIN_VERSION+x} ]; then \
    DOLPHIN_VERSION=$(curl -sL 'https://dolphin-emu.org/download/' \
    | awk -F '(dolphin-|-x86_64.flatpak)' '/-x86_64.flatpak/ {print $3;exit}'); \
  fi && \
  mkdir /root-out && \
  git clone https://github.com/dolphin-emu/dolphin.git && \
  cd dolphin && \
  echo "**** building dolphin at ${DOLPHIN_VERSION} ****" && \
  git checkout -f ${DOLPHIN_VERSION} && \
  git submodule update --init --recursive && \
  mkdir build && \
  cd build && \
  cmake .. && \
  make -j16 && \
  make install DESTDIR=/root-out

# runtime stage
FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

ENV TITLE=Dolphin \
    PIXELFLUX_WAYLAND=true

RUN \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/dolphin-logo.png && \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    libavcodec61 \
    libavformat61 \
    libqt6widgets6 \
    libswscale8 \
    qt6-svg-plugins \
    qt6-wayland && \
  echo "**** add symlink ****" && \
  ln -s \
    /usr/local/bin/dolphin-emu \
    /usr/games/dolphin-emu && \
  echo "**** cleanup ****" && \
  printf \
    "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" \
    > /build_version && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files and build stage
COPY --from=dolphin /root-out/ /
COPY /root /

# ports and volumes
EXPOSE 3001

VOLUME /config
