# Deploy Function Using OCI CLI (Bypassing Fn CLI)

Since Fn CLI authentication isn't working, we'll deploy directly using Docker + OCI CLI.

## Prerequisites

You need an **Auth Token** to push to OCIR (Oracle Container Image Registry).

### Create Auth Token

1. **OCI Console** → Profile icon (top-right) → User Settings
2. Click "Auth Tokens" (left sidebar)
3. Click "Generate Token"
4. Description: `Cloud Shell OCIR Access`
5. **Copy the token immediately** (you can't retrieve it later!)
6. Save it somewhere safe

## Step-by-Step Deployment

### 1. Navigate to Function Directory

```bash
cd delivery-function
```

### 2. Build Docker Image

```bash
docker build -t ord.ocir.io/orasenatdpltintegration03/delivery-agent:latest .
```

This will:
- Read the Dockerfile
- Install Python dependencies
- Package your code into a container
- Tag it for OCIR

**Expected output**: Successfully built and tagged message

### 3. Log In to OCIR

```bash
docker login ord.ocir.io
```

**Prompts:**
```
Username: orasenatdpltintegration03/blake.ramos@oracle.com
Password: <PASTE_YOUR_AUTH_TOKEN>
```

**Important:**
- Username format: `<namespace>/<username>`
- Namespace: `orasenatdpltintegration03`
- Username: Your OCI username (usually email)
- Password: The auth token you just created

### 4. Push Image to OCIR

```bash
docker push ord.ocir.io/orasenatdpltintegration03/delivery-agent:latest
```

This uploads your Docker image to Oracle Container Registry.

**Expected output**: 
```
latest: digest: sha256:xxx size: xxx
```

### 5. Check if Function Already Exists

```bash
# List functions in your application
oci fn function list \
  --application-id ocid1.fnapp.oc1.us-chicago-1.amaaaaaawe6j4fqa6kvd3n7g4fjkyfmhihj2pljls4edz5mdxw4vv5luwyaq
```

### 6a. If Function Exists - Update It

```bash
# Get function OCID from previous command
FUNCTION_OCID=<your_function_ocid_from_list>

# Update the function with new image
oci fn function update \
  --function-id $FUNCTION_OCID \
  --image ord.ocir.io/orasenatdpltintegration03/delivery-agent:latest
```

### 6b. If Function Doesn't Exist - Create It

```bash
# Create new function
oci fn function create \
  --application-id ocid1.fnapp.oc1.us-chicago-1.amaaaaaawe6j4fqa6kvd3n7g4fjkyfmhihj2pljls4edz5mdxw4vv5luwyaq \
  --display-name delivery-quality-function \
  --image ord.ocir.io/orasenatdpltintegration03/delivery-agent:latest \
  --memory-in-mbs 2048 \
  --timeout-in-seconds 300
```

### 7. Configure Environment Variables

```bash
# Get function OCID (if you just created it)
FUNCTION_OCID=$(oci fn function list \
  --application-id ocid1.fnapp.oc1.us-chicago-1.amaaaaaawe6j4fqa6kvd3n7g4fjkyfmhihj2pljls4edz5mdxw4vv5luwyaq \
  --display-name delivery-quality-function \
  --query 'data[0].id' \
  --raw-output)

echo "Function OCID: $FUNCTION_OCID"

# Set environment variables
oci fn function update --function-id $FUNCTION_OCID \
  --config '{
    "OCI_COMPARTMENT_ID": "ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga",
    "OCI_OS_NAMESPACE": "orasenatdpltintegration03",
    "OCI_OS_BUCKET": "YOUR_BUCKET_NAME",
    "OCI_TEXT_MODEL_OCID": "YOUR_GENAI_ENDPOINT_OCID",
    "OCI_GENAI_HOSTNAME": "https://inference.generativeai.us-chicago-1.oci.oraclecloud.com",
    "WEIGHT_TIMELINESS": "0.3",
    "WEIGHT_LOCATION": "0.3",
    "WEIGHT_DAMAGE": "0.4",
    "MAX_DISTANCE_METERS": "50"
  }'
```

**Replace:**
- `YOUR_BUCKET_NAME`: Your Object Storage bucket name
- `YOUR_GENAI_ENDPOINT_OCID`: Your GenAI endpoint OCID

### 8. Test the Function

```bash
# Create test event
cat > test-event.json << 'EOF'
{
  "data": {
    "compartmentId": "ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga",
    "resourceName": "deliveries/test-delivery.jpg",
    "namespace": "orasenatdpltintegration03",
    "bucketName": "YOUR_BUCKET_NAME"
  },
  "eventTime": "2024-01-10T16:45:00Z",
  "additionalDetails": {
    "expectedLatitude": 37.7749,
    "expectedLongitude": -122.4194,
    "promisedTime": "2024-01-10T17:00:00Z"
  }
}
EOF

# Invoke function
oci fn function invoke \
  --function-id $FUNCTION_OCID \
  --file test-event.json \
  --body -
```

## Complete Command Sequence

Here's the complete sequence without explanations:

```bash
# 1. Navigate to directory
cd delivery-function

# 2. Build image
docker build -t ord.ocir.io/orasenatdpltintegration03/delivery-agent:latest .

# 3. Login to OCIR (enter credentials when prompted)
docker login ord.ocir.io

# 4. Push image
docker push ord.ocir.io/orasenatdpltintegration03/delivery-agent:latest

# 5. Check existing functions
oci fn function list \
  --application-id ocid1.fnapp.oc1.us-chicago-1.amaaaaaawe6j4fqa6kvd3n7g4fjkyfmhihj2pljls4edz5mdxw4vv5luwyaq

# 6. Create or update function (choose one based on step 5)
# If creating new:
oci fn function create \
  --application-id ocid1.fnapp.oc1.us-chicago-1.amaaaaaawe6j4fqa6kvd3n7g4fjkyfmhihj2pljls4edz5mdxw4vv5luwyaq \
  --display-name delivery-quality-function \
  --image ord.ocir.io/orasenatdpltintegration03/delivery-agent:latest \
  --memory-in-mbs 2048 \
  --timeout-in-seconds 300

# OR if updating existing:
# oci fn function update \
#   --function-id <EXISTING_FUNCTION_OCID> \
#   --image ord.ocir.io/orasenatdpltintegration03/delivery-agent:latest

# 7. Configure environment variables
FUNCTION_OCID=$(oci fn function list \
  --application-id ocid1.fnapp.oc1.us-chicago-1.amaaaaaawe6j4fqa6kvd3n7g4fjkyfmhihj2pljls4edz5mdxw4vv5luwyaq \
  --display-name delivery-quality-function \
  --query 'data[0].id' \
  --raw-output)

oci fn function update --function-id $FUNCTION_OCID \
  --config '{
    "OCI_COMPARTMENT_ID": "ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga",
    "OCI_OS_NAMESPACE": "orasenatdpltintegration03",
    "OCI_OS_BUCKET": "YOUR_BUCKET_NAME",
    "OCI_TEXT_MODEL_OCID": "YOUR_GENAI_ENDPOINT_OCID",
    "OCI_GENAI_HOSTNAME": "https://inference.generativeai.us-chicago-1.oci.oraclecloud.com",
    "WEIGHT_TIMELINESS": "0.3",
    "WEIGHT_LOCATION": "0.3",
    "WEIGHT_DAMAGE": "0.4",
    "MAX_DISTANCE_METERS": "50"
  }'
```

## Troubleshooting

### Issue: "unauthorized: authentication required"
**Solution**: Re-run `docker login ord.ocir.io` with correct credentials

### Issue: "denied: requested access to the resource is denied"
**Solution**: Check IAM policies - you need permissions to push to OCIR

### Issue: Docker build fails
**Solution**: Check Dockerfile syntax and ensure all files are present

### Issue: Function fails to invoke
**Solution**: Check function logs:
```bash
oci logging-search search-logs \
  --search-query "search \"ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga/functions\"" \
  --time-start $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S.000Z) \
  --time-end $(date -u +%Y-%m-%dT%H:%M:%S.000Z)
```

## Next Steps

1. ✅ Deploy function using OCI CLI
2. ✅ Configure environment variables
3. ✅ Test with sample event
4. ✅ Upload test image to Object Storage
5. ✅ Verify function triggers automatically
6. ✅ Review function logs and output

## Advantages of This Approach

- ✅ **No Fn CLI issues**: Bypasses Fn CLI authentication problems
- ✅ **Direct control**: You see exactly what's happening
- ✅ **More transparent**: Each step is explicit
- ✅ **Easier debugging**: Clear error messages at each step
- ✅ **Works in Cloud Shell**: Pre-configured OCI CLI credentials
