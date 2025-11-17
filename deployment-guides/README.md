# OCI Deployment Guide - Complete Guide Index

This comprehensive guide walks you through deploying the Delivery Intelligence system to Oracle Cloud Infrastructure (OCI) using OCI CLI and Docker.

## 📋 What You'll Deploy

- **Delivery Quality Function**: AI-powered delivery assessment with GenAI Vision
- **Face Blur Function**: Privacy-focused image anonymization service

## ⏱️ Estimated Time

- **First-time setup**: 45-60 minutes
- **Subsequent deployments**: 10-15 minutes

## 📚 Guide Structure

Follow these guides in order:

### 1. Prerequisites & Setup
- **[01-prerequisites.md](01-prerequisites.md)** - Required OCIDs and information gathering
- **[02-oci-cli-installation.md](02-oci-cli-installation.md)** - Install and configure OCI CLI
- **[03-docker-installation.md](03-docker-installation.md)** - Install Docker for all platforms

### 2. Infrastructure Setup
- **[04-iam-policies.md](04-iam-policies.md)** - Configure IAM policies and dynamic groups
- **[05-vcn-networking.md](05-vcn-networking.md)** - Set up Virtual Cloud Network and subnets
- **[06-auth-token-ocir.md](06-auth-token-ocir.md)** - Generate auth token and access OCIR

### 3. Function Deployment
- **[07-function-application.md](07-function-application.md)** - Create Function Application
- **[08-deploy-delivery-function.md](08-deploy-delivery-function.md)** - Deploy main delivery function
- **[09-deploy-face-blur-function.md](09-deploy-face-blur-function.md)** - Deploy face blur function

### 4. Testing & Operations
- **[10-testing-verification.md](10-testing-verification.md)** - Test functions and verify deployment
- **[11-event-triggers.md](11-event-triggers.md)** - Set up Object Storage event triggers (optional)
- **[12-monitoring.md](12-monitoring.md)** - Monitor and maintain your functions

### 5. Reference
- **[13-troubleshooting.md](13-troubleshooting.md)** - Comprehensive troubleshooting guide
- **[14-command-reference.md](14-command-reference.md)** - Quick command reference
- **[15-best-practices.md](15-best-practices.md)** - Production best practices

## 🎯 Deployment Paths

### Path 1: Local Machine (macOS/Linux/Windows)
Best for: Development and testing
- Follow all guides in order
- Install OCI CLI and Docker locally
- Build and push images from your machine

### Path 2: Oracle Linux VM on OCI
Best for: Production deployments or if you don't have Docker locally
- Skip to Oracle Linux sections in installation guides
- Benefit from faster upload speeds to OCIR
- Pre-configured for OCI services

### Path 3: OCI Cloud Shell
Best for: Quick deployments without local setup
- OCI CLI pre-installed
- Skip OCI CLI installation guide
- Limited by Cloud Shell constraints (timeout after 20 min inactivity)

## ✅ Pre-Deployment Checklist

Before you begin, ensure you have:

- [ ] OCI account with admin access
- [ ] Access to a compartment
- [ ] Internet connectivity
- [ ] Local machine or OCI VM
- [ ] 30-60 minutes of uninterrupted time

## 🚀 Quick Start

1. **Start with Prerequisites**: [01-prerequisites.md](01-prerequisites.md)
2. **Follow guides sequentially** - Each builds on the previous
3. **Don't skip verification steps** - They help catch issues early
4. **Save your OCIDs** - You'll need them throughout deployment

## 📞 Getting Help

If you encounter issues:
1. Check the specific guide's troubleshooting section
2. Review [13-troubleshooting.md](13-troubleshooting.md)
3. Verify you completed all previous steps
4. Check OCI service status

## 🔄 Updates and Maintenance

After initial deployment:
- Use [08-deploy-delivery-function.md](08-deploy-delivery-function.md) for updates
- Use [09-deploy-face-blur-function.md](09-deploy-face-blur-function.md) for updates
- Review [12-monitoring.md](12-monitoring.md) for ongoing operations

## 📖 Additional Resources

- [OCI Functions Documentation](https://docs.oracle.com/en-us/iaas/Content/Functions/home.htm)
- [OCI CLI Documentation](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)
- [Docker Documentation](https://docs.docker.com/)
- [Oracle Container Registry (OCIR)](https://docs.oracle.com/en-us/iaas/Content/Registry/home.htm)

---

**Ready to begin?** Start with [01-prerequisites.md](01-prerequisites.md)
