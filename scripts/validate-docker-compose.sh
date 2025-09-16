#!/bin/bash

# Docker Compose validation script
# Validates docker-compose.yml for best practices and security

set -e

COMPOSE_FILE="docker-compose.yml"
EXIT_CODE=0

echo "🔍 Docker Compose Validation Script"
echo "===================================="

# Check if docker-compose.yml exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Error: $COMPOSE_FILE not found"
    exit 1
fi

echo "📋 Validating: $COMPOSE_FILE"
echo

# Test 1: Validate syntax
echo "🔍 Test 1: Validating YAML syntax..."

# Try different docker-compose commands
if command -v docker-compose > /dev/null 2>&1; then
    if docker-compose config -q; then
        echo "✅ YAML syntax is valid (docker-compose)"
    else
        echo "❌ YAML syntax error"
        EXIT_CODE=1
    fi
elif command -v docker > /dev/null 2>&1 && docker compose version > /dev/null 2>&1; then
    if docker compose config -q; then
        echo "✅ YAML syntax is valid (docker compose)"
    else
        echo "❌ YAML syntax error"
        EXIT_CODE=1
    fi
else
    echo "⚠️ docker-compose not available, using basic YAML validation"
    if python3 -c "import yaml; yaml.safe_load(open('$COMPOSE_FILE'))" 2>/dev/null; then
        echo "✅ Basic YAML syntax is valid"
    elif python -c "import yaml; yaml.safe_load(open('$COMPOSE_FILE'))" 2>/dev/null; then
        echo "✅ Basic YAML syntax is valid"
    else
        echo "❌ YAML syntax error"
        EXIT_CODE=1
    fi
fi
echo

# Test 2: Check for security best practices
echo "🔍 Test 2: Checking security best practices..."

# Check for read-only containers
if grep -q "read_only: true" "$COMPOSE_FILE"; then
    echo "✅ Found read-only containers"
else
    echo "⚠️  Warning: No read-only containers found"
fi

# Check for restart policies
if grep -q "restart:" "$COMPOSE_FILE"; then
    echo "✅ Restart policies configured"
else
    echo "⚠️  Warning: No restart policies found"
fi

# Check for custom networks
if grep -q "networks:" "$COMPOSE_FILE"; then
    echo "✅ Custom networks configured"
else
    echo "⚠️  Warning: Using default network"
fi

# Check for latest tags
if grep -q ":latest" "$COMPOSE_FILE"; then
    echo "⚠️  Warning: Found ':latest' tags"
    grep -n ":latest" "$COMPOSE_FILE"
else
    echo "✅ No ':latest' tags found"
fi
echo

# Test 3: Check exposed ports
echo "🔍 Test 3: Checking exposed ports..."
EXPOSED_PORTS=$(grep -E "^\s*-\s*\"[0-9]+:[0-9]+\"" "$COMPOSE_FILE" | wc -l)
echo "Found $EXPOSED_PORTS exposed port mappings"

# Check for dangerous ports
if grep -q "22:22" "$COMPOSE_FILE"; then
    echo "🚨 WARNING: SSH port 22 exposed!"
    EXIT_CODE=1
fi

if grep -q "3389:3389" "$COMPOSE_FILE"; then
    echo "🚨 WARNING: RDP port 3389 exposed!"
    EXIT_CODE=1
fi
echo

# Test 4: Check for hardcoded secrets
echo "🔍 Test 4: Checking for potential hardcoded secrets..."
if grep -iE "(password|secret|key|token).*=.*[^$\{]" "$COMPOSE_FILE"; then
    echo "🚨 WARNING: Potential hardcoded secrets found!"
    EXIT_CODE=1
else
    echo "✅ No hardcoded secrets detected"
fi
echo

# Test 5: Check for volume security
echo "🔍 Test 5: Checking volume mount security..."
if grep -q ":/.*:ro" "$COMPOSE_FILE"; then
    echo "✅ Found read-only volume mounts"
else
    echo "⚠️  Warning: No read-only volume mounts found"
fi

if grep -q ":/etc:" "$COMPOSE_FILE" || grep -q ":/root:" "$COMPOSE_FILE"; then
    echo "🚨 WARNING: Sensitive directory mounts found!"
    EXIT_CODE=1
fi
echo

# Summary
echo "📊 Validation Summary"
echo "===================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "🎉 All critical checks passed!"
else
    echo "❌ Some critical issues found. Please review the warnings above."
fi

exit $EXIT_CODE