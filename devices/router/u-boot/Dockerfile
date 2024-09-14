FROM router-firmware-builder

ARG UBOOT_REPO=https://github.com/u-boot/u-boot.git
ARG UBOOT_BRANCH

RUN if [ -n "$UBOOT_REPO" ]; then \
	echo git clone --depth 1 ${UBOOT_BRANCH:+-b ${UBOOT_BRANCH}} ${UBOOT_REPO} u-boot && \
	git clone --depth 1 ${UBOOT_BRANCH:+-b ${UBOOT_BRANCH}} ${UBOOT_REPO} u-boot; \
	fi

COPY build.sh .

RUN chmod +x build.sh

CMD ["./build.sh"]
