#!/bin/bash

# === CONFIG ===
# Allow custom environment location via ENV_PATH, default to project root
ENV_NAME="website_scrapers_env"
PYTHON_VERSION="python3"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Use ENV_PATH if set, otherwise default to project root
if [ -n "$ENV_PATH" ]; then
    ENV_LOCATION="$ENV_PATH/$ENV_NAME"
    echo "Using custom environment path: $ENV_LOCATION"
else
    ENV_LOCATION="$PROJECT_ROOT/$ENV_NAME"
    echo "Using default environment path: $ENV_LOCATION"
    echo "To use a custom location, set ENV_PATH environment variable:"
    echo "export ENV_PATH=/path/to/your/environments"
fi

# === CREATE ENVIRONMENT ===
echo "Creating virtual environment: $ENV_NAME"
$PYTHON_VERSION -m venv "$ENV_LOCATION"

# === ACTIVATE ENVIRONMENT ===
echo "Activating environment..."
source "$ENV_LOCATION/bin/activate"

# === INSTALL BASIC DEPENDENCIES ===
echo "Installing common scraping packages..."
pip install --upgrade pip
pip install playwright beautifulsoup4 requests pip-tools

# Optional: download Playwright drivers
playwright install

# === INSTALL PROJECT DEPENDENCIES ===
echo "Installing project dependencies..."
if [ -f "$BACKEND_DIR/requirements.in" ]; then
    echo "Found requirements.in, installing dependencies..."
    cd "$BACKEND_DIR"
    pip install -r requirements.in
    pip install -e .
    cd "$PROJECT_ROOT"
else
    echo "No requirements.in found, creating basic requirements.txt..."
    pip freeze > "$PROJECT_ROOT/requirements.txt"
fi

# === CREATE .GITIGNORE IF MISSING ===
if [ ! -f "$PROJECT_ROOT/.gitignore" ]; then
  echo "Creating .gitignore file..."
  touch "$PROJECT_ROOT/.gitignore"
fi

# === APPEND STANDARD PYTHON IGNORE RULES ===
echo "Adding venv and large file rules to .gitignore..."
cd "$PROJECT_ROOT"
# Only add to gitignore if using default location
if [ -z "$ENV_PATH" ]; then
    grep -qxF "$ENV_NAME/" .gitignore || echo "$ENV_NAME/" >> .gitignore
fi
grep -qxF '__pycache__/' .gitignore || echo '__pycache__/' >> .gitignore
grep -qxF '*.pyc' .gitignore || echo '*.pyc' >> .gitignore
grep -qxF '*.DS_Store' .gitignore || echo '*.DS_Store' >> .gitignore
grep -qxF '*.log' .gitignore || echo '*.log' >> .gitignore
grep -qxF '*.sqlite3' .gitignore || echo '*.sqlite3' >> .gitignore
grep -qxF '*.db' .gitignore || echo '*.db' >> .gitignore

# === FINISH ===
echo "✅ Setup complete. You are now in the '$ENV_NAME' environment."
echo "To activate it later, run: source $ENV_LOCATION/bin/activate"
echo "Project root: $PROJECT_ROOT"
echo ""
echo "💡 Tip: To use a custom environment location in the future:"
echo "export ENV_PATH=/path/to/your/environments"
echo "Then run this script again."
