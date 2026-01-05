# Production Deployment Guide

Complete guide for deploying PerfAnalysis to production environments.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Infrastructure Requirements](#infrastructure-requirements)
3. [Deployment Options](#deployment-options)
4. [Production Configuration](#production-configuration)
5. [Security Hardening](#security-hardening)
6. [Database Setup](#database-setup)
7. [Load Balancing & Scaling](#load-balancing--scaling)
8. [Monitoring & Logging](#monitoring--logging)
9. [Backup & Recovery](#backup--recovery)
10. [Maintenance](#maintenance)

---

## Pre-Deployment Checklist

### Required Items

- [ ] Domain name configured (e.g., perfanalysis.yourdomain.com)
- [ ] SSL/TLS certificates obtained
- [ ] Cloud infrastructure or servers provisioned
- [ ] Database server prepared (PostgreSQL 12.2+)
- [ ] Email server configured (for notifications)
- [ ] Backup strategy defined
- [ ] Monitoring tools selected
- [ ] Security audit completed

### Team Requirements

- [ ] System administrator assigned
- [ ] Database administrator assigned
- [ ] Security contact designated
- [ ] On-call rotation established

### Documentation

- [ ] Architecture review completed
- [ ] Security policies documented
- [ ] Disaster recovery plan created
- [ ] User training materials prepared

---

## Infrastructure Requirements

### Minimum Production Environment

| Component | Specifications |
|-----------|---------------|
| **Application Server** | 4 vCPU, 8GB RAM, 50GB SSD |
| **Database Server** | 4 vCPU, 16GB RAM, 500GB SSD |
| **Load Balancer** | 2 vCPU, 4GB RAM |
| **Network** | 1 Gbps |

### Recommended Production Environment

| Component | Specifications |
|-----------|---------------|
| **Application Servers** | 2x (8 vCPU, 16GB RAM, 100GB SSD) |
| **Database Server** | 8 vCPU, 32GB RAM, 1TB NVMe SSD |
| **Redis Cache** | 2 vCPU, 8GB RAM |
| **Load Balancer** | Managed service (AWS ALB, Azure LB) |
| **Network** | 10 Gbps, CDN integration |

### High Availability Environment

```
                        ┌─────────────┐
                        │   CDN       │
                        │  (Static)   │
                        └──────┬──────┘
                               │
                        ┌──────▼──────┐
                        │ Load        │
                        │ Balancer    │
                        └──┬─────┬────┘
                           │     │
              ┌────────────┘     └────────────┐
              ▼                                ▼
      ┌───────────────┐              ┌───────────────┐
      │  App Server 1 │              │  App Server 2 │
      │  (XATbackend) │              │  (XATbackend) │
      └───────┬───────┘              └───────┬───────┘
              │                                │
              └────────────┬───────────────────┘
                           │
                    ┌──────▼──────┐
                    │  PostgreSQL │
                    │  Primary    │
                    └──────┬──────┘
                           │ Replication
                    ┌──────▼──────┐
                    │  PostgreSQL │
                    │  Replica    │
                    └─────────────┘
```

---

## Deployment Options

### Option 1: Docker Compose (Small-Medium Scale)

**Best for**: Single server deployments, up to 50 collectors

```bash
# Clone repository
git clone https://github.com/yourusername/PerfAnalysis.git
cd PerfAnalysis

# Create production configuration
cp docker-compose.yml docker-compose.prod.yml

# Edit production settings
nano docker-compose.prod.yml
```

**docker-compose.prod.yml**:
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:12.2
    environment:
      POSTGRES_DB: perfanalysis
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 16G
    networks:
      - perfanalysis-net

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - perfanalysis-net

  xatbackend:
    build:
      context: ./XATbackend
      dockerfile: Dockerfile.prod
    environment:
      - DJANGO_SETTINGS_MODULE=core.settings.production
      - DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@postgres:5432/perfanalysis
      - REDIS_URL=redis://redis:6379/1
      - SECRET_KEY=${SECRET_KEY}
      - ALLOWED_HOSTS=${ALLOWED_HOSTS}
    depends_on:
      - postgres
      - redis
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '2'
          memory: 4G
    networks:
      - perfanalysis-net

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - static_files:/var/www/static
    depends_on:
      - xatbackend
    networks:
      - perfanalysis-net

  pcd:
    build:
      context: ./perfcollector2
      dockerfile: Dockerfile.prod
    ports:
      - "8080:8080"
    volumes:
      - pcd_data:/var/lib/pcd
    environment:
      - PCD_API_PORT=8080
      - PCD_XATBACKEND_URL=http://xatbackend:8000
    networks:
      - perfanalysis-net

volumes:
  postgres_data:
  redis_data:
  pcd_data:
  static_files:

networks:
  perfanalysis-net:
    driver: bridge
```

**Deploy**:
```bash
# Set environment variables
cp .env.example .env.production
nano .env.production

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Run migrations
docker-compose -f docker-compose.prod.yml exec xatbackend \
  python manage.py migrate

# Collect static files
docker-compose -f docker-compose.prod.yml exec xatbackend \
  python manage.py collectstatic --noreply

# Create superuser
docker-compose -f docker-compose.prod.yml exec xatbackend \
  python manage.py createsuperuser
```

### Option 2: Kubernetes (Large Scale)

**Best for**: Enterprise deployments, 100+ collectors, high availability

**Directory Structure**:
```
k8s/
├── namespace.yaml
├── postgres/
│   ├── statefulset.yaml
│   ├── service.yaml
│   └── pvc.yaml
├── redis/
│   ├── deployment.yaml
│   └── service.yaml
├── xatbackend/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── secret.yaml
├── pcd/
│   ├── deployment.yaml
│   └── service.yaml
├── ingress.yaml
└── hpa.yaml
```

**Example: XATbackend Deployment**

```yaml
# k8s/xatbackend/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xatbackend
  namespace: perfanalysis
spec:
  replicas: 3
  selector:
    matchLabels:
      app: xatbackend
  template:
    metadata:
      labels:
        app: xatbackend
    spec:
      containers:
      - name: xatbackend
        image: perfanalysis/xatbackend:latest
        ports:
        - containerPort: 8000
        env:
        - name: DJANGO_SETTINGS_MODULE
          value: "core.settings.production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: xatbackend-secrets
              key: database-url
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: xatbackend-secrets
              key: secret-key
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /health/
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: xatbackend
  namespace: perfanalysis
spec:
  selector:
    app: xatbackend
  ports:
  - port: 8000
    targetPort: 8000
  type: ClusterIP
```

**Deploy to Kubernetes**:
```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy PostgreSQL
kubectl apply -f k8s/postgres/

# Deploy Redis
kubectl apply -f k8s/redis/

# Deploy XATbackend
kubectl apply -f k8s/xatbackend/

# Deploy pcd
kubectl apply -f k8s/pcd/

# Configure ingress
kubectl apply -f k8s/ingress.yaml

# Set up auto-scaling
kubectl apply -f k8s/hpa.yaml

# Verify deployment
kubectl get pods -n perfanalysis
kubectl get svc -n perfanalysis
```

### Option 3: Cloud-Native (AWS Example)

**Architecture**:
```
AWS Cloud
├── VPC
│   ├── Public Subnets (ALB, NAT Gateway)
│   └── Private Subnets (ECS, RDS)
├── Application Load Balancer
├── ECS Fargate (XATbackend containers)
├── RDS PostgreSQL (Multi-AZ)
├── ElastiCache Redis
├── S3 (Static files, backups)
├── CloudWatch (Monitoring)
└── Route53 (DNS)
```

**Terraform Configuration**:
```hcl
# main.tf
provider "aws" {
  region = "us-east-1"
}

# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "perfanalysis-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier           = "perfanalysis-db"
  engine              = "postgres"
  engine_version      = "12.2"
  instance_class      = "db.m5.xlarge"
  allocated_storage   = 500
  storage_encrypted   = true

  db_name  = "perfanalysis"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  multi_az               = true
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "perfanalysis-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "xatbackend" {
  family                   = "xatbackend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"

  container_definitions = jsonencode([{
    name  = "xatbackend"
    image = "${var.ecr_repository_url}:latest"

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = [
      { name = "DJANGO_SETTINGS_MODULE", value = "core.settings.production" }
    ]

    secrets = [
      {
        name      = "DATABASE_URL"
        valueFrom = aws_secretsmanager_secret.db_url.arn
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/xatbackend"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "perfanalysis-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
}

# Deploy
# terraform init
# terraform plan
# terraform apply
```

---

## Production Configuration

### Django Settings

Create `XATbackend/core/settings/production.py`:

```python
from .base import *
import os

DEBUG = False

ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', '').split(',')

# Security
SECRET_KEY = os.getenv('SECRET_KEY')
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'perfanalysis'),
        'USER': os.getenv('DB_USER'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
        'CONN_MAX_AGE': 600,
        'OPTIONS': {
            'sslmode': 'require',
            'connect_timeout': 10,
        },
    }
}

# Cache (Redis)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': os.getenv('REDIS_URL', 'redis://localhost:6379/1'),
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {
                'max_connections': 50,
                'retry_on_timeout': True,
            }
        },
        'KEY_PREFIX': 'perfanalysis',
        'TIMEOUT': 300,
    }
}

# Static files
STATIC_ROOT = '/var/www/static'
STATIC_URL = '/static/'

MEDIA_ROOT = '/var/www/media'
MEDIA_URL = '/media/'

# Email
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.getenv('EMAIL_HOST')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', '587'))
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.getenv('EMAIL_USER')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_PASSWORD')
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL')

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/var/log/perfanalysis/django.log',
            'maxBytes': 1024 * 1024 * 100,  # 100MB
            'backupCount': 10,
            'formatter': 'verbose',
        },
        'error_file': {
            'level': 'ERROR',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/var/log/perfanalysis/django_errors.log',
            'maxBytes': 1024 * 1024 * 100,
            'backupCount': 10,
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file', 'error_file'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}

# Celery (for async tasks)
CELERY_BROKER_URL = os.getenv('REDIS_URL', 'redis://localhost:6379/0')
CELERY_RESULT_BACKEND = os.getenv('REDIS_URL', 'redis://localhost:6379/0')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'UTC'
```

### Nginx Configuration

Create `nginx/nginx.conf`:

```nginx
upstream xatbackend {
    least_conn;
    server xatbackend_1:8000;
    server xatbackend_2:8000;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name perfanalysis.yourdomain.com *.perfanalysis.yourdomain.com;
    return 301 https://$host$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name perfanalysis.yourdomain.com *.perfanalysis.yourdomain.com;

    # SSL certificates
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Static files
    location /static/ {
        alias /var/www/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Media files
    location /media/ {
        alias /var/www/media/;
        expires 7d;
    }

    # Django application
    location / {
        proxy_pass http://xatbackend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }

    # File upload size
    client_max_body_size 100M;
}
```

---

## Security Hardening

See [SECURITY.md](SECURITY.md) for complete security documentation.

### Quick Security Checklist

- [ ] SSL/TLS certificates installed and configured
- [ ] Firewall rules configured (only necessary ports open)
- [ ] Database encryption at rest enabled
- [ ] Strong passwords enforced
- [ ] API rate limiting enabled
- [ ] CORS properly configured
- [ ] Security headers enabled (CSP, HSTS, etc.)
- [ ] Regular security updates scheduled
- [ ] Intrusion detection system (IDS) configured
- [ ] Audit logging enabled
- [ ] Vulnerability scanning configured

---

## Database Setup

### PostgreSQL Production Configuration

```bash
# postgresql.conf
max_connections = 200
shared_buffers = 4GB
effective_cache_size = 12GB
maintenance_work_mem = 1GB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 20971kB
min_wal_size = 2GB
max_wal_size = 8GB
max_worker_processes = 4
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
max_parallel_maintenance_workers = 2
```

### Backup Strategy

```bash
# Automated backups with pg_dump
#!/bin/bash
# /usr/local/bin/backup-perfanalysis.sh

BACKUP_DIR="/var/backups/perfanalysis"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="perfanalysis"
DB_USER="perfadmin"

# Create backup
pg_dump -U $DB_USER -Fc $DB_NAME > $BACKUP_DIR/perfanalysis_$DATE.dump

# Compress older backups
find $BACKUP_DIR -name "*.dump" -mtime +7 -exec gzip {} \;

# Delete old backups (keep 30 days)
find $BACKUP_DIR -name "*.dump.gz" -mtime +30 -delete

# Upload to S3 (optional)
aws s3 cp $BACKUP_DIR/perfanalysis_$DATE.dump s3://your-backup-bucket/perfanalysis/
```

**Crontab**:
```bash
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/backup-perfanalysis.sh
```

---

## Monitoring & Logging

### Prometheus + Grafana

**docker-compose monitoring stack**:
```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=changeme

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
```

### CloudWatch (AWS)

```python
# Add to Django settings
LOGGING['handlers']['cloudwatch'] = {
    'class': 'watchtower.CloudWatchLogHandler',
    'log_group': '/aws/perfanalysis',
    'stream_name': 'django-{instance_id}',
}
```

---

## Backup & Recovery

### Backup Checklist

- [ ] Database daily backups
- [ ] Media files weekly backups
- [ ] Configuration files backed up
- [ ] SSL certificates backed up
- [ ] Disaster recovery plan tested

### Recovery Procedures

**Database Restore**:
```bash
# Stop services
docker-compose down

# Restore database
pg_restore -U perfadmin -d perfanalysis -c perfanalysis_backup.dump

# Start services
docker-compose up -d
```

---

## Maintenance

### Regular Tasks

**Daily**:
- Monitor logs for errors
- Check system resources
- Verify backups completed

**Weekly**:
- Review security alerts
- Check disk space
- Review performance metrics

**Monthly**:
- Update dependencies
- Security patch review
- Disaster recovery test

### Update Procedure

```bash
# 1. Backup database
./backup-perfanalysis.sh

# 2. Pull latest code
git pull origin main

# 3. Update dependencies
docker-compose build

# 4. Run migrations
docker-compose exec xatbackend python manage.py migrate

# 5. Collect static files
docker-compose exec xatbackend python manage.py collectstatic --noinput

# 6. Restart services
docker-compose restart

# 7. Verify
make health
```

---

For performance optimization, see [PERFORMANCE_OPTIMIZATION.md](PERFORMANCE_OPTIMIZATION.md).
For security details, see [SECURITY.md](SECURITY.md).
For user documentation, see [USER_GUIDE.md](USER_GUIDE.md).
