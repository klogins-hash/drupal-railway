# Immediate 403 Forbidden Fix - Action Steps

You're getting 403 Forbidden. Apache is running but Drupal isn't initialized.

## RIGHT NOW - Do These Steps In Order

### Step 1: Check Drupal Service Status (2 min)

1. Open: https://railway.app/dashboard
2. Click your **drupal-railway** project
3. Click the **Drupal** service box
4. Check these status indicators:
   - ✅ Status should be **Green (Running)**
   - ❌ If Red/Yellow → service is broken, restart it

### Step 2: Check What's Actually in the Container (3 min)

1. Still in Drupal service, find a **Terminal** or **SSH** button
2. Click it (or use: `railway ssh --service=<drupal-service-id>`)
3. Run these commands:

```bash
# Check if Drupal files exist
ls -la /var/www/html/

# Count PHP files (there should be many)
find /var/www/html -name "*.php" | wc -l
```

**Expected output:**
- Should see MANY files (drupal, modules, themes, etc.)
- Should see `index.php` in /var/www/html/
- Count of PHP files should be > 50

**If directory is EMPTY or has few files:**
→ Go to **Step 3**

### Step 3: Verify Shared Variables Are Set (5 min)

1. Go back to project canvas
2. Click the **gear/settings icon** (top right area)
3. Find **Variables** section (PROJECT-LEVEL, not service-level)
4. Verify these 6 exist and are filled in:

```
PGHOST = postgres
PGPORT = 5432
PGUSER = postgres
PGPASSWORD = (should have a value)
PGDATABASE = railway
DRUPAL_DRIVER = pgsql
```

**If any are missing:**
- Click **Add Variable**
- Enter name and value
- Click **Save**

### Step 4: Trigger Drupal Redeploy (2 min)

1. Click **Drupal** service
2. Look for **Deployments** tab
3. Look for a **Redeploy** button or similar
4. Click it to force service restart
5. Watch the logs - wait for "Apache successfully started"

### Step 5: Test URL Again (1 min)

```
Visit: https://drupal-railway-production.up.railway.app/
```

You should see:
- **Drupal installation wizard** (if first time)
- OR **Drupal dashboard** (if already set up)
- NOT this 403 error

---

## If Still Getting 403 After Above Steps

Try these in order:

### Option A: Check Apache Document Root

SSH into container and verify:
```bash
# Check where Apache is looking
grep -r "DocumentRoot" /etc/apache2/

# Output should show: /var/www/html (or similar)
# If it shows different path, that's the problem
```

### Option B: Check File Permissions

```bash
# SSH into container
# Verify files are owned by www-data user
ls -la /var/www/html/ | head -5

# Should show: www-data www-data (ownership)
# If not, fix with:
sudo chown -R www-data:www-data /var/www/html/
```

### Option C: Check if Persistent Volume is Mounted

1. Drupal Service → Settings
2. Look for **Volumes** section
3. Check if volume is mounted at `/var/www/html`
4. If NOT mounted:
   - Click **Add Volume**
   - Mount path: `/var/www/html`
   - Size: 5GB
   - Save and redeploy

### Option D: Access Drupal Installation Directly

```
Instead of: https://drupal-railway-production.up.railway.app/

Try: https://drupal-railway-production.up.railway.app/core/install.php
```

This may bypass the 403 and bring up the installer directly.

---

## The Real Issue

The 403 error happens because:

1. **Drupal Docker image runs Apache** ✅
2. **Apache starts successfully** ✅
3. **BUT /var/www/html is empty** ❌

The official Drupal Docker image should have files, but if the persistent volume isn't mounted properly, they might get lost.

**Solution:**
- Ensure persistent volume exists at `/var/www/html`
- Redeploy service
- Files should reappear (or Docker image repopulates them)

---

## Quick Checklist - Do ALL of These

- [ ] Drupal service status is 🟢 Green
- [ ] Shared variables are set at PROJECT level (not service level)
- [ ] `/var/www/html/` has files (not empty)
- [ ] Persistent volume is mounted at `/var/www/html`
- [ ] Apache is running (`ps aux | grep apache`)
- [ ] Owner is www-data (`ls -la /var/www/html/`)
- [ ] Service has been redeployed after setting variables
- [ ] Logs show "Apache successfully started" (no errors)

If ALL above are true and you still get 403:

→ Try accessing: `/core/install.php` directly
→ Or check logs for specific Apache errors

---

## Testing Database Connection

Once you get past 403, Drupal will try to connect to PostgreSQL.

If that fails, run:
```bash
# SSH into Drupal container
bash verify-connectivity.sh
```

This will test the database connection and show exactly what's wrong.

---

## Expected Timeline

- Step 1-2: 2 minutes
- Step 3-4: 5 minutes
- Service restart: 30-60 seconds
- Step 5: Instantly (should see success)

**Total: 10 minutes to fix 403 error**

If not fixed in 10 minutes, likely:
- Shared variables not set correctly
- Persistent volume issue
- Need to look at specific Apache/file permission errors

---

## When You See Success

Instead of "Forbidden", you'll see:

✅ **Drupal installation wizard** (7 steps to complete)
   OR
✅ **Drupal dashboard** (if already installed)

Then you're ready to:
1. Complete installation wizard (choose standard install)
2. Enter database info when prompted (should auto-fill from shared variables)
3. Create admin account
4. Access Drupal at `/admin`

---

## Key Things to Remember

1. **Shared variables go at PROJECT level** (not service level)
2. **Both services must be redeployed** for variables to take effect
3. **Wait 60 seconds after redeploy** for service to fully start
4. **Check logs** for actual error messages (clicking on service → Logs tab)
5. **Verify persistent volume** is mounted (Settings → Volumes)

Run through these steps systematically and you should get past the 403 error within 10 minutes!
