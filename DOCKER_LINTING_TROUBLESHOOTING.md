# Docker Compose Linting Troubleshooting Guide

## 🚨 Common Issues and Solutions

### Issue 1: `docker-compose: command not found`

**Problem:** The `docker-compose` command is not available in your environment.

**Solutions:**

#### Option 1: Install Docker Compose (Recommended)
```bash
# On Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker-compose

# On macOS
brew install docker-compose

# On Windows
winget install Docker.DockerDesktop
# Docker Desktop includes docker-compose
```

#### Option 2: Use Docker Compose V2 (Newer syntax)
```bash
# Instead of docker-compose, use:
docker compose config -q
docker compose up -d
```

#### Option 3: Use Fallback Validation (Automatic)
The linting scripts automatically fall back to basic YAML validation if docker-compose is not available.

### Issue 2: `Permission denied` when running scripts

**Problem:** Script files don't have execute permissions.

**Solution:**
```bash
# Make scripts executable
chmod +x scripts/validate-docker-compose.sh
chmod +x scripts/check-requirements.sh

# Or run with bash explicitly
bash scripts/validate-docker-compose.sh
```

### Issue 3: `Python not found` or `yaml module not found`

**Problem:** Python or required Python packages are missing.

**Solutions:**
```bash
# Install Python
# On Ubuntu/Debian:
sudo apt-get install python3 python3-pip

# On Windows:
winget install Python.Python.3

# Install required packages
pip install pyyaml yamllint
```

### Issue 4: GitHub Actions failing with Docker Compose errors

**Problem:** GitHub Actions runner doesn't have docker-compose installed.

**Solution:** The workflow has been updated to handle this automatically:
- Installs docker-compose via pip
- Falls back to basic YAML validation if needed
- Uses robust error handling

### Issue 5: `yamllint` command not found

**Problem:** yamllint is not installed.

**Solutions:**
```bash
# Install yamllint
pip install yamllint

# Or install all dev requirements
pip install -r requirements-dev.txt
```

### Issue 6: Windows PowerShell execution policy errors

**Problem:** PowerShell scripts can't run due to execution policy.

**Solutions:**
```powershell
# Temporary bypass (for current session)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Or run script with bypass flag
powershell -ExecutionPolicy Bypass -File scripts/validate-docker-compose.ps1

# Permanent solution (run as admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🔧 Platform-Specific Solutions

### Windows Users

1. **Use PowerShell version:**
   ```powershell
   # Use the PowerShell validation script
   .\scripts\validate-docker-compose.ps1
   
   # Or via Makefile
   make lint-docker-ps
   ```

2. **Install Docker Desktop:**
   - Download from https://www.docker.com/products/docker-desktop
   - Includes docker-compose automatically

3. **Use WSL2 (Windows Subsystem for Linux):**
   ```bash
   # Install WSL2 and use Linux commands
   wsl --install
   # Then use the bash version of scripts
   ```

### macOS Users

1. **Install via Homebrew:**
   ```bash
   brew install docker-compose yamllint
   brew install node  # For markdownlint
   npm install -g markdownlint-cli jsonlint
   ```

### Linux Users

1. **Install via package manager:**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install docker-compose python3-pip nodejs npm
   pip3 install yamllint
   npm install -g markdownlint-cli jsonlint
   ```

## 🛠️ Manual Validation (When Tools Are Missing)

If automated tools aren't available, you can manually validate:

### 1. Basic YAML Syntax Check
```bash
# Using Python
python -c "import yaml; yaml.safe_load(open('docker-compose.yml'))"

# Using yq (if available)
yq eval '.' docker-compose.yml > /dev/null
```

### 2. Security Checklist
Manually review your `docker-compose.yml` for:

- ✅ **Read-only containers:** `read_only: true`
- ✅ **Restart policies:** `restart: unless-stopped`
- ✅ **Custom networks:** `networks:` section
- ✅ **Specific image tags:** Avoid `:latest`
- ✅ **Environment variables:** Use `${VAR:-default}` syntax
- ❌ **Hardcoded secrets:** No passwords in plain text
- ❌ **Dangerous ports:** Avoid exposing 22, 3389
- ✅ **Read-only volumes:** Use `:ro` where possible

### 3. Production Readiness
- Resource limits (`mem_limit`, `cpus`, or `deploy.resources`)
- Health checks
- Proper volume management
- Network isolation

## 🚀 Quick Setup Commands

### Complete Setup (All Platforms)
```bash
# Check what's missing
bash scripts/check-requirements.sh

# Install Python requirements
pip install -r requirements-dev.txt

# Install Node.js requirements (if Node.js available)
npm install -g markdownlint-cli jsonlint

# Test the setup
make lint-docker
```

### Windows Quick Setup
```powershell
# Run the setup script
.\setup-linters.ps1

# Test with PowerShell version
make lint-docker-ps
```

### Minimal Setup (No Docker Compose)
```bash
# Install just the essentials for basic validation
pip install pyyaml yamllint

# Use the fallback validation
python -c "import yaml; yaml.safe_load(open('docker-compose.yml'))"
yamllint docker-compose.yml
```

## 📋 Verification

After setup, verify everything works:

```bash
# Check requirements
bash scripts/check-requirements.sh

# Test all linters
make lint

# Test Docker linting specifically
make lint-docker

# On Windows, also test PowerShell version
make lint-docker-ps
```

## 🆘 Still Having Issues?

1. **Check the requirements script:**
   ```bash
   bash scripts/check-requirements.sh
   ```

2. **Run individual components:**
   ```bash
   yamllint docker-compose.yml
   python -c "import yaml; yaml.safe_load(open('docker-compose.yml'))"
   ```

3. **Use verbose mode for debugging:**
   ```bash
   bash -x scripts/validate-docker-compose.sh
   ```

4. **Check GitHub Actions logs:**
   - Go to Actions tab in your GitHub repository
   - Click on the failed workflow
   - Expand the failed step to see detailed error messages

## 💡 Pro Tips

1. **Use Docker Desktop:** Simplest solution for Windows/macOS users
2. **Install requirements-dev.txt:** Gets all Python tools at once
3. **Use pre-commit hooks:** Catches issues before pushing
4. **Test locally first:** Run `make lint` before creating PRs
5. **Check the Actions summary:** Rich feedback in GitHub Actions results

The linting system is designed to be resilient and provide helpful feedback even when some tools are missing! 🎉