# Drupal + PostgreSQL on Railway Deployment Guide

This guide walks through deploying a Drupal instance with PostgreSQL database on Railway.app.

## Overview

We'll deploy:
- **Drupal**: Using the official Docker image from Docker Hub
- **PostgreSQL**: Database service
- **Persistent Storage**: For Drupal files and settings

## Architecture

```
┌─────────────────────────────────────────┐
│         Railway Services                │
├─────────────────────────────────────────┤
│                                         │
│  Drupal (PHP/Apache)                    │
│  - Official Docker image                │
│  - Port: 80 (mapped to 8080)           │
│  - Persistent volumes for /var/www/html│
│                                         │
│  PostgreSQL Database                    │
│  - Primary data store                   │
│  - Persistent volume                    │
│  - Port: 5432 (internal)               │
│                                         │
└─────────────────────────────────────────┘
```

## Prerequisites

1. Railway Account: https://railway.app
2. GitHub account (optional, for easy deploy)
3. Docker installed locally (for testing)

## Option 1: Using Railway CLI (Recommended for Speed)

### Step 1: Install Railway CLI

```bash
curl -L https://install.railway.app | sh
```

### Step 2: Create Railway Project

```bash
railway login
railway init
```

Select "Deploy from a template" or "Create a new project"

### Step 3: Add PostgreSQL Service

From your Railway project dashboard:
1. Click "New"
2. Search for "PostgreSQL"
3. Select the PostgreSQL plugin
4. Click "Add"

This automatically sets up:
- Database credentials
- Environment variables: `DATABASE_URL`, `PGPASSWORD`, `PGHOST`, `PGPORT`, `PGUSER`, `PGDATABASE`

### Step 4: Create Dockerfile for Drupal

Create `Dockerfile` in root of your project:

```dockerfile
FROM drupal:latest

# Copy any custom modules or themes (optional)
# COPY ./modules /var/www/html/modules/custom
# COPY ./themes /var/www/html/themes/custom

# Install additional PHP extensions if needed
RUN apt-get update && apt-get install -y \
    php-gd \
    php-dom \
    && rm -rf /var/lib/apt/lists/*

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
```

### Step 5: Create railway.json

Create `railway.json` in root of your project:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "dockerfile"
  },
  "deploy": {
    "startCommand": "apache2-foreground",
    "restartPolicy": "unless_stopped",
    "numReplicas": 1
  }
}
```

### Step 6: Configure Environment Variables

In your Railway project dashboard, go to **Drupal service** → **Variables**:

Add these variables:

```
DRUPAL_DB_HOST=${{Postgres.PGHOST}}
DRUPAL_DB_NAME=${{Postgres.PGDATABASE}}
DRUPAL_DB_USER=${{Postgres.PGUSER}}
DRUPAL_DB_PASSWORD=${{Postgres.PGPASSWORD}}
DRUPAL_DB_PORT=${{Postgres.PGPORT}}
DRUPAL_DRIVER=pgsql

# Optional but recommended
DRUPAL_SITE_NAME=My Drupal Site
DRUPAL_SITE_MAIL=admin@example.com
DRUPAL_ACCOUNT_NAME=admin
DRUPAL_ACCOUNT_PASS=your-secure-password
```

### Step 7: Add Persistent Volume

For Drupal service:
1. Click on "Drupal" service
2. Go to "Settings" → "Volumes"
3. Add a volume mount:
   - Path: `/var/www/html`
   - Size: 5GB (or as needed)

This ensures:
- Uploaded files persist across restarts
- Drupal configuration persists
- Modules/themes you install don't get lost

### Step 8: Deploy

```bash
# From your project directory with Dockerfile and railway.json
railway up
```

Or push to GitHub and connect:
1. Push code to GitHub
2. In Railway: "Connect from GitHub repo"
3. Railway auto-deploys on push to main branch

### Step 9: Initialize Drupal

After deployment:

1. Get your Drupal service URL from Railway dashboard
2. Visit the URL in browser
3. Complete Drupal installation:
   - Choose language
   - Verify database settings (should auto-fill from env vars)
   - Create site name and admin account
   - Complete installation

## Option 2: Using docker-compose.yml (Local Testing)

Before deploying to Railway, test locally:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: drupal-postgres
    environment:
      POSTGRES_DB: drupal
      POSTGRES_USER: drupal
      POSTGRES_PASSWORD: drupal
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U drupal"]
      interval: 10s
      timeout: 5s
      retries: 5

  drupal:
    image: drupal:latest
    container_name: drupal-app
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DRUPAL_DB_HOST: postgres
      DRUPAL_DB_NAME: drupal
      DRUPAL_DB_USER: drupal
      DRUPAL_DB_PASSWORD: drupal
      DRUPAL_DB_PORT: 5432
      DRUPAL_DRIVER: pgsql
    ports:
      - "80:80"
    volumes:
      - drupal_data:/var/www/html
    command: |
      bash -c "
        # Install Drupal if not already installed
        if [ ! -f /var/www/html/sites/default/settings.php ]; then
          drush site-install standard \
            --db-url=pgsql://drupal:drupal@postgres:5432/drupal \
            --site-name='My Drupal Site' \
            --account-name=admin \
            --account-pass=admin123
        fi

        apache2-foreground
      "

volumes:
  postgres_data:
  drupal_data:
```

Run locally:
```bash
docker-compose up -d
```

Access at `http://localhost`

## Environment Variables Reference

### From PostgreSQL Plugin (Auto-Set)
- `DATABASE_URL` - Full connection string
- `PGHOST` - PostgreSQL host
- `PGPORT` - PostgreSQL port
- `PGUSER` - PostgreSQL user
- `PGPASSWORD` - PostgreSQL password
- `PGDATABASE` - Database name

### Drupal Specific
- `DRUPAL_DB_HOST` - Database host
- `DRUPAL_DB_NAME` - Database name
- `DRUPAL_DB_USER` - Database user
- `DRUPAL_DB_PASSWORD` - Database password
- `DRUPAL_DB_PORT` - Database port
- `DRUPAL_DRIVER` - `pgsql` for PostgreSQL
- `DRUPAL_SITE_NAME` - Site name (optional)
- `DRUPAL_SITE_MAIL` - Admin email (optional)

## Post-Deployment Configuration

### 1. Domain Setup

In Railway:
1. Go to Drupal service
2. "Settings" → "Public Networking"
3. Get auto-assigned Railway domain
4. Or add custom domain

### 2. Configure Drupal Site Settings

Visit `your-drupal-url/admin/config/system/site-information`:
- Site name
- Site email
- Homepage

### 3. Initial Modules to Install

1. Admin → Extend
2. Install recommended modules:
   - **Automatic Updates** - Keep Drupal updated
   - **Administration** - Admin toolbar
   - **Content** - Core content management
   - **Database Replication** - (If scaling)

### 4. Backup Database

Set up regular backups:
```bash
# Manual backup (run from Railway shell)
pg_dump -h $PGHOST -U $PGUSER -d $PGDATABASE > backup.sql
```

Or use Railway's backup features in PostgreSQL settings.

### 5. Setup Let's Encrypt (Optional)

If using custom domain:
1. Go to Drupal service "Settings"
2. Enable "Public Networking"
3. Add custom domain
4. Railway auto-provisions SSL certificate

## Monitoring and Troubleshooting

### Check Logs

In Railway dashboard:
1. Select Drupal service
2. View "Logs" tab
3. Watch for errors during startup

### Common Issues

**Database Connection Failed**
- Verify environment variables are set correctly
- Check PostgreSQL service is running
- Ensure `DRUPAL_DRIVER` is set to `pgsql`

**Permission Denied on Drupal Directory**
- Drupal container runs as `www-data` user
- Ensure volume permissions allow write access
- May need to rebuild with proper permissions in Dockerfile

**Out of Memory**
- Check Drupal service memory allocation in Railway
- Increase if needed
- Monitor in "Settings" → "Resources"

**Database Not Initializing**
- First deploy takes longer for Drupal installation
- Check logs - you may need to manually run installation
- Visit `/` to trigger installer if not auto-running

## Accessing Drupal Admin Panel

1. Visit your Drupal URL
2. During first setup, you'll create admin account
3. Access admin at: `your-url/user/login`
4. Dashboard: `your-url/admin`
5. Content: `your-url/admin/content`

## Performance Optimization

### 1. Enable Caching
Admin → Configuration → Development → Performance:
- Enable page caching
- Enable block caching
- Aggregate CSS/JS files

### 2. Install Redis (Optional)
For better performance:
1. Add Redis service in Railway
2. Install Redis module in Drupal
3. Configure cache backend

### 3. Database Optimization
```bash
# SSH into Drupal container via Railway
railway run bash

# Run Drupal logging optimization
drush sql-query "ANALYZE;"
```

## Scaling Considerations

**For Production:**
- Set Drupal replicas to 1 (more causes file sync issues)
- Use distributed file storage (AWS S3 module) if scaling beyond 1 instance
- Implement Redis for multi-instance caching
- Monitor PostgreSQL: Railway shows metrics in service dashboard

## Security Best Practices

1. **Change Default Admin Password** - Do immediately after setup
2. **Monitor Updates** - Enable automatic security updates via "Automatic Updates" module
3. **HTTPS Only** - Use custom domain with auto SSL
4. **Regular Backups** - Set up automated backup schedule
5. **Restrict Access** - Use firewall rules if available
6. **Update Modules** - Keep contributed modules updated

## File Structure

If deploying from GitHub:

```
your-repo/
├── Dockerfile          # Drupal container definition
├── railway.json        # Railway configuration
├── docker-compose.yml  # For local testing
├── README.md          # Setup instructions
└── modules/           # Custom modules (optional)
└── themes/            # Custom themes (optional)
```

## Useful Drush Commands

Access via Railway shell or after SSH:

```bash
# Clear all caches
drush cr

# Update all modules
drush up

# Run database updates
drush updatedb

# Export configuration
drush config:export

# Import configuration
drush config:import
```

## Support & Documentation

- Drupal Docs: https://www.drupal.org/docs/drupal-apis
- PostgreSQL Docs: https://www.postgresql.org/docs/
- Railway Docs: https://docs.railway.app
- Official Drupal Docker: https://hub.docker.com/_/drupal

## Next Steps

1. ✅ Set up Drupal service in Railway
2. ✅ Add PostgreSQL plugin
3. ✅ Configure environment variables
4. ✅ Add persistent volumes
5. ✅ Deploy and initialize Drupal
6. ✅ Configure site settings
7. ✅ Set up domain and SSL
8. ✅ Install modules and themes
9. ✅ Set up backups
10. ✅ Configure caching for production
