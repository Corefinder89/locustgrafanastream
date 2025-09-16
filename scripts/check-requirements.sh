#!/bin/bash

# Check linting requirements script
# Checks if required tools are installed and provides installation suggestions

echo "🔍 Checking Linting Requirements"
echo "================================="

MISSING_TOOLS=()
AVAILABLE_TOOLS=()

# Check Python
if command -v python3 > /dev/null 2>&1; then
    AVAILABLE_TOOLS+=("python3")
    echo "✅ Python 3 available"
elif command -v python > /dev/null 2>&1; then
    AVAILABLE_TOOLS+=("python")
    echo "✅ Python available"
else
    MISSING_TOOLS+=("python")
    echo "❌ Python not found"
fi

# Check Docker Compose
if command -v docker-compose > /dev/null 2>&1; then
    AVAILABLE_TOOLS+=("docker-compose")
    echo "✅ docker-compose available"
elif command -v docker > /dev/null 2>&1 && docker compose version > /dev/null 2>&1; then
    AVAILABLE_TOOLS+=("docker compose")
    echo "✅ docker compose available"
else
    MISSING_TOOLS+=("docker-compose")
    echo "⚠️  docker-compose not available (Docker validation will use basic YAML check)"
fi

# Check Python packages
echo ""
echo "🐍 Checking Python packages..."

PYTHON_CMD=""
if command -v python3 > /dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python > /dev/null 2>&1; then
    PYTHON_CMD="python"
fi

if [ -n "$PYTHON_CMD" ]; then
    # Check for required Python packages
    PYTHON_PACKAGES=("yaml" "black" "flake8" "isort" "mypy" "bandit" "yamllint")
    
    for package in "${PYTHON_PACKAGES[@]}"; do
        if $PYTHON_CMD -c "import $package" 2>/dev/null; then
            echo "✅ $package available"
        else
            echo "❌ $package not found"
            MISSING_TOOLS+=("python:$package")
        fi
    done
fi

# Check Node.js tools
echo ""
echo "📦 Checking Node.js tools..."

if command -v node > /dev/null 2>&1; then
    echo "✅ Node.js available"
    
    NODE_PACKAGES=("markdownlint-cli" "jsonlint")
    for package in "${NODE_PACKAGES[@]}"; do
        if command -v ${package} > /dev/null 2>&1; then
            echo "✅ $package available"
        else
            echo "❌ $package not found"
            MISSING_TOOLS+=("node:$package")
        fi
    done
else
    echo "❌ Node.js not found"
    MISSING_TOOLS+=("node")
fi

# Summary and suggestions
echo ""
echo "📊 Summary"
echo "=========="

if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
    echo "🎉 All required tools are available!"
    echo ""
    echo "You can run:"
    echo "  make lint          # Run all linters"
    echo "  make lint-docker   # Run Docker linting"
    echo "  make format        # Format code"
else
    echo "⚠️  Some tools are missing. Here's how to install them:"
    echo ""
    
    # Installation suggestions
    if [[ " ${MISSING_TOOLS[@]} " =~ " python " ]]; then
        echo "📥 Install Python:"
        echo "  # On Ubuntu/Debian:"
        echo "  sudo apt-get install python3 python3-pip"
        echo ""
        echo "  # On macOS:"
        echo "  brew install python"
        echo ""
        echo "  # On Windows:"
        echo "  winget install Python.Python.3"
        echo ""
    fi
    
    # Python packages
    PYTHON_MISSING=($(printf '%s\n' "${MISSING_TOOLS[@]}" | grep '^python:' | sed 's/^python://'))
    if [ ${#PYTHON_MISSING[@]} -gt 0 ]; then
        echo "📥 Install Python packages:"
        echo "  pip install -r requirements-dev.txt"
        echo "  # Or individually:"
        echo "  pip install ${PYTHON_MISSING[*]}"
        echo ""
    fi
    
    if [[ " ${MISSING_TOOLS[@]} " =~ " node " ]]; then
        echo "📥 Install Node.js:"
        echo "  # On Ubuntu/Debian:"
        echo "  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
        echo "  sudo apt-get install -y nodejs"
        echo ""
        echo "  # On macOS:"
        echo "  brew install node"
        echo ""
        echo "  # On Windows:"
        echo "  winget install OpenJS.NodeJS"
        echo ""
    fi
    
    # Node packages
    NODE_MISSING=($(printf '%s\n' "${MISSING_TOOLS[@]}" | grep '^node:' | sed 's/^node://'))
    if [ ${#NODE_MISSING[@]} -gt 0 ]; then
        echo "📥 Install Node.js packages:"
        echo "  npm install -g ${NODE_MISSING[*]}"
        echo ""
    fi
    
    if [[ " ${MISSING_TOOLS[@]} " =~ " docker-compose " ]]; then
        echo "📥 Install Docker Compose:"
        echo "  # On Ubuntu/Debian:"
        echo "  sudo apt-get install docker-compose"
        echo ""
        echo "  # Or install Docker Desktop which includes compose"
        echo "  https://docs.docker.com/get-docker/"
        echo ""
    fi
    
    echo "💡 Quick setup:"
    echo "  ./setup-linters.ps1  # On Windows"
    echo "  # or"
    echo "  pip install -r requirements-dev.txt && npm install -g markdownlint-cli jsonlint"
fi