# 02 - OCI CLI Installation and Configuration

This guide covers installing and configuring the OCI Command Line Interface (CLI) on all supported platforms.

## 📋 What You'll Accomplish

- ✅ Install OCI CLI on your platform
- ✅ Configure OCI CLI with your credentials
- ✅ Generate and upload API signing keys
- ✅ Verify CLI functionality

## ⏱️ Estimated Time: 15-20 minutes

---

## 🖥️ Choose Your Platform

- [macOS Installation](#macos-installation)
- [Oracle Linux VM Installation](#oracle-linux-vm-installation)
- [Ubuntu/Debian Installation](#ubuntudebian-installation)
- [Windows Installation](#windows-installation)
- [OCI Cloud Shell](#oci-cloud-shell) (No installation needed!)

---

## 🍎 macOS Installation

### Option 1: Homebrew (Recommended)

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install OCI CLI
brew update && brew install oci-cli

# Verify installation
oci --version
```

### Option 2: Manual Installation Script

```bash
# Download and run installer
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Accept defaults or customize installation location
# Default location: ~/lib/oracle-cli

# Add to PATH (if not already added)
echo 'export PATH="$HOME/lib/oracle-cli/bin:$PATH"' >> ~/.zshrc  # For zsh (default on newer macOS)
# OR
echo 'export PATH="$HOME/lib/oracle-cli/bin:$PATH"' >> ~/.bash_profile  # For bash

# Reload shell configuration
source ~/.zshrc  # or source ~/.bash_profile

# Verify installation
oci --version
```

### Troubleshooting macOS

**Issue: `oci: command not found`**
```bash
# Check if OCI CLI is installed
ls ~/lib/oracle-cli/bin/oci

# Add to PATH manually
export PATH="$HOME/lib/oracle-cli/bin:$PATH"

# Make it permanent
echo 'export PATH="$HOME/lib/oracle-cli/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Issue: Python version conflict**
```bash
# OCI CLI requires Python 3.6+
python3 --version

# If Python is too old, install via Homebrew
brew install python@3.11
```

**Issue: Permission denied**
```bash
# Don't use sudo with Homebrew
brew install oci-cli

# If manual install, ensure you own the directory
sudo chown -R $(whoami) ~/lib/oracle-cli
```

---

## 🐧 Oracle Linux VM Installation

### Using YUM Package Manager (Recommended)

```bash
# Install OCI CLI from YUM repository
sudo yum install -y python36-oci-cli

# Verify installation
oci --version
```

### Manual Installation (Alternative)

```bash
# Install required dependencies
sudo yum install -y python3 python3-pip

# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Accept prompts or use automated installation
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults

# Add to PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
oci --version
```

### Troubleshooting Oracle Linux

**Issue: `python36-oci-cli` package not found**
```bash
# Enable OL7 repository
sudo yum-config-manager --enable ol7_developer

# Update repository cache
sudo yum makecache

# Try installation again
sudo yum install -y python36-oci-cli
```

**Issue: pip installation fails**
```bash
# Update pip
python3 -m pip install --upgrade pip

# Install OCI CLI via pip
pip3 install oci-cli --user

# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 🐧 Ubuntu/Debian Installation

### Using Installation Script

```bash
# Install required dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip

# Download and run installer
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Accept all defaults for quick installation
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults

# Add to PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
oci --version
```

### Using pip (Alternative)

```bash
# Install via pip
pip3 install oci-cli --user

# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
oci --version
```

### Troubleshooting Ubuntu/Debian

**Issue: `command not found` after installation**
```bash
# Add to PATH
export PATH="$HOME/bin:$PATH"

# Make permanent
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Issue: SSL certificate errors**
```bash
# Install ca-certificates
sudo apt-get install -y ca-certificates

# Update certificates
sudo update-ca-certificates
```

---

## 🪟 Windows Installation

### Using PowerShell (Recommended)

```powershell
# Open PowerShell as Administrator

# Download installer
Invoke-WebRequest -Uri https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.ps1 -OutFile install.ps1

# Run installer
.\install.ps1 -AcceptAllDefaults

# Verify installation (restart PowerShell first)
oci --version
```

### Using Windows Subsystem for Linux (WSL2)

If you have WSL2 installed, follow the [Ubuntu/Debian Installation](#ubuntudebian-installation) steps inside your WSL2 environment.

### Troubleshooting Windows

**Issue: Execution policy prevents script**
```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run installer again
.\install.ps1 -AcceptAllDefaults
```

**Issue: Python not found**
```powershell
# Install Python from Microsoft Store or python.org
# Ensure Python 3.6+ is installed
python --version

# Add Python to PATH
# Control Panel → System → Advanced → Environment Variables
# Add Python and pip to PATH
```

**Issue: `oci` command not recognized**
```powershell
# Check installation location (usually)
# C:\Users\<username>\bin\oci.exe

# Add to PATH via PowerShell
$env:Path += ";C:\Users\$env:USERNAME\bin"

# Make permanent (System Properties → Environment Variables)
```

---

## ☁️ OCI Cloud Shell

If you're using OCI Cloud Shell, **OCI CLI is pre-installed!** Skip to [Configuration](#oci-cli-configuration) section.

To access Cloud Shell:
1. Log into OCI Console
2. Click the **Cloud Shell icon** (top-right, looks like `>_`)
3. Wait for Cloud Shell to start
4. Verify: `oci --version`

**Note**: Cloud Shell times out after 20 minutes of inactivity.

---

## 🔧 OCI CLI Configuration

After installation, configure OCI CLI with your credentials.

### Interactive Configuration (Recommended for First-Time Setup)

```bash
# Start interactive configuration
oci setup config

# You'll be prompted for:
# 1. Configuration file location: [Press Enter for default: ~/.oci/config]
# 2. User OCID: [Paste your user OCID from prerequisites]
# 3. Tenancy OCID: [Paste your tenancy OCID]
# 4. Region: [Enter your region identifier, e.g., us-chicago-1]
# 5. Generate new API signing key? [Y/n]: Y
# 6. Key directory location: [Press Enter for default: ~/.oci]
# 7. Key name: [Press Enter for default: oci_api_key]
```

**Example session:**
```
Enter a location for your config [/Users/yourname/.oci/config]: [Press Enter]
Enter a user OCID: ocid1.user.oc1..aaaaaaaexample
Enter a tenancy OCID: ocid1.tenancy.oc1..aaaaaaaexample
Enter a region: us-chicago-1
Do you want to generate a new API Signing RSA key pair? [Y/n]: Y
Enter a directory for your keys [/Users/yourname/.oci]: [Press Enter]
Enter a name for your key [oci_api_key]: [Press Enter]
```

This generates:
- `~/.oci/config` - Configuration file
- `~/.oci/oci_api_key.pem` - Private key
- `~/.oci/oci_api_key_public.pem` - Public key

### Manual Configuration (Advanced)

```bash
# Create OCI directory
mkdir -p ~/.oci

# Create config file
cat > ~/.oci/config << EOF
[DEFAULT]
user=<YOUR_USER_OCID>
fingerprint=<WILL_BE_ADDED_AFTER_KEY_UPLOAD>
tenancy=<YOUR_TENANCY_OCID>
region=<YOUR_REGION_ID>
key_file=~/.oci/oci_api_key.pem
EOF

# Generate API signing key
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# Set proper permissions
chmod 600 ~/.oci/oci_api_key.pem
chmod 644 ~/.oci/oci_api_key_public.pem
```

---

## 🔑 Upload API Public Key to OCI

After generating your API signing key, you must upload the public key to OCI.

### Via OCI Console

1. **Log into OCI Console**
2. Click **Profile icon** (top-right) → **User Settings**
3. Scroll to **API Keys** section (left sidebar)
4. Click **Add API Key**
5. Select **Paste Public Key**
6. Copy the contents of your public key:
   ```bash
   cat ~/.oci/oci_api_key_public.pem
   ```
7. Paste the entire key (including `-----BEGIN PUBLIC KEY-----` and `-----END PUBLIC KEY-----`)
8. Click **Add**

9. **Important**: Copy the **Fingerprint** displayed
10. Update your config file with the fingerprint:
    ```bash
    # Edit config file
    nano ~/.oci/config
    
    # Add fingerprint line (looks like: a1:b2:c3:d4:...)
    fingerprint=a1:b2:c3:d4:e5:f6:g7:h8:i9:j0:k1:l2:m3:n4:o5:p6
    ```

### Verify Public Key Upload

```bash
# View your API keys
oci iam api-key list --user-id <YOUR_USER_OCID>

# Should show your key with matching fingerprint
```

---

## ✅ Verify Installation and Configuration

### Test OCI CLI

```bash
# Test basic connectivity
oci iam region list

# Test authentication
oci iam user get --user-id <YOUR_USER_OCID>

# Test compartment access
oci iam compartment get --compartment-id <YOUR_COMPARTMENT_OCID>

# All commands should return JSON data without errors
```

### Check Configuration File

```bash
# View your configuration
cat ~/.oci/config

# Should look like:
# [DEFAULT]
# user=ocid1.user.oc1..aaaaaaaXXXXXXXX
# fingerprint=a1:b2:c3:d4:e5:f6:g7:h8:i9:j0:k1:l2:m3:n4:o5:p6
# tenancy=ocid1.tenancy.oc1..aaaaaaaXXXXXXXX
# region=us-chicago-1
# key_file=~/.oci/oci_api_key.pem
```

### Check File Permissions

```bash
# Verify permissions (important for security)
ls -la ~/.oci/

# Private key should be 600 (-rw-------)
# Public key should be 644 (-rw-r--r--)
# Config should be 600 (-rw-------)

# Fix if needed
chmod 600 ~/.oci/oci_api_key.pem
chmod 644 ~/.oci/oci_api_key_public.pem
chmod 600 ~/.oci/config
```

---

## 🔧 Common Configuration Issues

### Issue: "Not authenticated" or "401 Unauthorized"

**Causes:**
- Public key not uploaded to OCI Console
- Wrong fingerprint in config file
- Wrong user OCID

**Fix:**
```bash
# Verify public key is uploaded
oci iam api-key list --user-id <YOUR_USER_OCID>

# Verify fingerprint matches
# Compare fingerprint in config with fingerprint in OCI Console

# Regenerate if needed
oci setup config --repair-file-permissions
```

### Issue: "Service error: NotAuthenticated"

**Fix:**
```bash
# Check config file exists and has correct format
cat ~/.oci/config

# Check private key exists
ls ~/.oci/oci_api_key.pem

# Verify key permissions
chmod 600 ~/.oci/oci_api_key.pem

# Test with debug mode
oci --debug iam region list
```

### Issue: "ConfigFileNotFound"

**Fix:**
```bash
# Create config file
oci setup config

# Or specify config location
oci --config-file /path/to/config iam region list
```

### Issue: Certificate verification errors

**Fix:**
```bash
# Update ca-certificates (Linux)
sudo apt-get install -y ca-certificates  # Ubuntu/Debian
sudo yum install -y ca-certificates      # Oracle Linux

# macOS - update certificates
brew upgrade openssl

# Windows - ensure Python has SSL support
python -c "import ssl; print(ssl.OPENSSL_VERSION)"
```

---

## 📝 Configuration File Format

Example complete `~/.oci/config`:

```ini
[DEFAULT]
user=ocid1.user.oc1..aaaaaaaexampleuserocidhere
fingerprint=a1:b2:c3:d4:e5:f6:g7:h8:i9:j0:k1:l2:m3:n4:o5:p6
tenancy=ocid1.tenancy.oc1..aaaaaaaexampletenancyocidhere
region=us-chicago-1
key_file=~/.oci/oci_api_key.pem

# You can have multiple profiles
[PROFILE2]
user=ocid1.user.oc1..anotheuserocid
fingerprint=x1:x2:x3:x4:x5:x6:x7:x8:x9:x0:x1:x2:x3:x4:x5:x6
tenancy=ocid1.tenancy.oc1..anothertenancyocid
region=us-ashburn-1
key_file=~/.oci/oci_api_key_profile2.pem
```

To use alternate profile:
```bash
oci --profile PROFILE2 iam region list
```

---

## ✅ Verification Checklist

Before proceeding, verify:

- [ ] OCI CLI installed (`oci --version` works)
- [ ] Configuration file created at `~/.oci/config`
- [ ] API signing keys generated
- [ ] Public key uploaded to OCI Console
- [ ] Fingerprint added to config file
- [ ] File permissions correct (600 for private key)
- [ ] `oci iam region list` returns data
- [ ] `oci iam user get --user-id <YOUR_OCID>` works

---

## 📚 Next Steps

Once OCI CLI is installed and configured:
- **Next Guide**: [03-docker-installation.md](03-docker-installation.md) - Install Docker

---

## 🔗 Additional Resources

- [OCI CLI Documentation](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)
- [OCI CLI GitHub](https://github.com/oracle/oci-cli)
- [OCI CLI Command Reference](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/)
- [API Signing Key Setup](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm)
