# VCN Setup for OCI Functions

Before deploying your function, you need a properly configured Virtual Cloud Network (VCN) with the right subnet configuration.

## Quick Answer: Use a **PRIVATE Subnet**

**✅ Recommended: Private Subnet**
- Functions should run in private subnets for security
- Access external services through NAT Gateway or Service Gateway
- Follows OCI security best practices
- Keeps function resources isolated from direct internet access

**❌ Not Recommended: Public Subnet**
- Exposes function directly to the internet
- Less secure
- Not following cloud security best practices

## VCN Architecture for Functions

```
Internet
    ↓
[Internet Gateway] ← For bastion/management only (optional)
    ↓
[Public Subnet] ← NOT for functions
    
[NAT Gateway] ← Allows private subnet outbound access
    ↓
[Private Subnet] ← YOUR FUNCTIONS GO HERE
    ↓
[Service Gateway] ← Access to OCI services (Object Storage, GenAI, etc.)
```

## Step-by-Step VCN Setup

### Option 1: Use VCN Wizard (Easiest)

1. **Open VCN Wizard**:
   - OCI Console → Networking → Virtual Cloud Networks
   - Click "Start VCN Wizard"
   - Select "VCN with Internet Connectivity"
   - Click "Start VCN Wizard"

2. **Configure Basic Information**:
   ```
   VCN Name: functions-vcn
   Compartment: <Your Compartment>
   VCN CIDR Block: 10.0.0.0/16
   ```

3. **Configure Subnets**:
   ```
   Public Subnet CIDR: 10.0.0.0/24
   Private Subnet CIDR: 10.0.1.0/24
   ```

4. **Review and Create**:
   - The wizard automatically creates:
     - Internet Gateway (for public subnet)
     - NAT Gateway (for private subnet outbound)
     - Service Gateway (for OCI services)
     - Route tables and security lists

5. **Wait for Creation**: Takes ~1 minute

6. **Get Private Subnet OCID**:
   - Click on your VCN
   - Click "Private Subnet-functions-vcn"
   - Copy the OCID (starts with `ocid1.subnet.oc1...`)

### Option 2: Manual Setup (Advanced)

If you prefer manual control:

#### 1. Create VCN

```bash
oci network vcn create \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --display-name functions-vcn \
  --cidr-block 10.0.0.0/16 \
  --dns-label functionvcn
```

#### 2. Create Internet Gateway

```bash
VCN_OCID=$(oci network vcn list --compartment-id <YOUR_COMPARTMENT_OCID> --display-name functions-vcn --query 'data[0].id' --raw-output)

oci network internet-gateway create \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --vcn-id $VCN_OCID \
  --display-name functions-igw \
  --is-enabled true
```

#### 3. Create NAT Gateway

```bash
oci network nat-gateway create \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --vcn-id $VCN_OCID \
  --display-name functions-nat-gateway
```

#### 4. Create Service Gateway

```bash
# Get all services OCID
SERVICES_OCID=$(oci network service list --query 'data[?"cidr-block"]|[0].id' --raw-output)

oci network service-gateway create \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --vcn-id $VCN_OCID \
  --services '[{"serviceId":"'$SERVICES_OCID'"}]' \
  --display-name functions-service-gateway
```

#### 5. Create Private Subnet Route Table

```bash
NAT_GW_OCID=$(oci network nat-gateway list --compartment-id <YOUR_COMPARTMENT_OCID> --vcn-id $VCN_OCID --query 'data[0].id' --raw-output)

SERVICE_GW_OCID=$(oci network service-gateway list --compartment-id <YOUR_COMPARTMENT_OCID> --vcn-id $VCN_OCID --query 'data[0].id' --raw-output)

oci network route-table create \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --vcn-id $VCN_OCID \
  --display-name private-route-table \
  --route-rules '[
    {
      "destination": "0.0.0.0/0",
      "destinationType": "CIDR_BLOCK",
      "networkEntityId": "'$NAT_GW_OCID'"
    },
    {
      "destination": "all-ord-services-in-oracle-services-network",
      "destinationType": "SERVICE_CIDR_BLOCK",
      "networkEntityId": "'$SERVICE_GW_OCID'"
    }
  ]'
```

#### 6. Create Security List for Private Subnet

```bash
oci network security-list create \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --vcn-id $VCN_OCID \
  --display-name private-security-list \
  --egress-security-rules '[
    {
      "destination": "0.0.0.0/0",
      "protocol": "all",
      "isStateless": false
    }
  ]' \
  --ingress-security-rules '[
    {
      "source": "10.0.0.0/16",
      "protocol": "all",
      "isStateless": false
    }
  ]'
```

#### 7. Create Private Subnet

```bash
ROUTE_TABLE_OCID=$(oci network route-table list --compartment-id <YOUR_COMPARTMENT_OCID> --vcn-id $VCN_OCID --display-name private-route-table --query 'data[0].id' --raw-output)

SECURITY_LIST_OCID=$(oci network security-list list --compartment-id <YOUR_COMPARTMENT_OCID> --vcn-id $VCN_OCID --display-name private-security-list --query 'data[0].id' --raw-output)

oci network subnet create \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --vcn-id $VCN_OCID \
  --display-name private-subnet \
  --cidr-block 10.0.1.0/24 \
  --route-table-id $ROUTE_TABLE_OCID \
  --security-list-ids "[$SECURITY_LIST_OCID]" \
  --prohibit-public-ip-on-vnic true \
  --dns-label privatesubnet
```

## Required IAM Policies

Your function needs access to OCI services. Create these policies:

### 1. Create Dynamic Group for Functions

```bash
# In OCI Console → Identity → Dynamic Groups → Create Dynamic Group

Name: functions-dynamic-group
Description: Dynamic group for OCI Functions

Matching Rules:
ALL {resource.type = 'fnfunc', resource.compartment.id = '<YOUR_COMPARTMENT_OCID>'}
```

### 2. Create Policies

```bash
# In OCI Console → Identity → Policies → Create Policy

Name: functions-policies
Description: Policies for OCI Functions to access services

Policy Statements:
```

```
Allow dynamic-group functions-dynamic-group to manage objects in compartment <YOUR_COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to read objectstorage-namespaces in compartment <YOUR_COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to use generative-ai-family in compartment <YOUR_COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to use generative-ai-chat in compartment <YOUR_COMPARTMENT_NAME>
Allow dynamic-group functions-dynamic-group to use generative-ai-inference in compartment <YOUR_COMPARTMENT_NAME>
```

## Verify Your VCN Setup

### Check Components

```bash
# List VCNs
oci network vcn list --compartment-id <YOUR_COMPARTMENT_OCID>

# List Subnets (verify private subnet exists)
oci network subnet list --compartment-id <YOUR_COMPARTMENT_OCID> --vcn-id <YOUR_VCN_OCID>

# Verify NAT Gateway
oci network nat-gateway list --compartment-id <YOUR_COMPARTMENT_OCID> --vcn-id <YOUR_VCN_OCID>

# Verify Service Gateway
oci network service-gateway list --compartment-id <YOUR_COMPARTMENT_OCID> --vcn-id <YOUR_VCN_OCID>
```

### Get Private Subnet OCID

```bash
PRIVATE_SUBNET_OCID=$(oci network subnet list \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --vcn-id <YOUR_VCN_OCID> \
  --query 'data[?"prohibit-public-ip-on-vnic"]|[0].id' \
  --raw-output)

echo "Private Subnet OCID: $PRIVATE_SUBNET_OCID"
```

## Use in Function Application

When creating your function application in Cloud Shell:

```bash
oci fn application create \
  --compartment-id <YOUR_COMPARTMENT_OCID> \
  --display-name delivery-agent-app \
  --subnet-ids '["<YOUR_PRIVATE_SUBNET_OCID>"]'
```

## Why Private Subnet?

### Security Benefits
- ✅ **No Direct Internet Exposure**: Functions not accessible from internet
- ✅ **Controlled Outbound Access**: NAT Gateway controls outbound traffic
- ✅ **Service Gateway**: Secure, private path to OCI services
- ✅ **Defense in Depth**: Multiple security layers

### What Functions Can Access
- ✅ **OCI Object Storage** (via Service Gateway)
- ✅ **OCI Generative AI** (via Service Gateway)
- ✅ **External APIs** (via NAT Gateway)
- ✅ **Other OCI Services** (via Service Gateway)

### What Functions CANNOT Access (Good!)
- ❌ **Direct Inbound Internet Traffic** (unless you explicitly configure it)
- ❌ **Unauthorized External Services** (controlled by security rules)

## Common Issues

### Issue: Function can't access external APIs
**Solution**: Make sure NAT Gateway is attached and route table is configured

### Issue: Function can't access Object Storage
**Solution**: Make sure Service Gateway is attached and route table includes service route

### Issue: Function deployment fails
**Solution**: Verify subnet has available IP addresses (check subnet size)

## Next Steps

After VCN setup:
1. ✅ Get your private subnet OCID
2. ✅ Update CLOUD-SHELL-DEPLOYMENT.md with your subnet OCID
3. ✅ Create Function Application with private subnet
4. ✅ Deploy your function following the Cloud Shell guide

## Quick Start Checklist

- [ ] Create VCN using VCN Wizard
- [ ] Verify private subnet exists
- [ ] Copy private subnet OCID
- [ ] Create Dynamic Group for functions
- [ ] Create IAM policies for function access
- [ ] Proceed with function deployment

## Summary

**Use a PRIVATE subnet** for your OCI Functions deployment. This provides:
- Better security posture
- Controlled access to external resources
- Compliance with cloud security best practices
- Secure access to OCI services via Service Gateway

The VCN Wizard makes this easy - just follow Option 1 above!
