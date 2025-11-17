# 05 - VCN and Networking Setup

This guide covers setting up a Virtual Cloud Network (VCN) with private subnets for OCI Functions deployment.

## 📋 What You'll Accomplish

- ✅ Understand VCN architecture for Functions
- ✅ Create VCN using VCN Wizard (easy) or CLI (advanced)
- ✅ Configure private subnet with NAT and Service Gateways
- ✅ Set up security lists and route tables
- ✅ Get private subnet OCID for function deployment

## ⏱️ Estimated Time: 15-20 minutes

---

## 🏗️ VCN Architecture Overview

### Why Private Subnet?

Functions should run in **private subnets** for security:
- ✅ Not directly accessible from internet
- ✅ Controlled outbound access via NAT Gateway
- ✅ Secure access to OCI services via Service Gateway
- ✅ Follows cloud security best practices

### Network Architecture

```
Internet
    ↓
[Internet Gateway] ← (Optional: for bastion/management)
    ↓
[Public Subnet] ← NOT for functions
    
[NAT Gateway] ← Allows functions outbound internet access
    ↓
[Private Subnet] ← YOUR FUNCTIONS GO HERE ✅
    ↓
[Service Gateway] ← Secure access to OCI services
    ↓
OCI Services (Object Storage, GenAI, etc.)
```

### What Gets Created

- **VCN**: Virtual Cloud Network (10.0.0.0/16)
- **Private Subnet**: For functions (10.0.1.0/24)
- **NAT Gateway**: Outbound internet for functions
- **Service Gateway**: Private path to OCI services
- **Route Tables**: Traffic routing rules
- **Security Lists**: Firewall rules

---

## 🚀 Option 1: VCN Wizard (Recommended - Easy)

The VCN Wizard automatically creates everything you need.

### Step 1: Start VCN Wizard

1. **OCI Console** → **Networking** → **Virtual Cloud Networks**
2. Click **Start VCN Wizard**
3. Select **VCN with Internet Connectivity**
4. Click **Start VCN Wizard**

### Step 2: Configure VCN

**Basic Information:**
- **VCN Name**: `functions-vcn`
- **Compartment**: Select your compartment
- **VCN CIDR Block**: `10.0.0.0/16` (default is fine)

**Configure Subnets:**
- **Public Subnet CIDR**: `10.0.0.0/24` (for management, optional)
- **Private Subnet CIDR**: `10.0.1.0/24` ← **Functions will use this**

**DNS and Other Options:**
- Leave defaults

### Step 3: Review and Create

1. Click **Next**
2. Review the configuration
3. Click **Create**
4. Wait ~1-2 minutes for creation

The wizard automatically creates:
- ✅ VCN
- ✅ Public subnet (with Internet Gateway)
- ✅ Private subnet (what we need!)
- ✅ NAT Gateway
- ✅ Service Gateway
- ✅ Route tables
- ✅ Security lists

### Step 4: Get Private Subnet OCID

1. Click on your new VCN (`functions-vcn`)
2. Click **Subnets** (left sidebar)
3. Click on **Private Subnet-functions-vcn**
4. **Copy the OCID** (starts with `ocid1.subnet.oc1...`)

**Save this OCID - you'll need it for function deployment!**

```bash
# Save to your config file
PRIVATE_SUBNET_OCID=ocid1.subnet.oc1..aaaaaaaXXXXXXXX
```

---

## 🔧 Option 2: CLI/Manual Setup (Advanced)

For full control, create VCN components via OCI CLI.

### Step 1: Create VCN

```bash
# Set variables
COMPARTMENT_OCID=<YOUR_COMPARTMENT_OCID>
REGION=<YOUR_REGION>  # e.g., us-chicago-1

# Create VCN
VCN_OCID=$(oci network vcn create \
  --compartment-id $COMPARTMENT_OCID \
  --display-name functions-vcn \
  --cidr-block 10.0.0.0/16 \
  --dns-label functionvcn \
  --query 'data.id' \
  --raw-output)

echo "VCN OCID: $VCN_OCID"

# Wait for VCN to be available
oci network vcn get --vcn-id $VCN_OCID --wait-for-state AVAILABLE
```

### Step 2: Create Internet Gateway (Optional)

Only needed if you want public subnet for management/bastion.

```bash
oci network internet-gateway create \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID \
  --display-name functions-igw \
  --is-enabled true \
  --wait-for-state AVAILABLE
```

### Step 3: Create NAT Gateway

Required for functions to access internet (e.g., external APIs).

```bash
NAT_GW_OCID=$(oci network nat-gateway create \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID \
  --display-name functions-nat-gateway \
  --query 'data.id' \
  --raw-output \
  --wait-for-state AVAILABLE)

echo "NAT Gateway OCID: $NAT_GW_OCID"
```

### Step 4: Create Service Gateway

Required for functions to access OCI services (Object Storage, GenAI, etc.).

```bash
# Get all services for your region
SERVICES_OCID=$(oci network service list \
  --query 'data[?"cidr-block"]|[0].id' \
  --raw-output)

# Create Service Gateway
SERVICE_GW_OCID=$(oci network service-gateway create \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID \
  --services "[{\"serviceId\":\"$SERVICES_OCID\"}]" \
  --display-name functions-service-gateway \
  --query 'data.id' \
  --raw-output \
  --wait-for-state AVAILABLE)

echo "Service Gateway OCID: $SERVICE_GW_OCID"
```

### Step 5: Create Route Table for Private Subnet

```bash
# Get service CIDR block for route rule
SERVICE_CIDR=$(oci network service list \
  --query 'data[?"cidr-block"]|[0]."cidr-block"' \
  --raw-output)

# Create route table
ROUTE_TABLE_OCID=$(oci network route-table create \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID \
  --display-name private-route-table \
  --route-rules "[
    {
      \"destination\": \"0.0.0.0/0\",
      \"destinationType\": \"CIDR_BLOCK\",
      \"networkEntityId\": \"$NAT_GW_OCID\"
    },
    {
      \"destination\": \"$SERVICE_CIDR\",
      \"destinationType\": \"SERVICE_CIDR_BLOCK\",
      \"networkEntityId\": \"$SERVICE_GW_OCID\"
    }
  ]" \
  --query 'data.id' \
  --raw-output \
  --wait-for-state AVAILABLE)

echo "Route Table OCID: $ROUTE_TABLE_OCID"
```

### Step 6: Create Security List for Private Subnet

```bash
SECURITY_LIST_OCID=$(oci network security-list create \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID \
  --display-name private-security-list \
  --egress-security-rules "[
    {
      \"destination\": \"0.0.0.0/0\",
      \"protocol\": \"all\",
      \"isStateless\": false
    }
  ]" \
  --ingress-security-rules "[
    {
      \"source\": \"10.0.0.0/16\",
      \"protocol\": \"all\",
      \"isStateless\": false
    }
  ]" \
  --query 'data.id' \
  --raw-output \
  --wait-for-state AVAILABLE)

echo "Security List OCID: $SECURITY_LIST_OCID"
```

### Step 7: Create Private Subnet

```bash
PRIVATE_SUBNET_OCID=$(oci network subnet create \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID \
  --display-name private-subnet-functions \
  --cidr-block 10.0.1.0/24 \
  --route-table-id $ROUTE_TABLE_OCID \
  --security-list-ids "[\"$SECURITY_LIST_OCID\"]" \
  --prohibit-public-ip-on-vnic true \
  --dns-label privatesubnet \
  --query 'data.id' \
  --raw-output \
  --wait-for-state AVAILABLE)

echo "Private Subnet OCID: $PRIVATE_SUBNET_OCID"

# IMPORTANT: Save this OCID!
echo "Save this for function deployment: $PRIVATE_SUBNET_OCID"
```

---

## ✅ Verify VCN Setup

### List VCN Components

```bash
# List VCNs
oci network vcn list --compartment-id $COMPARTMENT_OCID

# List subnets in VCN
oci network subnet list \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID

# Verify private subnet exists
oci network subnet list \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID \
  --query 'data[?"prohibit-public-ip-on-vnic"].{Name:"display-name", CIDR:"cidr-block", Private:"prohibit-public-ip-on-vnic"}'
```

### Verify Gateways

```bash
# Verify NAT Gateway
oci network nat-gateway list \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID

# Verify Service Gateway
oci network service-gateway list \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID
```

### Get Private Subnet OCID (if you lost it)

```bash
# Get private subnet OCID
PRIVATE_SUBNET_OCID=$(oci network subnet list \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID \
  --query 'data[?"prohibit-public-ip-on-vnic"]|[0].id' \
  --raw-output)

echo "Private Subnet OCID: $PRIVATE_SUBNET_OCID"
```

---

## 🔧 Security List Rules Explained

### Egress Rules (Outbound from Functions)

```json
{
  "destination": "0.0.0.0/0",
  "protocol": "all"
}
```
- Allows functions to make outbound connections to any destination
- Required for accessing external APIs, OCIR, etc.

### Ingress Rules (Inbound to Functions)

```json
{
  "source": "10.0.0.0/16",
  "protocol": "all"
}
```
- Allows traffic from within VCN
- Functions can communicate with each other
- Management access from within VCN

**Note**: Functions are invoked via OCI control plane, not direct network access.

---

## 📊 Route Table Rules Explained

### NAT Gateway Route

```json
{
  "destination": "0.0.0.0/0",
  "networkEntityId": "<NAT_GATEWAY_OCID>"
}
```
- Routes all internet-bound traffic through NAT Gateway
- Enables functions to access external resources
- Provides outbound-only connectivity

### Service Gateway Route

```json
{
  "destination": "all-<region>-services-in-oracle-services-network",
  "networkEntityId": "<SERVICE_GATEWAY_OCID>"
}
```
- Routes OCI service traffic through Service Gateway
- Faster and more secure than going through internet
- Enables access to Object Storage, GenAI, etc.

---

## 🔧 Troubleshooting

### Issue: Function can't access Object Storage

**Cause**: Missing Service Gateway or route

**Fix**:
```bash
# Verify Service Gateway exists
oci network service-gateway list \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID

# Verify route table has service gateway route
oci network route-table get --rt-id $ROUTE_TABLE_OCID
```

### Issue: Function can't access external APIs

**Cause**: Missing NAT Gateway or route

**Fix**:
```bash
# Verify NAT Gateway exists and is enabled
oci network nat-gateway list \
  --compartment-id $COMPARTMENT_OCID \
  --vcn-id $VCN_OCID

# Check if NAT Gateway is enabled
oci network nat-gateway get --nat-gateway-id $NAT_GW_OCID
```

### Issue: "No available IPs in subnet"

**Cause**: Subnet too small or IPs exhausted

**Fix**:
```bash
# Check subnet available IPs
oci network subnet get --subnet-id $PRIVATE_SUBNET_OCID

# If needed, create larger subnet (e.g., 10.0.1.0/23 for more IPs)
```

### Issue: Function deployment fails with network error

**Cause**: Incorrect subnet configuration or subnet is public

**Fix**:
```bash
# Verify subnet prohibits public IPs
oci network subnet get \
  --subnet-id $PRIVATE_SUBNET_OCID \
  --query 'data."prohibit-public-ip-on-vnic"'

# Should return: true
```

---

## 📝 Save Your Configuration

Add these to your configuration file:

```bash
# Update ~/oci-deployment-config.txt
cat >> ~/oci-deployment-config.txt << EOF

# VCN Configuration
VCN_OCID=$VCN_OCID
PRIVATE_SUBNET_OCID=$PRIVATE_SUBNET_OCID
NAT_GATEWAY_OCID=$NAT_GW_OCID
SERVICE_GATEWAY_OCID=$SERVICE_GW_OCID
EOF
```

---

## ✅ Verification Checklist

Before proceeding, verify:

- [ ] VCN created
- [ ] Private subnet created and OCID saved
- [ ] NAT Gateway created and attached
- [ ] Service Gateway created and attached
- [ ] Route table configured correctly
- [ ] Security list allows required traffic
- [ ] `prohibit-public-ip-on-vnic` is `true` for private subnet
- [ ] Private subnet has available IP addresses

---

## 📚 Next Steps

Once VCN is set up:
- **Next Guide**: [06-auth-token-ocir.md](06-auth-token-ocir.md) - Generate Auth Token for OCIR

---

## 🔗 Additional Resources

- [OCI VCN Overview](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm)
- [VCN Wizard](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/quickstartnetworking.htm)
- [NAT Gateway](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/NATgateway.htm)
- [Service Gateway](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/servicegateway.htm)
- [Security Lists](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/securitylists.htm)
- [Functions Networking](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsconfig networkingSubnets.htm)
