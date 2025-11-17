# 01 - Prerequisites and Required Information

Before deploying to OCI, you need to gather several OCIDs (Oracle Cloud Identifiers) and configure your environment.

## 📋 What You'll Need

This guide will help you find and save:
- ✅ Tenancy OCID
- ✅ User OCID
- ✅ Compartment OCID
- ✅ Region Identifier
- ✅ Object Storage Namespace
- ✅ GenAI Service Endpoint (optional, for later)

## 🎯 Step 1: Access OCI Console

1. Navigate to [cloud.oracle.com](https://cloud.oracle.com)
2. Sign in with your credentials
3. Select your region from the top-right dropdown

## 🔍 Step 2: Find Your Tenancy OCID

### Via OCI Console

1. Click the **Profile icon** (top-right corner)
2. Click **Tenancy: [Your Tenancy Name]**
3. Find **OCID** field
4. Click **Copy** to copy the OCID
5. Save it (format: `ocid1.tenancy.oc1..aaaaaaaXXXXXXXX`)

### Via OCI CLI (if already installed)

```bash
oci iam tenancy get --tenancy-id $(grep tenancy ~/.oci/config | cut -d '=' -f 2 | tr -d ' ') --query 'data.id' --raw-output
```

**Save this value:**
```
TENANCY_OCID=ocid1.tenancy.oc1..aaaaaaaXXXXXXXX
```

---

## 👤 Step 3: Find Your User OCID

### Via OCI Console

1. Click the **Profile icon** (top-right corner)
2. Click **User Settings**
3. Find **OCID** field under user information
4. Click **Copy** to copy the OCID
5. Save it (format: `ocid1.user.oc1..aaaaaaaXXXXXXXX`)

### Via OCI CLI (if already installed)

```bash
# If you know your username (usually your email)
oci iam user list --query "data[?name=='your.email@example.com'].id | [0]" --raw-output
```

**Save this value:**
```
USER_OCID=ocid1.user.oc1..aaaaaaaXXXXXXXX
```

---

## 📦 Step 4: Find Your Compartment OCID

### Via OCI Console

1. Open the **navigation menu** (☰ top-left)
2. Go to **Identity & Security** → **Compartments**
3. Find the compartment you want to deploy to
4. Click on the compartment name
5. Find **OCID** field
6. Click **Copy** to copy the OCID

**Note**: You can use the root compartment, but creating a dedicated compartment is recommended for organization.

### Create a New Compartment (Recommended)

```bash
# Create a compartment named "delivery-intelligence"
oci iam compartment create \
  --compartment-id <YOUR_TENANCY_OCID> \
  --name "delivery-intelligence" \
  --description "Compartment for Delivery Intelligence Functions"
```

### Via OCI CLI

```bash
# List all compartments
oci iam compartment list --all

# List compartments by name
oci iam compartment list --name "delivery-intelligence" --query 'data[0].id' --raw-output
```

**Save this value:**
```
COMPARTMENT_OCID=ocid1.compartment.oc1..aaaaaaaXXXXXXXX
```

---

## 🌎 Step 5: Identify Your Region

### Via OCI Console

Look at the top-right of the console. You'll see your region name (e.g., "US East (Ashburn)")

### Common Region Identifiers

| Region Name | Region Identifier | OCIR Hostname |
|-------------|-------------------|---------------|
| US East (Ashburn) | us-ashburn-1 | iad.ocir.io |
| US West (Phoenix) | us-phoenix-1 | phx.ocir.io |
| US West (San Jose) | us-sanjose-1 | sjc.ocir.io |
| US Midwest (Chicago) | us-chicago-1 | ord.ocir.io |
| Canada Southeast (Toronto) | ca-toronto-1 | yyz.ocir.io |
| Canada Southeast (Montreal) | ca-montreal-1 | yul.ocir.io |
| UK South (London) | uk-london-1 | lhr.ocir.io |
| Germany Central (Frankfurt) | eu-frankfurt-1 | fra.ocir.io |
| Switzerland North (Zurich) | eu-zurich-1 | zrh.ocir.io |
| Netherlands Northwest (Amsterdam) | eu-amsterdam-1 | ams.ocir.io |
| Japan East (Tokyo) | ap-tokyo-1 | nrt.ocir.io |
| Japan Central (Osaka) | ap-osaka-1 | kix.ocir.io |
| South Korea Central (Seoul) | ap-seoul-1 | icn.ocir.io |
| Australia East (Sydney) | ap-sydney-1 | syd.ocir.io |
| Australia Southeast (Melbourne) | ap-melbourne-1 | mel.ocir.io |
| India West (Mumbai) | ap-mumbai-1 | bom.ocir.io |
| India South (Hyderabad) | ap-hyderabad-1 | hyd.ocir.io |
| Brazil East (Sao Paulo) | sa-saopaulo-1 | gru.ocir.io |
| Chile (Santiago) | sa-santiago-1 | scl.ocir.io |
| Saudi Arabia West (Jeddah) | me-jeddah-1 | jed.ocir.io |
| UAE East (Dubai) | me-dubai-1 | dxb.ocir.io |
| South Africa Central (Johannesburg) | af-johannesburg-1 | jnb.ocir.io |

### Via OCI CLI

```bash
oci iam region-subscription list --query 'data[?"is-home-region"].{Region:"region-name"}' 
```

**Save these values:**
```
REGION_ID=us-chicago-1
OCIR_HOSTNAME=ord.ocir.io
```

---

## 📦 Step 6: Find Your Object Storage Namespace

### Via OCI Console

1. Open the **navigation menu** (☰)
2. Go to **Storage** → **Object Storage** → **Buckets**
3. Look at the breadcrumb at the top: **Object Storage / [Namespace] / Buckets**
4. The namespace is displayed there (usually your tenancy name)

### Via OCI CLI

```bash
oci os ns get --query 'data' --raw-output
```

**Save this value:**
```
OS_NAMESPACE=your_namespace_here
```

---

## 🎯 Step 7: Find Your GenAI Service Endpoint (For Later)

You'll need this when configuring the delivery function.

### Via OCI Console

1. Open the **navigation menu** (☰)
2. Go to **Analytics & AI** → **AI Services** → **Generative AI**
3. Select **Dedicated AI Clusters** or **Endpoints**
4. Click on your endpoint (or create one if needed)
5. Copy the **OCID**

### Via OCI CLI

```bash
# List GenAI endpoints
oci generative-ai endpoint list --compartment-id <YOUR_COMPARTMENT_OCID>

# Get a specific endpoint
oci generative-ai endpoint get --endpoint-id <ENDPOINT_OCID>
```

**GenAI Hostname by Region:**
```
https://inference.generativeai.<region-id>.oci.oraclecloud.com
```

Example for us-chicago-1:
```
https://inference.generativeai.us-chicago-1.oci.oraclecloud.com
```

**Save this value (you'll need it later):**
```
GENAI_ENDPOINT_OCID=ocid1.generativeaiendpoint.oc1..aaaaaaaXXXXXXXX
GENAI_HOSTNAME=https://inference.generativeai.us-chicago-1.oci.oraclecloud.com
```

---

## 📝 Step 8: Create a Configuration File

Save all your values in a text file for easy reference:

```bash
# Create a file to track your OCIDs
cat > ~/oci-deployment-config.txt << 'EOF'
# OCI Deployment Configuration
# Generated: $(date)

# Core OCIDs
TENANCY_OCID=ocid1.tenancy.oc1..aaaaaaaXXXXXXXX
USER_OCID=ocid1.user.oc1..aaaaaaaXXXXXXXX
COMPARTMENT_OCID=ocid1.compartment.oc1..aaaaaaaXXXXXXXX

# Region Information
REGION_ID=us-chicago-1
OCIR_HOSTNAME=ord.ocir.io

# Object Storage
OS_NAMESPACE=your_namespace_here
OS_BUCKET_NAME=delivery-images  # You'll create this later

# GenAI (for function configuration)
GENAI_ENDPOINT_OCID=ocid1.generativeaiendpoint.oc1..aaaaaaaXXXXXXXX
GENAI_HOSTNAME=https://inference.generativeai.us-chicago-1.oci.oraclecloud.com

# You'll fill these in during deployment
FUNCTION_APP_OCID=
DELIVERY_FUNCTION_OCID=
FACE_BLUR_FUNCTION_OCID=
VCN_OCID=
PRIVATE_SUBNET_OCID=
EOF

# Open in your default editor
nano ~/oci-deployment-config.txt
```

**Fill in your actual values and save this file!**

---

## ✅ Verification Checklist

Before proceeding to the next guide, verify you have:

- [ ] Tenancy OCID saved
- [ ] User OCID saved
- [ ] Compartment OCID saved (or created new compartment)
- [ ] Region identifier saved
- [ ] OCIR hostname identified
- [ ] Object Storage namespace saved
- [ ] Configuration file created at `~/oci-deployment-config.txt`
- [ ] All values are in the format `ocid1.XXXX.oc1..aaaaaaaXXXXXXXX`

---

## 🔧 Quick Verification Commands

If you have OCI CLI installed, verify your values:

```bash
# Verify tenancy
oci iam tenancy get --tenancy-id <YOUR_TENANCY_OCID>

# Verify user
oci iam user get --user-id <YOUR_USER_OCID>

# Verify compartment
oci iam compartment get --compartment-id <YOUR_COMPARTMENT_OCID>

# Verify namespace
oci os ns get
```

All commands should return data without errors.

---

## 📚 Next Steps

Once you have all OCIDs saved:
- **Next Guide**: [02-oci-cli-installation.md](02-oci-cli-installation.md) - Install OCI CLI

---

## ❓ Common Questions

**Q: Can I use the root compartment?**
A: Yes, but it's better practice to create a dedicated compartment for organization and access control.

**Q: Where do I find my username?**
A: It's usually your email address. Check User Settings in the OCI Console.

**Q: What if I don't have GenAI access yet?**
A: That's okay - you'll set this up later. For now, just note where to find it.

**Q: Do these OCIDs change?**
A: No, OCIDs are permanent identifiers. Save them securely.

**Q: Can I have multiple compartments?**
A: Yes! You can deploy to any compartment. Just use the appropriate OCID.
