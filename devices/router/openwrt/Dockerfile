FROM router-firmware-builder

ARG IMAGE_BUILDER=https://downloads.openwrt.org/snapshots/targets/mediatek/filogic/openwrt-imagebuilder-mediatek-filogic.Linux-x86_64.tar.zst

RUN mkdir imagebuilder \
    && wget -q --show-progress --progress=bar:force -O- ${IMAGE_BUILDER} \
    | tar --zstd -x --strip-components=1 -C imagebuilder

COPY files/ files/
COPY packages.txt .
COPY build.sh .

RUN chmod +x build.sh \
    && find files/ -type d -exec chmod 755 {} \; \
    && find files/etc/uci-defaults/ -type f -exec chmod 755 {} \; \
    && chmod 755 files/etc/rc.local \
    && chmod 644 files/root/.profile

CMD ["./build.sh"]
