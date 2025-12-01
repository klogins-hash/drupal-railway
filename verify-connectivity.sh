#!/bin/bash

####################################
# Railway Drupal + PostgreSQL Verification Script
# This script verifies that Drupal and PostgreSQL services can communicate
# Run this inside the Drupal container via: railway ssh <service-id>
####################################

set -e

echo "🔍 Railway Drupal-PostgreSQL Connectivity Verification"
echo "======================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're inside a Railway container
if [ ! -f "/.railway/metadata.json" ]; then
    echo -e "${YELLOW}⚠️  Warning: This script is designed to run inside a Railway container${NC}"
    echo "Run with: railway ssh --project=<id> --environment=<id> --service=<id>"
    echo ""
fi

# 1. Check environment variables
echo -e "${BLUE}1. Checking Environment Variables${NC}"
echo "-----------------------------------"

if [ -z "$DRUPAL_DB_HOST" ]; then
    echo -e "${RED}❌ DRUPAL_DB_HOST not set${NC}"
    exit 1
else
    echo -e "${GREEN}✓ DRUPAL_DB_HOST=$DRUPAL_DB_HOST${NC}"
fi

if [ -z "$DRUPAL_DB_PORT" ]; then
    echo -e "${RED}❌ DRUPAL_DB_PORT not set${NC}"
    exit 1
else
    echo -e "${GREEN}✓ DRUPAL_DB_PORT=$DRUPAL_DB_PORT${NC}"
fi

if [ -z "$DRUPAL_DB_NAME" ]; then
    echo -e "${RED}❌ DRUPAL_DB_NAME not set${NC}"
    exit 1
else
    echo -e "${GREEN}✓ DRUPAL_DB_NAME=$DRUPAL_DB_NAME${NC}"
fi

if [ -z "$DRUPAL_DB_USER" ]; then
    echo -e "${RED}❌ DRUPAL_DB_USER not set${NC}"
    exit 1
else
    echo -e "${GREEN}✓ DRUPAL_DB_USER=$DRUPAL_DB_USER${NC}"
fi

if [ -z "$DRUPAL_DB_PASSWORD" ]; then
    echo -e "${RED}❌ DRUPAL_DB_PASSWORD not set${NC}"
    exit 1
else
    echo -e "${GREEN}✓ DRUPAL_DB_PASSWORD is set${NC}"
fi

if [ -z "$DRUPAL_DRIVER" ]; then
    echo -e "${YELLOW}⚠️  DRUPAL_DRIVER not set (defaulting to mysql)${NC}"
else
    echo -e "${GREEN}✓ DRUPAL_DRIVER=$DRUPAL_DRIVER${NC}"
fi

echo ""

# 2. Test DNS resolution
echo -e "${BLUE}2. Testing DNS Resolution${NC}"
echo "-------------------------"

if command -v nslookup &> /dev/null; then
    if nslookup $DRUPAL_DB_HOST > /dev/null 2>&1; then
        echo -e "${GREEN}✓ DNS resolves $DRUPAL_DB_HOST${NC}"
        nslookup $DRUPAL_DB_HOST | grep -E "Address|name"
    else
        echo -e "${RED}❌ Cannot resolve $DRUPAL_DB_HOST${NC}"
        echo "   This usually means the PostgreSQL service is not linked or has a different name"
        exit 1
    fi
elif command -v dig &> /dev/null; then
    if dig $DRUPAL_DB_HOST +short | grep -q .; then
        echo -e "${GREEN}✓ DNS resolves $DRUPAL_DB_HOST${NC}"
        dig $DRUPAL_DB_HOST +short
    else
        echo -e "${RED}❌ Cannot resolve $DRUPAL_DB_HOST${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  DNS tools not available (nslookup/dig)${NC}"
fi

echo ""

# 3. Test network connectivity
echo -e "${BLUE}3. Testing Network Connectivity${NC}"
echo "-------------------------------"

if command -v nc &> /dev/null; then
    if nc -z -w 5 $DRUPAL_DB_HOST $DRUPAL_DB_PORT 2>/dev/null; then
        echo -e "${GREEN}✓ TCP connection succeeds to $DRUPAL_DB_HOST:$DRUPAL_DB_PORT${NC}"
    else
        echo -e "${RED}❌ Cannot connect to $DRUPAL_DB_HOST:$DRUPAL_DB_PORT${NC}"
        echo "   Check that PostgreSQL service is running and healthy"
        exit 1
    fi
elif command -v timeout &> /dev/null; then
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$DRUPAL_DB_HOST/$DRUPAL_DB_PORT" 2>/dev/null; then
        echo -e "${GREEN}✓ TCP connection succeeds to $DRUPAL_DB_HOST:$DRUPAL_DB_PORT${NC}"
    else
        echo -e "${RED}❌ Cannot connect to $DRUPAL_DB_HOST:$DRUPAL_DB_PORT${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Network connectivity tools not available${NC}"
fi

echo ""

# 4. Test PostgreSQL connection
echo -e "${BLUE}4. Testing PostgreSQL Connection${NC}"
echo "--------------------------------"

# First, try to install postgresql-client if not present
if ! command -v psql &> /dev/null; then
    echo "Installing postgresql-client..."
    apt-get update > /dev/null 2>&1
    apt-get install -y postgresql-client > /dev/null 2>&1
fi

if command -v psql &> /dev/null; then
    # Test with pg_isready first (faster)
    if command -v pg_isready &> /dev/null; then
        echo "Running pg_isready..."
        if PGPASSWORD="$DRUPAL_DB_PASSWORD" pg_isready \
            -h $DRUPAL_DB_HOST \
            -p $DRUPAL_DB_PORT \
            -U $DRUPAL_DB_USER \
            -d $DRUPAL_DB_NAME 2>/dev/null; then
            echo -e "${GREEN}✓ PostgreSQL is accepting connections${NC}"
        else
            echo -e "${RED}❌ PostgreSQL is not accepting connections${NC}"
            echo "   Check PostgreSQL is running and credentials are correct"
            exit 1
        fi
    fi

    # Test actual database connection
    echo "Testing database query..."
    if PGPASSWORD="$DRUPAL_DB_PASSWORD" psql \
        -h $DRUPAL_DB_HOST \
        -p $DRUPAL_DB_PORT \
        -U $DRUPAL_DB_USER \
        -d $DRUPAL_DB_NAME \
        -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Can execute queries on PostgreSQL${NC}"
    else
        echo -e "${RED}❌ Cannot execute queries on PostgreSQL${NC}"
        echo "   Check database credentials and database exists"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  psql not available, skipping PostgreSQL connection test${NC}"
fi

echo ""

# 5. Summary
echo -e "${BLUE}5. Summary${NC}"
echo "----------"
echo -e "${GREEN}✅ All connectivity checks passed!${NC}"
echo ""
echo "Service-to-service configuration:"
echo "  Drupal Service  → $DRUPAL_DB_HOST:$DRUPAL_DB_PORT"
echo "  Database        → $DRUPAL_DB_NAME"
echo "  Driver          → $DRUPAL_DRIVER"
echo ""
echo "Next steps:"
echo "  1. Verify Drupal installation is complete"
echo "  2. Check Drupal admin panel at /admin"
echo "  3. Review settings: /admin/config/system/site-information"
echo ""
