# 07 - Create Function Application

This guide covers creating an OCI Function Application, which is a container for your functions.

## 📋 What You'll Accomplish

- ✅ Understand Function Applications
- ✅ Create Function Application via Console or CLI
- ✅ Configure application with private subnet
- ✅ Set up logging (optional but recommended)
- ✅ Get Application OCID for function deployment

## ⏱️ Estimated Time: 5-10 minutes

---

## 🎯 What is a Function Application?

A **Function Application** is a logical grouping of functions that:
- Share the same subnet configuration
- Share the same shape (resource allocation)
- Can share configuration variables
- Are managed as a unit

### Function Application vs Function

```
Function Application (Container)
  ├── Function 1 (delivery-quality-function)
  ├── Function 2 (face-blur-function)
  └── Function 3 (other functions...)
```

**Analogy**: Think of an application as a folder, and functions as files within it.

---

## 🚀 Option 1: Create via OCI Console (Recommended)

### Step 1: Navigate to Functions

1. **OCI Console** → **Developer Services** → **Functions**
2. Select **Applications** (left sidebar)
3. Ensure you've selected your compartment (top-left dropdown)

### Step 2: Create Application

1. Click **Create Application**

2. **Basic Information**:
   - **Name**: `delivery-intelligence-app`
   - **VCN**: Select `functions-vcn` (created in guide 05)
   - **Subnets**: Select your **private subnet** (e.g., `Private Subnet-functions-vcn`)

3. **Shape**: (Optional - defaults are usually fine)
   - Leave as **Generic X86**

4. **Logging** (Recommended):
   - **Enable**: ✅ (Check the box)
   - This creates automatic logs for function invocations
   - Helps with debugging

5. Click **Create**

### Step 3: Get Application OCID

After creation:
1. Click on your application (`delivery-intelligence-app`)
2. Find **OCID** field
3. Click **Copy**

**Save this OCID - you'll need it for deploying functions!**

```bash
FUNCTION_APP_OCID=ocid1.fnapp.oc1..aaaaaaaXXXXXXXX
```

---

## 🔧 Option 2: Create via OCI CLI

### Step 1: Prepare Variables

```bash
# Set variables from previous guides
COMPARTMENT_OCID=<YOUR_COMPARTMENT_OCID>
PRIVATE_SUBNET_OCID=<YOUR_PRIVATE_SUBNET_OCID>  # From VCN guide
```

### Step 2: Create Application

```bash
# Create Function Application
FUNCTION_APP_OCID=$(oci fn application create \
  --compartment-id $COMPARTMENT_OCID \
  --display-name delivery-intelligence-app \
  --subnet-ids "[\"$PRIVATE_SUBNET_OCID\"]" \
  --query 'data.id' \
  --raw-output)

echo "Function Application OCID: $FUNCTION_APP_OCID"

# Wait for application to be available
oci fn application get \
  --application-id $FUNCTION_APP_OCID \
  --wait-for-state ACTIVE
```

### Step 3: Configure Logging (Optional)

Enable logging for better debugging:

```bash
# First, create a log group (if you don't have one)
LOG_GROUP_OCID=$(oci logging log-group create \
  --compartment-id $COMPARTMENT_OCID \
  --display-name functions-logs \
  --query 'data.id' \
  --raw-output)

# Update application with logging
oci fn application update \
  --application-id $FUNCTION_APP_OCID \
  --syslog-url "tcp://<LOG_SERVICE_ENDPOINT>"
```

**Note**: Logging can also be configured per-function or via Console.

---

## ✅ Verify Application Creation

### Via OCI Console

1. **OCI Console** → **Developer Services** → **Functions** → **Applications**
2. You should see `delivery-intelligence-app` with status **Active**
3. Click on it to see details

### Via OCI CLI

```bash
# List applications
oci fn application list --compartment-id $COMPARTMENT_OCID

# Get specific application details
oci fn application get --application-id $FUNCTION_APP_OCID

# Should show:
# - lifecycle-state: ACTIVE
# - display-name: delivery-intelligence-app
# - subnet-ids: [your private subnet OCID]
```

### Verify Subnet Configuration

```bash
# Verify application is using private subnet
oci fn application get \
  --application-id $FUNCTION_APP_OCID \
  --query 'data."subnet-ids"'

# Should return your private subnet OCID
```

---

## 🔧 Application Configuration

### Set Application-Wide Configuration (Optional)

You can set configuration variables at the application level that all functions inherit:

```bash
# Set application-level config
oci fn application update \
  --application-id $FUNCTION_APP_OCID \
  --config '{
    "SHARED_VARIABLE": "value",
    "ENVIRONMENT": "production"
  }'
```

**Note**: Function-specific config overrides application-level config.

### View Application Configuration

```bash
# View current configuration
oci fn application get \
  --application-id $FUNCTION_APP_OCID \
  --query 'data.config'
```

---

## 📊 Application Shape and Resources

### Understanding Shapes

Functions support different shapes for resource allocation:

| Shape | vCPUs | Memory | Use Case |
|-------|-------|--------|----------|
| GENERIC_X86 | Flexible | Flexible | Most functions |
| GENERIC_ARM | Flexible | Flexible | ARM architecture |
| GENERIC_X86_ARM | Flexible | Flexible | Multi-arch support |

**Default**: GENERIC_X86 (works for most cases)

### Changing Shape (If Needed)

```bash
# Update application shape
oci fn application update \
  --application-id $FUNCTION_APP_OCID \
  --shape GENERIC_X86_ARM
```

---

## 📝 Application Limits and Quotas

### Default Limits

- **Functions per application**: 50
- **Concurrent invocations**: 100 (can be increased)
- **Memory per function**: Up to 2048 MB
- **Timeout per function**: Up to 300 seconds

### Check Your Limits

```bash
# View service limits
oci limits value list \
  --compartment-id $COMPARTMENT_OCID \
  --service-name functions

# Look for:
# - function-count
# - function-memory-MB
# - function-timeout-seconds
```

### Request Limit Increase

If you need more resources:
1. **OCI Console** → **Governance** → **Limits, Quotas and Usage**
2. Find **Functions** service
3. Click **Request a service limit increase**

---

## 🔧 Troubleshooting

### Issue: "Subnet not found" or subnet error

**Cause**: Incorrect subnet OCID or subnet not in correct compartment

**Fix**:
```bash
# Verify subnet exists and is in correct compartment
oci network subnet get --subnet-id $PRIVATE_SUBNET_OCID

# Verify subnet is private (prohibit-public-ip-on-vnic: true)
oci network subnet get \
  --subnet-id $PRIVATE_SUBNET_OCID \
  --query 'data."prohibit-public-ip-on-vnic"'
```

### Issue: "NotAuthorizedOrResourceAlreadyExists"

**Cause**: Missing IAM policies or application name already exists

**Fix**:
```bash
# Check if application already exists
oci fn application list \
  --compartment-id $COMPARTMENT_OCID \
  --display-name delivery-intelligence-app

# If it exists, use existing application or choose different name

# Verify IAM policies (from guide 04)
oci iam policy list --compartment-id $TENANCY_OCID --all
```

### Issue: Application stuck in "Creating" state

**Cause**: Network configuration issues or insufficient resources

**Fix**:
```bash
# Check application state
oci fn application get --application-id $FUNCTION_APP_OCID

# Verify VCN has NAT Gateway and Service Gateway
oci network nat-gateway list --compartment-id $COMPARTMENT_OCID --vcn-id $VCN_OCID
oci network service-gateway list --compartment-id $COMPARTMENT_OCID --vcn-id $VCN_OCID

# If stuck for >5 minutes, delete and recreate
oci fn application delete --application-id $FUNCTION_APP_OCID --force
```

### Issue: Can't find application in Console

**Cause**: Wrong compartment selected

**Fix**:
- Use compartment dropdown (top-left) to select correct compartment
- Or select "root" and enable "Include child compartments"

---

## 💡 Best Practices

### Naming

- ✅ Use descriptive, meaningful names
- ✅ Include environment in name (dev, test, prod)
- ✅ Use consistent naming convention
  ```
  Examples:
  - delivery-intelligence-app-dev
  - delivery-intelligence-app-prod
  - di-functions-prod
  ```

### Subnet Configuration

- ✅ Always use **private subnets** for security
- ✅ Ensure NAT Gateway for outbound access
- ✅ Ensure Service Gateway for OCI services
- ✅ One application per subnet is fine (subnets are not scarce)

### Resource Planning

- ✅ Group related functions in same application
- ✅ Separate dev/test/prod into different applications
- ✅ Consider separate applications for different scaling requirements

---

## 📋 Quick Reference

### Create Application (Console)
1. Functions → Applications → Create Application
2. Name: `delivery-intelligence-app`
3. VCN: `functions-vcn`
4. Subnet: Private subnet
5. Enable logging ✅

### Create Application (CLI)
```bash
oci fn application create \
  --compartment-id $COMPARTMENT_OCID \
  --display-name delivery-intelligence-app \
  --subnet-ids "[\"$PRIVATE_SUBNET_OCID\"]"
```

### Get Application OCID
```bash
oci fn application list \
  --compartment-id $COMPARTMENT_OCID \
  --display-name delivery-intelligence-app \
  --query 'data[0].id' \
  --raw-output
```

---

## ✅ Verification Checklist

Before proceeding, verify:

- [ ] Application created successfully
- [ ] Application state is **ACTIVE**
- [ ] Application OCID saved
- [ ] Application using correct private subnet
- [ ] Application appears in OCI Console
- [ ] Logging enabled (optional but recommended)

---

## 📝 Save Configuration

Add application OCID to your config file:

```bash
# Update ~/oci-deployment-config.txt
cat >> ~/oci-deployment-config.txt << EOF

# Function Application
FUNCTION_APP_OCID=$FUNCTION_APP_OCID
FUNCTION_APP_NAME=delivery-intelligence-app
EOF
```

---

## 📚 Next Steps

Once Function Application is created:
- **Next Guide**: [08-deploy-delivery-function.md](08-deploy-delivery-function.md) - Deploy main delivery function

---

## 🔗 Additional Resources

- [Function Applications Overview](https://docs.oracle.com/en-us/iaas/Content/Functions/Concepts/functionsconcepts.htm)
- [Creating Applications](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionscreatingapps.htm)
- [Application Configuration](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsconfig.htm)
- [Functions Logging](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsexportingfunctionlogfiles.htm)
