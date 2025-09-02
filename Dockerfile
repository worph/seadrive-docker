
# Dockerfile for SeaDrive Client
FROM ubuntu:22.04

LABEL maintainer="SeaDrive Docker"
LABEL description="Containerized Seafile Drive Client (SeaDrive)"

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive
ENV SEADRIVE_VERSION=3.0.16

# Install dependencies
RUN apt-get update && apt-get install -y \
    fuse \
    wget \
    curl \
    ca-certificates \
    libfuse2 \
    libglib2.0-0 \
    libgtk-3-0 \
    libssl3 \
    libsqlite3-0 \
    libjansson4 \
    libevent-2.1-7 \
    libcurl4 \
    uuid-runtime \
    gettext-base \
    sudo \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create seadrive user and directories
RUN useradd -r -u 1000 -m -s /bin/bash seadrive \
    && mkdir -p /seadrive/mount \
    && mkdir -p /seadrive/data \
    && mkdir -p /seadrive/logs \
    && mkdir -p /seadrive/config \
    && chown -R seadrive:seadrive /seadrive \
    && chmod 755 /seadrive/mount \
    && echo "seadrive ALL=(ALL) NOPASSWD: /bin/mount, /bin/umount" >> /etc/sudoers

# Download SeaDrive AppImage (CLI version for server use)
RUN wget -O /usr/local/bin/seadrive-cli \
    "https://download.seadrive.org/SeaDrive-cli-x86_64-${SEADRIVE_VERSION}.AppImage" \
    && chmod +x /usr/local/bin/seadrive-cli \
    && ln -s /usr/local/bin/seadrive-cli /usr/local/bin/seadrive

# Create default configuration template
COPY seadrive.conf.template /seadrive/config/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to seadrive user
USER seadrive
WORKDIR /seadrive

# Set environment variables with defaults
ENV SEAFILE_SERVER=""
ENV SEAFILE_USERNAME=""
ENV SEAFILE_PASSWORD=""
ENV SEAFILE_TOKEN=""
ENV CLIENT_NAME="seadrive-docker"
ENV CACHE_SIZE_LIMIT="10GB"
ENV CACHE_CLEAN_INTERVAL="10"
ENV MOUNT_POINT="/seadrive/mount"
ENV DATA_DIR="/seadrive/data"
ENV LOG_LEVEL="info"

# Expose the mount point as a volume
VOLUME ["/seadrive/mount", "/seadrive/data", "/seadrive/config"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["seadrive"]