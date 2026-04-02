#!/bin/bash

# Activation script for CRS-V1 virtual environments
ENV_NAME="website_scrapers_env"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Function to find the environment
find_environment() {
    # Check common locations
    local locations=(
        "$PROJECT_ROOT/$ENV_NAME"
        "$HOME/$ENV_NAME"
        "$HOME/.virtualenvs/$ENV_NAME"
        "$HOME/Environments/$ENV_NAME"
        "/opt/virtualenvs/$ENV_NAME"
    )
    
    for location in "${locations[@]}"; do
        if [ -d "$location" ] && [ -f "$location/bin/activate" ]; then
            echo "$location"
            return 0
        fi
    done
    
    return 1
}

# Try to find the environment
ENV_LOCATION=$(find_environment)

if [ $? -eq 0 ]; then
    echo "Found environment at: $ENV_LOCATION"
    echo "Activating $ENV_NAME..."
    source "$ENV_LOCATION/bin/activate"
    echo "✅ Environment activated!"
    echo "To deactivate, run: deactivate"
else
    echo "❌ Environment '$ENV_NAME' not found in common locations:"
    echo "  - $PROJECT_ROOT/$ENV_NAME"
    echo "  - $HOME/$ENV_NAME"
    echo "  - $HOME/.virtualenvs/$ENV_NAME"
    echo "  - $HOME/Environments/$ENV_NAME"
    echo "  - /opt/virtualenvs/$ENV_NAME"
    echo ""
    echo "To create the environment, run: ./scripts/setup_env.sh"
    echo "Or set ENV_PATH and run setup: export ENV_PATH=/your/path && ./scripts/setup_env.sh"
    exit 1
fi
