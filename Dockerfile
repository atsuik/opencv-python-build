FROM ubuntu:22.04 AS base

# 必要なパッケージをインストール
RUN apt-get update && apt-get install -y \
    git curl make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev python3-pip python3-setuptools \
    libavcodec-dev libavformat-dev libswscale-dev \
    libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev \
    libgtk-3-dev libgtk2.0-dev libcanberra-gtk-module \
    libpng-dev libjpeg-dev libopenexr-dev libtiff-dev libwebp-dev \
    libopencv-dev ffmpeg libx264-dev ninja-build \
    && rm -rf /var/lib/apt/lists/*

# pyenvインストール
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
RUN git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT

FROM base AS builder

# ARGでPythonバージョンとheadless指定とOpenCVバージョンを受け取る
ARG PYTHON_VERSION=3.10.13
ARG OPENCV_VERSION=latest
ARG OPENCV_HEADLESS=1

ENV DEBIAN_FRONTEND=noninteractive

# pyenvで指定バージョンのPythonをインストール
RUN pyenv install ${PYTHON_VERSION} && pyenv global ${PYTHON_VERSION}

# pip, wheel, setuptoolsをアップグレード
RUN pip install --upgrade pip setuptools wheel

# OpenCVのクローン（どの場合も浅いクローン）
RUN if [ "$OPENCV_VERSION" != "latest" ]; then \
      git clone --depth 1 --branch $OPENCV_VERSION --recurse-submodules --shallow-submodules https://github.com/opencv/opencv-python.git /opt/opencv-python; \
    else \
      git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/opencv/opencv-python.git /opt/opencv-python; \
    fi

WORKDIR /opt/opencv-python

# headless指定でビルド
RUN if [ "$OPENCV_HEADLESS" = "1" ]; then \
      export OPENCV_PACKAGE_NAME=opencv-python-headless; \
    else \
      export OPENCV_PACKAGE_NAME=opencv-python; \
    fi && \
    echo "ビルドするパッケージ: $OPENCV_PACKAGE_NAME" && \
    # ビルド時に依存ライブラリを含めるために環境変数を設定
    export ENABLE_HEADLESS=$OPENCV_HEADLESS && \
    export OPENCV_PYTHON_SKIP_DETECTION=1 && \
    export OPENCV_PYTHON_BINARY_WITH_SYSTEM_LIBS=1 && \
    OPENCV_PACKAGE_NAME=$OPENCV_PACKAGE_NAME python -m pip wheel . --verbose && \
    ls -la *.whl && \
    echo "ビルド完了。whlファイル:" && \
    find . -name "*.whl" -type f

# whlファイルは /opt/opencv-python/ に生成されます