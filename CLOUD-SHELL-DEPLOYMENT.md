# Deploy OCI Delivery Function Using Cloud Shell

This guide walks you through deploying the main delivery function using OCI Cloud Shell (no local Docker needed!).

## Step 1: Access OCI Cloud Shell

1. **Log into OCI Console**: https://cloud.oracle.com
2. **Open Cloud Shell**: Click the terminal icon (>_) in the top-right corner of the console
3. **Wait for Cloud Shell to start**: It takes ~30 seconds to initialize

Cloud Shell comes pre-installed with:
- ✅ Docker
- ✅ Fn Project CLI
- ✅ OCI CLI (pre-configured with your credentials)
- ✅ Git

## Step 2: Upload Your Code to Cloud Shell

You have two options:

### Option A: Upload as ZIP file

1. **Create a ZIP of the delivery-function folder** on your local machine:
   ```bash
   # Run this on your local machine (work computer)
   cd /Users/blramos/Documents/Oracle/FY26/Q2/TForce\ Logistics/Delivery-Intelligence-main
   zip -r delivery-function.zip delivery-function/
   ```

2. **Upload to Cloud Shell**:
   - In Cloud Shell, click the ☰ (hamburger menu) in top-left
   - Select "Upload"
   - Choose your `delivery-function.zip` file
   - Wait for upload to complete

3. **Unzip in Cloud Shell**:
   ```bash
   unzip delivery-function.zip
   cd delivery-function
   ```

### Option B: Use Git (if your code is in a repo)

```bash
# Clone your repository
git clone <YOUR_REPO_URL>
cd Delivery-Intelligence-main/delivery-function
```

## Step 3: Verify Prerequisites in Cloud Shell

```bash
# Verify Fn CLI is installed
fn --version

# Verify Docker is running
docker --version

# Verify OCI CLI is configured
oci iam region list --output table
```

All should work without any setup!

## Step 4: Configure Fn Context for OCI

```bash
# Create Fn context for your OCI region
fn create context oci --api-url https://functions.us-chicago-1.oci.oraclecloud.com

# Use the OCI context
fn use context oci

# Set your registry (replace with your values)
# Format: <region>.ocir.io/<namespace>
fn update context registry ord.ocir.io/<YOUR_NAMESPACE>
# fn update context registry ord.ocir.io/orasenatdpltintegration03

# Set your compartment ID
fn update context compartment-id <YOUR_COMPARTMENT_OCID>

fn update context compartment-id ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga
```

### Find Your Values:

**Namespace**:
```bash
# Get your Object Storage namespace
oci os ns get --query 'data' --raw-output
```

**Compartment OCID**:
- OCI Console → Identity → Compartments
- Copy the OCID of your target compartment

**Region Codes**:
- us-chicago-1 → ord (default for this deployment)
- us-ashburn-1 → iad
- us-phoenix-1 → phx
- eu-frankfurt-1 → fra
- ap-tokyo-1 → nrt

## Step 5: Create Function Application (Using Fn CLI)

According to [Oracle's official documentation](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionscreatingapps.htm), the recommended way to create an application is using the Fn Project CLI:

```bash
# Create application using Fn CLI
fn create app delivery-agent-app --annotation oracle.com/oci/subnetIds='["<YOUR_SUBNET_OCID>"]'

# Example with your subnet:
fn create app delivery-agent-app --annotation oracle.com/oci/subnetIds='["ocid1.subnet.oc1.us-chicago-1.aaaaaaaa7vkyfaell3yzvjdmlracvtycxgpzptmokxxpnvdlxfvt45bewvqq"]'

# Verify the application was created
fn list apps
```

**Note**: The application is created in the compartment specified in your Fn context (from Step 4).

### Find Your Subnet OCID:
- OCI Console → Networking → Virtual Cloud Networks
- Select your VCN → Subnets
- Copy the subnet OCID

### If Application Already Exists:
If you see an error that the application already exists, you can skip this step and proceed to Step 6.

## Step 6: Deploy the Function

```bash
# Make sure you're in the delivery-function directory
cd delivery-function

# Deploy (this builds Docker image, pushes to OCIR, and creates function)
fn -v deploy --app delivery-agent-app
```

This will:
1. Build Docker image from your code
2. Push to Oracle Container Image Registry (OCIR)
3. Create/update the function in OCI

**Expected output**:
```
Deploying delivery-quality-function to app: delivery-agent-app
Building image ord.ocir.io/<namespace>/delivery-agent:latest
Successfully built <image-id>
Pushing ord.ocir.io/<namespace>/delivery-agent:latest
Successfully created function: delivery-quality-function
```

## Step 7: Configure Environment Variables

After deployment, configure the function:

```bash
# Get your function OCID
FUNCTION_OCID=$(oci fn function list \
  --application-id <YOUR_APPLICATION_OCID> \
  --display-name delivery-quality-function \
  --query 'data[0].id' \
  --raw-output)

echo "Function OCID: $FUNCTION_OCID"

# Set required environment variables
oci fn function update --function-id $FUNCTION_OCID \
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

### Find Your GenAI Endpoint OCID:
- OCI Console → Analytics & AI → Generative AI
- Select your endpoint
- Copy the OCID

## Step 8: Test Your Function

### Create a Test Event

```bash
# Create test payload
cat > test-event.json << 'EOF'
{
  "data": {
    "compartmentId": "YOUR_COMPARTMENT_OCID",
    "resourceName": "deliveries/test-delivery.jpg",
    "namespace": "YOUR_NAMESPACE",
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
```

### Invoke the Function

```bash
# Test invoke
oci fn function invoke \
  --function-id $FUNCTION_OCID \
  --file test-event.json \
  --body - | jq '.'
```

### Upload a Test Image

```bash
# Upload a test image to your bucket
oci os object put \
  --bucket-name YOUR_BUCKET_NAME \
  --name deliveries/test-delivery.jpg \
  --file /path/to/test/image.jpg
```

The function should automatically trigger when images are uploaded!

## Step 9: View Logs

```bash
# View function logs
oci logging-search search-logs \
  --search-query "search \"<YOUR_COMPARTMENT_OCID>/functions\" | source = '<YOUR_APPLICATION_OCID>'" \
  --time-start $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S.000Z) \
  --time-end $(date -u +%Y-%m-%dT%H:%M:%S.000Z)
```

Or use the OCI Console:
- Solutions and Platform → Logging → Search
- Filter by your function's compartment and application

## Troubleshooting

### Issue: "Image not found in registry"
```bash
# Log in to OCIR
docker login ord.ocir.io
# Username: <namespace>/<username>
# Password: <auth-token>
```

### Issue: "Subnet not configured"
Make sure your function application has a valid subnet attached:
```bash
oci fn application update \
  --application-id <APP_OCID> \
  --subnet-ids '["<SUBNET_OCID>"]'
```

### Issue: "Permission denied"
Check IAM policies for Functions and OCIR access:
```
Allow dynamic-group <your-fn-dynamic-group> to manage objects in compartment <compartment>
Allow dynamic-group <your-fn-dynamic-group> to use generative-ai-family in compartment <compartment>
```

## Next Steps

Once deployed:
1. ✅ Set up Object Storage event rules to trigger your function
2. ✅ Upload test delivery images
3. ✅ Monitor function execution and logs
4. ✅ Configure alerts for quality issues
5. ✅ Integrate with dashboard (future step)

## Quick Reference Commands

```bash
# List all functions
oci fn function list --application-id <APP_OCID>

# Get function details
oci fn function get --function-id <FUNCTION_OCID>

# Update function memory
oci fn function update --function-id <FUNCTION_OCID> --memory-in-mbs 2048

# Update function timeout
oci fn function update --function-id <FUNCTION_OCID> --timeout-in-seconds 300

# Delete function
oci fn function delete --function-id <FUNCTION_OCID>
```

## Clean Up

To remove the function:
```bash
# Delete function
oci fn function delete --function-id $FUNCTION_OCID

# Delete application (if needed)
oci fn application delete --application-id <APP_OCID>
