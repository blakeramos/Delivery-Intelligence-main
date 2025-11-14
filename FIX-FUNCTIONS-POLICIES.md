# Fix OCI Functions IAM Policies

You're absolutely right! A 404 error from Fn CLI can be caused by missing IAM policies. Let's check and fix your permissions.

## Required Policies for Functions

According to [Oracle's documentation](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionscreatingpolicies.htm), you need these policies:

### 1. Policies for Users (You)

```
Allow group <your-group> to manage repos in tenancy
Allow group <your-group> to read objectstorage-namespaces in tenancy
Allow group <your-group> to manage functions-family in compartment <compartment-name>
Allow group <your-group> to use virtual-network-family in compartment <compartment-name>
```

### 2. Policies for Functions (Dynamic Group)

```
Allow dynamic-group <dynamic-group-name> to manage all-resources in compartment <compartment-name>
```

## Step-by-Step: Check and Add Policies

### Step 1: Find Your User Group

```bash
# Get your user OCID
USER_OCID=$(oci iam user list --query "data[?name=='blake.ramos@oracle.com'].id | [0]" --raw-output)

# List groups you belong to
oci iam group list --compartment-id $(oci iam compartment list --query 'data[0]."compartment-id"' --raw-output)
```

Common groups: `Administrators`, `OCI_Developers`, `FunctionsUsers`

### Step 2: Check Existing Policies

```bash
# List all policies in your compartment
oci iam policy list \
  --compartment-id ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga \
  --all
```

Look for policies that include:
- `functions-family`
- `repos` (for OCIR)
- `virtual-network-family`

### Step 3: Create Required Policies

#### Option A: Via OCI Console (Easiest)

1. **OCI Console** → Identity & Security → Policies
2. Click **Create Policy**
3. **Name**: `functions-user-policy`
4. **Description**: `Policies for Functions users`
5. **Compartment**: Select your compartment
6. **Policy Builder** → Click "Show manual editor"
7. **Paste these statements** (replace `<group-name>` with your group, e.g., `Administrators`):

```
Allow group <group-name> to manage repos in tenancy
Allow group <group-name> to read objectstorage-namespaces in tenancy
Allow group <group-name> to manage functions-family in compartment id ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga
Allow group <group-name> to use virtual-network-family in compartment id ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga
Allow group <group-name> to read metrics in compartment id ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga
```

8. Click **Create**

#### Option B: Via OCI CLI

```bash
# Get your root compartment OCID (tenancy)
TENANCY_OCID=$(oci iam compartment list --compartment-id-in-subtree false --query 'data[0]."compartment-id"' --raw-output)

# Get compartment OCID
COMPARTMENT_OCID="ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga"

# Create policy (replace YOUR_GROUP_NAME)
oci iam policy create \
  --compartment-id $TENANCY_OCID \
  --name functions-user-policy \
  --description "Policies for Functions users" \
  --statements '[
    "Allow group YOUR_GROUP_NAME to manage repos in tenancy",
    "Allow group YOUR_GROUP_NAME to read objectstorage-namespaces in tenancy", 
    "Allow group YOUR_GROUP_NAME to manage functions-family in compartment id '$COMPARTMENT_OCID'",
    "Allow group YOUR_GROUP_NAME to use virtual-network-family in compartment id '$COMPARTMENT_OCID'",
    "Allow group YOUR_GROUP_NAME to read metrics in compartment id '$COMPARTMENT_OCID'"
  ]'
```

**Replace `YOUR_GROUP_NAME`** with your actual group (likely `Administrators` or check with `oci iam group list`)

### Step 4: Create Dynamic Group for Functions

Functions need their own permissions to access resources.

#### Via OCI Console:

1. **OCI Console** → Identity & Security → Dynamic Groups
2. Click **Create Dynamic Group**
3. **Name**: `functions-dynamic-group`
4. **Description**: `Dynamic group for Functions`
5. **Matching Rules** (click "Add Rule"):

```
ALL {resource.type = 'fnfunc', resource.compartment.id = 'ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga'}
```

6. Click **Create**

#### Via OCI CLI:

```bash
oci iam dynamic-group create \
  --name functions-dynamic-group \
  --description "Dynamic group for Functions" \
  --matching-rule "ALL {resource.type = 'fnfunc', resource.compartment.id = 'ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga'}"
```

### Step 5: Create Policies for Dynamic Group

Functions need access to Object Storage, GenAI, etc.

#### Via OCI Console:

1. **OCI Console** → Identity & Security → Policies
2. Click **Create Policy**
3. **Name**: `functions-service-policy`
4. **Description**: `Policies for Functions service`
5. **Compartment**: Select your compartment
6. **Policy Builder** → "Show manual editor"
7. **Paste**:

```
Allow dynamic-group functions-dynamic-group to manage all-resources in compartment id ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga
```

#### Via OCI CLI:

```bash
# Get root compartment (policies for dynamic groups go in root)
TENANCY_OCID=$(oci iam compartment list --compartment-id-in-subtree false --query 'data[0]."compartment-id"' --raw-output)

COMPARTMENT_OCID="ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga"

oci iam policy create \
  --compartment-id $TENANCY_OCID \
  --name functions-service-policy \
  --description "Policies for Functions service" \
  --statements '[
    "Allow dynamic-group functions-dynamic-group to manage all-resources in compartment id '$COMPARTMENT_OCID'"
  ]'
```

## Verify Policies

```bash
# List all policies in tenancy
oci iam policy list --compartment-id $(oci iam compartment list --compartment-id-in-subtree false --query 'data[0]."compartment-id"' --raw-output) --all

# Check dynamic groups
oci iam dynamic-group list --compartment-id $(oci iam compartment list --compartment-id-in-subtree false --query 'data[0]."compartment-id"' --raw-output)
```

Look for:
- ✅ `functions-user-policy` (for you)
- ✅ `functions-service-policy` (for dynamic group)
- ✅ `functions-dynamic-group` (dynamic group exists)

## Wait for Policies to Propagate

**IMPORTANT**: Policies take **60-90 seconds** to propagate across OCI regions.

```bash
# Wait 90 seconds
sleep 90
```

## Now Try Fn Deploy Again

After policies are created and propagated:

```bash
# 1. Recreate Fn context (fresh start)
fn create context oci --api-url https://functions.us-chicago-1.oci.oraclecloud.com

# 2. Use context
fn use context oci

# 3. Configure context
fn update context registry ord.ocir.io/orasenatdpltintegration03
fn update context compartment-id ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga
fn update context oracle.profile DEFAULT
fn update context oracle.compartment-id ocid1.compartment.oc1..aaaaaaaalrxincasdt4rojwphvzmrgaziphyqmkbgpszzd44vosrj6hmw7ga

# 4. Verify
fn inspect context oci

# 5. Deploy
cd delivery-function
fn -v deploy --app delivery-agent-app
```

## If You're an Administrator

If you belong to the `Administrators` group, you may already have these permissions. However, explicit Functions policies are still recommended.

```bash
# Check if you're an admin
oci iam group list --compartment-id $(oci iam compartment list --compartment-id-in-subtree false --query 'data[0]."compartment-id"' --raw-output) --query "data[?name=='Administrators']"
```

## Minimum Required Policies Summary

**For Your User Group:**
```
Allow group <group> to manage repos in tenancy
Allow group <group> to read objectstorage-namespaces in tenancy
Allow group <group> to manage functions-family in compartment <compartment>
Allow group <group> to use virtual-network-family in compartment <compartment>
```

**For Functions Dynamic Group:**
```
Allow dynamic-group functions-dynamic-group to manage all-resources in compartment <compartment>
```

## Common Policy Issues

### Issue: Still getting 404 after adding policies
- Wait 90 seconds for policies to propagate
- Check policy is in correct compartment
- Verify compartment OCID is correct

### Issue: "NotAuthorizedOrResourceAlreadyExists"
- You don't have `manage functions-family` permission
- Or resource already exists (which we know it does)

### Issue: Can't create policies
- You need to be in `Administrators` group
- Or have `manage policies` permission

## Next Steps

1. ✅ Add required IAM policies (user and dynamic group)
2. ✅ Wait 90 seconds for propagation
3. ✅ Recreate Fn context
4. ✅ Try `fn deploy` again
5. ✅ If it works, continue with deployment!

The 404 error should be resolved once proper policies are in place!
