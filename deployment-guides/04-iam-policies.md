# 04 - IAM Policies Configuration

This guide covers setting up Identity and Access Management (IAM) policies required for deploying and running OCI Functions.

## 📋 What You'll Accomplish

- ✅ Understand OCI IAM policy structure
- ✅ Create user group policies (for deployment)
- ✅ Create dynamic group for functions (runtime)
- ✅ Configure dynamic group policies
- ✅ Verify policy configuration

## ⏱️ Estimated Time: 15-20 minutes

---

## 🎯 Understanding IAM Policies

### Two Types of Policies Needed

1. **User Policies**: Allow YOU to deploy functions
   - Deploy functions
   - Push images to OCIR
   - Manage networking

2. **Dynamic Group Policies**: Allow FUNCTIONS to access OCI services
   - Read/write Object Storage
   - Access GenAI services
   - Write logs

### Policy Propagation

**Important**: After creating policies, wait **90 seconds** for them to propagate across all OCI regions.

---

## 👥 Step 1: Identify Your User Group

First, find which group you belong to.

### Via OCI Console

1. **OCI Console** → **Identity & Security** → **Users**
2. Click on your username
3. Scroll to **Groups** section
4. Note your group name (common: `Administrators`, `Developers`, `FunctionsUsers`)

### Via OCI CLI

```bash
# Get your user OCID (from prerequisites)
USER_OCID=<YOUR_USER_OCID>

# List groups for your user
oci iam user list-groups --user-id $USER_OCID

# Example output will show group names
```

**Save your group name:**
```
MY_GROUP=Administrators
```

### Create a New Group (Optional)

If you want dedicated group for functions:

```bash
# Via CLI
oci iam group create \
  --name "FunctionsDeployers" \
  --description "Group for users who deploy OCI Functions"

# Get the group OCID
oci iam group list --name "FunctionsDeployers" --query 'data[0].id' --raw-output
```

---

## 🔐 Step 2: Create User Group Policies

These policies allow you to deploy functions and push images to OCIR.

### Required Policies

```
Allow group <YOUR_GROUP> to manage repos in tenancy
Allow group <YOUR_GROUP> to read objectstorage-namespaces in tenancy
Allow group <YOUR_GROUP> to manage functions-family in compartment <COMPARTMENT_NAME>
Allow group <YOUR_GROUP> to use virtual-network-family in compartment <COMPARTMENT_NAME>
Allow group <YOUR_GROUP> to read metrics in compartment <COMPARTMENT_NAME>
```

### Option A: Via OCI Console (Recommended)

1. **Navigate to Policies**:
   - **OCI Console** → **Identity & Security** → **Policies**

2. **Create Policy**:
   - Click **Create Policy**
   - **Name**: `functions-user-policies`
   - **Description**: `Policies for Functions deployers`
   - **Compartment**: Select root compartment (tenancy)
   - Click **Show manual editor**

3. **Add Policy Statements**:

   Replace `<YOUR_GROUP>` with your actual group name (e.g., `Administrators`):
   Replace `<COMPARTMENT_NAME>` with your compartment name:

   ```
   Allow group <YOUR_GROUP> to manage repos in tenancy
   Allow group <YOUR_GROUP> to read objectstorage-namespaces in tenancy
   Allow group <YOUR_GROUP> to manage functions-family in compartment <COMPARTMENT_NAME>
   Allow group <YOUR_GROUP> to use virtual-network-family in compartment <COMPARTMENT_NAME>
   Allow group <YOUR_GROUP> to read metrics in compartment <COMPARTMENT_NAME>
   Allow group <YOUR_GROUP> to use cloud-shell in tenancy
   ```

4. **Create Policy**

### Option B: Via OCI CLI

```bash
# Set variables
TENANCY_OCID=<YOUR_TENANCY_OCID>
COMPARTMENT_NAME=<YOUR_COMPARTMENT_NAME>  # e.g., "delivery-intelligence"
GROUP_NAME=<YOUR_GROUP_NAME>              # e.g., "Administrators"

# Create policy
oci iam policy create \
  --compartment-id $TENANCY_OCID \
  --name functions-user-policies \
  --description "Policies for Functions deployers" \
  --statements "[
    \"Allow group $GROUP_NAME to manage repos in tenancy\",
    \"Allow group $GROUP_NAME to read objectstorage-namespaces in tenancy\",
    \"Allow group $GROUP_NAME to manage functions-family in compartment $COMPARTMENT_NAME\",
    \"Allow group $GROUP_NAME to use virtual-network-family in compartment $COMPARTMENT_NAME\",
    \"Allow group $GROUP_NAME to read metrics in compartment $COMPARTMENT_NAME\",
    \"Allow group $GROUP_NAME to use cloud-shell in tenancy\"
  ]"
```

### Policy Explanation

| Policy | Purpose |
|--------|---------|
| `manage repos in tenancy` | Push Docker images to OCIR |
| `read objectstorage-namespaces` | Access Object Storage namespace |
| `manage functions-family` | Create/update/delete functions |
| `use virtual-network-family` | Configure VCN and subnets for functions |
| `read metrics` | View function metrics and logs |
| `use cloud-shell` | Use OCI Cloud Shell (optional) |

---

## 🤖 Step 3: Create Dynamic Group for Functions

Dynamic groups automatically include resources based on matching rules. Functions need their own permissions to access OCI services at runtime.

### What is a Dynamic Group?

A dynamic group is a special type of group that contains resources (like functions) instead of users. Functions use this for authentication when accessing other OCI services.

### Create Dynamic Group

#### Via OCI Console

1. **Navigate to Dynamic Groups**:
   - **OCI Console** → **Identity & Security** → **Dynamic Groups**

2. **Create Dynamic Group**:
   - Click **Create Dynamic Group**
   - **Name**: `functions-dynamic-group`
   - **Description**: `Dynamic group for OCI Functions`

3. **Add Matching Rule**:
   
   Click **Rule 1** and add:
   ```
   ALL {resource.type = 'fnfunc', resource.compartment.id = '<YOUR_COMPARTMENT_OCID>'}
   ```
   
   Replace `<YOUR_COMPARTMENT_OCID>` with your actual compartment OCID.

4. **Create**

#### Via OCI CLI

```bash
# Set variables
COMPARTMENT_OCID=<YOUR_COMPARTMENT_OCID>

# Create dynamic group
oci iam dynamic-group create \
  --name functions-dynamic-group \
  --description "Dynamic group for OCI Functions" \
  --matching-rule "ALL {resource.type = 'fnfunc', resource.compartment.id = '$COMPARTMENT_OCID'}"

# Get the dynamic group OCID
DYNAMIC_GROUP_OCID=$(oci iam dynamic-group list \
  --name functions-dynamic-group \
  --query 'data[0].id' \
  --raw-output)

echo "Dynamic Group OCID: $DYNAMIC_GROUP_OCID"
```

### Matching Rule Explanation

The matching rule `ALL {resource.type = 'fnfunc', resource.compartment.id = 'ocid1.compartment...'}` means:

- **ALL**: All conditions must be true
- **resource.type = 'fnfunc'**: Resource must be a function
- **resource.compartment.id**: Function must be in specified compartment

This ensures only your functions in your compartment are included.

---

## 🔓 Step 4: Create Dynamic Group Policies

These policies allow functions to access OCI services at runtime.

### Required Policies

```
Allow dynamic-group functions-dynamic-group to manage objects in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to read objectstorage-namespaces in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to use generative-ai-family in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to manage object-family in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to use fn-function in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to use fn-invocation in compartment <COMPARTMENT_NAME>
```

### Option A: Via OCI Console

1. **Navigate to Policies**:
   - **OCI Console** → **Identity & Security** → **Policies**

2. **Create Policy**:
   - Click **Create Policy**
   - **Name**: `functions-service-policies`
   - **Description**: `Policies for Functions to access OCI services`
   - **Compartment**: Select root compartment (tenancy)
   - Click **Show manual editor**

3. **Add Policy Statements**:

   Replace `<COMPARTMENT_NAME>` with your compartment name:

   ```
   Allow dynamic-group functions-dynamic-group to manage objects in compartment <COMPARTMENT_NAME>
   Allow dynamic-group functions-dynamic-group to read objectstorage-namespaces in compartment <COMPARTMENT_NAME>
   Allow dynamic-group functions-dynamic-group to use generative-ai-family in compartment <COMPARTMENT_NAME>
   Allow dynamic-group functions-dynamic-group to manage object-family in compartment <COMPARTMENT_NAME>
   Allow dynamic-group functions-dynamic-group to use fn-function in compartment <COMPARTMENT_NAME>
   Allow dynamic-group functions-dynamic-group to use fn-invocation in compartment <COMPARTMENT_NAME>
   Allow dynamic-group functions-dynamic-group to read metrics in compartment <COMPARTMENT_NAME>
   Allow dynamic-group functions-dynamic-group to use log-content in compartment <COMPARTMENT_NAME>
   ```

4. **Create Policy**

### Option B: Via OCI CLI

```bash
# Set variables
TENANCY_OCID=<YOUR_TENANCY_OCID>
COMPARTMENT_NAME=<YOUR_COMPARTMENT_NAME>

# Create policy
oci iam policy create \
  --compartment-id $TENANCY_OCID \
  --name functions-service-policies \
  --description "Policies for Functions to access OCI services" \
  --statements "[
    \"Allow dynamic-group functions-dynamic-group to manage objects in compartment $COMPARTMENT_NAME\",
    \"Allow dynamic-group functions-dynamic-group to read objectstorage-namespaces in compartment $COMPARTMENT_NAME\",
    \"Allow dynamic-group functions-dynamic-group to use generative-ai-family in compartment $COMPARTMENT_NAME\",
    \"Allow dynamic-group functions-dynamic-group to manage object-family in compartment $COMPARTMENT_NAME\",
    \"Allow dynamic-group functions-dynamic-group to use fn-function in compartment $COMPARTMENT_NAME\",
    \"Allow dynamic-group functions-dynamic-group to use fn-invocation in compartment $COMPARTMENT_NAME\",
    \"Allow dynamic-group functions-dynamic-group to read metrics in compartment $COMPARTMENT_NAME\",
    \"Allow dynamic-group functions-dynamic-group to use log-content in compartment $COMPARTMENT_NAME\"
  ]"
```

### Policy Explanation

| Policy | Purpose |
|--------|---------|
| `manage objects` | Read/write images from Object Storage |
| `read objectstorage-namespaces` | Access Object Storage namespace |
| `use generative-ai-family` | Access GenAI Vision services |
| `manage object-family` | Full Object Storage access |
| `use fn-function` | Function can call itself or other functions |
| `use fn-invocation` | Allow function invocations |
| `read metrics` | Write function metrics |
| `use log-content` | Write function logs |

---

## ⏱️ Step 5: Wait for Policy Propagation

**CRITICAL**: Policies take time to propagate across OCI.

```bash
# Wait 90 seconds for policies to propagate
echo "Waiting for policies to propagate across OCI..."
sleep 90
echo "Policy propagation complete!"
```

Do NOT skip this step! Attempting to deploy functions immediately after creating policies will result in authorization errors.

---

## ✅ Step 6: Verify Policies

### List All Policies

```bash
# List policies in tenancy
oci iam policy list \
  --compartment-id $TENANCY_OCID \
  --all \
  --query 'data[*].{Name:name, Description:description}' \
  --output table
```

### Verify Specific Policies

```bash
# Verify user policies exist
oci iam policy list \
  --compartment-id $TENANCY_OCID \
  --name functions-user-policies

# Verify service policies exist
oci iam policy list \
  --compartment-id $TENANCY_OCID \
  --name functions-service-policies
```

### Verify Dynamic Group

```bash
# List dynamic groups
oci iam dynamic-group list --all

# Get specific dynamic group
oci iam dynamic-group list \
  --name functions-dynamic-group \
  --query 'data[0].{Name:name, Rule:"matching-rule"}'
```

### Test Permissions

```bash
# Test you can list functions (even if empty)
oci fn application list --compartment-id $COMPARTMENT_OCID

# Test you can access OCIR namespace
oci os ns get

# Should return data without "NotAuthorized" errors
```

---

## 🔧 Troubleshooting

### Issue: "NotAuthorizedOrNotFound" when deploying

**Cause**: Missing user policies or policies not propagated

**Fix**:
```bash
# Verify policies exist
oci iam policy list --compartment-id $TENANCY_OCID --all

# Wait additional time for propagation
sleep 90

# Verify you're in the correct group
oci iam user list-groups --user-id $USER_OCID
```

### Issue: Function can't access Object Storage at runtime

**Cause**: Missing dynamic group policies

**Fix**:
```bash
# Verify dynamic group exists
oci iam dynamic-group list --name functions-dynamic-group

# Verify dynamic group policies exist
oci iam policy list \
  --compartment-id $TENANCY_OCID \
  --name functions-service-policies

# Check policy statements include object storage permissions
oci iam policy get --policy-id <POLICY_OCID>
```

### Issue: "Policy already exists with name"

**Cause**: Policy name conflict

**Fix**:
```bash
# Use a different name or update existing policy
oci iam policy list --compartment-id $TENANCY_OCID --all

# Update existing policy
oci iam policy update \
  --policy-id <EXISTING_POLICY_OCID> \
  --statements "<NEW_STATEMENTS>"
```

### Issue: Dynamic group rule not matching

**Cause**: Incorrect compartment OCID or typo in matching rule

**Fix**:
```bash
# Verify compartment OCID
oci iam compartment get --compartment-id $COMPARTMENT_OCID

# Update dynamic group matching rule
DYNAMIC_GROUP_OCID=<YOUR_DYNAMIC_GROUP_OCID>

oci iam dynamic-group update \
  --dynamic-group-id $DYNAMIC_GROUP_OCID \
  --matching-rule "ALL {resource.type = 'fnfunc', resource.compartment.id = '$COMPARTMENT_OCID'}"
```

---

## 📋 Complete Policy Summary

### User Policies (functions-user-policies)
```
Allow group <YOUR_GROUP> to manage repos in tenancy
Allow group <YOUR_GROUP> to read objectstorage-namespaces in tenancy
Allow group <YOUR_GROUP> to manage functions-family in compartment <COMPARTMENT_NAME>
Allow group <YOUR_GROUP> to use virtual-network-family in compartment <COMPARTMENT_NAME>
Allow group <YOUR_GROUP> to read metrics in compartment <COMPARTMENT_NAME>
Allow group <YOUR_GROUP> to use cloud-shell in tenancy
```

### Dynamic Group (functions-dynamic-group)
```
Matching Rule:
ALL {resource.type = 'fnfunc', resource.compartment.id = '<COMPARTMENT_OCID>'}
```

### Service Policies (functions-service-policies)
```
Allow dynamic-group functions-dynamic-group to manage objects in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to read objectstorage-namespaces in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to use generative-ai-family in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to manage object-family in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to use fn-function in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to use fn-invocation in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to read metrics in compartment <COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to use log-content in compartment <COMPARTMENT_NAME>
```

---

## ✅ Verification Checklist

Before proceeding, verify:

- [ ] User group identified
- [ ] User policies created (functions-user-policies)
- [ ] Dynamic group created (functions-dynamic-group)
- [ ] Service policies created (functions-service-policies)
- [ ] Waited 90+ seconds for propagation
- [ ] `oci fn application list` works (no auth errors)
- [ ] `oci os ns get` returns namespace
- [ ] Policies appear in OCI Console

---

## 📚 Next Steps

Once IAM policies are configured:
- **Next Guide**: [05-vcn-networking.md](05-vcn-networking.md) - Set up Virtual Cloud Network

---

## 🔗 Additional Resources

- [OCI IAM Policies Overview](https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/policies.htm)
- [Functions IAM Policies](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionscreatingpolicies.htm)
- [Dynamic Groups](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingdynamicgroups.htm)
- [Policy Reference](https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm)
