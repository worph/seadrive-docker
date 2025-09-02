# SeaDrive Docker Container

A Docker container for Seafile Drive Client (SeaDrive) that provides a FUSE-based virtual drive for accessing Seafile files.

## Features

- Based on official SeaDrive CLI AppImage (v3.0.16)
- FUSE-based virtual filesystem
- Configurable via environment variables
- Persistent configuration and data storage
- Proper signal handling and cleanup
- Support for authentication tokens

## Quick Start

### Using Docker Compose (Recommended)

1. Configure your environment in `docker-compose.yml`:
```yaml
environment:
  - SEAFILE_SERVER=https://your-seafile-server.com
  - SEAFILE_USERNAME=your-username@example.com
  - SEAFILE_TOKEN=your-auth-token-here
```

2. Start the container:
```bash
docker-compose up -d
```

3. View logs:
```bash
docker-compose logs -f
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
  -e SEAFILE_TOKEN=your-auth-token \
  -v $(pwd)/seadrive-mount:/seadrive/mount:shared \
  -v seadrive-data:/seadrive/data \
  -v seadrive-config:/seadrive/config \
  seadrive
```

## Configuration

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SEAFILE_SERVER` | Your Seafile server URL | `https://seafile.example.com` |
| `SEAFILE_USERNAME` | Your Seafile username/email | `user@example.com` |
| `SEAFILE_TOKEN` | Authentication token | `abc123...` |

### Optional Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLIENT_NAME` | `seadrive-docker` | Client identifier |
| `CACHE_SIZE_LIMIT` | `10GB` | Maximum cache size |
| `CACHE_CLEAN_INTERVAL` | `10` | Cache cleanup interval (minutes) |
| `MOUNT_POINT` | `/seadrive/mount` | Mount point inside container |
| `DATA_DIR` | `/seadrive/data` | Data directory for SeaDrive |
| `LOG_LEVEL` | `info` | Logging level |

## Getting Your Authentication Token

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

## Volume Mounts

| Container Path | Purpose | Recommended Host Mount |
|----------------|---------|----------------------|
| `/seadrive/mount` | Seafile files access point | `./seadrive-mount` (with `shared` propagation) |
| `/seadrive/data` | SeaDrive cache and internal data | Named volume `seadrive-data` |
| `/seadrive/config` | Configuration files | Named volume `seadrive-config` |

## Accessing Your Files

Once the container is running, your Seafile libraries will be available in the mount directory:

```bash
# List your libraries
ls ./seadrive-mount/

# Access files
cat ./seadrive-mount/My\ Library/document.txt

# Copy files
cp ./seadrive-mount/Photos/image.jpg ./local-copy.jpg
```

## Troubleshooting

### Container Won't Start

**Error: "FUSE device not available"**
```bash
# Ensure FUSE is available on host
ls -la /dev/fuse

# Run with proper device access
docker run --device /dev/fuse ...
```

**Error: "Permission denied"**
```bash
# Add required capabilities
docker run --cap-add SYS_ADMIN --security-opt apparmor:unconfined ...
```

### Mount Issues

**Mount point not accessible from host:**
- Use `shared` bind propagation:
  ```yaml
  volumes:
    - type: bind
      source: ./seadrive-mount
      target: /seadrive/mount
      bind:
        propagation: shared
  ```

**Mount appears empty:**
- Check container logs: `docker logs seadrive-client`
- Verify authentication token is valid
- Ensure server URL is correct and accessible

### Authentication Issues

**Token authentication failed:**
- Verify token hasn't expired
- Check username/server combination
- Generate a new token from Seafile web interface

## Commands

### Interactive Shell
```bash
docker-compose exec seadrive bash
```

### View Real-time Logs
```bash
docker-compose logs -f seadrive
```

### Restart Container
```bash
docker-compose restart seadrive
```

### Stop and Remove
```bash
docker-compose down
```

## Building Custom Versions

```bash
# Build with different SeaDrive version
docker build --build-arg SEADRIVE_VERSION=3.0.15 -t seadrive:3.0.15 .

# Build with custom base image
docker build --build-arg BASE_IMAGE=ubuntu:20.04 -t seadrive .
```

## Security Notes

- Store authentication tokens securely (use `.env` file with proper permissions)
- Consider using Docker secrets for production deployments
- The container runs as non-root user `seadrive` (UID 1000)
- FUSE access requires elevated privileges - avoid `--privileged` when possible

## License

This Docker implementation is provided as-is. SeaDrive and Seafile are products of Seafile Ltd.