# 08 - Deploy Delivery Quality Function

This guide covers building and deploying the main delivery quality assessment function with AI vision capabilities.

## 📋 What You'll Accomplish

- ✅ Navigate to function directory
- ✅ Build Docker image locally
- ✅ Push image to OCIR
- ✅ Create function in OCI
- ✅ Configure environment variables
- ✅ Test function deployment

## ⏱️ Estimated Time: 15-20 minutes

---

## 📦 What This Function Does

The **Delivery Quality Function** provides:
- 🖼️ AI-powered image analysis using OCI GenAI Vision
- 📦 Package detection and damage assessment
- 📍 GPS coordinate extraction from EXIF data
- 📊 Quality scoring based on timeliness, location, and damage
- 🔒 Privacy protection with face blurring
- 📝 Structured JSON output for downstream processing

---

## 🚀 Step 1: Navigate to Function Directory

```bash
# Navigate to project root
cd /path/to/Delivery-Intelligence-main

# Navigate to delivery function
cd delivery-function

# Verify files exist
ls -la

# Should see:
# - Dockerfile
# - func.yaml
# - func.py
# - requirements.txt
# - src/ directory
```

---

## 🐳 Step 2: Build Docker Image

### Set Variables

```bash
# From previous guides
OCIR_HOSTNAME=ord.ocir.io  # Your region's OCIR hostname
NAMESPACE=<YOUR_NAMESPACE>  # Your Object Storage namespace
REGION=us-chicago-1  # Your region

# Image name and tag
IMAGE_NAME=delivery-agent
IMAGE_TAG=latest
FULL_IMAGE_PATH=$OCIR_HOSTNAME/$NAMESPACE/$IMAGE_NAME:$IMAGE_TAG

echo "Building image: $FULL_IMAGE_PATH"
```

### Build the Image

```bash
# Build Docker image
docker build -t $FULL_IMAGE_PATH .

# This will:
# 1. Download base Python 3.11 image
# 2. Install all dependencies from requirements.txt
# 3. Copy function code
# 4. Set up entrypoint
```

### Expected Output

```
[+] Building 45.2s (12/12) FINISHED
 => [internal] load build definition from Dockerfile
 => [internal] load .dockerignore
 => [internal] load metadata for docker.io/fnproject/python:3.11
 => CACHED [1/6] FROM docker.io/fnproject/python:3.11
 => [2/6] WORKDIR /function
 => [3/6] ADD requirements.txt /function/
 => [4/6] RUN pip3 install --no-cache-dir -r requirements.txt
 => [5/6] ADD . /function/
 => [6/6] RUN chmod +x /function/func.py
 => exporting to image
 => => writing image sha256:abc123...
 => => naming to ord.ocir.io/namespace/delivery-agent:latest
```

### Verify Image

```bash
# List Docker images
docker images | grep delivery-agent

# Should show your image with size (usually 500MB-1GB)
```

### Troubleshooting Build Issues

**Issue: Build fails with "requirements not found"**
```bash
# Ensure you're in delivery-function directory
pwd  # Should end with /delivery-function

# Verify requirements.txt exists
ls -la requirements.txt
```

**Issue: Build takes very long or fails downloading packages**
```bash
# Check internet connectivity
ping -c 3 pypi.org

# Try building with --no-cache
docker build --no-cache -t $FULL_IMAGE_PATH .
```

**Issue: Out of disk space**
```bash
# Clean up old images
docker system prune -a

# Check available space
docker system df
```

---

## ☁️ Step 3: Push Image to OCIR

### Login to OCIR (if not already logged in)

```bash
# Login with your auth token
docker login $OCIR_HOSTNAME
# Username: <namespace>/<username>
# Password: <auth_token>
```

### Push the Image

```bash
# Push image to OCIR
docker push $FULL_IMAGE_PATH

# This uploads all layers to Oracle Container Registry
# Usually takes 3-10 minutes depending on internet speed
```

### Expected Output

```
The push refers to repository [ord.ocir.io/namespace/delivery-agent]
abc123: Pushed
def456: Pushed
ghi789: Pushed
latest: digest: sha256:xyz123... size: 2841
```

### Verify Image in OCIR

```bash
# Via OCI CLI
oci artifacts container repository list \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --display-name delivery-agent

# Via OCI Console
# Developer Services → Container Registry
# Should see "delivery-agent" repository
```

---

## 🎯 Step 4: Create Function

Now deploy the function to OCI.

### Set Variables

```bash
# From previous guides
FUNCTION_APP_OCID=<YOUR_FUNCTION_APP_OCID>
COMPARTMENT_OCID=<YOUR_COMPARTMENT_OCID>

# Image path (from build step)
FULL_IMAGE_PATH=$OCIR_HOSTNAME/$NAMESPACE/delivery-agent:latest
```

### Create the Function

```bash
# Create function
DELIVERY_FUNCTION_OCID=$(oci fn function create \
  --application-id $FUNCTION_APP_OCID \
  --display-name delivery-quality-function \
  --image $FULL_IMAGE_PATH \
  --memory-in-mbs 2048 \
  --timeout-in-seconds 300 \
  --query 'data.id' \
  --raw-output)

echo "Function OCID: $DELIVERY_FUNCTION_OCID"

# Save this OCID!
```

### Function Parameters Explained

| Parameter | Value | Why |
|-----------|-------|-----|
| `--memory-in-mbs` | 2048 | 2GB RAM for AI processing |
| `--timeout-in-seconds` | 300 | 5 minutes for GenAI calls |
| `--image` | OCIR path | Your Docker image location |

### Wait for Function to Be Active

```bash
# Wait for function to be ready
oci fn function get \
  --function-id $DELIVERY_FUNCTION_OCID \
  --wait-for-state ACTIVE

# Should complete in 30-60 seconds
```

---

## ⚙️ Step 5: Configure Environment Variables

The function needs configuration to access OCI services.

### Required Environment Variables

```bash
# Configure function with environment variables
oci fn function update \
  --function-id $DELIVERY_FUNCTION_OCID \
  --config '{
    "OCI_COMPARTMENT_ID": "<YOUR_COMPARTMENT_OCID>",
    "OCI_OS_NAMESPACE": "<YOUR_NAMESPACE>",
    "OCI_OS_BUCKET": "<YOUR_BUCKET_NAME>",
    "OCI_TEXT_MODEL_OCID": "<YOUR_GENAI_ENDPOINT_OCID>",
    "OCI_GENAI_HOSTNAME": "https://inference.generativeai.us-chicago-1.oci.oraclecloud.com",
    "WEIGHT_TIMELINESS": "0.3",
    "WEIGHT_LOCATION": "0.3",
    "WEIGHT_DAMAGE": "0.4",
    "MAX_DISTANCE_METERS": "50"
  }'
```

### Configuration Variables Explained

| Variable | Purpose | Example |
|----------|---------|---------|
| `OCI_COMPARTMENT_ID` | Where function runs | ocid1.compartment... |
| `OCI_OS_NAMESPACE` | Object Storage namespace | orasenatdpltintegration03 |
| `OCI_OS_BUCKET` | Bucket with delivery images | delivery-images |
| `OCI_TEXT_MODEL_OCID` | GenAI model endpoint | ocid1.generativeaiendpoint... |
| `OCI_GENAI_HOSTNAME` | GenAI API hostname | https://inference.generativeai... |
| `WEIGHT_TIMELINESS` | Score weight (0-1) | 0.3 (30%) |
| `WEIGHT_LOCATION` | Score weight (0-1) | 0.3 (30%) |
| `WEIGHT_DAMAGE` | Score weight (0-1) | 0.4 (40%) |
| `MAX_DISTANCE_METERS` | Acceptable delivery distance | 50 meters |

### Verify Configuration

```bash
# View function configuration
oci fn function get \
  --function-id $DELIVERY_FUNCTION_OCID \
  --query 'data.config'

# Should show all your environment variables
```

---

## ✅ Step 6: Verify Function Deployment

### Check Function Status

```bash
# Get function details
oci fn function get --function-id $DELIVERY_FUNCTION_OCID

# Verify:
# - lifecycle-state: ACTIVE
# - memory-in-mbs: 2048
# - timeout-in-seconds: 300
```

### View Function in Console

1. **OCI Console** → **Developer Services** → **Functions**
2. Click **Applications** → **delivery-intelligence-app**
3. Click **Functions** tab
4. Should see **delivery-quality-function** with status **Active**

---

## 🧪 Step 7: Test Function (Optional but Recommended)

Create a simple test invocation.

### Create Test Event

```bash
# Create test event JSON
cat > test-event.json << 'EOF'
{
  "data": {
    "compartmentId": "<YOUR_COMPARTMENT_OCID>",
    "resourceName": "test-delivery.jpg",
    "namespace": "<YOUR_NAMESPACE>",
    "bucketName": "<YOUR_BUCKET_NAME>"
  },
  "eventTime": "2024-01-10T16:45:00Z",
  "additionalDetails": {
    "expectedLatitude": 37.7749,
    "expectedLongitude": -122.4194,
    "promisedTime": "2024-01-10T17:00:00Z"
  }
}
EOF

# Update with your actual values
```

### Invoke Function

```bash
# Invoke function with test event
oci fn function invoke \
  --function-id $DELIVERY_FUNCTION_OCID \
  --file test-event.json \
  --body -

# Note: This will fail if test image doesn't exist in bucket
# That's OK for now - we're just testing deployment
```

### Expected Response

If successful (with real image):
```json
{
  "status": "success",
  "quality_score": 85.5,
  "timeliness": {...},
  "location": {...},
  "damage": {...}
}
```

If image not found (expected for test):
```json
{
  "status": "error",
  "message": "Image not found"
}
```

---

## 🔧 Troubleshooting

### Issue: "Image pull failed" or "ImagePullBackoff"

**Cause**: OCI can't pull image from OCIR

**Fix**:
```bash
# Verify image exists in OCIR
oci artifacts container repository list \
  --compartment-id $COMPARTMENT_OCID \
  --display-name delivery-agent

# Verify image path is correct
echo $FULL_IMAGE_PATH

# Check IAM policies allow image pull
# Dynamic group should have access to repos
```

### Issue: Function times out

**Cause**: Timeout too short or function hanging

**Fix**:
```bash
# Increase timeout
oci fn function update \
  --function-id $DELIVERY_FUNCTION_OCID \
  --timeout-in-seconds 300

# Check function logs for errors
oci logging-search search-logs \
  --search-query "search \"<COMPARTMENT_OCID>/functions\"" \
  --time-start $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S.000Z) \
  --time-end $(date -u +%Y-%m-%dT%H:%M:%S.000Z)
```

### Issue: Out of memory errors

**Cause**: 2048 MB insufficient for processing

**Fix**:
```bash
# Increase memory allocation
oci fn function update \
  --function-id $DELIVERY_FUNCTION_OCID \
  --memory-in-mbs 4096  # 4GB
```

### Issue: Can't access GenAI or Object Storage

**Cause**: Missing dynamic group policies

**Fix**:
```bash
# Verify dynamic group policies (from guide 04)
oci iam policy list --compartment-id $TENANCY_OCID --all

# Ensure these policies exist:
# - Allow dynamic-group to use generative-ai-family
# - Allow dynamic-group to manage objects
```

---

## 🔄 Updating the Function

When you make code changes, rebuild and redeploy:

```bash
# 1. Make code changes in delivery-function/src/

# 2. Rebuild image with new tag
docker build -t $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:v2 .

# 3. Push new image
docker push $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:v2

# 4. Update function with new image
oci fn function update \
  --function-id $DELIVERY_FUNCTION_OCID \
  --image $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:v2
```

---

## 📝 Save Configuration

```bash
# Update config file
cat >> ~/oci-deployment-config.txt << EOF

# Delivery Function
DELIVERY_FUNCTION_OCID=$DELIVERY_FUNCTION_OCID
DELIVERY_IMAGE_PATH=$FULL_IMAGE_PATH
EOF
```

---

## ✅ Verification Checklist

Before proceeding, verify:

- [ ] Docker image built successfully
- [ ] Image pushed to OCIR
- [ ] Image visible in OCIR console
- [ ] Function created with correct parameters
- [ ] Function status is **ACTIVE**
- [ ] Environment variables configured
- [ ] Function OCID saved
- [ ] Test invocation attempted (optional)

---

## 📚 Next Steps

Once delivery function is deployed:
- **Next Guide**: [09-deploy-face-blur-function.md](09-deploy-face-blur-function.md) - Deploy face blur function
- **Skip to**: [10-testing-verification.md](10-testing-verification.md) - Test both functions

---

## 🔗 Additional Resources

- [OCI Functions Overview](https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm)
- [Deploying Functions](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsdeploying.htm)
- [Function Configuration](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsconfig.htm)
- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [OCIR Documentation](https://docs.oracle.com/en-us/iaas/Content/Registry/home.htm)
