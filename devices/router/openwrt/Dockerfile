FROM router-firmware-builder

ARG IMAGE_BUILDER=https://downloads.openwrt.org/snapshots/targets/mediatek/filogic/openwrt-imagebuilder-mediatek-filogic.Linux-x86_64.tar.zst

RUN mkdir imagebuilder && wget -q --show-progress --progress=bar:force -O- ${IMAGE_BUILDER} | tar --zstd -x --strip-components=1 -C imagebuilder

COPY build.sh .
COPY packages.txt .

RUN chmod +x build.sh

CMD ["./build.sh"]

# full build variant https://github.com/galalmounir/openwrt-image-builder
