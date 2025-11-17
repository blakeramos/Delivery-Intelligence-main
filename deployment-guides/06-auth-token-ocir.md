# 06 - Auth Token and OCIR Access

This guide covers generating an Auth Token for Docker login to Oracle Container Image Registry (OCIR).

## 📋 What You'll Accomplish

- ✅ Understand what Auth Tokens are and why you need them
- ✅ Generate an Auth Token via OCI Console
- ✅ Save Auth Token securely
- ✅ Test Docker login to OCIR

## ⏱️ Estimated Time: 5 minutes

---

## 🔑 What is an Auth Token?

An **Auth Token** is a special password used for:
- Logging into Oracle Container Image Registry (OCIR) with Docker
- Authenticating API calls to certain OCI services
- Alternative to using API signing keys for some services

### Auth Token vs API Signing Key

| Auth Token | API Signing Key |
|------------|-----------------|
| Used for Docker/OCIR login | Used for OCI CLI authentication |
| Simple password-like token | RSA key pair (public/private) |
| Can be regenerated easily | Requires reuploading public key |
| Used as Docker password | Used by OCI CLI |

---

## 🎯 Step 1: Generate Auth Token

### Via OCI Console (Recommended)

1. **Log into OCI Console**
2. Click **Profile icon** (top-right) → **User Settings**
3. Scroll down to **Auth Tokens** section (left sidebar)
4. Click **Generate Token**
5. **Description**: Enter a description
   ```
   OCIR Docker Access for Functions
   ```
6. Click **Generate Token**
7. **IMPORTANT**: Copy the token immediately!
   - You won't be able to retrieve it later
   - Click **Copy** button
   - Paste into a secure location

**The token looks like this:**
```
}xK1x2<example>token3J8x}
```

### Save Your Auth Token

```bash
# Save to a secure location (NOT in git!)
# Option 1: Save to a file (secure location only!)
echo "}xK1x2<your_actual_token>3J8x}" > ~/.oci/auth_token.txt
chmod 600 ~/.oci/auth_token.txt

# Option 2: Add to your config file (recommended)
cat >> ~/oci-deployment-config.txt << EOF

# Auth Token (for OCIR)
AUTH_TOKEN=}xK1x2<your_actual_token>3J8x}
EOF
chmod 600 ~/oci-deployment-config.txt
```

**Security Note**: 
- Never commit auth tokens to git
- Store in secure password manager
- Regenerate if compromised
- Each user should have their own auth token

---

## 🔧 Step 2: Test Docker Login to OCIR

Before deploying functions, verify you can log into OCIR.

### Prepare Login Credentials

You need three pieces of information:

1. **OCIR Hostname**: Based on your region (from prerequisites)
   ```
   Example: ord.ocir.io (for us-chicago-1)
   ```

2. **Username**: Format is `<namespace>/<username>`
   ```
   Example: orasenatdpltintegration03/blake.ramos@oracle.com
   ```

3. **Password**: Your Auth Token (just generated)
   ```
   Example: }xK1x2<your_actual_token>3J8x}
   ```

### Docker Login Command

```bash
# Set variables (from your prerequisites)
OCIR_HOSTNAME=ord.ocir.io  # Your region's OCIR hostname
NAMESPACE=<YOUR_NAMESPACE>  # From prerequisites
USERNAME=<YOUR_OCI_USERNAME>  # Usually your email

# Login to OCIR
docker login $OCIR_HOSTNAME

# When prompted:
# Username: orasenatdpltintegration03/blake.ramos@oracle.com
# Password: <paste your auth token>
```

### Alternative: Login with Command

```bash
# Login with credentials in command (careful with shell history!)
echo "<YOUR_AUTH_TOKEN>" | docker login $OCIR_HOSTNAME \
  --username $NAMESPACE/$USERNAME \
  --password-stdin
```

### Expected Output

**Success:**
```
Login Succeeded
```

**Failure:**
```
Error response from daemon: Get https://ord.ocir.io/v2/: unauthorized: authentication required
```

---

## ✅ Step 3: Verify OCIR Access

Test that you can interact with OCIR.

### List Your OCIR Repositories

```bash
# Via OCI CLI
oci artifacts container repository list \
  --compartment-id <YOUR_COMPARTMENT_OCID>

# Should return empty list or existing repositories (not an error)
```

### Via OCI Console

1. **OCI Console** → **Developer Services** → **Container Registry**
2. Select your compartment
3. You should see the OCIR interface (may be empty if no images pushed yet)

---

## 🔧 Troubleshooting

### Issue: "unauthorized: authentication required"

**Causes:**
- Wrong username format
- Wrong auth token
- Auth token expired or revoked
- Wrong OCIR hostname

**Fix:**
```bash
# Verify username format
# Should be: <namespace>/<username>
# Example: orasenatdpltintegration03/blake.ramos@oracle.com

# Check namespace
oci os ns get

# Verify OCIR hostname for your region
# See prerequisites guide for region-to-hostname mapping

# Try logging in again with correct credentials
docker login $OCIR_HOSTNAME
```

### Issue: "Get https://xxx.ocir.io/v2/: dial tcp: lookup xxx.ocir.io: no such host"

**Cause**: Wrong OCIR hostname

**Fix:**
```bash
# Verify OCIR hostname matches your region
# Common hostnames:
# us-chicago-1: ord.ocir.io
# us-ashburn-1: iad.ocir.io
# us-phoenix-1: phx.ocir.io

# Check your region
oci iam region-subscription list
```

### Issue: "Cannot connect to Docker daemon"

**Cause**: Docker not running

**Fix:**
```bash
# Start Docker (macOS)
open /Applications/Docker.app

# Start Docker (Linux)
sudo systemctl start docker

# Verify Docker is running
docker ps
```

### Issue: "Auth token not working"

**Cause**: Token may be revoked or expired

**Fix:**
```bash
# Generate new auth token
# OCI Console → User Settings → Auth Tokens → Generate Token

# Delete old token if needed
# OCI Console → User Settings → Auth Tokens → Delete

# Login with new token
docker login $OCIR_HOSTNAME
```

---

## 🔐 Managing Auth Tokens

### View Your Auth Tokens

```bash
# Via CLI
oci iam auth-token list --user-id <YOUR_USER_OCID>

# Note: The actual token value is never shown again after generation
```

### Delete Auth Token

If you need to revoke access:

```bash
# Via OCI Console
# User Settings → Auth Tokens → Three dots → Delete

# Via CLI
oci iam auth-token delete \
  --user-id <YOUR_USER_OCID> \
  --auth-token-id <AUTH_TOKEN_OCID>
```

### Generate Additional Tokens

You can have up to 2 auth tokens per user:

```bash
# Via OCI Console
# User Settings → Auth Tokens → Generate Token
# Give it a descriptive name (e.g., "Laptop", "CI/CD Pipeline")
```

---

## 📝 OCIR Image Path Format

When you push images to OCIR, they follow this path format:

```
<region>.ocir.io/<namespace>/<repository>:<tag>
```

**Example:**
```
ord.ocir.io/orasenatdpltintegration03/delivery-agent:latest
```

**Breakdown:**
- `ord.ocir.io` - OCIR hostname for us-chicago-1
- `orasenatdpltintegration03` - Your namespace
- `delivery-agent` - Repository name (you choose this)
- `latest` - Image tag (you choose this)

---

## 💡 Best Practices

### Security

- ✅ Use unique auth tokens for different environments
- ✅ Rotate auth tokens regularly
- ✅ Never commit auth tokens to version control
- ✅ Use password manager for auth tokens
- ✅ Revoke tokens when no longer needed

### Naming

- ✅ Use descriptive token names ("Laptop", "CI/CD", etc.)
- ✅ Include date in description for tracking
- ✅ Document which token is used where

### Storage

```bash
# Good: Secure file with restricted permissions
echo "token" > ~/.oci/auth_token.txt
chmod 600 ~/.oci/auth_token.txt

# Bad: Plain text in shell history
export AUTH_TOKEN="token"

# Bad: Committed to git
git add secrets.txt  # DON'T DO THIS!
```

---

## 📋 Quick Reference

### Generate Auth Token
1. OCI Console → Profile → User Settings
2. Auth Tokens → Generate Token
3. Copy token immediately

### Docker Login
```bash
docker login ord.ocir.io
Username: <namespace>/<username>
Password: <auth_token>
```

### OCIR Image Format
```
<region>.ocir.io/<namespace>/<repo>:<tag>
```

---

## ✅ Verification Checklist

Before proceeding, verify:

- [ ] Auth token generated
- [ ] Auth token saved securely
- [ ] Docker login to OCIR succeeds
- [ ] Can list OCIR repositories (via CLI or Console)
- [ ] Know your OCIR hostname and namespace
- [ ] Understand OCIR image path format

---

## 📚 Next Steps

Once OCIR access is configured:
- **Next Guide**: [07-function-application.md](07-function-application.md) - Create Function Application

---

## 🔗 Additional Resources

- [Auth Tokens Documentation](https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrygettingauthtoken.htm)
- [OCIR Documentation](https://docs.oracle.com/en-us/iaas/Content/Registry/home.htm)
- [Accessing OCIR](https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registryoverview.htm)
- [Docker Login Documentation](https://docs.docker.com/engine/reference/commandline/login/)
