# Fixing "403 Forbidden" Error in Drupal on Railway

You're getting a 403 Forbidden error from Apache. This is actually a good sign - the service is running! But Drupal isn't initialized yet.

## Why This Happens

The official Drupal Docker image runs Apache, but doesn't automatically set up Drupal. You need to:
1. Either run the installation wizard
2. Or create the proper Drupal directory structure

## Solution 1: Fix Service Settings (Quick)

The issue might be that the Drupal container doesn't have the proper setup. Let's help it initialize correctly.

### Check Docker Logs

1. Go to Railway dashboard → Drupal service
2. Click **Logs** tab
3. Look for any errors about:
   - `/var/www/html` permissions
   - Missing `index.php`
   - Missing configuration files

### Add Environment Variable to Auto-Initialize

1. Drupal service → **Variables** tab
2. Add this variable:
   ```
   DRUPAL_SETUP=true
   ```

3. Or add this to trigger setup:
   ```
   DRUPAL_SITE_CONFIG=standard
   ```

4. **Redeploy** the service

Wait 2-3 minutes for the container to fully initialize.

Visit the URL again - you should either see:
- Drupal installation wizard, OR
- Drupal welcome page (if already installed)

---

## Solution 2: SSH In and Check Directory

If the above doesn't work, SSH into the container to diagnose:

```bash
railway ssh --project=<PROJECT_ID> --service=<DRUPAL_SERVICE_ID>
```

Inside the container, run:

```bash
# Check if web root exists
ls -la /var/www/html/

# Check if index.php exists
ls -la /var/www/html/index.php

# Check Apache document root
grep -i "DocumentRoot" /etc/apache2/sites-enabled/*.conf
```

Expected output:
```
total 150
drwxr-xr-x  11 www-data www-data  4096 ...
-rw-r--r--   1 www-data www-data  1234 ... index.php
-rw-r--r--   1 www-data www-data  ...  ... other-drupal-files
```

---

## Solution 3: Force Drupal Installation

If files are missing, reinitialize:

1. SSH into the Drupal container
2. Run:
   ```bash
   # Check what's in the web root
   ls /var/www/html/

   # If mostly empty, Drupal needs setup
   # The official image should have files, if not:
   docker pull drupal:latest  # Update the image
   ```

3. In Railway, trigger a redeploy of the Drupal service:
   - Drupal Service → Deployments tab
   - Look for "Redeploy" or "Deploy" button
   - Click to redeploy with the latest Drupal image

---

## Solution 4: Check Persistent Volume

The issue might be that the persistent volume isn't properly mounted.

1. Drupal Service → **Settings** tab (might be called "Integration" or "Configuration")
2. Look for **Volumes** section
3. Verify volume is mounted at **`/var/www/html`**
4. Size should be reasonable (e.g., 5GB)

If volume isn't mounted:
1. Add a new volume
2. Mount path: `/var/www/html`
3. Size: 5GB
4. Save and redeploy

---

## Solution 5: Access Installation Wizard Directly

Once the service is running (logs show "Apache started"), access Drupal setup:

### Check these URLs:

1. **Main installation page:**
   ```
   https://drupal-railway-production.up.railway.app/
   ```

2. **Install script directly:**
   ```
   https://drupal-railway-production.up.railway.app/core/install.php
   ```

3. **Admin interface:**
   ```
   https://drupal-railway-production.up.railway.app/user/login
   ```

One of these should show the Drupal installation wizard or login page.

---

## Checking Service Health

### In Railway Dashboard:

1. Select Drupal service
2. Look at **Status indicator** (top-right)
   - 🟢 Green = Running (good)
   - 🟡 Yellow = Starting
   - 🔴 Red = Failed

3. Check **Logs** for errors:
   - Apache error messages
   - Permission denied
   - Missing files

4. Check **Health** metrics:
   - Is container actually receiving requests?
   - Is memory usage normal?

---

## If Still Seeing 403

The 403 Forbidden specifically means:

1. **Apache is serving** ✅
2. **But the document doesn't exist** or **permissions are wrong** ❌

### Fix #1: Verify Directory Structure

```bash
# SSH in and check
ls -la /var/www/html/web/
# OR
ls -la /var/www/html/public/
# OR
ls -la /var/www/html/
```

Drupal might be in a subdirectory like `/var/www/html/web/` instead of root.

### Fix #2: Check Apache Configuration

```bash
# SSH in and check where Apache looks
grep -r "DocumentRoot" /etc/apache2/
grep -r "directory" /etc/apache2/sites-enabled/
```

If Apache DocumentRoot doesn't match where Drupal actually is, that's the issue.

### Fix #3: Check File Permissions

```bash
# SSH in
# Check ownership
ls -la /var/www/html/
# Should show www-data:www-data ownership

# If wrong, fix with:
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/
```

---

## Complete Troubleshooting Checklist

- [ ] Service Status is 🟢 Green (Running)
- [ ] Check Logs tab for error messages
- [ ] SSH in and verify `/var/www/html/` isn't empty
- [ ] Verify persistent volume is mounted
- [ ] Check file permissions (www-data owner)
- [ ] Check Apache DocumentRoot configuration
- [ ] Try accessing `/core/install.php` directly
- [ ] Verify environment variables are set (DRUPAL_DB_*)

---

## What Success Looks Like

Once everything is working, you'll see:

✅ **HTTP 200** status (not 403)
✅ **Drupal installation wizard** loads
✅ **Database connection** works (thanks to our DRUPAL_DB_* variables)
✅ **Admin account creation** page appears
✅ **Drupal dashboard** accessible after setup

---

## Need More Help?

1. **Check complete logs:**
   - SSH in: `tail -f /var/log/apache2/error.log`
   - Or in Railway: Logs tab with scrolling

2. **Verify database is actually connected:**
   - Run: `bash verify-connectivity.sh` (in Drupal container)
   - Should pass all checks before Drupal can initialize

3. **Check if Drupal files exist:**
   ```bash
   # SSH in and check
   find /var/www/html -name "*.php" | head -5
   # Should show PHP files if Drupal is there
   ```

4. **Restart the service:**
   - Drupal Service → Settings/Configure
   - Look for "Restart" option
   - Click to restart

---

## Railway-Specific Tips

### Force a Fresh Deployment

1. Drupal Service → Settings
2. Click "Redeploy" or similar
3. Railway will pull fresh image and restart
4. Wait for logs to show "Apache successfully started"

### Check Service Connectivity

1. SSH into Drupal: `railway ssh --service=<drupal-id>`
2. Test database: `bash verify-connectivity.sh`
3. All tests should pass before Drupal can work

### View Real-Time Logs

```bash
# Get service ID
railway status  # If linked

# Or in dashboard, copy the service ID from URL
# Then stream logs:
railway logs --tail=100 <service-id>
```

---

## Final Deployment Checklist

Before Drupal shows properly:

- [ ] PostgreSQL service is **Running** (green)
- [ ] Drupal service is **Running** (green)
- [ ] All 6 DRUPAL_DB_* environment variables set
- [ ] Persistent volume at `/var/www/html` exists and is mounted
- [ ] Latest deployment is **Success** (green)
- [ ] Logs show "Apache successfully started"
- [ ] `verify-connectivity.sh` passes all checks
- [ ] Drupal files exist in `/var/www/html/` (run: `ls /var/www/html/`)

Once all above are true, visiting the service URL should show Drupal installation wizard instead of 403 error.
