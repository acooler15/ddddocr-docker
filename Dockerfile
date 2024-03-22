# 基础镜像
FROM alpine:edge

# 维护者信息
LABEL maintainer "a76yyyy <q981331502@163.com>"
LABEL org.opencontainers.image.source=https://github.com/qd-today/ddddocr-docker
ARG APK_MIRROR=""  #e.g., https://mirrors.tuna.tsinghua.edu.cn
ARG PIP_MIRROR=""  #e.g., https://pypi.tuna.tsinghua.edu.cn/simple
ARG GIT_DOMAIN=https://github.com   #e.g., https://gh-proxy.com/https://github.com
ARG TARGETARCH
# ENV TARGETARCH=${TARGETARCH}

# Envirenment for dddocr
ARG DDDDOCR_VERSION=master
# ENV DDDDOCR_VERSION=${DDDDOCR_VERSION}

# 换源 & Install packages
RUN <<EOT
#!/usr/bin/env sh
set -ex
echo 'https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories
APK_CMD="apk"
if [ -n "$APK_MIRROR" ]; then
    APK_CMD="apk --repositories-file=/dev/null -X $APK_MIRROR/alpine/edge/main -X $APK_MIRROR/alpine/edge/community -X $APK_MIRROR/alpine/edge/testing"
fi
$APK_CMD update
$APK_CMD add --update --no-cache bash git tzdata ca-certificates file python3 py3-six
# ln -s /usr/bin/python3 /usr/bin/python
if [ "${TARGETARCH}" != "i386" ] && [ "${TARGETARCH}" != "s390x" ]; then
    $APK_CMD add --update --no-cache py3-pillow py3-onnxruntime py3-opencv libprotobuf-lite
    $APK_CMD add --update --no-cache --virtual .build_deps py3-pip py3-setuptools py3-wheel \
        protobuf-dev py3-numpy-dev lld samurai build-base gcc python3-dev musl-dev linux-headers make
    git clone --branch $DDDDOCR_VERSION $GIT_DOMAIN/sml2h3/ddddocr.git
    cd /ddddocr
    sed -i '/install_package_data/d' setup.py
    sed -i '/install_requires/d' setup.py
    sed -i '/python_requires/d' setup.py
    PIP_INSTALL="pip install"
    if [ -n "$PIP_MIRROR" ]; then
        PIP_INSTALL="pip install --index-url $PIP_MIRROR"
    fi
    $PIP_INSTALL --no-cache-dir --compile --break-system-packages .
    cd / && rm -rf /ddddocr
    $APK_CMD del .build_deps;
else
    $APK_CMD add --update --no-cache libprotobuf-lite
    echo "Onnxruntime Builder does not currently support building i386 and s390x wheels"
fi
rm -rf /var/cache/apk/*
rm -rf /usr/share/man/*
EOT
