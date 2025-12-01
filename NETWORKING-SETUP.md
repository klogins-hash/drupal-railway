# Drupal + PostgreSQL Networking Setup on Railway

Complete guide to ensuring Drupal and PostgreSQL talk to each other correctly via Railway's private network.

## Overview

Your deployment consists of two services communicating through Railway's private network:

```
┌─────────────────────────────────────────────────────┐
│ Railway Project: drupal-railway                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Drupal Service (Port 80)   PostgreSQL Service    │
│  ┌──────────────────┐       ┌─────────────────┐  │
│  │ - PHP/Apache     │────→  │ - PostgreSQL    │  │
│  │ - Port: 80       │  ←─── │ - Port: 5432    │  │
│  │ - Persistent Vol │       │ - Persistent Vol│  │
│  └──────────────────┘       └─────────────────┘  │
│         ↓                                          │
│    Public Internet                                 │
│    (via Railway Domain)                            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 1. PostgreSQL Service Configuration

### Auto-Generated Environment Variables

When you added the PostgreSQL plugin in Railway, it automatically created:

| Variable | Value | Used By |
|----------|-------|---------|
| `PGHOST` | postgres service name | Drupal DB_HOST |
| `PGPORT` | 5432 | Drupal DB_PORT |
| `PGUSER` | postgres | Drupal DB_USER |
| `PGPASSWORD` | random generated | Drupal DB_PASSWORD |
| `PGDATABASE` | railway | Drupal DB_NAME |
| `DATABASE_URL` | postgresql://user:pass@host:5432/db | Full connection string |

**Found in:** Railway Dashboard → PostgreSQL Service → Variables tab

## 2. Drupal Service Configuration

### Environment Variables to Set

In Railway Dashboard → Drupal Service → Variables, add these:

```bash
DRUPAL_DB_HOST=${{Postgres.PGHOST}}
DRUPAL_DB_PORT=${{Postgres.PGPORT}}
DRUPAL_DB_NAME=${{Postgres.PGDATABASE}}
DRUPAL_DB_USER=${{Postgres.PGUSER}}
DRUPAL_DB_PASSWORD=${{Postgres.PGPASSWORD}}
DRUPAL_DRIVER=pgsql
```

**Important Notes:**
- Railway will substitute `${{Postgres.VARIABLE}}` with actual PostgreSQL values
- Service name `Postgres` must match your PostgreSQL service name
- These are resolved at deployment time

## 3. Network Communication Flow

### How Services Talk to Each Other

1. **Service Discovery**: Railway's internal DNS automatically resolves `postgres` (or your service name) to an internal IP
2. **Private Network**: Services use Railway's private network - no public internet involved
3. **Port Access**: PostgreSQL listens on port 5432 (only accessible from within the private network)
4. **Authentication**: Drupal uses the credentials from environment variables

### Network Diagram

```
Drupal Container                PostgreSQL Container
┌─────────────────────┐        ┌───────────────────┐
│ DRUPAL_DB_HOST      │        │ PGHOST (internal) │
│   = postgres        │───────→│ IP: (internal)    │
│                     │        │ PORT: 5432        │
│ Connection String:  │        └───────────────────┘
│ pgsql://user:pass@  │
│ postgres:5432/db    │
└─────────────────────┘
```

## 4. Verification Checklist

### ✅ Pre-Deployment

- [ ] PostgreSQL service added to Railway project
- [ ] PostgreSQL is in "Running" state (green status)
- [ ] Environment variables copied from PostgreSQL service

### ✅ During Drupal Deployment

- [ ] Drupal environment variables set with `${{Postgres.*}}` references
- [ ] DRUPAL_DRIVER set to `pgsql`
- [ ] All six database variables present (HOST, PORT, NAME, USER, PASSWORD, DRIVER)
- [ ] Persistent volume configured at `/var/www/html`
- [ ] Service is "Running" (green status)

### ✅ Post-Deployment

1. **Check Drupal Logs**
   ```
   Railway Dashboard → Drupal Service → Logs
   ```
   Look for database connection messages (no errors about "host not found")

2. **Run Verification Script**
   ```bash
   railway ssh --project=<PROJECT_ID> --service=<DRUPAL_SERVICE_ID>
   bash verify-connectivity.sh
   ```

   This script will verify:
   - All environment variables are set
   - DNS resolution works
   - Network connectivity to PostgreSQL
   - PostgreSQL authentication succeeds
   - Database queries work

3. **Access Drupal Web Interface**
   - Get URL from: Railway Dashboard → Drupal Service → Networking
   - Should see Drupal installation wizard or dashboard
   - If database not found, check environment variables

## 5. Troubleshooting Guide

### Issue: "Cannot connect to database"

**Check these in order:**

1. **PostgreSQL Service Running?**
   ```
   Railway → PostgreSQL Service → Check status is "Running" (green)
   ```

2. **Environment Variables Set?**
   ```
   Railway → Drupal Service → Variables tab

   Verify all 6 are present:
   - DRUPAL_DB_HOST
   - DRUPAL_DB_PORT
   - DRUPAL_DB_NAME
   - DRUPAL_DB_USER
   - DRUPAL_DB_PASSWORD
   - DRUPAL_DRIVER=pgsql
   ```

3. **Variable Values Correct?**
   ```bash
   # SSH into Drupal service
   railway ssh --project=<ID> --service=<DRUPAL_ID>

   # Print the values
   echo "HOST: $DRUPAL_DB_HOST"
   echo "PORT: $DRUPAL_DB_PORT"
   echo "NAME: $DRUPAL_DB_NAME"
   echo "USER: $DRUPAL_DB_USER"
   echo "DRIVER: $DRUPAL_DRIVER"
   ```

4. **Can Reach PostgreSQL?**
   ```bash
   # Inside Drupal container
   nc -z -v postgres 5432
   # Should output: Connection to postgres 5432 port [tcp/*] succeeded!
   ```

5. **Can Connect with credentials?**
   ```bash
   # Inside Drupal container
   psql -h $DRUPAL_DB_HOST -U $DRUPAL_DB_USER -d $DRUPAL_DB_NAME -c "SELECT 1;"
   # Should return: 1
   ```

### Issue: "Service name not found" / DNS error

**Cause:** PostgreSQL service name is different
**Solution:**
1. Check actual service name in Railway Dashboard
2. If it's not `Postgres`, update all variable references
3. Example: if service is `postgres-db`, use `${{postgres-db.PGHOST}}`

### Issue: "Authentication failed"

**Cause:** Username or password mismatch
**Solution:**
1. Copy PGUSER and PGPASSWORD directly from PostgreSQL Variables tab
2. Paste into Drupal DRUPAL_DB_USER and DRUPAL_DB_PASSWORD
3. Redeploy Drupal service

### Issue: "Port connection refused"

**Cause:** PostgreSQL port not exposed or blocked
**Solution:**
1. Verify PostgreSQL is running: `railway ssh postgres-service && psql -c "SELECT 1;"`
2. Check listener: `netstat -tulpn | grep 5432`
3. Restart PostgreSQL service if needed

## 6. Service-to-Service Linking

### Railway Automatically Links Services When:

1. You use `${{ServiceName.VARIABLE}}` syntax in environment variables
2. Service names match the referenced service
3. Both services are in the same project
4. Both services are in the same environment

### Manual Verification

```
Railway Dashboard → Drupal Service → Settings
↓
Linked Services (should show PostgreSQL service)
```

If not linked:
1. Add the environment variable with `${{Postgres.*}}` syntax
2. Save and redeploy
3. Railway will auto-link

## 7. Debugging Commands

### SSH into Drupal Service
```bash
railway ssh --project=<PROJECT_ID> --service=<DRUPAL_SERVICE_ID> --environment=<ENV_ID>
```

### View Drupal Logs
```bash
Railway Dashboard → Drupal Service → Logs tab
# Or SSH in and check:
tail -f /var/www/html/web/sites/default/files/php_errorlog
```

### Test DNS from Drupal
```bash
# Inside container
nslookup postgres
dig postgres
host postgres
```

### Test PostgreSQL Connection
```bash
# Inside container
psql -h postgres -U $DRUPAL_DB_USER -d $DRUPAL_DB_NAME -c "SELECT version();"
```

### Run Full Verification
```bash
# Inside Drupal container
bash verify-connectivity.sh
```

## 8. Performance Optimization

### For Production

1. **Connection Pooling**: Consider PgBouncer for connection management
2. **Indexes**: Ensure PostgreSQL has indexes on frequently queried fields
3. **Persistent Connections**: Drupal caches DB connections within requests
4. **Monitoring**: Enable Railway metrics for Drupal and PostgreSQL

### Check Service Health
```
Railway Dashboard → Service → Health & Metrics
- CPU Usage
- Memory Usage
- Network I/O
```

## 9. Persistence & Data

### Persistent Volumes

Both services have persistent volumes:

```
Drupal:     /var/www/html         (5GB recommended)
PostgreSQL: /var/lib/postgresql/  (auto-managed by Railway)
```

**Important:** Data persists across:
- Service restarts
- Deployments
- Scaling events

**Data is lost only if:**
- Volume is manually deleted
- Project is deleted
- Data backup not configured

### Backup Strategy

```bash
# Manual PostgreSQL backup
railway ssh --service=postgres-service
pg_dump -U $PGUSER $PGDATABASE > backup.sql

# Backup Drupal files
railway ssh --service=drupal-service
tar -czf drupal-backup.tar.gz /var/www/html
```

## 10. Final Checklist

- [ ] Services deployed to Railway
- [ ] PostgreSQL service is Running
- [ ] Drupal service is Running
- [ ] Environment variables set in Drupal service
- [ ] Variables use correct `${{Postgres.*}}` references
- [ ] Drupal logs show successful database connection
- [ ] Verification script passes all checks
- [ ] Can access Drupal at public URL
- [ ] Drupal installation wizard or admin dashboard visible
- [ ] Persistent volumes configured

## Support

For detailed information on each aspect, see:

- **Environment Setup**: `.railway-env-setup.md`
- **Deployment Guide**: `DRUPAL_RAILWAY_DEPLOYMENT.md`
- **Quick Start**: `DRUPAL_QUICK_START.md`
- **Connectivity Testing**: Run `verify-connectivity.sh` in Drupal container

## Quick Links

- Railway Docs: https://docs.railway.app
- Railway Dashboard: https://railway.app/dashboard
- Drupal Docs: https://www.drupal.org/docs
- PostgreSQL Docs: https://www.postgresql.org/docs/
