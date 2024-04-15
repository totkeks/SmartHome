FROM docker.io/ubuntu:20.04

# Avoid issues with dialogs
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install --no-install-recommends -y \
	bc \
	bison \
	build-essential \
	ca-certificates \
	device-tree-compiler \
	file \
	flex \
	gawk \
	gcc-aarch64-linux-gnu \
	git \
	libssl-dev \
	make \
	python3-distutils \
	unzip \
	wget \
	xxd \
	zstd \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
