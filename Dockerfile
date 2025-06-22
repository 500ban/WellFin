FROM ubuntu:22.04

# 必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  openjdk-21-jdk \
  wget \
  clang \
  cmake \
  ninja-build \
  gnupg \
  lsb-release \
  software-properties-common \
  socat \
  && rm -rf /var/lib/apt/lists/*

# Node.jsとnpmのインストール（Firebase CLI用）
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y nodejs

# Firebase CLIのインストール
RUN npm install -g firebase-tools

# Android SDKのインストール
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

RUN mkdir -p $ANDROID_HOME/cmdline-tools \
  && wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
  && unzip commandlinetools-linux-9477386_latest.zip \
  && mv cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
  && rm commandlinetools-linux-9477386_latest.zip

# Android SDKコンポーネントのインストール
RUN yes | sdkmanager --licenses
RUN sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

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
RUN chown -R flutter:flutter $FLUTTER_HOME $ANDROID_HOME

USER flutter
WORKDIR /workspace

# Flutter doctorの実行（Android SDKの確認）
RUN flutter doctor
