# Drupal + PostgreSQL on Railway

Production-ready Drupal deployment with PostgreSQL database on Railway.app

## Quick Start

### Local Development
```bash
docker-compose up -d
```

Visit `http://localhost` and complete the Drupal installation.

### Deploy to Railway

1. **Create Railway Account** - https://railway.app
2. **Push to GitHub** - Fork or clone this repo
3. **Connect to Railway** - Select "Deploy from GitHub repo"
4. **Add PostgreSQL** - Click "New" and add PostgreSQL plugin
5. **Configure Environment** - Add the following variables:
   ```
   DRUPAL_DB_HOST=${{Postgres.PGHOST}}
   DRUPAL_DB_NAME=${{Postgres.PGDATABASE}}
   DRUPAL_DB_USER=${{Postgres.PGUSER}}
   DRUPAL_DB_PASSWORD=${{Postgres.PGPASSWORD}}
   DRUPAL_DB_PORT=${{Postgres.PGPORT}}
   DRUPAL_DRIVER=pgsql
   ```
6. **Add Storage** - Add persistent volume at `/var/www/html` (5GB)
7. **Deploy** - Railway will automatically deploy on push

## Files

- `Dockerfile.drupal` - Production Drupal image with PHP extensions
- `railway.json` - Railway platform configuration
- `docker-compose.yml` - Local development environment
- `DRUPAL_QUICK_START.md` - Quick reference guide
- `DRUPAL_RAILWAY_DEPLOYMENT.md` - Comprehensive deployment guide

## Architecture

```
┌─────────────────────┐
│  Drupal (Apache)    │
│  Port: 80           │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│ PostgreSQL Database │
│ Port: 5432          │
└─────────────────────┘
```

## Key Features

✅ Official Drupal Docker image
✅ PostgreSQL integration
✅ Persistent file storage
✅ Health checks configured
✅ Auto-restart on failure
✅ Railway environment templates

## Documentation

- **Quick Start**: See `DRUPAL_QUICK_START.md` for 3-step deployment
- **Full Guide**: See `DRUPAL_RAILWAY_DEPLOYMENT.md` for detailed instructions
- **Docker Hub**: https://hub.docker.com/_/drupal
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Railway**: https://docs.railway.app

## Troubleshooting

**Database connection failed?**
- Verify PostgreSQL plugin is added in Railway
- Check environment variables match PostgreSQL credentials

**Persistent storage not working?**
- Ensure volume is added at `/var/www/html` path
- Check Railway storage quota

**Local port conflicts?**
- Edit docker-compose.yml: change `"80:80"` to `"8080:80"`
- Access at `http://localhost:8080`

## Local Testing Credentials

- Username: `admin`
- Password: `admin123`
- Database: `drupal` (PostgreSQL)

⚠️ **Change these credentials immediately after production deployment!**

## Support

- Railway Support: https://railway.app/support
- Drupal Community: https://www.drupal.org/community
- PostgreSQL Docs: https://www.postgresql.org/docs/

## License

This deployment configuration is provided as-is. Drupal is open source under the GPL license.
