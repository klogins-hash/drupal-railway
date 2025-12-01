# Railway Shared Variables for Drupal + PostgreSQL

Using Railway's **Shared Variables** feature is the cleanest way to connect services without duplicating environment variables in each service.

## What Are Shared Variables?

Shared Variables are environment variables defined **once at the project level** and automatically available to all services in that project.

**Benefits:**
- ✅ Define once, use everywhere
- ✅ Easy to update credentials across all services
- ✅ Cleaner than per-service variables
- ✅ Services automatically linked through dependencies

---

## Step 1: Go to Project Settings

1. Open https://railway.app/dashboard
2. Click on **drupal-railway** project
3. Look for **Settings** (usually top-right or in a menu)
4. Find **Environment** or **Shared Variables** section
5. Click on **Variables** or **Environment Variables**

---

## Step 2: Add Shared Variables

In the **Shared Variables** section, add these variables that will be available to all services:

### Auto-Detect from PostgreSQL

Railway may auto-populate these from the PostgreSQL plugin:

```
DATABASE_URL          = postgresql://user:pass@host:5432/database
PGHOST               = postgres
PGPORT               = 5432
PGUSER               = postgres
PGPASSWORD           = <randomly generated>
PGDATABASE           = railway
```

If not auto-populated, add them manually:

1. Click **Add Variable**
2. **Name:** `DATABASE_URL`
3. **Value:** (copy from PostgreSQL service variables, or create)
   ```
   postgresql://postgres:<PGPASSWORD>@postgres:5432/railway
   ```
4. Click Save

Repeat for:
- `PGHOST` → `postgres`
- `PGPORT` → `5432`
- `PGUSER` → `postgres`
- `PGPASSWORD` → (from PostgreSQL service)
- `PGDATABASE` → `railway`

---

## Step 3: Add Drupal-Specific Shared Variables

Add these additional variables that Drupal needs:

```
DRUPAL_DRIVER       = pgsql
DRUPAL_DB_HOST      = ${{PGHOST}}
DRUPAL_DB_PORT      = ${{PGPORT}}
DRUPAL_DB_NAME      = ${{PGDATABASE}}
DRUPAL_DB_USER      = ${{PGUSER}}
DRUPAL_DB_PASSWORD  = ${{PGPASSWORD}}
```

**Or** use the full DATABASE_URL:

```
DRUPAL_DATABASE_URL = ${{DATABASE_URL}}
DRUPAL_DRIVER       = pgsql
```

---

## Step 4: Verify Services Access Shared Variables

Both services will now have access to these variables automatically:

```
PostgreSQL Service:
- Can see: DATABASE_URL, PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE

Drupal Service:
- Can see: DATABASE_URL, PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE, DRUPAL_DRIVER, DRUPAL_DB_HOST, etc.
```

---

## Step 5: Deploy and Link Services

1. After adding shared variables, go back to **Project Canvas**
2. Click **Deploy** or redeploy both services
3. Look for the **connection line** between Drupal and PostgreSQL
4. Both services should show as **Running** (green)

---

## How Shared Variables Work vs Service Variables

### Old Way (Service-Level Variables)
```
Project Canvas
├── PostgreSQL Service
│   └── Variables: PGHOST, PGPORT, etc.
└── Drupal Service
    └── Variables: ${{Postgres.PGHOST}}, ${{Postgres.PGPORT}}, etc.
```

### Better Way (Shared Variables)
```
Project Canvas
├── Shared Variables: DATABASE_URL, PGHOST, PGUSER, etc.
├── PostgreSQL Service
│   └── Inherits: DATABASE_URL, PGHOST, PGUSER, etc.
└── Drupal Service
    └── Inherits: DATABASE_URL, PGHOST, PGUSER, DRUPAL_DRIVER, etc.
```

---

## Complete Shared Variables Setup

### All Variables to Add (Copy & Paste)

In Railway Project → Settings → Variables:

```
# PostgreSQL Connection (auto-generated or manual)
DATABASE_URL=postgresql://postgres:PASSWORD@postgres:5432/railway
PGHOST=postgres
PGPORT=5432
PGUSER=postgres
PGPASSWORD=PASSWORD
PGDATABASE=railway

# Drupal-Specific
DRUPAL_DRIVER=pgsql
DRUPAL_DB_HOST=${{PGHOST}}
DRUPAL_DB_PORT=${{PGPORT}}
DRUPAL_DB_NAME=${{PGDATABASE}}
DRUPAL_DB_USER=${{PGUSER}}
DRUPAL_DB_PASSWORD=${{PGPASSWORD}}

# Optional: Drupal Config
DRUPAL_SITE_NAME=My Drupal Site
DRUPAL_SITE_MAIL=admin@example.com
```

---

## Step-by-Step: Using Shared Variables Interface

### If Railway Has Dedicated Shared Variables UI:

1. **Project Dashboard** → Look for "Shared Variables" or "Environment Variables"
2. Click **Add** or **Edit**
3. Enter variable name and value
4. Click **Save/Add**
5. Variable is immediately available to all services

### If Shared Variables Are in Project Settings:

1. **Project name** (top-left) → Click dropdown
2. **Settings** option
3. **Environment** or **Variables** tab
4. **Add Variable** button
5. Fill in name and value
6. **Save**

### Verify Variables Are Shared:

1. Go to **PostgreSQL Service** → **Variables** tab
2. Scroll down - should see a section like "Inherited Variables" or "Shared Variables"
3. Should list all the project-level variables
4. Do the same for **Drupal Service**

---

## Troubleshooting Shared Variables

### Variables Not Showing in Services

**Issue:** Added shared variables but services don't have them
**Solution:**
1. Redeploy both services (forces them to pick up new variables)
2. Check if variables were actually saved (refresh page)
3. Verify variable names and values are correct

### Services Still Not Connected

**Issue:** Still no connection line between services
**Solution:**
1. Ensure using correct variable references: `${{PGHOST}}` not `$PGHOST` or `postgres`
2. Verify PostgreSQL service name is exactly `postgres` (or use correct name)
3. Redeploy Drupal service after changing variables
4. Wait 30-60 seconds for service to start with new variables

### Variables Showing but Not Resolving

**Issue:** Variables reference other variables but not resolving
**Solution:**
- Variable resolution order: PostgreSQL variables must exist first
- Restart PostgreSQL service
- Then redeploy Drupal service
- Wait for both to fully start

---

## Advantages of Shared Variables

✅ **Single Source of Truth**: Define DATABASE_URL once, all services use it
✅ **Easy Updates**: Change password once, affects all services
✅ **No Duplication**: Don't repeat PGHOST, PGUSER in every service
✅ **Team Collaboration**: Shared credentials are clear and centralized
✅ **Environment Specific**: Can have different shared variables per environment (staging, production)
✅ **Less Error-Prone**: Fewer places to mistype values

---

## Variable Reference in Shared Variables

You can reference shared variables from within shared variables:

```
# PostgreSQL Connection Details
PGHOST=postgres
PGPORT=5432
PGUSER=postgres
PGPASSWORD=secretpassword
PGDATABASE=railway

# Full Connection String (references above variables)
DATABASE_URL=postgresql://${{PGUSER}}:${{PGPASSWORD}}@${{PGHOST}}:${{PGPORT}}/${{PGDATABASE}}

# Drupal Uses Shared Variables
DRUPAL_DB_HOST=${{PGHOST}}
DRUPAL_DB_PORT=${{PGPORT}}
DRUPAL_DB_NAME=${{PGDATABASE}}
DRUPAL_DB_USER=${{PGUSER}}
DRUPAL_DB_PASSWORD=${{PGPASSWORD}}
DRUPAL_DRIVER=pgsql
```

---

## Complete Setup Checklist Using Shared Variables

- [ ] Open Railway Dashboard → drupal-railway project
- [ ] Go to Project Settings → Variables (Shared Variables section)
- [ ] Add/verify all 6 PostgreSQL variables (PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE, DATABASE_URL)
- [ ] Add Drupal-specific variables (DRUPAL_DRIVER, DRUPAL_DB_HOST, etc.)
- [ ] Both variables reference shared ones using `${{VARIABLE_NAME}}` syntax
- [ ] Save all variables
- [ ] Go to Project Canvas
- [ ] Redeploy PostgreSQL service (wait for green status)
- [ ] Redeploy Drupal service (wait for green status)
- [ ] Verify connection line appears between services
- [ ] Check Drupal logs for successful database connection
- [ ] Access Drupal URL in browser

---

## After Setup is Complete

Once shared variables are working:

1. **Services Show Connection** ✅
   - Connection line visible in project canvas
   - Shows dependency: Drupal → PostgreSQL

2. **Services Can Communicate** ✅
   - Drupal logs show successful DB connection
   - No "Cannot connect to postgres" errors
   - `verify-connectivity.sh` passes all checks

3. **Drupal Initializes** ✅
   - Installation wizard appears (not 403 error)
   - Can create admin account
   - Can access dashboard at `/admin`

---

## Railway UI Reference

The exact location of "Shared Variables" depends on Railway version:

**Typical Locations:**
- Project Canvas → gear icon (Settings) → Variables
- Project name → Settings → Environment
- Project name → Shared or Project Settings
- Right sidebar → Project settings icon

**If you can't find it:**
1. Click on your project name (top)
2. Look for Settings/Configuration icon
3. Look for "Variables", "Environment", or "Shared"
4. The section should show variables that apply to ALL services

---

## Advantages Over Service-Level Variables

| Aspect | Service Variables | Shared Variables |
|--------|-------------------|------------------|
| Define Where | Each service | Once at project level |
| Reference | `${{Postgres.PGHOST}}` | `${{PGHOST}}` |
| Change Password | Update in PostgreSQL + update in Drupal | Update once, affects all |
| Cleaner | More work per service | Less repetition |
| Team Friendly | Easy to miss updates | Single source of truth |
| Environment Staging | Different per environment | Different per environment |

---

## Final Architecture With Shared Variables

```
Railway Project: drupal-railway
├── Shared Variables (Project Level)
│   ├── DATABASE_URL
│   ├── PGHOST = postgres
│   ├── PGPORT = 5432
│   ├── PGUSER = postgres
│   ├── PGPASSWORD = ***
│   ├── PGDATABASE = railway
│   ├── DRUPAL_DRIVER = pgsql
│   ├── DRUPAL_DB_HOST = ${{PGHOST}}
│   └── (other Drupal config...)
│
├── PostgreSQL Service (Running)
│   └── Inherits all shared variables
│
└── Drupal Service (Running)
    └── Inherits all shared variables
    └── Uses DRUPAL_DB_* to connect to PostgreSQL
```

When configured this way, services automatically show as connected in the Railway UI because they share the same variables that define their relationship!
