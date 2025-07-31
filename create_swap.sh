#!/bin/bash

# ==============================================================================
# Script to automatically create or recreate a 16GB swap file.
# Safe to re-run. Works on both VPS and WSL.
# ==============================================================================

# Variables
SWAP_SIZE_GB=16
SWAP_FILE="/swapfile"

# --- Pre-run Checks ---

# 1. Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   echo "Try running: sudo ./create_swap.sh"
   exit 1
fi

# 2. User Confirmation
echo "This script will create or recreate a ${SWAP_SIZE_GB}GB swap file."
echo "File path: ${SWAP_FILE}"
read -p "Do you want to proceed? (y/n): " answer
if [[ "${answer,,}" != "y" ]]; then
    echo "Operation cancelled by the user."
    exit 0
fi

# --- Main Script Logic ---

echo ""
echo "--- Step 1: Disabling and removing the old swap file (if it exists) ---"
swapoff ${SWAP_FILE} 2>/dev/null || true
rm -f ${SWAP_FILE}
echo "Old swap file successfully removed."

echo ""
echo "--- Step 2: Creating a new ${SWAP_SIZE_GB}GB swap file ---"
echo "This may take a few minutes..."
dd if=/dev/zero of=${SWAP_FILE} bs=1G count=${SWAP_SIZE_GB}
echo "File created successfully."

echo ""
echo "--- Step 3: Setting permissions and formatting ---"
chmod 600 ${SWAP_FILE}
mkswap ${SWAP_FILE}
echo "Permissions and formatting complete."

echo ""
echo "--- Step 4: Activating the new swap file ---"
swapon ${SWAP_FILE}
echo "Swap file activated."

echo ""
echo "--- Step 5: Making the swap permanent (adding to /etc/fstab) ---"
# Remove the old line if it exists to avoid duplicates
sed -i "\#${SWAP_FILE}#d" /etc/fstab
# Add the new line
echo "${SWAP_FILE} none swap sw 0 0" >> /etc/fstab
echo "The /etc/fstab entry has been updated for auto-mount on boot."

echo ""
echo "======================================================"
echo "          SCRIPT COMPLETED SUCCESSFULLY!"
echo "======================================================"
echo "Verifying the current memory and swap status:"
echo ""
free -h
