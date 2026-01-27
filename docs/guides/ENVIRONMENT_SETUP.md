# Environment Configuration Guide

This guide documents the environment variables used across the PerfAnalysis ecosystem.

## Overview

Each component has its own `.env.example` file that should be copied to `.env` for local development. Never commit `.env` files with real credentials.

## Component Environment Files

| Component | Example File | Description |
|-----------|--------------|-------------|
| XATSimplified | `XATSimplified/.env.example` | Production backend API |
| perf-dashboard | `perf-dashboard/.env.example` | React frontend |
| XATbackend | `XATbackend/.env.example` | Deprecated backend (reference only) |

---

## XATSimplified Environment Variables

The production Django backend requires these environment variables:

### Core Django Settings

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY` | Yes | - | Django secret key (generate a unique one) |
| `DEBUG` | No | `False` | Debug mode (never True in production) |
| `ALLOWED_HOSTS` | Yes | - | Comma-separated list of allowed hostnames |
| `DATABASE_URL` | Yes | - | PostgreSQL connection URL |

### CORS Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CORS_ALLOWED_ORIGINS` | No | - | Comma-separated list of allowed origins for CORS |

### Rate Limiting (v1.1+)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `RATELIMIT_ENABLE` | No | `True` | Enable/disable rate limiting |
| `RATELIMIT_AUTH` | No | `5/m` | Rate limit for auth endpoints |
| `RATELIMIT_API` | No | `60/m` | Rate limit for general API |
| `RATELIMIT_UPLOAD` | No | `10/m` | Rate limit for upload endpoints |
| `RATELIMIT_TRICKLE` | No | `120/m` | Rate limit for trickle data |
| `REDIS_URL` | No | - | Redis URL for rate limiting cache (production) |

### Error Tracking (Sentry)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SENTRY_DSN` | No | - | Sentry DSN for error tracking |
| `SENTRY_ENVIRONMENT` | No | `development` | Environment name for Sentry |
| `SENTRY_TRACES_SAMPLE_RATE` | No | `0.1` | Performance tracing sample rate |
| `SENTRY_PROFILES_SAMPLE_RATE` | No | `0.1` | Profiling sample rate |

### Azure Key Vault (Optional)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AZURE_KEY_VAULT_URL` | No | - | Azure Key Vault URL for secrets management |

### Logging

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DJANGO_LOG_LEVEL` | No | `INFO` | Logging level (DEBUG, INFO, WARNING, ERROR) |

### Example `.env` for Development

```bash
# XATSimplified/.env
SECRET_KEY=your-development-secret-key-change-in-production
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/xatsimplified
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
DJANGO_LOG_LEVEL=DEBUG
```

### Example `.env` for Production

```bash
# XATSimplified/.env (production)
SECRET_KEY=<from-azure-key-vault-or-secure-storage>
DEBUG=False
ALLOWED_HOSTS=api.perfanalysis.com,*.perfanalysis.com
DATABASE_URL=postgresql://user:pass@prod-db.postgres.database.azure.com:5432/perfanalysis

# Rate Limiting
RATELIMIT_ENABLE=True
REDIS_URL=redis://prod-redis.redis.cache.windows.net:6379/0

# Error Tracking
SENTRY_DSN=https://xxx@sentry.io/project
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=0.1

# Azure Key Vault
AZURE_KEY_VAULT_URL=https://perfanalysis-vault.vault.azure.net/
```

---

## perf-dashboard Environment Variables

The React frontend uses Vite environment variables (prefixed with `VITE_`).

### API Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VITE_API_URL` | Yes | - | XATSimplified backend URL |

### Azure AD Authentication

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VITE_AZURE_CLIENT_ID` | Yes* | - | Azure AD App Registration Client ID |
| `VITE_AZURE_TENANT_ID` | No | `common` | Azure AD Tenant ID |
| `VITE_AZURE_REDIRECT_URI` | No | `http://localhost:5173` | OAuth redirect URI |

*Required if using Azure AD authentication.

### Feature Flags

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VITE_ENABLE_CONTAINERS` | No | `true` | Enable container/collector views |
| `VITE_ENABLE_REPORTS` | No | `true` | Enable reporting features |
| `VITE_ENABLE_REALTIME` | No | `false` | Enable real-time updates |

### Build Information

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VITE_APP_VERSION` | No | `0.1.0` | Application version |
| `VITE_BUILD_DATE` | No | - | Build date (set by CI/CD) |

### Example `.env` for Development

```bash
# perf-dashboard/.env
VITE_API_URL=http://localhost:8000
VITE_ENABLE_CONTAINERS=true
VITE_ENABLE_REPORTS=true
VITE_ENABLE_REALTIME=false
```

### Example `.env` for Production

```bash
# perf-dashboard/.env (production)
VITE_API_URL=https://api.perfanalysis.com
VITE_AZURE_CLIENT_ID=<your-azure-app-client-id>
VITE_AZURE_TENANT_ID=<your-azure-tenant-id>
VITE_AZURE_REDIRECT_URI=https://app.perfanalysis.com
VITE_ENABLE_CONTAINERS=true
VITE_ENABLE_REPORTS=true
VITE_ENABLE_REALTIME=true
VITE_APP_VERSION=1.0.0
```

---

## perfcollector2 Environment Variables

The Go-based collector uses environment variables for configuration.

### pcc (Client)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PCC_DURATION` | No | `24h` | Collection duration |
| `PCC_FREQUENCY` | No | `15s` | Sampling interval |
| `PCC_COLLECTION` | No | `~/pcc.json` | Output file path |
| `PCC_MODE` | No | `local` | Mode: `local` or `trickle` |
| `PCC_APIKEY` | Yes* | - | API key for trickle mode |
| `PCC_SERVER` | Yes* | - | pcd server address (trickle mode) |

*Required if using trickle mode.

### pcd (Server)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LISTENADDRESS` | No | `localhost:8080` | Server bind address |
| `PCD_LOGLEVEL` | No | `info` | Log level |
| `PCD_APIKEYS_FILE` | No | `~/.pcd/apikeys` | Path to API keys file |

### pcprocess (Processor)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PCR_COLLECTION` | Yes | - | Input JSON file path |
| `PCR_OUTDIR` | Yes | - | Output CSV file path |

---

## Security Best Practices

1. **Never commit `.env` files** - Add them to `.gitignore`
2. **Use different secrets per environment** - Dev, staging, production should have unique keys
3. **Use Azure Key Vault in production** - Store sensitive values securely
4. **Rotate secrets regularly** - API keys and tokens should be rotated periodically
5. **Validate required variables** - Fail fast if required variables are missing
6. **Use least privilege** - Database users should have minimal required permissions

---

## Troubleshooting

### "SECRET_KEY must be set"

The Django application requires a SECRET_KEY. Generate one:

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### "Database connection failed"

Check your `DATABASE_URL` format:
```
postgresql://username:password@hostname:port/database
```

### "CORS error in browser"

Ensure `CORS_ALLOWED_ORIGINS` includes your frontend URL:
```bash
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
```

---

*Last Updated: 2026-01-27*
