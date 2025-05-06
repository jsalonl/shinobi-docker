FROM node:12-alpine

# Environment variables
ENV SHINOBI_SHA="010abad7da5e594da0e3fb697c86a753011aa53b" \
    SHINOBI_BRANCH="master" \
    ADMIN_USER=admin@shinobi.video \
    ADMIN_PASSWORD=admin \
    CRON_KEY=fd6c7849-904d-47ea-922b-5143358ba0de \
    PLUGINKEY_MOTION=b7502fd9-506c-4dda-9b56-8e699a6bc41c \
    PLUGINKEY_OPENCV=f078bcfe-c39a-4eb5-bd52-9382ca828e8a \
    PLUGINKEY_OPENALPR=dbff574e-9d4a-44c1-b578-3dc0f1944a3c

# Base system update
RUN apk --no-cache update && apk upgrade --no-cache

# Install runtime dependencies
RUN apk add --no-cache \
    ffmpeg gnutls x264 libssh2 tar xz bzip2 \
    mariadb-client ttf-freefont ca-certificates wget \
 && update-ca-certificates

# Install static build of ffmpeg
RUN wget -q https://cdn.shinobi.video/installers/ffmpeg-release-64bit-static.tar.xz \
 && tar -xpf ffmpeg-release-64bit-static.tar.xz \
 && cp -f ffmpeg-3.3.4-64bit-static/ff* /usr/bin/ \
 && chmod +x /usr/bin/ff* \
 && rm -rf ffmpeg-release-64bit-static.tar.xz ffmpeg-3.3.4-64bit-static

# Create required directories
RUN mkdir -p /config /tmp/shinobi /opt/shinobi

# Install build dependencies and fetch Shinobi
RUN apk add --no-cache --virtual .build-dependencies \
    build-base coreutils nasm python3 make pkgconfig \
    wget freetype-dev gnutls-dev lame-dev libass-dev \
    libogg-dev libtheora-dev libvorbis-dev libvpx-dev \
    libwebp-dev opus-dev rtmpdump-dev x264-dev x265-dev yasm-dev \
 && wget -q "https://gitlab.com/Shinobi-Systems/Shinobi/-/archive/${SHINOBI_BRANCH}/Shinobi-${SHINOBI_BRANCH}.tar.bz2" -O /tmp/shinobi.tar.bz2 \
 && tar -xjpf /tmp/shinobi.tar.bz2 -C /tmp/shinobi --strip-components=1 \
 && mv /tmp/shinobi /opt/shinobi \
 && rm -f /tmp/shinobi.tar.bz2 \
 && cd /opt/shinobi \
 && npm install -g npm@latest \
 && npm install -g pm2 \
 && npm install \
 && apk del .build-dependencies

# Copy config and entrypoint
COPY docker-entrypoint.sh pm2Shinobi.yml conf.sample.json super.sample.json /opt/shinobi/
RUN chmod +x /opt/shinobi/docker-entrypoint.sh

# Expose Shinobi port
EXPOSE 8080

# Set working directory
WORKDIR /opt/shinobi

# Entrypoint and default command
ENTRYPOINT ["/opt/shinobi/docker-entrypoint.sh"]
CMD ["pm2-docker", "pm2Shinobi.yml"]
