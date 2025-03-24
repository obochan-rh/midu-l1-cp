#!/bin/bash
#
# Script Name: custom-index.sh
# Description: Automates the setup and deployment of a custom OpenShift operator index.
# Author: Mihai IDU
# Email: midu@redhat.com
# Created: 2024-03-24
# Version: 1.0
# License: MIT
#
# Usage: ./custom-index.sh

# Enable strict error handling
set -euo pipefail

# Function to handle unexpected errors
error_exit() {
    echo "❌ ERROR: $1"
    exit 1
}

# Ensure cleanup on exit
trap 'echo "⚠️  Script interrupted or failed."; exit 1' INT TERM ERR

# Set variables
# Function to validate OCP version format
validate_ocp_version() {
    local version_regex='^[0-9]+\.[0-9]+\.[0-9]+$'
    if [[ ! $1 =~ $version_regex ]]; then
        error_exit "Invalid OCP version format. Expected format: X.Y.Z (e.g., 4.17.21)"
    fi
}

# Prompt user for OCP_VERSION
read -rp "Enter OCP version (format X.Y.Z, e.g., 4.17.21): " OCP_VERSION

# Validate the input format
validate_ocp_version "$OCP_VERSION"

# If validation passes, proceed and display the OCP VERSION
echo "✅ Valid OCP version entered: $OCP_VERSION"
OCP_MAJOR_MINOR="${OCP_VERSION%.*}" # Extracts "4.y" out of "OCP_VERSION"
#INDEX_IMAGE="quay.io/midu/custom-operator-index:v$OCP_MAJOR_MINOR-test"
# Function to validate INDEX_IMAGE format
validate_index_image() {
    local image_regex='^[a-zA-Z0-9.-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+:v[0-9]+\.[0-9]+-test$'
    if [[ ! $1 =~ $image_regex ]]; then
        error_exit "Invalid INDEX_IMAGE format. Expected format: quay.io/namespace/repository:vX.Y (e.g., quay.io/midu/custom-operator-index:v4.17-test)"
    fi
}

# Prompt user for INDEX_IMAGE
read -rp "Enter INDEX_IMAGE (format quay.io/namespace/repository:vX.Y-test): " INDEX_IMAGE

# Validate the input format
validate_index_image "$INDEX_IMAGE"

# If validation passes, proceed
echo "✅ Valid INDEX_IMAGE entered: $INDEX_IMAGE"

WORK_DIR="catalog"
CUSTOM_INDEX_DIR="$WORK_DIR/custom-operator-index"
OPM_BINARY="opm-rhel8"  # Use opm-rhel8 binary from tarball
OPM_TAR="opm-linux-${OCP_VERSION}.tar.gz"
OPM_URL="https://mirror.openshift.com/pub/openshift-v4/amd64/clients/ocp/${OCP_VERSION}/${OPM_TAR}"
DOCKERFILE="Dockerfile"

echo "🔍 Checking prerequisites..."
# Check if Podman is installed
command -v podman &>/dev/null || error_exit "Podman is not installed. Install it first."

# Check if the system is RHEL-based
if [ -f /etc/redhat-release ]; then
    echo "RHEL-based OS detected. Proceeding with the script..."
else
    echo "This script can only run on RHEL-based systems. Exiting."
    exit 1
fi

# Ensure the working directory its empty
if [ -d "$WORK_DIR" ]; then
    echo "🧹 Cleaning up working directory..."
    rm -rf "$WORK_DIR" || error_exit "Failed to clean up working directory."
fi

# Create working directory
echo "📂 Setting up working directory..."
mkdir -p "$CUSTOM_INDEX_DIR"
cd "$WORK_DIR" || error_exit "Failed to change directory to $WORK_DIR"

# Check if OPM binary is already present and executable
if [ -x "$OPM_BINARY" ]; then
    echo "✅ OPM binary found: $OPM_BINARY (Skipping download)"
else
    echo "⬇️  Downloading OPM binary..."
    curl -sSLO "$OPM_URL" || error_exit "Failed to download OPM binary."
    
    echo "📦 Listing contents of the tarball..."
    tar -tvf "$OPM_TAR" || error_exit "Failed to list contents of tarball."
    
    echo "📦 Extracting OPM binary..."
    tar xvf "$OPM_TAR" || error_exit "Failed to extract OPM binary."
    
    # Debugging: Show the contents of the working directory after extraction
    echo "📂 Listing extracted files in the working directory:"
    ls -l

    # Check if the binary exists after extraction
    if [ ! -f "$OPM_BINARY" ]; then
        error_exit "❌ OPM binary extraction failed. File $OPM_BINARY not found."
    fi

    chmod +x "$OPM_BINARY" || error_exit "Failed to make OPM executable."
    echo "✅ OPM binary is ready."
fi

# Ensure index.json file exists
echo "📝 Rendering index.json..."
./"$OPM_BINARY" render registry.redhat.io/redhat/redhat-operator-index:v${OCP_MAJOR_MINOR} --output=json > index.json \
    || error_exit "Failed to render redhat-operator-index."

./"$OPM_BINARY" render registry.redhat.io/redhat/certified-operator-index:v${OCP_MAJOR_MINOR} --output=json >> index.json \
    || error_exit "Failed to render certified-operator-index."

# Ensure index.json exists
echo "🔍 Filtering operators..."
#touch "$CUSTOM_INDEX_DIR/index.json"

# Defining the RAN RDS operator list
operators=(
  'lvms-operator' 
  'ptp-operator'
  'sriov-operator' 
  'local-storage-operator' 
  'cluster-logging' 
  'lifecycle-agent' 
  'redhat-oadp-operator' 
  'sriov-fec'
)

for package in "${operators[@]}"; do
    echo "Processing package: $package"

    jq --arg pkg "$package" '. | select((.package==$pkg) or (.name==$pkg))' ./index.json >> ./custom-operator-index/index.json

    if [[ $? -ne 0 ]]; then
        echo "Error processing package: $package"
    fi
done

# Validate the generated index
echo "✅ Validating the custom index..."
./"$OPM_BINARY" validate ./custom-operator-index/ || error_exit "Validation failed."

# Create Dockerfile
echo "📝 Creating Dockerfile..."
cat <<EOF > "$DOCKERFILE"
FROM registry.redhat.io/openshift4/ose-operator-registry-rhel9:v$OCP_MAJOR_MINOR
ENTRYPOINT ["/bin/opm"]
CMD ["serve", "/configs"]
ADD custom-operator-index /configs
LABEL operators.operatorframework.io.index.configs.v1=/configs
EOF

# Build the container image
echo "🔨 Building custom index image..."
podman build . -f "$DOCKERFILE" -t "$INDEX_IMAGE" || error_exit "Image build failed."

# Push the custom index image to the registry
echo "🚀 Pushing image to registry..."
podman push "$INDEX_IMAGE" || error_exit "Image push failed."

echo "✅ Custom index creation complete."
