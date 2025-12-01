# Drupal + PostgreSQL on Railway - Quick Start Guide

## Files Created

This setup includes everything needed to deploy Drupal with PostgreSQL on Railway:

- **DRUPAL_RAILWAY_DEPLOYMENT.md** - Complete deployment guide with all details
- **Dockerfile.drupal** - Docker image definition for Drupal
- **railway.json** - Railway platform configuration
- **docker-compose.yml** - Local testing with Docker Compose

## Quick Local Test (Before Deploying to Railway)

```bash
# Make sure Docker is running, then:
docker-compose up -d

# Check if services are running
docker-compose ps

# View logs
docker-compose logs -f drupal

# Once Drupal is ready (wait 30-60 seconds), access at:
http://localhost
```

**Default credentials (for local testing):**
- Admin Username: `admin`
- Admin Password: `admin123`
- Database: PostgreSQL (drupal / drupal_secure_password_123)

## Deploy to Railway (3 Steps)

### Step 1: Create Railway Project
```bash
railway login
railway init
```

### Step 2: Add PostgreSQL
In Railway Dashboard:
1. Click "New"
2. Search and select "PostgreSQL"
3. Click "Add"

### Step 3: Deploy Drupal Service
In Railway Dashboard:
1. Click "New"
2. Select "GitHub Repo" (push these files to GitHub first)
   OR
   Use Railway CLI: `railway up`

## Environment Variables in Railway

Railway will auto-set these from PostgreSQL plugin:
```
DRUPAL_DB_HOST=${{Postgres.PGHOST}}
DRUPAL_DB_NAME=${{Postgres.PGDATABASE}}
DRUPAL_DB_USER=${{Postgres.PGUSER}}
DRUPAL_DB_PASSWORD=${{Postgres.PGPASSWORD}}
DRUPAL_DB_PORT=${{Postgres.PGPORT}}
DRUPAL_DRIVER=pgsql
```

## Add Persistent Storage

In Railway (Drupal service):
1. Settings → Volumes
2. Add volume: `/var/www/html` (5GB recommended)

This keeps uploads, modules, and themes after restart.

## Post-Deploy

1. Railway provides a public URL - visit it
2. Complete Drupal installation wizard
3. Create admin account
4. Configure site settings in `/admin`

## Troubleshooting

**Can't connect to database?**
- Check environment variables in Railway dashboard
- Ensure PostgreSQL service is running

**Port already in use locally?**
- Change in docker-compose.yml: `"8080:80"` instead of `"80:80"`
- Access at http://localhost:8080

**Need to start fresh?**
```bash
docker-compose down -v  # Removes volumes
docker-compose up -d    # Fresh restart
```

## Architecture

```
Drupal (Apache/PHP)
        ↓
PostgreSQL Database
        ↓
Persistent Storage
```

All three components auto-scale on Railway with this setup.

## Key Features

✅ Official Drupal Docker image
✅ PostgreSQL database integration
✅ Persistent file storage
✅ Health checks configured
✅ Auto-restart on failure
✅ Environment variable templating for Railway
✅ Tested docker-compose for local development

## Documentation

For detailed setup, troubleshooting, and configuration, see:
**DRUPAL_RAILWAY_DEPLOYMENT.md**

## Support Resources

- Railway Docs: https://docs.railway.app
- Drupal Docs: https://www.drupal.org/docs
- Docker Hub Drupal: https://hub.docker.com/_/drupal
