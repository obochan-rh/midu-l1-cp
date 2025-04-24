#!/bin/bash

# List of package names
packages=(
  'advanced-cluster-management'
  'multicluster-engine'
  'topology-aware-lifecycle-manager'
  'openshift-gitops-operator'
  'odf-operator'
  'ocs-operator'
  'odf-csi-addons-operator'
  'local-storage-operator'
  'mcg-operator'
  'cluster-logging'
  'odf-prometheus-operator'
  'recipe'
  'rook-ceph-operator'
)

#!/bin/bash

# Set variables
DOWNLOAD_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.16.0/oc-mirror.tar.gz"
FILE_NAME="oc-mirror.tar.gz"
TARGET_DIR="oc-mirror"

# Download the file
echo "Downloading oc-mirror from $DOWNLOAD_URL..."
curl -LO "$DOWNLOAD_URL"

# Verify the download
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to download the file."
    exit 1
fi

echo "Download completed: $FILE_NAME"

# Create target directory and extract the tar.gz file
echo "Extracting $FILE_NAME..."
mkdir -p "$TARGET_DIR"
tar -xzf "$FILE_NAME" -C "$TARGET_DIR"

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to extract $FILE_NAME."
    exit 1
fi

echo "Extraction completed."

# Make binaries executable
echo "Making binaries executable..."
chmod +x "$TARGET_DIR"/*

# Check if chmod was successful
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to make files executable."
    exit 1
fi

echo "All binaries are now executable."

# Cleanup
echo "Cleaning up the downloaded archive..."
rm -f "$FILE_NAME"

echo "Script completed successfully. The binaries are located in $TARGET_DIR."


# Loop through each package
for package in "${packages[@]}"; do
  echo "Processing package: $package"
  
  # Example command (replace with actual logic)
  ./${TARGET_DIR}/oc-mirror list operators --catalog registry.redhat.io/redhat/redhat-operator-index:v4.16 --package="$package"
  
  # Add additional logic here for processing the output if needed
done

echo "All packages processed."