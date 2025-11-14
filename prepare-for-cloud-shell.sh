#!/bin/bash

# Script to prepare delivery-function for OCI Cloud Shell deployment
# This creates a ZIP file you can upload to Cloud Shell

echo "================================================"
echo "Preparing Delivery Function for Cloud Shell"
echo "================================================"
echo ""

# Check if we're in the right directory
if [ ! -d "delivery-function" ]; then
    echo "❌ Error: delivery-function directory not found"
    echo "Please run this script from the project root directory:"
    echo "  cd /Users/blramos/Documents/Oracle/FY26/Q2/TForce\ Logistics/Delivery-Intelligence-main"
    exit 1
fi

# Create ZIP file
echo "📦 Creating delivery-function.zip..."
zip -r delivery-function.zip delivery-function/ -x "*.pyc" -x "*__pycache__*" -x "*.DS_Store"

if [ $? -eq 0 ]; then
    echo "✅ Successfully created delivery-function.zip"
    echo ""
    echo "File size: $(du -h delivery-function.zip | cut -f1)"
    echo "Location: $(pwd)/delivery-function.zip"
    echo ""
    echo "================================================"
    echo "Next Steps:"
    echo "================================================"
    echo "1. Open OCI Console: https://cloud.oracle.com"
    echo "2. Click the terminal icon (>_) to open Cloud Shell"
    echo "3. In Cloud Shell, click ☰ menu → Upload"
    echo "4. Select delivery-function.zip"
    echo "5. Follow the steps in CLOUD-SHELL-DEPLOYMENT.md"
    echo ""
else
    echo "❌ Error creating ZIP file"
    exit 1
fi
