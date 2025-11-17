# 10 - Testing and Verification

This comprehensive guide covers testing your deployed functions and verifying the complete system works as expected.

## 📋 What You'll Accomplish

- ✅ Verify all components are deployed
- ✅ Test delivery quality function
- ✅ Test face blur function
- ✅ Upload test images to Object Storage
- ✅ Verify end-to-end workflow
- ✅ Review logs and troubleshoot issues

## ⏱️ Estimated Time: 15-20 minutes

---

## ✅ Step 1: Verify All Components

Before testing, ensure everything is deployed.

### Check Functions Status

```bash
# List all functions in your application
oci fn function list \
  --application-id <YOUR_FUNCTION_APP_OCID>

# Should see:
# - delivery-quality-function (ACTIVE)
# - face-blur-function (ACTIVE)
```

### Verification Checklist

```bash
# OCI CLI installed and configured
oci --version

# Docker installed and running
docker --version

# Both function images in OCIR
oci artifacts container repository list \
  --compartment-id <YOUR_COMPARTMENT_OCID>

# VCN and networking configured
oci network vcn list --compartment-id <YOUR_COMPARTMENT_OCID>

# IAM policies in place
oci iam policy list --compartment-id <YOUR_TENANCY_OCID> --all

# All functions ACTIVE
oci fn function list --application-id <YOUR_FUNCTION_APP_OCID>
```

---

## 📤 Step 2: Prepare Test Images

Upload sample images to Object Storage for testing.

### Create Object Storage Bucket (if needed)

```bash
# Create bucket for delivery images
oci os bucket create \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --name delivery-images

# Verify bucket created
oci os bucket list \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --query 'data[?"name"==`delivery-images`]'
```

### Upload Test Images

```bash
# Navigate to test images directory
cd development/assets/deliveries

# Upload sample images to Object Storage
oci os object put \
  --bucket-name delivery-images \
  --file sample.jpg \
  --name test/sample.jpg

# Upload damage samples
oci os object put \
  --bucket-name delivery-images \
  --file damage1.jpg \
  --name test/damage1.jpg

# Verify uploads
oci os object list \
  --bucket-name delivery-images \
  --prefix test/
```

---

## 🧪 Step 3: Test Delivery Quality Function

Test the main delivery assessment function.

### Create Test Event

```bash
# Create test event with sample image
cat > test-delivery-event.json << EOF
{
  "data": {
    "compartmentId": "<YOUR_COMPARTMENT_OCID>",
    "resourceName": "test/sample.jpg",
    "namespace": "<YOUR_NAMESPACE>",
    "bucketName": "delivery-images"
  },
  "eventTime": "2024-01-15T16:45:00Z",
  "eventType": "com.oraclecloud.objectstorage.createobject",
  "additionalDetails": {
    "expectedLatitude": 37.7749,
    "expectedLongitude": -122.4194,
    "promisedTime": "2024-01-15T17:00:00Z"
  }
}
EOF
```

### Invoke Function

```bash
# Invoke delivery quality function
oci fn function invoke \
  --function-id <YOUR_DELIVERY_FUNCTION_OCID> \
  --file test-delivery-event.json \
  --body output.json

# View results
cat output.json | jq '.'
```

### Expected Response Structure

```json
{
  "status": "success",
  "delivery_id": "test/sample.jpg",
  "quality_score": 85.5,
  "timestamp": "2024-01-15T16:45:30Z",
  "analysis": {
    "timeliness": {
      "score": 90.0,
      "on_time": true,
      "delay_minutes": 0
    },
    "location": {
      "score": 88.0,
      "distance_meters": 15.2,
      "within_threshold": true
    },
    "damage": {
      "score": 95.0,
      "probability": 5.0,
      "detected": false,
      "indicators": []
    }
  },
  "metadata": {
    "image_size": "1920x1080",
    "processing_time_ms": 2450
  }
}
```

### Verify Success Criteria

- ✅ Status is "success"
- ✅ Quality score is calculated (0-100)
- ✅ All three components (timeliness, location, damage) have scores
- ✅ Processing completed in <5 seconds

---

## 🔒 Step 4: Test Face Blur Function

Test privacy protection functionality.

### Create Face Blur Test Event

```bash
# Create test event (use image with faces if available)
cat > test-blur-event.json << EOF
{
  "data": {
    "compartmentId": "<YOUR_COMPARTMENT_OCID>",
    "resourceName": "test/sample.jpg",
    "namespace": "<YOUR_NAMESPACE>",
    "bucketName": "delivery-images"
  }
}
EOF
```

### Invoke Face Blur Function

```bash
# Invoke face blur function
oci fn function invoke \
  --function-id <YOUR_FACE_BLUR_FUNCTION_OCID> \
  --file test-blur-event.json \
  --body blur-output.json

# View results
cat blur-output.json | jq '.'
```

### Expected Response

```json
{
  "status": "success",
  "original_image": "test/sample.jpg",
  "blurred_image": "blurred/test/sample.jpg",
  "faces_detected": 2,
  "faces_blurred": 2,
  "processing_time_ms": 245,
  "blur_intensity": 71
}
```

### Verify Success Criteria

- ✅ Status is "success"
- ✅ Blurred image created in "blurred/" prefix
- ✅ Face count reported (may be 0 if no faces)
- ✅ Processing completed in <1 second (warm)

---

## 📊 Step 5: View Function Logs

Check function execution logs for detailed information.

### View Recent Logs

```bash
# Get compartment OCID
COMPARTMENT_OCID=<YOUR_COMPARTMENT_OCID>

# Search logs from last hour
oci logging-search search-logs \
  --search-query "search \"$COMPARTMENT_OCID/functions\" | sort by datetime desc" \
  --time-start $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S.000Z) \
  --time-end $(date -u +%Y-%m-%dT%H:%M:%S.000Z)
```

### Via OCI Console

1. **OCI Console** → **Observability & Management** → **Logging** → **Search**
2. **Custom Filters**:
   - Log Group: Select your functions log group
   - Time Range: Last 1 hour
3. Click **Search**
4. Review function invocation logs

### What to Look For

- ✅ Function invocation start/end
- ✅ No error messages
- ✅ Expected processing times
- ✅ Successful completion messages

---

## 🔄 Step 6: Test End-to-End Workflow

Test the complete workflow from upload to analysis.

### Upload New Image

```bash
# Upload a new test image
oci os object put \
  --bucket-name delivery-images \
  --file development/assets/deliveries/damage2.jpg \
  --name deliveries/2024-01-15/delivery-001.jpg
```

### Manually Trigger Function

```bash
# Create event for new upload
cat > e2e-test-event.json << EOF
{
  "data": {
    "compartmentId": "<YOUR_COMPARTMENT_OCID>",
    "resourceName": "deliveries/2024-01-15/delivery-001.jpg",
    "namespace": "<YOUR_NAMESPACE>",
    "bucketName": "delivery-images"
  },
  "eventTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "eventType": "com.oraclecloud.objectstorage.createobject",
  "additionalDetails": {
    "expectedLatitude": 40.7128,
    "expectedLongitude": -74.0060,
    "promisedTime": "$(date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%SZ)"
  }
}
EOF

# Invoke function
oci fn function invoke \
  --function-id <YOUR_DELIVERY_FUNCTION_OCID> \
  --file e2e-test-event.json \
  --body e2e-output.json

# Check results
cat e2e-output.json | jq '.quality_score, .analysis.damage'
```

---

## 🔧 Common Test Scenarios

### Scenario 1: Test Damaged Package

```bash
# Upload damaged package image
oci os object put \
  --bucket-name delivery-images \
  --file development/assets/deliveries/damage3.jpg \
  --name test/damaged-package.jpg

# Create event
cat > damaged-test.json << EOF
{
  "data": {
    "compartmentId": "<YOUR_COMPARTMENT_OCID>",
    "resourceName": "test/damaged-package.jpg",
    "namespace": "<YOUR_NAMESPACE>",
    "bucketName": "delivery-images"
  },
  "additionalDetails": {
    "expectedLatitude": 37.7749,
    "expectedLongitude": -122.4194,
    "promisedTime": "2024-01-15T17:00:00Z"
  }
}
EOF

# Invoke and check damage score
oci fn function invoke \
  --function-id <YOUR_DELIVERY_FUNCTION_OCID> \
  --file damaged-test.json \
  --body - | jq '.analysis.damage'
```

**Expected**: High damage probability (>50%), damage indicators detected

### Scenario 2: Test Late Delivery

```bash
# Test with delivery time past promised time
cat > late-delivery-test.json << EOF
{
  "data": {
    "compartmentId": "<YOUR_COMPARTMENT_OCID>",
    "resourceName": "test/sample.jpg",
    "namespace": "<YOUR_NAMESPACE>",
    "bucketName": "delivery-images"
  },
  "eventTime": "2024-01-15T18:30:00Z",
  "additionalDetails": {
    "promisedTime": "2024-01-15T17:00:00Z"
  }
}
EOF

# Invoke
oci fn function invoke \
  --function-id <YOUR_DELIVERY_FUNCTION_OCID> \
  --file late-delivery-test.json \
  --body - | jq '.analysis.timeliness'
```

**Expected**: Lower timeliness score, on_time: false, delay_minutes > 0

### Scenario 3: Test Wrong Location

```bash
# Test with delivery far from expected location
cat > wrong-location-test.json << EOF
{
  "data": {
    "compartmentId": "<YOUR_COMPARTMENT_OCID>",
    "resourceName": "test/sample.jpg",
    "namespace": "<YOUR_NAMESPACE>",
    "bucketName": "delivery-images"
  },
  "additionalDetails": {
    "expectedLatitude": 37.7749,
    "expectedLongitude": -122.4194,
    "actualLatitude": 37.8000,
    "actualLongitude": -122.5000
  }
}
EOF

# Invoke
oci fn function invoke \
  --function-id <YOUR_DELIVERY_FUNCTION_OCID> \
  --file wrong-location-test.json \
  --body - | jq '.analysis.location'
```

**Expected**: Lower location score, distance_meters > 50, within_threshold: false

---

## 📈 Performance Testing

### Measure Function Performance

```bash
# Test cold start time (first invocation after idle)
time oci fn function invoke \
  --function-id <YOUR_DELIVERY_FUNCTION_OCID> \
  --file test-delivery-event.json \
  --body -

# Test warm invocation (immediate second call)
time oci fn function invoke \
  --function-id <YOUR_DELIVERY_FUNCTION_OCID> \
  --file test-delivery-event.json \
  --body -
```

### Expected Performance

| Metric | Delivery Function | Face Blur Function |
|--------|------------------|--------------------|
| **Cold Start** | 3-8 seconds | 3-5 seconds |
| **Warm Invocation** | 1-3 seconds | <300ms |
| **Memory Usage** | 1500-2000 MB | 400-600 MB |
| **Timeout** | 300s (configured) | 300s (configured) |

---

## 🔍 Troubleshooting Test Failures

### Issue: Function returns error status

**Check:**
```bash
# View function logs
oci logging-search search-logs \
  --search-query "search \"$COMPARTMENT_OCID/functions\" | sort by datetime desc" \
  --time-start $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S.000Z) \
  --time-end $(date -u +%Y-%m-%dT%H:%M:%S.000Z)

# Check function configuration
oci fn function get --function-id <YOUR_FUNCTION_OCID>
```

### Issue: Image not found

**Check:**
```bash
# Verify image exists in bucket
oci os object list \
  --bucket-name delivery-images \
  --prefix test/

# Check bucket permissions
oci os bucket get --name delivery-images

# Verify function has Object Storage access (dynamic group policies)
oci iam policy list --compartment-id <YOUR_TENANCY_OCID> --all
```

### Issue: GenAI errors

**Check:**
```bash
# Verify GenAI endpoint configuration
oci fn function get \
  --function-id <YOUR_DELIVERY_FUNCTION_OCID> \
  --query 'data.config.OCI_TEXT_MODEL_OCID'

# Verify GenAI policies
oci iam policy list \
  --compartment-id <YOUR_TENANCY_OCID> \
  --query 'data[?contains("statements", `generative-ai`)]'
```

### Issue: Function timeout

**Check:**
```bash
# Increase timeout
oci fn function update \
  --function-id <YOUR_FUNCTION_OCID> \
  --timeout-in-seconds 300

# Increase memory
oci fn function update \
  --function-id <YOUR_FUNCTION_OCID> \
  --memory-in-mbs 4096
```

---

## ✅ Final Verification Checklist

Before considering deployment complete:

- [ ] Both functions deployed and ACTIVE
- [ ] Delivery function returns valid quality scores
- [ ] Face blur function detects and blurs faces (if present)
- [ ] Functions complete within timeout
- [ ] No errors in function logs
- [ ] Test images successfully analyzed
- [ ] Object Storage integration working
- [ ] All three scoring components (timeliness, location, damage) calculated
- [ ] Function performance acceptable
- [ ] IAM policies verified and working

---

## 🎉 Success Criteria

Your deployment is successful if:

✅ Functions invoke without errors
✅ Quality scores calculated correctly (0-100 range)
✅ Damage detection working (high scores for good deliveries)
✅ Face blurring operational (if faces present)
✅ Performance within acceptable ranges (<5s for delivery function)
✅ Logs show successful completions
✅ End-to-end workflow functional

---

## 📚 Next Steps

Once testing is complete:
- **Optional**: [11-event-triggers.md](11-event-triggers.md) - Set up automatic Object Storage triggers
- **Optional**: [12-monitoring.md](12-monitoring.md) - Configure monitoring and alerts
- **Reference**: [14-command-reference.md](14-command-reference.md) - Quick command reference

---

## 🔗 Additional Resources

- [OCI Functions Testing](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionstesting.htm)
- [Function Logs](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsexportingfunctionlogfiles.htm)
- [Troubleshooting Functions](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionstroubleshooting.htm)
- [Object Storage CLI](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/os.html)
