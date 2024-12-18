# Use Alpine Linux as the base image
FROM alpine:3.18.4

# Install dependencies
RUN apk add --no-cache \
    build-base \
    cmake \
    ninja \
    git \
    libx11-dev \
    libxkbfile-dev \
    libxi-dev \
    libxcursor-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxrender-dev \
    alsa-lib-dev \
    ffmpeg-dev \
    jpeg-dev \
    openssl-dev \
    zlib-dev \
    musl-dev \
    libc-dev \
    wayland-dev \
    libxkbcommon-dev \
    libxdamage-dev \
    libxcomposite-dev \
    dbus-dev \
    cups-dev \
    pulseaudio-dev \
    linux-headers \
    bash \
    openssl \
    krb5 \
    krb5-dev 

RUN apk add --no-cache \
    icu \
    icu-dev \
    fuse3 \
    fuse3-dev \
    libusb \
    libusb-dev

# Set up directory structure
WORKDIR /src
RUN mkdir -p install && \
    echo "" > toolchain.cmake

WORKDIR /src
# Generate SSL certificates
RUN openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048 && \
    openssl req -new -x509 -key private_key.pem -out certificate.pem -days 365 -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Clone and build zlib following exact steps
RUN git clone --depth 1 -b v1.3 https://github.com/madler/zlib.git && \
    cmake -GNinja \
    -DCMAKE_TOOLCHAIN_FILE=/src/toolchain.cmake \
    -B zlib-build \
    -S zlib \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SKIP_INSTALL_ALL_DEPENDENCY=ON \
    -DCMAKE_INSTALL_PREFIX=/src/install \
    -DLIBRESSL_APPS=OFF \
    -DLIBRESSL_TESTS=OFF && \
    cmake --build zlib-build && \
    cmake --install zlib-build && \
    rm -rf /src/zlib /src/zlib-build

# Clone and build uriparser following exact steps
RUN git clone --depth 1 -b uriparser-0.9.7 https://github.com/uriparser/uriparser.git && \
    cmake -GNinja \
    -DCMAKE_TOOLCHAIN_FILE=/src/toolchain.cmake \
    -B uriparser-build \
    -S uriparser \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SKIP_INSTALL_ALL_DEPENDENCY=ON \
    -DCMAKE_INSTALL_PREFIX=/src/install \
    -DURIPARSER_BUILD_DOCS=OFF \
    -DURIPARSER_BUILD_TESTS=OFF && \
    cmake --build uriparser-build && \
    cmake --install uriparser-build && \
    rm -rf /src/uriparser /src/uriparser-build

# Clone and build cJSON following exact steps
RUN git clone --depth 1 -b v1.7.16 https://github.com/DaveGamble/cJSON.git && \
    cmake -GNinja \
    -DCMAKE_TOOLCHAIN_FILE=/src/toolchain.cmake \
    -B cJSON-build \
    -S cJSON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SKIP_INSTALL_ALL_DEPENDENCY=ON \
    -DCMAKE_INSTALL_PREFIX=/src/install \
    -DENABLE_CJSON_TEST=OFF \
    -DBUILD_SHARED_AND_STATIC_LIBS=ON && \
    cmake --build cJSON-build && \
    cmake --install cJSON-build && \
    rm -rf /src/cJSON /src/cJSON-build

# Clone and build SDL2
RUN git clone --depth 1 -b release-2.28.1 https://github.com/libsdl-org/SDL.git && \
    cmake -GNinja \
        -DCMAKE_TOOLCHAIN_FILE=/src/toolchain.cmake \
        -B SDL-build \
        -S SDL \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SKIP_INSTALL_ALL_DEPENDENCY=ON \
        -DCMAKE_INSTALL_PREFIX=/src/install \
        -DSDL_TEST=OFF \
        -DSDL_TESTS=OFF \
        -DSDL_STATIC_PIC=ON && \
    cmake --build SDL-build && \
    cmake --install SDL-build && \
    rm -rf /src/SDL /src/SDL-build

# Clone and build SDL2_ttf
RUN git clone --depth 1 --recurse-submodules -b release-2.20.2 https://github.com/libsdl-org/SDL_ttf.git && \
    cmake -GNinja \
        -DCMAKE_TOOLCHAIN_FILE=/src/toolchain.cmake \
        -B SDL_ttf-build \
        -S SDL_ttf \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SKIP_INSTALL_ALL_DEPENDENCY=ON \
        -DCMAKE_INSTALL_PREFIX=/src/install \
        -DSDL2TTF_HARFBUZZ=ON \
        -DSDL2TTF_FREETYPE=ON \
        -DSDL2TTF_VENDORED=ON \
        -DFT_DISABLE_ZLIB=OFF \
        -DSDL2TTF_SAMPLES=OFF && \
    cmake --build SDL_ttf-build && \
    cmake --install SDL_ttf-build && \
    rm -rf /src/SDL_ttf /src/SDL_ttf-build

# Clone and build SDL2_image
RUN git clone --depth 1 --recurse-submodules -b release-2.8.1 https://github.com/libsdl-org/SDL_image.git && \
    cmake -GNinja \
        -DCMAKE_TOOLCHAIN_FILE=/src/toolchain.cmake \
        -B SDL_image-build \
        -S SDL_image \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SKIP_INSTALL_ALL_DEPENDENCY=ON \
        -DCMAKE_INSTALL_PREFIX=/src/install \
        -DSDL2IMAGE_SAMPLES=OFF \
        -DSDL2IMAGE_DEPS_SHARED=OFF && \
    cmake --build SDL_image-build && \
    cmake --install SDL_image-build && \
    rm -rf /src/SDL_image /src/SDL_image-build

# Copy pre-downloaded FreeRDP source files instead of cloning
COPY . /src/freerdp

# Build FreeRDP using the copied source files
RUN cmake -GNinja \
        -DCMAKE_TOOLCHAIN_FILE=/src/toolchain.cmake \
        -B freerdp-build \
        -S freerdp \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SKIP_INSTALL_ALL_DEPENDENCY=ON \
        -DCMAKE_INSTALL_PREFIX=/src/install \
        -DWITH_SERVER=ON \
        -DWITH_KRB5=ON \
        -DWITH_SAMPLE=ON \
        -DWITH_PLATFORM_SERVER=OFF \
        -DUSE_UNWIND=OFF \
        -DWITH_SWSCALE=OFF \
        -DWITH_FFMPEG=OFF \
        -DWITH_WEBVIEW=OFF \
        -DWITH_PROXY=ON \
        -DWITH_MANPAGES=OFF \
        -DWITH_OPUS=OFF \
        -DWITH_CLIENT_SDL=OFF \
        -DWITH_SHADOW=OFF \
        -DWITH_X11=ON \
        -DWITH_CUPS=OFF

# Build step with logging
RUN cmake --build freerdp-build 2>&1 | tee build.log

# Install step
RUN cmake --install freerdp-build

# Add configuration file with SSL settings
RUN printf "[Server]\nHost=0.0.0.0\nPort=3389\n\n[Target]\nHost=example.hostname.com\nPort=3389\n\n[Channels]\nClipboard=TRUE\nPassthroughIsBlacklist=TRUE\n\n[Clipboard]\nTextOnly=FALSE\nMaxTextLength=0\n\n[Certificates]\nCertificateFile=\"/src/certificate.pem\"\nPrivateKeyFile=\"/src/private_key.pem\"\n" > /src/config.ini

# Expose the proxy port
EXPOSE 3389

# Start the FreeRDP proxy
ENTRYPOINT ["/src/install/bin/freerdp-proxy", "config.ini"]