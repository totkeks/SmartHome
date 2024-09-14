FROM router-firmware-builder

ARG ATF_REPO=https://github.com/mtk-openwrt/arm-trusted-firmware.git
ARG ATF_BRANCH

RUN if [ -n "$ATF_REPO" ]; then \
	echo git clone --depth 1 ${ATF_BRANCH:+-b ${ATF_BRANCH}} ${ATF_REPO} atf && \
	git clone --depth 1 ${ATF_BRANCH:+-b ${ATF_BRANCH}} ${ATF_REPO} atf; \
	fi

COPY build.sh .

RUN chmod +x build.sh

CMD ["./build.sh"]
