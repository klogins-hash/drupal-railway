# Railway Dashboard Setup - Step-by-Step for Service Linking

This guide walks through the exact steps in the Railway dashboard to link Drupal and PostgreSQL services.

## Problem
Services exist but show NO connection to each other in the Railway UI.

## Solution
Add environment variables to the Drupal service that reference PostgreSQL variables.

---

## Step 1: Go to Railway Dashboard

1. Open https://railway.app/dashboard
2. Find your `drupal-railway` project
3. Click to open it

---

## Step 2: Navigate to Drupal Service Settings

1. In the project canvas, you should see 2 services:
   - **Drupal** (or similar name)
   - **Postgres** (or similar name)

2. Click on the **Drupal** service (or the Node/App service running your code)

3. Look for tabs at the top - find the **"Variables"** tab
   - You may see: Overview | Deployments | Logs | **Variables** | Settings | etc.

4. Click on **Variables** tab

---

## Step 3: Add Environment Variables for PostgreSQL

In the Variables tab, you should see an "Add Variable" button or a table of existing variables.

### Add These Variables (One by One)

Click "Add Variable" or the "+" button and enter:

#### Variable 1: Database Host
- **Name:** `DRUPAL_DB_HOST`
- **Value:** `${{Postgres.PGHOST}}`
- Click Save/Add

#### Variable 2: Database Port
- **Name:** `DRUPAL_DB_PORT`
- **Value:** `${{Postgres.PGPORT}}`
- Click Save/Add

#### Variable 3: Database Name
- **Name:** `DRUPAL_DB_NAME`
- **Value:** `${{Postgres.PGDATABASE}}`
- Click Save/Add

#### Variable 4: Database User
- **Name:** `DRUPAL_DB_USER`
- **Value:** `${{Postgres.PGUSER}}`
- Click Save/Add

#### Variable 5: Database Password
- **Name:** `DRUPAL_DB_PASSWORD`
- **Value:** `${{Postgres.PGPASSWORD}}`
- Click Save/Add

#### Variable 6: Database Driver
- **Name:** `DRUPAL_DRIVER`
- **Value:** `pgsql`
- Click Save/Add

---

## Step 4: Verify PostgreSQL Service Name

**Important:** The service name `Postgres` must match your actual PostgreSQL service name.

To check:
1. Click on the **PostgreSQL service** in the canvas
2. Look at the top - what is it called?
   - Default names: `postgres`, `Postgres`, `PostgreSQL`, or something custom
3. If it's different, use that name in the variables above

**Example:** If your PostgreSQL service is called `postgres-db`, use:
- `${{postgres-db.PGHOST}}`
- `${{postgres-db.PGPORT}}`
- etc.

---

## Step 5: Trigger Deployment

After adding all variables, you need to deploy for them to take effect.

### Option A: Automatic (GitHub Push)
1. Push changes to GitHub
2. Railway automatically redeploys

### Option B: Manual Redeploy
1. In Railway dashboard, go to Drupal service
2. Look for a "Redeploy" or "Deploy" button
3. Click it
4. Wait for deployment to complete (watch the Deployments tab)

---

## Step 6: Verify Services Are Linked

After deployment completes:

1. Go back to your project canvas view
2. Look between the Drupal and PostgreSQL services
3. You should now see a **line/arrow connecting them**
4. The connection shows the services are linked

If there's still no connection line:
- Check if all variables were saved (refresh the page)
- Verify variable values are using `${{ServiceName.VARIABLE}}` syntax
- Check PostgreSQL service name matches your variable references
- Try manually triggering a redeploy

---

## Step 7: Verify Connection Works

Once services show as connected:

1. Check **Drupal service Logs**
   - Go to Drupal service → Logs tab
   - Look for messages about database connection
   - Should NOT see "Cannot connect to postgres" errors

2. (Optional) SSH into Drupal and run verification
   ```bash
   railway ssh --project=<project-id> --service=<drupal-service-id>
   bash verify-connectivity.sh
   ```

---

## Troubleshooting

### Services Still Not Connected

**Check #1: Variable Syntax**
- Make sure you're using `${{ServiceName.VARIABLE}}` format
- NOT `$ServiceName.VARIABLE` or `${ServiceName.VARIABLE}`
- NOT literal text like "postgres" or "localhost"

**Check #2: PostgreSQL Service Name**
```
Look at your PostgreSQL service in the canvas.
What does it say at the top?
That's the name to use in the variables.

If it says "postgres" → use ${{postgres.PGHOST}}
If it says "Postgres" → use ${{Postgres.PGHOST}}
If it says "db-service" → use ${{db-service.PGHOST}}
```

**Check #3: All 6 Variables Present**
```
DRUPAL_DB_HOST
DRUPAL_DB_PORT
DRUPAL_DB_NAME
DRUPAL_DB_USER
DRUPAL_DB_PASSWORD
DRUPAL_DRIVER

All 6 must be there. Check the Variables tab carefully.
```

**Check #4: Deployment Completed**
- Go to Deployments tab
- Make sure the latest deployment says "Success" (green)
- If it says "Failed" or "Running", wait for it to complete

**Check #5: PostgreSQL Service Healthy**
- Click on PostgreSQL service
- Check status indicator - should be green "Running"
- If red or yellow, wait or restart it

### Still Having Issues?

1. Try **restarting** the PostgreSQL service:
   - Click PostgreSQL service
   - Look for a restart/settings option
   - Restart the service

2. Try **restarting** the Drupal service:
   - Click Drupal service
   - Look for a restart/settings option
   - Restart the service

3. Check the **full Drupal logs** for database errors:
   - Drupal service → Logs tab
   - Scroll through for error messages
   - Look for "Connection refused" or "Authentication failed"

---

## What Connected Services Look Like

When properly connected in Railway:

```
Canvas View:
┌──────────────┐              ┌──────────────┐
│   Drupal     │──────────→   │  PostgreSQL  │
│   (Running)  │  ←──────────│  (Running)   │
└──────────────┘              └──────────────┘

Variables Tab (Drupal service):
DRUPAL_DB_HOST      ${{Postgres.PGHOST}}      (resolved)
DRUPAL_DB_PORT      ${{Postgres.PGPORT}}      (resolved)
DRUPAL_DB_NAME      ${{Postgres.PGDATABASE}}  (resolved)
DRUPAL_DB_USER      ${{Postgres.PGUSER}}      (resolved)
DRUPAL_DB_PASSWORD  ${{Postgres.PGPASSWORD}}  (resolved)
DRUPAL_DRIVER       pgsql                      (literal)

Logs (Drupal service):
No "Cannot connect to postgres" errors
Apache starts successfully
Drupal accesses database without issues
```

---

## Quick Reference

| Step | Action |
|------|--------|
| 1 | Open Railway dashboard → drupal-railway project |
| 2 | Click Drupal service |
| 3 | Go to Variables tab |
| 4 | Add 6 variables (see Step 3) |
| 5 | Check PostgreSQL service name matches |
| 6 | Deploy/Redeploy |
| 7 | Verify connection line appears in canvas |
| 8 | Check logs for successful database connection |

---

## Expected Result

When everything is correct, Railway will:

✅ Show a connection between Drupal and PostgreSQL services
✅ Resolve the `${{Postgres.*}}` variables to actual values
✅ Allow Drupal to connect to PostgreSQL
✅ Display database connection success in logs
✅ Drupal can install and operate normally

Once you see that connection line in the Railway UI between the two services, you'll know everything is properly wired!
