# 03 - Docker Installation

This guide covers installing Docker on all supported platforms. Docker is required to build and push function images to Oracle Container Registry (OCIR).

## 📋 What You'll Accomplish

- ✅ Install Docker on your platform
- ✅ Configure Docker for your system
- ✅ Verify Docker installation
- ✅ Ensure Docker can build images

## ⏱️ Estimated Time: 15-30 minutes

---

## 🖥️ Choose Your Platform

- [macOS Installation](#macos-installation)
- [Oracle Linux VM Installation](#oracle-linux-vm-installation)
- [Ubuntu/Debian Installation](#ubuntudebian-installation)
- [Windows Installation](#windows-installation)
- [Verify Installation](#verify-installation)

---

## 🍎 macOS Installation

### Install Docker Desktop (Recommended)

1. **Download Docker Desktop**:
   - Visit [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Download for Mac (Intel or Apple Silicon)

2. **Install**:
   - Open the `.dmg` file
   - Drag Docker to Applications folder
   - Launch Docker from Applications

3. **Complete Setup**:
   - Accept license agreement
   - Wait for Docker Engine to start
   - Look for whale icon in menu bar

4. **Verify Installation**:
   ```bash
   docker --version
   docker run hello-world
   ```

### Homebrew Installation (Alternative)

```bash
# Install Docker via Homebrew
brew install --cask docker

# Launch Docker Desktop
open /Applications/Docker.app

# Verify
docker --version
```

### macOS Configuration

**For Apple Silicon (M1/M2/M3) Macs:**

Docker Desktop should automatically detect your architecture. However, for OCI Functions deployment, ensure multi-platform builds:

```bash
# Enable BuildKit (better multi-platform support)
export DOCKER_BUILDKIT=1

# Add to your shell config for persistence
echo 'export DOCKER_BUILDKIT=1' >> ~/.zshrc
source ~/.zshrc
```

**Resource Allocation:**

1. Docker Desktop → **Preferences** (gear icon)
2. **Resources** → **Advanced**
3. Recommended settings:
   - **CPUs**: 4 or more
   - **Memory**: 8 GB or more
   - **Swap**: 2 GB
   - **Disk**: 60 GB or more

### Troubleshooting macOS

**Issue: "Cannot connect to Docker daemon"**
```bash
# Ensure Docker Desktop is running
open /Applications/Docker.app

# Wait for whale icon in menu bar to stop animating
# Try command again
docker ps
```

**Issue: "Docker Desktop requires macOS 10.14 or newer"**
- Upgrade macOS or use Docker Toolbox (legacy)
- Minimum: macOS 10.14 (Mojave)
- Recommended: macOS 12+ (Monterey or newer)

**Issue: Rosetta 2 not installed (M1/M2/M3)**
```bash
# Install Rosetta 2 for compatibility
softwareupdate --install-rosetta --agree-to-license
```

**Issue: Slow Docker performance**
```bash
# Increase resources in Docker Desktop settings
# Preferences → Resources → Advanced
# Increase CPUs to 4-6
# Increase Memory to 8-12 GB
```

---

## 🐧 Oracle Linux VM Installation

### Install Docker CE (Community Edition)

```bash
# Update system
sudo yum update -y

# Install required packages
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# Add Docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker CE
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker

# Verify installation
sudo docker --version
sudo docker run hello-world
```

### Add User to Docker Group (Important!)

Without this, you'll need `sudo` for every Docker command.

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Apply group changes (logout/login or use newgrp)
newgrp docker

# Verify you can run without sudo
docker ps
```

**Note**: If you get "permission denied", logout and login again for group changes to take effect.

### Configure Docker for Production (Optional)

```bash
# Create daemon configuration
sudo mkdir -p /etc/docker

# Configure Docker daemon
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Restart Docker
sudo systemctl restart docker

# Verify configuration
docker info
```

### Troubleshooting Oracle Linux

**Issue: "Cannot connect to Docker daemon"**
```bash
# Check Docker service status
sudo systemctl status docker

# If not running, start it
sudo systemctl start docker

# If failed, check logs
sudo journalctl -u docker
```

**Issue: "permission denied while trying to connect"**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Re-login or use newgrp
newgrp docker

# Verify
docker ps
```

**Issue: Docker installation fails**
```bash
# Remove conflicting packages
sudo yum remove docker docker-common docker-selinux docker-engine

# Clean yum cache
sudo yum clean all

# Try installation again
sudo yum install -y docker-ce docker-ce-cli containerd.io
```

---

## 🐧 Ubuntu/Debian Installation

### Install Docker CE

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt-get update

# Install Docker CE
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
sudo docker --version
sudo docker run hello-world
```

### Post-Installation Steps

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Verify non-root access
docker ps

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker
```

### For Debian

Replace Ubuntu repository with Debian:

```bash
# For Debian, use debian repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Then continue with apt-get install as above
```

### Troubleshooting Ubuntu/Debian

**Issue: "E: Unable to locate package docker-ce"**
```bash
# Verify you added the repository correctly
cat /etc/apt/sources.list.d/docker.list

# Update package index
sudo apt-get update

# Search for docker packages
apt-cache search docker-ce
```

**Issue: GPG key errors**
```bash
# Re-add GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set correct permissions
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

**Issue: "docker.service failed"**
```bash
# Check service status
sudo systemctl status docker

# View logs
sudo journalctl -u docker --no-pager

# Restart service
sudo systemctl restart docker
```

---

## 🪟 Windows Installation

### Prerequisites

- **Windows 10/11 64-bit**: Pro, Enterprise, or Education (Build 19041 or higher)
- **WSL 2** (Windows Subsystem for Linux 2)
- **Hardware virtualization** enabled in BIOS

### Install WSL 2 (Required)

```powershell
# Open PowerShell as Administrator

# Install WSL 2
wsl --install

# Restart computer when prompted
# After restart, set WSL 2 as default
wsl --set-default-version 2

# Verify WSL 2
wsl --list --verbose
```

### Install Docker Desktop for Windows

1. **Download Docker Desktop**:
   - Visit [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Download for Windows

2. **Install**:
   - Run installer (`Docker Desktop Installer.exe`)
   - Ensure "Use WSL 2 instead of Hyper-V" is checked
   - Follow installation wizard
   - Restart computer when prompted

3. **Launch Docker Desktop**:
   - Start Docker Desktop from Start menu
   - Accept license agreement
   - Wait for Docker Engine to start
   - Look for whale icon in system tray

4. **Verify Installation**:
   ```powershell
   docker --version
   docker run hello-world
   ```

### Configure Docker Desktop

1. **Open Docker Desktop Settings** (gear icon)
2. **General**:
   - ✅ Use WSL 2 based engine
3. **Resources** → **WSL Integration**:
   - ✅ Enable integration with default WSL distro
   - ✅ Enable for your specific distros
4. **Apply & Restart**

### Troubleshooting Windows

**Issue: "WSL 2 installation is incomplete"**
```powershell
# Update WSL
wsl --update

# Install WSL 2 kernel update
# Download from: https://aka.ms/wsl2kernel
# Run the installer
```

**Issue: "Docker Desktop requires a newer WSL kernel"**
```powershell
# Update WSL
wsl --update
wsl --shutdown

# Restart Docker Desktop
```

**Issue: "Hardware assisted virtualization is not enabled"**
- Restart computer
- Enter BIOS/UEFI settings (usually F2, F10, or Del during boot)
- Enable Virtualization Technology (Intel VT-x or AMD-V)
- Save and exit BIOS

**Issue: "Docker Desktop starting..." never completes**
```powershell
# Reset Docker Desktop
# Right-click Docker Desktop in system tray
# Select "Troubleshoot" → "Reset to factory defaults"

# Or uninstall and reinstall Docker Desktop
```

**Issue: Cannot access docker command in PowerShell**
```powershell
# Check if Docker is in PATH
$env:Path

# Restart PowerShell
# Or add Docker to PATH manually:
$env:Path += ";C:\Program Files\Docker\Docker\resources\bin"
```

---

## ✅ Verify Installation

Run these commands on **any platform** to verify Docker is working:

### Basic Verification

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Check Docker info
docker info

# Run hello-world container
docker run hello-world

# List running containers
docker ps

# List all containers
docker ps -a
```

### Expected Output

```bash
$ docker --version
Docker version 24.0.6, build ed223bc

$ docker run hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

### Build Test

Test that Docker can build images:

```bash
# Create a test Dockerfile
cat > Dockerfile.test << EOF
FROM alpine:latest
RUN echo "Hello from Docker build test"
CMD ["/bin/sh"]
EOF

# Build test image
docker build -f Dockerfile.test -t docker-test:latest .

# Run test container
docker run --rm docker-test:latest echo "Docker build successful!"

# Clean up
rm Dockerfile.test
docker rmi docker-test:latest
```

If this works, you're ready to build function images!

---

## 🔧 Docker Resource Requirements

For building OCI Functions, ensure Docker has:

- **Minimum**:
  - 2 CPUs
  - 4 GB RAM
  - 20 GB disk space

- **Recommended**:
  - 4 CPUs
  - 8 GB RAM
  - 60 GB disk space

### Check Current Resources

```bash
# View Docker resource usage
docker system df

# View detailed info
docker info | grep -i "CPUs\|Total Memory"
```

### Clean Up Docker Resources

```bash
# Remove unused images
docker image prune -a

# Remove unused containers
docker container prune

# Remove unused volumes
docker volume prune

# Remove everything unused (use carefully!)
docker system prune -a --volumes
```

---

## 📝 Docker Configuration Tips

### Enable BuildKit (Recommended)

BuildKit provides better performance and features:

```bash
# Enable for current session
export DOCKER_BUILDKIT=1

# Make permanent (add to shell config)
echo 'export DOCKER_BUILDKIT=1' >> ~/.bashrc  # Linux
echo 'export DOCKER_BUILDKIT=1' >> ~/.zshrc   # macOS
source ~/.bashrc  # or ~/.zshrc
```

### Configure Logging

Prevent logs from consuming too much disk space:

```bash
# Edit/create daemon.json
sudo nano /etc/docker/daemon.json

# Add logging configuration
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}

# Restart Docker (Linux)
sudo systemctl restart docker

# For macOS/Windows, restart Docker Desktop
```

---

## ✅ Verification Checklist

Before proceeding, verify:

- [ ] Docker installed (`docker --version` works)
- [ ] Docker daemon running (`docker ps` works without sudo)
- [ ] User added to docker group (Linux only)
- [ ] Test container runs (`docker run hello-world`)
- [ ] Can build images (build test passed)
- [ ] Adequate resources allocated (4+ GB RAM)
- [ ] BuildKit enabled (optional but recommended)

---

## 📚 Next Steps

Once Docker is installed and verified:
- **Next Guide**: [04-iam-policies.md](04-iam-policies.md) - Configure IAM Policies

---

## 🔗 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Desktop for Mac](https://docs.docker.com/desktop/mac/install/)
- [Docker Desktop for Windows](https://docs.docker.com/desktop/windows/install/)
- [Docker on Linux](https://docs.docker.com/engine/install/)
- [Docker BuildKit](https://docs.docker.com/build/buildkit/)
- [Post-installation steps for Linux](https://docs.docker.com/engine/install/linux-postinstall/)
