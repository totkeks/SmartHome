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
	flex \
	gcc-aarch64-linux-gnu \
	git \
	libssl-dev \
	make \
	wget \
	xxd \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
