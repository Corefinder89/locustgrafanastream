# GitHub Actions CI/CD Pipeline

This document describes the GitHub Actions workflows configured for this project to ensure code quality, security, and automated maintenance.

## 📋 Overview

The project includes several automated workflows that run on different triggers:

1. **Code Quality Checks** - Runs on every PR and push to main
2. **Security & Dependency Checks** - Runs daily and on dependency changes
3. **Automated Dependency Updates** - Runs weekly to keep dependencies up-to-date

## 🔄 Workflows

### 1. Code Quality Checks (`.github/workflows/lint.yml`)

**Triggers:** Pull requests and pushes to `main`/`master` branch

**Jobs:**
- **Lint Job**: Runs across Python 3.8-3.11 matrix
  - Black code formatting check
  - isort import sorting check
  - flake8 linting
  - mypy type checking
  - bandit security linting
  - YAML linting with yamllint
  - JSON validation with jsonlint
  - Markdown linting with markdownlint

- **Pre-commit Job**: Runs all pre-commit hooks
- **Security Job**: Trivy vulnerability scanning
- **Docker Lint Job**: Docker Compose validation and hadolint (if Dockerfile exists)
- **Quality Gate**: Final check that ensures all critical jobs passed

**Features:**
- Matrix testing across multiple Python versions
- Caching for faster builds
- Automatic PR comments on failures
- Security report uploads
- Artifact uploads for bandit reports

### 2. Security & Dependency Checks (`.github/workflows/security.yml`)

**Triggers:** 
- Daily at 2 AM UTC
- Changes to `requirements-dev.txt` or `docker-compose.yml`
- Pull requests affecting security-related files

**Jobs:**
- **Dependency Security Scan**: safety and pip-audit checks
- **Docker Security Scan**: Trivy scanning of Docker configurations
- **CodeQL Analysis**: GitHub's semantic code analysis

**Features:**
- Automated security vulnerability detection
- SARIF report uploads to GitHub Security tab
- Daily monitoring of new vulnerabilities

### 3. Automated Dependency Updates (`.github/workflows/update-deps.yml`)

**Triggers:** 
- Weekly on Mondays at 8 AM UTC
- Manual trigger via workflow_dispatch

**Jobs:**
- **Update Python Dependencies**: Uses pip-tools to update Python packages
- **Update GitHub Actions**: Updates action versions in workflows

**Features:**
- Automatic PR creation for dependency updates
- Proper commit messages and PR descriptions
- Branch cleanup after merge

### 4. Dependabot Configuration (`.github/dependabot.yml`)

**Automated Updates:**
- **Python dependencies**: Weekly on Mondays at 8 AM
- **GitHub Actions**: Weekly on Mondays at 9 AM  
- **Docker images**: Weekly on Tuesdays at 8 AM

**Features:**
- Proper labeling and assignment
- Ignores major version updates for stability
- Limits concurrent PRs to avoid spam

## 🚀 Setup Instructions

### 1. Enable GitHub Actions
1. Push the `.github/workflows/` directory to your repository
2. GitHub Actions will automatically start running on the next PR or push

### 2. Configure Branch Protection
Go to your repository settings and set up branch protection rules:

```
Settings → Branches → Add rule
```

Recommended settings for `main` branch:
- ✅ Require a pull request before merging
- ✅ Require approvals (1)
- ✅ Dismiss stale PR approvals when new commits are pushed
- ✅ Require status checks to pass before merging
  - ✅ Code Quality & Linting
  - ✅ Pre-commit Hooks
  - ✅ Quality Gate
- ✅ Require branches to be up to date before merging
- ✅ Require linear history
- ✅ Include administrators

### 3. Configure Dependabot
1. Update the `@me` references in `.github/dependabot.yml` with your GitHub username
2. Dependabot will start creating PRs automatically

### 4. Security Configuration
1. Enable GitHub Security features:
   - Go to Settings → Security & analysis
   - Enable dependency graph
   - Enable Dependabot alerts
   - Enable Dependabot security updates
   - Enable Code scanning

## 📊 Quality Gates

The pipeline enforces these quality standards:

### Python Code
- ✅ Black formatting (88 char line length)
- ✅ isort import sorting
- ✅ flake8 linting (PEP 8 compliance)
- ✅ mypy type checking
- ✅ bandit security scanning

### YAML Files
- ✅ yamllint validation
- ✅ Syntax correctness

### JSON Files
- ✅ jsonlint validation
- ✅ Syntax correctness

### Markdown Files
- ✅ markdownlint validation
- ✅ Consistent formatting

### Docker
- ✅ docker-compose validation
- ✅ hadolint Dockerfile linting (if present)

### Security
- ✅ Dependency vulnerability scanning
- ✅ CodeQL semantic analysis
- ✅ Trivy configuration scanning

## 💡 Usage Tips

### Running Checks Locally
Before pushing, run these commands locally:

```bash
# Run all linters
make lint

# Format code
make format

# Run pre-commit hooks
pre-commit run --all-files
```

### Handling Failed Checks
If CI fails:

1. **Check the Actions tab** for detailed error messages
2. **Run checks locally** using the Makefile commands
3. **Fix issues** and push again
4. **Request review** once all checks pass

### Skipping Checks (Emergency Only)
In rare cases, you can skip specific checks by adding to commit messages:
- `[skip ci]` - Skip all CI checks
- `[no-verify]` - Skip pre-commit hooks locally

⚠️ **Use sparingly and only for emergencies**

## 🔧 Customization

### Adding New Linters
1. Update `requirements-dev.txt` with new Python linters
2. Add linter commands to `.github/workflows/lint.yml`
3. Update `Makefile` with new lint targets
4. Add configuration files as needed

### Changing Python Versions
Update the matrix in `.github/workflows/lint.yml`:

```yaml
strategy:
  matrix:
    python-version: [3.8, 3.9, '3.10', '3.11', '3.12']
```

### Modifying Security Scans
- Add new security tools to `.github/workflows/security.yml`
- Configure additional Trivy scan types
- Add custom bandit rules in `.bandit`

## 📈 Monitoring

### GitHub Security Tab
- View vulnerability alerts
- Monitor dependency updates
- Review security scan results

### Actions Tab
- Monitor workflow runs
- Download artifacts (security reports)
- Review performance metrics

### Pull Requests
- Automatic status checks
- Security scan results
- Code quality feedback

This comprehensive CI/CD setup ensures high code quality, security, and maintainability for your load testing infrastructure project! 🚀