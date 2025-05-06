FROM ubuntu:22.04

# 必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  openjdk-11-jdk \
  wget \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  gnupg \
  libgtk-3-dev \
  && rm -rf /var/lib/apt/lists/*

# Google Chromeのリポジトリを追加
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
  && apt-get update \
  && apt-get install -y google-chrome-stable \
  && rm -rf /var/lib/apt/lists/*

# Android SDKのインストール
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/android-cmdline-tools.zip && \
  unzip -q /tmp/android-cmdline-tools.zip -d /tmp && \
  mv /tmp/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
  rm /tmp/android-cmdline-tools.zip

# Android SDKのセットアップ
RUN yes | sdkmanager --licenses && \
  sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Flutterのインストール
ENV FLUTTER_HOME=/flutter
ENV PATH=$FLUTTER_HOME/bin:$PATH

# Flutterディレクトリが存在しない場合のみインストールを実行
RUN if [ ! -d "$FLUTTER_HOME" ]; then \
  git clone https://github.com/flutter/flutter.git $FLUTTER_HOME && \
  flutter channel stable && \
  flutter upgrade && \
  flutter doctor; \
  fi

# 非rootユーザーの作成
RUN useradd -ms /bin/bash flutter
RUN chown -R flutter:flutter $FLUTTER_HOME
RUN chown -R flutter:flutter $ANDROID_HOME

USER flutter
WORKDIR /workspace
