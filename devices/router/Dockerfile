FROM docker.io/ubuntu:20.04

# Avoid issues with dialogs
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
	bc \
	bison \
	build-essential \
	device-tree-compiler \
	flex \
	gcc-aarch64-linux-gnu \
	git \
	libssl-dev \
	make \
	wget \
	xxd \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /build

ARG UBOOT_REPO=https://github.com/u-boot/u-boot.git
ARG UBOOT_BRANCH

RUN echo git clone --depth 1 ${UBOOT_BRANCH:+-b ${UBOOT_BRANCH}} ${UBOOT_REPO} u-boot && \
	git clone --depth 1 ${UBOOT_BRANCH:+-b ${UBOOT_BRANCH}} ${UBOOT_REPO} u-boot

ARG ATF_REPO=https://github.com/mtk-openwrt/arm-trusted-firmware.git
ARG ATF_BRANCH

RUN echo git clone --depth 1 ${ATF_BRANCH:+-b ${ATF_BRANCH}} ${ATF_REPO} atf && \
	git clone --depth 1 ${ATF_BRANCH:+-b ${ATF_BRANCH}} ${ATF_REPO} atf

COPY build.sh ./
RUN chmod +x ./build.sh

CMD ["./build.sh"]
