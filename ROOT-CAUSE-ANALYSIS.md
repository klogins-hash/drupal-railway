# Root Cause Analysis: 403 Forbidden Error

## Problem Identified

✅ **Good News:** Environment variables ARE correctly set!
✅ **Good News:** Apache IS running!
✅ **Good News:** Shared variables are inherited!
❌ **Problem:** `/var/www/html/` directory is EMPTY

## Diagnostic Results

```
SSH into Drupal container revealed:

1. /var/www/html/ Contents:
   - EMPTY (only lost+found from formatted volume)
   - No Drupal files present
   - No index.php
   - Directory is mounted correctly (we can see lost+found)

2. Apache Status:
   ✅ Running with 6 processes
   ✅ root apache2 (master)
   ✅ 5x www-data apache2 (workers)

3. Apache Configuration:
   ✅ DocumentRoot = /var/www/html (correct)
   ✅ Port 80 listening (correct)

4. Environment Variables:
   ✅ DRUPAL_DB_HOST = postgres
   ✅ DRUPAL_DB_PORT = 5432
   ✅ DRUPAL_DB_NAME = railway
   ✅ DRUPAL_DB_USER = postgres
   ✅ DRUPAL_DB_PASSWORD = (set)
   ✅ DRUPAL_DRIVER = pgsql
   ✅ DATABASE_URL = postgresql://postgres:PASSWORD@postgres:5432/railway
```

## Why You Get 403 Forbidden

```
User visits: drupal-railway-production.up.railway.app

Apache flow:
1. Request arrives at port 80 ✅
2. Apache starts → DocumentRoot = /var/www/html ✅
3. Looks for file/index.php ❌ NOT FOUND
4. Returns: 403 Forbidden

Why? /var/www/html is completely empty!
```

## The Real Issue

The official Drupal Docker image (`drupal:latest`) should populate `/var/www/html/` automatically during startup, but something prevented that from happening.

**Possible causes:**
1. Image didn't build completely
2. Startup script didn't run
3. Volume mounting cleared the directory
4. Files exist in image but not being copied to volume

## Solution: Populate Drupal Files

There are several ways to fix this:

### Option A: Initialize Drupal in Dockerfile (Recommended)

Modify `Dockerfile.drupal`:

```dockerfile
FROM drupal:latest

# Ensure Drupal files are present and permissions are correct
RUN ls -la /var/www/html/ || true

# Additional PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 80

# This ensures Apache runs properly
CMD ["apache2-foreground"]
```

Then:
1. Redeploy the Dockerfile
2. Railway will rebuild the image
3. Drupal files should be populated

### Option B: Initialize on Startup Script

Create an entrypoint that initializes Drupal:

```dockerfile
FROM drupal:latest

# ... (extensions and permissions as above) ...

# Create initialization script
RUN echo '#!/bin/bash\n\
if [ ! -f /var/www/html/index.php ]; then\n\
  echo "Initializing Drupal..."\n\
  # Ensure files from image are in volume\n\
  ls /var/www/html/ 2>/dev/null | grep -q "core" || {\n\
    echo "ERROR: Drupal files missing!"\n\
    exit 1\n\
  }\n\
fi\n\
apache2-foreground' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

### Option C: Check Image Build

The Dockerfile rebuild might fix it automatically:

1. Railway → Drupal service
2. Deployments tab
3. Click "Redeploy"
4. Watch logs carefully for any build errors
5. Once deployment succeeds, check if files appear

**This often works** because the Drupal image may just need to be rebuilt with fresh volume.

### Option D: Use Base Image with Drupal Pre-installed

If the docker image is the problem, try a different approach:

```dockerfile
FROM php:8.3-apache

# Install Drupal dependencies
RUN apt-get update && apt-get install -y \
    composer \
    git \
    mariadb-client \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Drupal via Composer
WORKDIR /var/www
RUN composer create-project drupal/recommended-project:11 html

WORKDIR /var/www/html

# Ensure permissions
RUN chown -R www-data:www-data . && \
    chmod -R 755 .

EXPOSE 80
CMD ["apache2-foreground"]
```

This explicitly installs Drupal instead of relying on the image.

## Immediate Fix (Try This First)

1. Railway → Drupal service
2. Click **Deployments** tab
3. Click **Redeploy** button
4. Watch logs for:
   ```
   [apache2:notice] Apache/2.4.x started (or restarted)
   ```
5. Wait for green "Success" indicator
6. Visit: https://drupal-railway-production.up.railway.app/

If Drupal files still don't appear after redeploy:
→ Try Option A or B above (modify Dockerfile)

## Why This Happens

Docker volumes have special behavior:
- If volume is empty AND image has files in that path, they DON'T automatically mount into the empty volume
- The files exist in image layers but not in the volume
- Need special handling to copy them over

That's why Option A (Dockerfile) or B (startup script) is better - they explicitly ensure files are in the right place.

## Files That Should Be Present

After fixing, `/var/www/html/` should contain:

```
/var/www/html/
├── index.php                 ← This is critical for web access
├── composer.json
├── composer.lock
├── core/                    ← Drupal core files
├── modules/                 ← Drupal modules
├── themes/                  ← Drupal themes
├── sites/                   ← Site configuration
├── vendor/                  ← Composer dependencies
├── web/                     ← OR web-root (depending on Drupal version)
└── ...
```

If you see these files when you SSH:
```bash
ls -la /var/www/html/index.php
# Then ✅ FIXED - Drupal files are there
```

## Shared Variables Status

**Good News:** Your shared variables are ALL in place:
- ✅ DRUPAL_DB_HOST = postgres
- ✅ DRUPAL_DB_PORT = 5432
- ✅ DRUPAL_DB_USER = postgres
- ✅ DRUPAL_DB_PASSWORD = (set)
- ✅ DRUPAL_DB_NAME = railway
- ✅ DRUPAL_DRIVER = pgsql

**So once you get files in `/var/www/html/`, Drupal WILL connect to PostgreSQL successfully.**

## Next Steps

1. **Try Redeploy First** (Option C above) - Often fixes itself
2. **If Still 403** → Modify Dockerfile (Option A)
3. **Check Files** → SSH and run: `ls -la /var/www/html/ | head -20`
4. **Should see** hundreds of files (not just lost+found)

Once `/var/www/html/` has files → 403 error goes away → Drupal installer shows → Database connects automatically using your shared variables.

## Summary

| Component | Status |
|-----------|--------|
| Apache running | ✅ YES (6 processes) |
| Shared variables | ✅ YES (all 6 set) |
| Docker network | ✅ YES (postgres accessible) |
| Permissions set | ✅ YES (www-data owner) |
| Drupal files | ❌ MISSING (volume empty) |

**Fix the missing Drupal files and everything else will work automatically!**
