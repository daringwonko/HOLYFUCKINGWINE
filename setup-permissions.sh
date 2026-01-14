#!/bin/bash
##############################################################################
# Make all scripts executable
# Run this once after cloning the repository
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/sketchup-wine-setup/scripts" && pwd)"

echo "Making all scripts executable..."
chmod +x "$SCRIPT_DIR"/*.sh

echo "Checking permissions..."
ls -lh "$SCRIPT_DIR"/*.sh

echo ""
echo "✓ All scripts are now executable"
echo ""
echo "Next steps:"
echo "  cd sketchup-wine-setup"
echo "  ./scripts/00-master-setup.sh"
