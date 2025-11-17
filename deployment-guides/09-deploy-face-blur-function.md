# 09 - Deploy Face Blur Function

This guide covers deploying the face blur function for privacy protection in delivery images.

## 📋 What You'll Accomplish

- ✅ Navigate to face-blur-function directory
- ✅ Build Docker image
- ✅ Push image to OCIR
- ✅ Create face blur function in OCI
- ✅ Configure environment variables
- ✅ Test function deployment

## ⏱️ Estimated Time: 10-15 minutes

---

## 🔒 What This Function Does

The **Face Blur Function** provides:
- 👤 Automatic face detection using OpenCV Haar Cascades
- 🔒 Adaptive blur intensity based on face size
- ⚡ Fast processing (<300ms overhead)
- 📸 Privacy-compliant image anonymization (GDPR, CCPA, BIPA)
- 🎯 No impact on package damage analysis

---

## 🚀 Step 1: Navigate to Function Directory

```bash
# Navigate to project root
cd /path/to/Delivery-Intelligence-main

# Navigate to face-blur function
cd face-blur-function

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

# Image name and tag
IMAGE_NAME=face-blur-agent
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
# 2. Install OpenCV and other dependencies
# 3. Copy function code
# 4. Set up entrypoint
```

**Note**: Building may take longer than delivery-function due to OpenCV compilation.

### Expected Output

```
[+] Building 60.5s (12/12) FINISHED
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
 => => writing image sha256:def456...
 => => naming to ord.ocir.io/namespace/face-blur-agent:latest
```

### Verify Image

```bash
# List Docker images
docker images | grep face-blur-agent

# Should show your image (usually 400-800MB)
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
# Usually takes 2-8 minutes depending on internet speed
```

### Expected Output

```
The push refers to repository [ord.ocir.io/namespace/face-blur-agent]
abc456: Pushed
def789: Pushed
ghi012: Pushed
latest: digest: sha256:xyz789... size: 2456
```

### Verify Image in OCIR

```bash
# Via OCI CLI
oci artifacts container repository list \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --display-name face-blur-agent

# Should see face-blur-agent repository
```

---

## 🎯 Step 4: Create Function

Deploy the face blur function to OCI.

### Set Variables

```bash
# From previous guides
FUNCTION_APP_OCID=<YOUR_FUNCTION_APP_OCID>

# Image path (from build step)
FULL_IMAGE_PATH=$OCIR_HOSTNAME/$NAMESPACE/face-blur-agent:latest
```

### Create the Function

```bash
# Create function
FACE_BLUR_FUNCTION_OCID=$(oci fn function create \
  --application-id $FUNCTION_APP_OCID \
  --display-name face-blur-function \
  --image $FULL_IMAGE_PATH \
  --memory-in-mbs 1024 \
  --timeout-in-seconds 300 \
  --query 'data.id' \
  --raw-output)

echo "Function OCID: $FACE_BLUR_FUNCTION_OCID"

# Save this OCID!
```

### Function Parameters Explained

| Parameter | Value | Why |
|-----------|-------|-----|
| `--memory-in-mbs` | 1024 | 1GB RAM (sufficient for OpenCV) |
| `--timeout-in-seconds` | 300 | 5 minutes (usually completes in <1s) |
| `--image` | OCIR path | Your Docker image location |

**Note**: Face blur function needs less memory than delivery function since it doesn't use GenAI.

### Wait for Function to Be Active

```bash
# Wait for function to be ready
oci fn function get \
  --function-id $FACE_BLUR_FUNCTION_OCID \
  --wait-for-state ACTIVE

# Should complete in 30-60 seconds
```

---

## ⚙️ Step 5: Configure Environment Variables

The face blur function needs minimal configuration.

### Required Environment Variables

```bash
# Configure function with environment variables
oci fn function update \
  --function-id $FACE_BLUR_FUNCTION_OCID \
  --config '{
    "OCI_COMPARTMENT_ID": "<YOUR_COMPARTMENT_OCID>",
    "OCI_OS_NAMESPACE": "<YOUR_NAMESPACE>",
    "OCI_OS_BUCKET": "<YOUR_BUCKET_NAME>",
    "BLUR_INTENSITY": "71",
    "MIN_FACE_SIZE": "30"
  }'
```

### Configuration Variables Explained

| Variable | Purpose | Default | Range |
|----------|---------|---------|-------|
| `OCI_COMPARTMENT_ID` | Where function runs | Required | - |
| `OCI_OS_NAMESPACE` | Object Storage namespace | Required | - |
| `OCI_OS_BUCKET` | Bucket with images | Required | - |
| `BLUR_INTENSITY` | Blur strength (must be odd) | 71 | 11-99 |
| `MIN_FACE_SIZE` | Minimum face size (pixels) | 30 | 20-100 |

**Blur Intensity Tips:**
- **71** (Default): Maximum anonymization, best for privacy
- **51**: Strong blur, still unrecognizable
- **31**: Moderate blur
- **11**: Light blur (use only for testing)

### Verify Configuration

```bash
# View function configuration
oci fn function get \
  --function-id $FACE_BLUR_FUNCTION_OCID \
  --query 'data.config'

# Should show all your environment variables
```

---

## ✅ Step 6: Verify Function Deployment

### Check Function Status

```bash
# Get function details
oci fn function get --function-id $FACE_BLUR_FUNCTION_OCID

# Verify:
# - lifecycle-state: ACTIVE
# - memory-in-mbs: 1024
# - timeout-in-seconds: 300
```

### View Function in Console

1. **OCI Console** → **Developer Services** → **Functions**
2. Click **Applications** → **delivery-intelligence-app**
3. Click **Functions** tab
4. Should see both:
   - **delivery-quality-function** ✅
   - **face-blur-function** ✅

---

## 🧪 Step 7: Test Function (Optional)

Test face blur function independently.

### Create Test Event

```bash
# Create test event JSON
cat > test-blur-event.json << 'EOF'
{
  "data": {
    "compartmentId": "<YOUR_COMPARTMENT_OCID>",
    "resourceName": "test-image-with-faces.jpg",
    "namespace": "<YOUR_NAMESPACE>",
    "bucketName": "<YOUR_BUCKET_NAME>"
  }
}
EOF

# Update with your actual values
```

### Invoke Function

```bash
# Invoke function with test event
oci fn function invoke \
  --function-id $FACE_BLUR_FUNCTION_OCID \
  --file test-blur-event.json \
  --body -
```

### Expected Response

If successful:
```json
{
  "status": "success",
  "faces_detected": 2,
  "faces_blurred": 2,
  "processing_time_ms": 245,
  "output_image": "blurred/test-image-with-faces.jpg"
}
```

If no faces found:
```json
{
  "status": "success",
  "faces_detected": 0,
  "faces_blurred": 0,
  "processing_time_ms": 123,
  "output_image": "blurred/test-image-with-faces.jpg"
}
```

---

## 🔧 Troubleshooting

### Issue: "Image pull failed"

**Fix**:
```bash
# Verify image exists in OCIR
oci artifacts container repository list \
  --compartment-id $COMPARTMENT_OCID \
  --display-name face-blur-agent

# Verify image path
echo $FULL_IMAGE_PATH
```

### Issue: Function times out during build

**Cause**: OpenCV installation takes time on first run

**Fix**:
```bash
# This is normal for first invocation
# Wait 60-90 seconds for container warm-up
# Subsequent invocations will be fast (<1 second)
```

### Issue: "Module 'cv2' not found"

**Cause**: OpenCV not installed correctly

**Fix**:
```bash
# Verify requirements.txt includes opencv-python-headless
cat face-blur-function/requirements.txt | grep opencv

# Rebuild image with --no-cache
docker build --no-cache -t $FULL_IMAGE_PATH .
docker push $FULL_IMAGE_PATH

# Update function
oci fn function update \
  --function-id $FACE_BLUR_FUNCTION_OCID \
  --image $FULL_IMAGE_PATH
```

### Issue: Faces not being detected

**Cause**: MIN_FACE_SIZE too high or blur intensity issue

**Fix**:
```bash
# Lower minimum face size
oci fn function update \
  --function-id $FACE_BLUR_FUNCTION_OCID \
  --config '{"MIN_FACE_SIZE": "20"}'

# Test with sample image that has clear faces
```

---

## 🔄 Integration with Delivery Function

The face blur function can be called by the delivery function automatically, or used standalone.

### Standalone Use

For privacy compliance, process images before analysis:

```bash
# 1. Upload image to Object Storage
# 2. Invoke face-blur-function
# 3. Use blurred image for delivery analysis
```

### Integrated Use

Delivery function can call face-blur-function automatically (if configured).

---

## 📊 Performance Characteristics

### Typical Performance

| Metric | Value |
|--------|-------|
| **Cold start** | 3-5 seconds |
| **Warm invocation** | <300ms |
| **Face detection** | ~100ms per face |
| **Blur operation** | ~50ms per face |
| **Memory usage** | ~400-600 MB |

### Optimization Tips

- ✅ Keep function warm with periodic invocations
- ✅ Process images in batches if possible
- ✅ Use appropriate MIN_FACE_SIZE (larger = faster)
- ✅ Consider increasing memory for large images

---

## 🔄 Updating the Function

When you make code changes:

```bash
# 1. Make code changes in face-blur-function/src/

# 2. Rebuild image
docker build -t $OCIR_HOSTNAME/$NAMESPACE/face-blur-agent:v2 .

# 3. Push new image
docker push $OCIR_HOSTNAME/$NAMESPACE/face-blur-agent:v2

# 4. Update function
oci fn function update \
  --function-id $FACE_BLUR_FUNCTION_OCID \
  --image $OCIR_HOSTNAME/$NAMESPACE/face-blur-agent:v2
```

---

## 📝 Save Configuration

```bash
# Update config file
cat >> ~/oci-deployment-config.txt << EOF

# Face Blur Function
FACE_BLUR_FUNCTION_OCID=$FACE_BLUR_FUNCTION_OCID
FACE_BLUR_IMAGE_PATH=$FULL_IMAGE_PATH
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
- [ ] Both functions (delivery + face-blur) active in application

---

## 🎉 Deployment Complete!

You now have both functions deployed:
- ✅ **delivery-quality-function** - AI-powered delivery assessment
- ✅ **face-blur-function** - Privacy-compliant face anonymization

---

## 📚 Next Steps

Once both functions are deployed:
- **Next Guide**: [10-testing-verification.md](10-testing-verification.md) - Test complete system
- **Optional**: [11-event-triggers.md](11-event-triggers.md) - Set up automatic triggers

---

## 🔗 Additional Resources

- [Face Blurring Documentation](../docs/face-blurring-privacy.md)
- [OpenCV Haar Cascades](https://docs.opencv.org/3.4/db/d28/tutorial_cascade_classifier.html)
- [Privacy Compliance Guide](../docs/face-blurring-quickstart.md)
- [OCI Functions Best Practices](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsbestpractices.htm)
