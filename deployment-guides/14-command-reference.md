# 14 - Quick Command Reference

Quick reference for common OCI CLI commands used in deployment and management of the Delivery Intelligence functions.

## 📋 Purpose

This is a cheat sheet for frequently used commands. Copy and paste as needed, replacing placeholders with your actual values.

---

## 🔧 Set Your Variables First

```bash
# Core OCIDs
export TENANCY_OCID=ocid1.tenancy.oc1..aaaaaaaXXXXXXXX
export USER_OCID=ocid1.user.oc1..aaaaaaaXXXXXXXX
export COMPARTMENT_OCID=ocid1.compartment.oc1..aaaaaaaXXXXXXXX

# Region and OCIR
export REGION=us-chicago-1
export OCIR_HOSTNAME=ord.ocir.io
export NAMESPACE=your_namespace_here

# Function Resources
export FUNCTION_APP_OCID=ocid1.fnapp.oc1..aaaaaaaXXXXXXXX
export DELIVERY_FUNCTION_OCID=ocid1.fnfunc.oc1..aaaaaaaXXXXXXXX
export FACE_BLUR_FUNCTION_OCID=ocid1.fnfunc.oc1..aaaaaaaXXXXXXXX

# Networking
export VCN_OCID=ocid1.vcn.oc1..aaaaaaaXXXXXXXX
export PRIVATE_SUBNET_OCID=ocid1.subnet.oc1..aaaaaaaXXXXXXXX
```

---

## 🎯 Function Management

### List Functions
```bash
# List all functions in application
oci fn function list --application-id $FUNCTION_APP_OCID

# List all applications
oci fn application list --compartment-id $COMPARTMENT_OCID
```

### Get Function Details
```bash
# Get delivery function details
oci fn function get --function-id $DELIVERY_FUNCTION_OCID

# Get face blur function details
oci fn function get --function-id $FACE_BLUR_FUNCTION_OCID
```

### Invoke Functions
```bash
# Invoke delivery function
oci fn function invoke \
  --function-id $DELIVERY_FUNCTION_OCID \
  --file event.json \
  --body output.json

# Invoke face blur function
oci fn function invoke \
  --function-id $FACE_BLUR_FUNCTION_OCID \
  --file event.json \
  --body -
```

### Update Function
```bash
# Update function image
oci fn function update \
  --function-id $DELIVERY_FUNCTION_OCID \
  --image $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:v2

# Update function memory
oci fn function update \
  --function-id $DELIVERY_FUNCTION_OCID \
  --memory-in-mbs 4096

# Update function timeout
oci fn function update \
  --function-id $DELIVERY_FUNCTION_OCID \
  --timeout-in-seconds 300

# Update function config
oci fn function update \
  --function-id $DELIVERY_FUNCTION_OCID \
  --config '{"KEY": "value"}'
```

### Delete Function
```bash
# Delete function
oci fn function delete --function-id $DELIVERY_FUNCTION_OCID --force
```

---

## 🐳 Docker & OCIR Commands

### Docker Login
```bash
# Login to OCIR
docker login $OCIR_HOSTNAME
# Username: <namespace>/<username>
# Password: <auth_token>
```

### Build and Push Images
```bash
# Build delivery function
cd delivery-function
docker build -t $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:latest .
docker push $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:latest

# Build face blur function
cd face-blur-function
docker build -t $OCIR_HOSTNAME/$NAMESPACE/face-blur-agent:latest .
docker push $OCIR_HOSTNAME/$NAMESPACE/face-blur-agent:latest
```

### List OCIR Repositories
```bash
# List all repositories
oci artifacts container repository list --compartment-id $COMPARTMENT_OCID

# Get specific repository
oci artifacts container repository list \
  --compartment-id $COMPARTMENT_OCID \
  --display-name delivery-agent
```

### Docker Cleanup
```bash
# Remove unused images
docker image prune -a

# Remove all stopped containers
docker container prune

# Full cleanup (be careful!)
docker system prune -a --volumes
```

---

## 📦 Object Storage Commands

### Bucket Management
```bash
# Create bucket
oci os bucket create \
  --compartment-id $COMPARTMENT_OCID \
  --name delivery-images

# List buckets
oci os bucket list --compartment-id $COMPARTMENT_OCID

# Get bucket details
oci os bucket get --name delivery-images

# Delete bucket (must be empty)
oci os bucket delete --name delivery-images --force
```

### Object Operations
```bash
# Upload object
oci os object put \
  --bucket-name delivery-images \
  --file local-file.jpg \
  --name path/in/bucket/file.jpg

# List objects
oci os object list \
  --bucket-name delivery-images \
  --prefix path/in/bucket/

# Download object
oci os object get \
  --bucket-name delivery-images \
  --name path/in/bucket/file.jpg \
  --file local-output.jpg

# Delete object
oci os object delete \
  --bucket-name delivery-images \
  --name path/in/bucket/file.jpg \
  --force
```

### Bulk Operations
```bash
# Upload directory
oci os object bulk-upload \
  --bucket-name delivery-images \
  --src-dir ./local-directory \
  --prefix path/in/bucket/

# Download directory
oci os object bulk-download \
  --bucket-name delivery-images \
  --download-dir ./local-directory \
  --prefix path/in/bucket/
```

---

## 🔐 IAM Commands

### Policies
```bash
# List all policies
oci iam policy list --compartment-id $TENANCY_OCID --all

# Get policy details
oci iam policy get --policy-id <POLICY_OCID>

# Create policy
oci iam policy create \
  --compartment-id $TENANCY_OCID \
  --name my-policy \
  --description "My policy" \
  --statements '["Allow group MyGroup to manage all-resources in compartment MyCompartment"]'
```

### Dynamic Groups
```bash
# List dynamic groups
oci iam dynamic-group list --all

# Get dynamic group
oci iam dynamic-group get --dynamic-group-id <DYNAMIC_GROUP_OCID>

# Create dynamic group
oci iam dynamic-group create \
  --name functions-dynamic-group \
  --description "Dynamic group for functions" \
  --matching-rule "ALL {resource.type = 'fnfunc', resource.compartment.id = '$COMPARTMENT_OCID'}"
```

### Users and Groups
```bash
# List groups for user
oci iam user list-groups --user-id $USER_OCID

# List users in group
oci iam group list-users --group-id <GROUP_OCID>

# Get user details
oci iam user get --user-id $USER_OCID
```

---

## 🌐 Networking Commands

### VCN Management
```bash
# List VCNs
oci network vcn list --compartment-id $COMPARTMENT_OCID

# Get VCN details
oci network vcn get --vcn-id $VCN_OCID

# List subnets
oci network subnet list --compartment-id $COMPARTMENT_OCID --vcn-id $VCN_OCID

# Get subnet details
oci network subnet get --subnet-id $PRIVATE_SUBNET_OCID
```

### Gateways
```bash
# List NAT Gateways
oci network nat-gateway list --compartment-id $COMPARTMENT_OCID --vcn-id $VCN_OCID

# List Service Gateways
oci network service-gateway list --compartment-id $COMPARTMENT_OCID --vcn-id $VCN_OCID

# List Internet Gateways
oci network internet-gateway list --compartment-id $COMPARTMENT_OCID --vcn-id $VCN_OCID
```

---

## 📊 Monitoring & Logs

### Function Logs
```bash
# Search function logs (last hour)
oci logging-search search-logs \
  --search-query "search \"$COMPARTMENT_OCID/functions\" | sort by datetime desc" \
  --time-start $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S.000Z) \
  --time-end $(date -u +%Y-%m-%dT%H:%M:%S.000Z)

# Search for errors
oci logging-search search-logs \
  --search-query "search \"$COMPARTMENT_OCID/functions\" | where type='error'" \
  --time-start $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S.000Z) \
  --time-end $(date -u +%Y-%m-%dT%H:%M:%S.000Z)
```

### Metrics
```bash
# Get function metrics
oci monitoring metric list \
  --compartment-id $COMPARTMENT_OCID \
  --namespace oci_faas

# Get function invocation count
oci monitoring metric-data summarize-metrics-data \
  --compartment-id $COMPARTMENT_OCID \
  --namespace oci_faas \
  --query-text 'FunctionInvocationCount[$FUNCTION_APP_OCID]'
```

---

## 🔍 Troubleshooting Commands

### Check Function Status
```bash
# Quick status check
oci fn function get \
  --function-id $DELIVERY_FUNCTION_OCID \
  --query 'data."lifecycle-state"'

# Full function details
oci fn function get --function-id $DELIVERY_FUNCTION_OCID
```

### Check IAM Permissions
```bash
# Verify you can list functions
oci fn application list --compartment-id $COMPARTMENT_OCID

# Verify dynamic group exists
oci iam dynamic-group list --name functions-dynamic-group

# Verify policies
oci iam policy list --compartment-id $TENANCY_OCID --all
```

### Check Network Connectivity
```bash
# Verify NAT Gateway is enabled
oci network nat-gateway list \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID \
  --query 'data[0]."block-traffic"'

# Verify Service Gateway
oci network service-gateway list \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID
```

### Check OCIR Access
```bash
# Verify can list repositories
oci artifacts container repository list --compartment-id $COMPARTMENT_OCID

# Check specific image
oci artifacts container image list \
  --compartment-id $COMPARTMENT_OCID \
  --repository-name delivery-agent
```

---

## 🔄 Common Workflows

### Deploy New Version
```bash
# 1. Build new image
cd delivery-function
docker build -t $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:v2 .

# 2. Push to OCIR
docker push $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:v2

# 3. Update function
oci fn function update \
  --function-id $DELIVERY_FUNCTION_OCID \
  --image $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:v2

# 4. Test new version
oci fn function invoke \
  --function-id $DELIVERY_FUNCTION_OCID \
  --file test-event.json \
  --body -
```

### View Function Logs After Invocation
```bash
# Invoke function
oci fn function invoke \
  --function-id $DELIVERY_FUNCTION_OCID \
  --file test-event.json \
  --body output.json

# Immediately check logs
oci logging-search search-logs \
  --search-query "search \"$COMPARTMENT_OCID/functions\" | sort by datetime desc" \
  --time-start $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S.000Z) \
  --time-end $(date -u +%Y-%m-%dT%H:%M:%S.000Z) \
  | head -50
```

### Clean Up Everything
```bash
# WARNING: This deletes all resources!

# 1. Delete functions
oci fn function delete --function-id $DELIVERY_FUNCTION_OCID --force
oci fn function delete --function-id $FACE_BLUR_FUNCTION_OCID --force

# 2. Delete application
oci fn application delete --application-id $FUNCTION_APP_OCID --force

# 3. Delete OCIR images
oci artifacts container repository delete \
  --repository-id <DELIVERY_REPO_OCID> \
  --force

# 4. Delete VCN (must delete subnets, gateways first)
# See VCN documentation for proper teardown sequence
```

---

## 📝 Useful Queries

### Find Resources
```bash
# Find all functions
oci search resource structured-search \
  --query-text "query fnfunc resources where compartmentId = '$COMPARTMENT_OCID'"

# Find all VCNs
oci search resource structured-search \
  --query-text "query vcn resources where compartmentId = '$COMPARTMENT_OCID'"

# Find all buckets
oci search resource structured-search \
  --query-text "query bucket resources where compartmentId = '$COMPARTMENT_OCID'"
```

### Get OCIDs
```bash
# Get function OCID by name
oci fn function list \
  --application-id $FUNCTION_APP_OCID \
  --display-name delivery-quality-function \
  --query 'data[0].id' \
  --raw-output

# Get application OCID by name
oci fn application list \
  --compartment-id $COMPARTMENT_OCID \
  --display-name delivery-intelligence-app \
  --query 'data[0].id' \
  --raw-output

# Get VCN OCID by name
oci network vcn list \
  --compartment-id $COMPARTMENT_OCID \
  --display-name functions-vcn \
  --query 'data[0].id' \
  --raw-output
```

---

## 💡 Pro Tips

### Save Common Commands as Aliases
```bash
# Add to ~/.bashrc or ~/.zshrc

# Function management
alias fn-list='oci fn function list --application-id $FUNCTION_APP_OCID'
alias fn-invoke-delivery='oci fn function invoke --function-id $DELIVERY_FUNCTION_OCID'
alias fn-invoke-blur='oci fn function invoke --function-id $FACE_BLUR_FUNCTION_OCID'

# Logs
alias fn-logs='oci logging-search search-logs --search-query "search \"$COMPARTMENT_OCID/functions\" | sort by datetime desc" --time-start $(date -u -d "1 hour ago" +%Y-%m-%dT%H:%M:%S.000Z) --time-end $(date -u +%Y-%m-%dT%H:%M:%S.000Z)'

# Docker
alias ocir-login='docker login $OCIR_HOSTNAME'
alias docker-clean='docker system prune -a'
```

### Use JSON Output with jq
```bash
# Pretty print function config
oci fn function get --function-id $DELIVERY_FUNCTION_OCID | jq '.data.config'

# Extract specific field
oci fn function list --application-id $FUNCTION_APP_OCID | jq '.data[].["display-name"]'

# Filter results
oci fn function list --application-id $FUNCTION_APP_OCID | jq '.data[] | select(.["lifecycle-state"] == "ACTIVE")'
```

### Use Variables in Scripts
```bash
#!/bin/bash
# deploy.sh - Quick deployment script

# Load config
source ~/oci-deployment-config.txt

# Build
cd delivery-function
docker build -t $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:latest .

# Push
docker push $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:latest

# Update
oci fn function update \
  --function-id $DELIVERY_FUNCTION_OCID \
  --image $OCIR_HOSTNAME/$NAMESPACE/delivery-agent:latest

echo "Deployment complete!"
```

---

## 📚 Additional Resources

- [OCI CLI Reference](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/)
- [Functions CLI Reference](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/fn.html)
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [jq Manual](https://stedolan.github.io/jq/manual/)

---

## 🔗 Related Guides

- [01-prerequisites.md](01-prerequisites.md) - Get all OCIDs
- [08-deploy-delivery-function.md](08-deploy-delivery-function.md) - Full deployment guide
- [10-testing-verification.md](10-testing-verification.md) - Testing commands
- [13-troubleshooting.md](13-troubleshooting.md) - Troubleshooting guide
