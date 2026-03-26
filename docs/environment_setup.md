# Environment Setup Guide

This document explains the different approaches for setting up and managing the Altoscope development environment.

## Option 1: Virtual Environment with Custom Location (Current Setup)

The active environment lives at `~/Documents/VirtualEnvironments/altoscope/`.

### Activation
```bash
# fish shell (current)
source ~/Documents/VirtualEnvironments/altoscope/bin/activate.fish

# bash / zsh
source ~/Documents/VirtualEnvironments/altoscope/bin/activate
```

### Setup from scratch
```bash
# Set a custom location for your virtual environment
export ENV_PATH=/path/to/your/environments

# Run the setup script
./scripts/setup_env.sh
```

### Benefits
- Environment stored outside repository
- Works across different machines
- Easy to manage multiple projects
- No conflicts with other developers

## Option 2: Project-Local Environment (Default)

### Setup
```bash
# Run setup without ENV_PATH (creates in project root)
./scripts/setup_env.sh
```

### Activation
```bash
# Activate from project root
source website_scrapers_env/bin/activate
```

### Benefits
- Simple and straightforward
- Environment travels with project
- Good for single-developer projects

## Option 3: Docker (Recommended for Production/Deployment)

### Why Docker?
- **Consistency**: Same environment across all machines
- **Isolation**: No conflicts with system Python
- **Reproducibility**: Exact same dependencies everywhere
- **Deployment**: Easy to deploy to production

### Basic Docker Setup
```dockerfile
# Example Dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY backend/requirements.in .
RUN pip install pip-tools && pip-compile requirements.in
RUN pip install -r requirements.txt

COPY . .
RUN pip install -e backend/

CMD ["python", "-m", "your_main_module"]
```

### Docker Usage
```bash
# Build the image
docker build -t crs-v1 .

# Run the container
docker run -it crs-v1
```

## Option 4: Conda/Miniconda

### Setup
```bash
# Create conda environment
conda create -n crs-v1 python=3.11

# Activate
conda activate crs-v1

# Install dependencies
cd backend
pip install -r requirements.in
pip install -e .
```

## Environment Variables

The setup script supports these environment variables:

- `ENV_PATH`: Custom location for virtual environment
- `PYTHON_VERSION`: Python version to use (default: python3)

## Pipeline DB connection (`DATABASE_URL`)

The ingestion pipeline reads Postgres connection info from:

- `DATABASE_URL` (preferred)
- `SUPABASE_DB_URL` (fallback)

`backend/scripts/run.py` will also auto-load variables from `.env` / `.env.local` in the repo root and `backend/` directory.

### zsh note: `event not found`

If your DB password contains `!`, zsh history expansion can throw `event not found`. Use single quotes:

```bash
export DATABASE_URL='postgresql://postgres:<password>@db.<project_ref>.supabase.co:5432/postgres?sslmode=require'
```

## Common Locations

The current active environment:
- `~/Documents/VirtualEnvironments/altoscope/` ← **use this one**

Legacy name (no longer used):
- `~/Documents/VirtualEnvironments/website_scraper_env/` (old name, can be deleted)

## Troubleshooting

### Environment Not Found
```bash
# Check if environment exists
ls -la ~/Documents/VirtualEnvironments/altoscope/

# Recreate if needed
export ENV_PATH=~/Documents/VirtualEnvironments
./scripts/setup_env.sh
```

### Permission Issues
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### Python Version Issues
```bash
# Specify Python version
PYTHON_VERSION=python3.11 ./scripts/setup_env.sh
```
