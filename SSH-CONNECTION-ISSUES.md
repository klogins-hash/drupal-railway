# SSH Connection Issues - Diagnostics

If you can't SSH into the Drupal service, it usually means the service isn't running properly.

## Error: "Device not configured" (os error 6)

This means the Drupal service either:
- ❌ Isn't running (status not green)
- ❌ Isn't accepting SSH connections
- ❌ Just restarted and isn't ready yet

## What To Do Instead

### Option 1: Check Service Status in Dashboard (Fastest)

1. Go to: https://railway.app/dashboard
2. Click **drupal-railway** project
3. Look at **Drupal service** box
4. Check the STATUS indicator:
   - 🟢 **Green** = Running (SSH should work)
   - 🟡 **Yellow** = Starting (wait 30 seconds, then retry)
   - 🔴 **Red** = Failed (need to restart or check logs)

**If Green:** Wait 60 seconds and try SSH again

**If Yellow:** Wait 2 minutes, then try

**If Red:** Click the service and check Logs tab for errors

### Option 2: Check Logs Without SSH

Since SSH isn't working, check logs directly:

1. Railway Dashboard → **Drupal** service
2. Click **Logs** tab (right side)
3. Scroll through and look for:
   ```
   ✅ Good signs:
   - "Apache successfully started"
   - "Listening on port 80"
   - No ERROR messages

   ❌ Bad signs:
   - "ERROR" anywhere in logs
   - "Connection refused"
   - "Permission denied"
   - Apache didn't start
   ```

### Option 3: Check if Shared Variables Are Applied

1. Railway Dashboard → **drupal-railway** project
2. Click the **gear/settings icon**
3. Find **Variables** (project-level)
4. Verify these exist:
   - PGHOST
   - PGPORT
   - PGUSER
   - PGPASSWORD
   - PGDATABASE
   - DRUPAL_DRIVER

**If any are missing:** Add them immediately

### Option 4: Force Service Restart

Sometimes the service just needs a kick:

1. Railway → **Drupal** service
2. Look for **Settings** or **Configure**
3. Look for **Restart** button
4. Click it
5. Wait 60 seconds
6. Try again

### Option 5: Redeploy Service

This rebuilds the entire service:

1. Railway → **Drupal** service
2. Click **Deployments** tab
3. Look for **Redeploy** button
4. Click it
5. Wait for deployment to complete (logs will show progress)
6. Once "Success" appears, service is ready
7. Try SSH again (or test URL)

---

## Why SSH Fails

| Reason | Solution |
|--------|----------|
| Service is Red (failed) | Restart or redeploy |
| Service is Yellow (starting) | Wait 2 minutes |
| Service just redeployed | Wait 60 seconds |
| SSH not enabled | Try redeploy |
| Service logs show errors | Fix the errors (see Logs) |

---

## What To Do Without SSH Access

Don't worry - you don't NEED SSH to fix the 403 error. Here's what to do:

### Step 1: Check Logs (You can do this!)

1. Railway → Drupal service → **Logs** tab
2. Look for Apache errors
3. Look for permission errors
4. Look for missing files

### Step 2: Check Shared Variables (You can do this!)

1. Railway → Project settings
2. **Variables** section
3. Verify all 6 are set
4. If missing, add them

### Step 3: Trigger Redeploy (You can do this!)

1. Railway → Drupal service
2. **Deployments** tab
3. **Redeploy** button
4. Wait for green success

### Step 4: Test URL (You can do this!)

```
https://drupal-railway-production.up.railway.app/
```

If you see Drupal installer instead of 403 → YOU FIXED IT!

---

## Service Status Meanings

### 🟢 Green = Running
- Service is up and healthy
- Should be able to SSH
- Should respond to web requests
- Can take 30-120 seconds to reach this state

### 🟡 Yellow = Starting/Deploying
- Service is starting or redeploying
- Don't try to SSH yet
- Wait 2-3 minutes
- Then check again

### 🔴 Red = Failed
- Service crashed or failed to start
- SSH will definitely fail
- Check **Logs** tab for error messages
- Common fixes:
  - Out of memory (upgrade plan)
  - Environment variable missing
  - Port conflict
  - Database connection failed
  - Application crash

### ⚫ Gray = Not Deployed Yet
- Service hasn't been deployed
- Click **Redeploy** to start it
- Wait for status to turn green

---

## Complete Troubleshooting Without SSH

### 1. Check Status
```
Railway → Drupal → Status Indicator = Green?
If No → Restart/Redeploy first
If Yes → Go to Step 2
```

### 2. Check Logs for Errors
```
Railway → Drupal → Logs tab
Look for: ERROR, failed, refused, denied, permission
If found → These are the issues to fix
If not → Go to Step 3
```

### 3. Verify Shared Variables
```
Railway → Project → Variables
Have all 6 PostgreSQL vars?
Have DRUPAL_DRIVER set?
If missing → Add them → Go to Step 4
If present → Go to Step 4
```

### 4. Redeploy Service
```
Railway → Drupal → Deployments
Find Redeploy button → Click
Wait for green "Success"
Go to Step 5
```

### 5. Test URL in Browser
```
Visit: https://drupal-railway-production.up.railway.app/
See Drupal installer instead of 403?
YES → ✅ FIXED!
NO → Go back to Step 2 and check logs more carefully
```

---

## Why This Happens

When you SSH into a production container, the container needs to:
1. Be fully running and healthy
2. Have sshd service running
3. Have SSH keys configured
4. Not be in a crash loop

If any of these is false, SSH fails.

**But you don't need SSH!** You can fix everything from the Railway dashboard using:
- Logs tab (diagnose issues)
- Variables section (configure)
- Redeploy button (restart)

---

## The 403 Error (Not SSH Related)

The 403 error you're seeing is **separate from SSH issues**.

**403 means:**
- Apache is running ✅
- But Drupal files aren't there ❌

**Fixes:**
- Add shared variables → Redeploy → Try again
- Check persistent volume → Make sure it's mounted
- Check logs → Look for volume mount errors

**This doesn't require SSH.** You can fix it entirely from dashboard.

---

## Recommended Action Now

1. **Don't try SSH again yet** - Service may not be ready
2. **Go to Railway Dashboard**
3. **Check Logs** - See what's happening
4. **Check/Add Shared Variables**
5. **Click Redeploy**
6. **Wait 60-90 seconds**
7. **Try the URL again**

If still 403 → Logs will tell you why.

SSH will work once service is healthy, but you don't need it to fix 403 error.
