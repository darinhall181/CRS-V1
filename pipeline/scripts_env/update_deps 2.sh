#!/bin/bash

# Update dependencies script for CRS-V1
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

echo "🔄 Updating dependencies..."
echo "Project root: $PROJECT_ROOT"
echo "Backend directory: $BACKEND_DIR"

# Check if we're in the right directory structure
if [ ! -f "$BACKEND_DIR/requirements.in" ]; then
    echo "❌ Error: requirements.in not found in $BACKEND_DIR"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Ensure pip-tools is installed
echo "📦 Checking pip-tools installation..."
if ! pip show pip-tools > /dev/null 2>&1; then
    echo "Installing pip-tools..."
    pip install pip-tools
fi

# Change to backend directory for dependency operations
cd "$BACKEND_DIR"

# Regenerate requirements.txt from requirements.in
echo "📦 Regenerating requirements.txt..."
pip-compile requirements.in

# Reinstall the package in editable mode
echo "🔧 Reinstalling package in editable mode..."
pip install -e .

# Return to project root
cd "$PROJECT_ROOT"

echo "✅ Dependencies updated successfully!"
echo ""
echo "To add a new dependency:"
echo "1. Add it to $BACKEND_DIR/requirements.in"
echo "2. Run: ./scripts/update_deps.sh"
echo ""
echo "To install all dependencies in a new environment:"
echo "cd $BACKEND_DIR && pip install -r requirements.txt"
