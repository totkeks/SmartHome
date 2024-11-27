FROM router-firmware-builder

ARG IMAGE_BUILDER
ARG OPENWRT_REVISION

RUN OPENWRT_REVISION=${OPENWRT_REVISION} \
    && mkdir imagebuilder \
    && wget -q --show-progress --progress=bar:force -O- ${IMAGE_BUILDER} \
    | tar --zstd -x --strip-components=1 -C imagebuilder

COPY --chmod=555 build.sh .
COPY --chmod=444 packages.txt .

COPY --chmod=644 files/etc/ files/etc/
COPY --chmod=600 files/root/ files/root/

RUN chmod +x files/root/wireguard.sh

CMD ["./build.sh"]
