# SeaDrive Docker Container

A Docker container for Seafile Drive Client (SeaDrive) that provides a FUSE-based virtual filesystem for accessing Seafile files.

## Features

- Based on official SeaDrive CLI AppImage (v3.0.16)
- FUSE-based virtual filesystem
- Configurable via environment variables
- Persistent configuration and data storage
- Proper signal handling and cleanup
- Support for authentication tokens and password-based login
- Automatic token generation from credentials
- Community Edition and Pro server support

## Quick Start

### Using Docker Compose (Recommended)

1. Configure your environment in `docker-compose.yml`:
```yaml
environment:
  - SEAFILE_SERVER=https://your-seafile-server.com
  - SEAFILE_USERNAME=your-username@example.com
  - SEAFILE_PASSWORD=your-password  # Token will be auto-generated
  # OR use existing token:
  # - SEAFILE_TOKEN=your-auth-token-here
```

2. Start the container:
```bash
docker compose up -d
```

3. View logs:
```bash
docker compose logs -f seadrive-docker
```

4. Access your files:
```bash
# List your Seafile libraries
docker exec seadrive-docker ls "/seadrive/mount/"

# Access files in a specific library
docker exec seadrive-docker ls "/seadrive/mount/My Libraries/My Library/"

# Copy files from container to host
docker cp seadrive-docker:"/seadrive/mount/My Libraries/My Library/file.txt" ./local-file.txt
```

### Using Docker Run

```bash
docker build -t seadrive-docker .

docker run -d \
  --name seadrive-client \
  --device /dev/fuse \
  --cap-add SYS_ADMIN \
  --security-opt apparmor:unconfined \
  -e SEAFILE_SERVER=https://your-seafile-server.com \
  -e SEAFILE_USERNAME=your-username@example.com \
  -e SEAFILE_PASSWORD=your-password \
  -v seadrive-data:/seadrive/data \
  -v seadrive-config:/seadrive/config \
  seadrive-docker
```

**Note**: Direct host bind mounting to `/seadrive/mount` conflicts with FUSE and is not currently supported. Use container access methods shown above.

## Configuration

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SEAFILE_SERVER` | Your Seafile server URL | `https://seafile.example.com` |
| `SEAFILE_USERNAME` | Your Seafile username/email | `user@example.com` |
| `SEAFILE_PASSWORD` | Your password (for auto token generation) | `your-password` |

**OR** (if you already have a token):

| Variable | Description | Example |
|----------|-------------|---------|
| `SEAFILE_TOKEN` | Pre-generated authentication token | `abc123def456...` |

### Optional Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLIENT_NAME` | `seadrive-docker` | Client identifier |
| `CACHE_SIZE_LIMIT` | `10GB` | Maximum cache size |
| `CACHE_CLEAN_INTERVAL` | `10` | Cache cleanup interval (minutes) |
| `MOUNT_POINT` | `/seadrive/mount` | Mount point inside container |
| `DATA_DIR` | `/seadrive/data` | Data directory for SeaDrive |
| `LOG_LEVEL` | `info` | Logging level |

## Authentication Methods

### Option 1: Password (Recommended)
Provide your `SEAFILE_PASSWORD` - the container will automatically generate an authentication token.

### Option 2: Pre-generated Token
If you prefer to use an existing token:

1. **Web Interface Method:**
   - Login to your Seafile web interface
   - Go to Settings → Password
   - Generate or copy an existing auth token

2. **API Method:**
   ```bash
   curl -d "username=your-username&password=your-password" \
     https://your-seafile-server.com/api2/auth-token/
   ```

## Docker Requirements

SeaDrive requires FUSE support and special privileges:

- `--device /dev/fuse` - Access to FUSE device
- `--cap-add SYS_ADMIN` - Required capabilities for mounting
- `--security-opt apparmor:unconfined` - Disable AppArmor restrictions

## Volume Mounts & File Access

### Supported Volumes

| Container Path | Purpose | Mount Type |
|----------------|---------|------------|
| `/seadrive/data` | SeaDrive cache and internal data | Named volume `seadrive-data` |
| `/seadrive/config` | Configuration files | Named volume `seadrive-config` |


## Troubleshooting

## Building Custom Versions

```bash
# Build with different SeaDrive version
docker build --build-arg SEADRIVE_VERSION=3.0.15 -t seadrive:3.0.15 .

# Build with custom base image
docker build --build-arg BASE_IMAGE=ubuntu:20.04 -t seadrive .
```

## Security Notes

- **Credentials**: Store passwords/tokens securely using `.env` files with proper permissions (600)
- **Production**: Consider using Docker secrets for production deployments
- **Privileges**: FUSE requires `SYS_ADMIN` capability - avoid `--privileged` flag
- **Network**: Container connects to Seafile server - ensure network security

## Current Status

- ✅ **Working**: FUSE mounting, authentication, file access via container
- ✅ **Supported**: Password and token-based authentication
- ✅ **Supported**: Community Edition and Pro servers
- ⚠️ **Limited**: Direct host bind mounting conflicts with FUSE
- 🔄 **Alternative**: Use `docker cp` or `docker exec` for file operations

## License

This Docker implementation is provided as-is. SeaDrive and Seafile are products of Seafile Ltd.