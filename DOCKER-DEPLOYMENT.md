# Docker Compose Deployment Guide

Complete guide for deploying the WhatsApp AI Support Agent v2.0 using Docker Compose.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Container Services](#container-services)
3. [Deployment Profiles](#deployment-profiles)
4. [Quick Start](#quick-start)
5. [Production Deployment](#production-deployment)
6. [Configuration](#configuration)
7. [Monitoring](#monitoring)
8. [Backup & Restore](#backup--restore)
9. [Troubleshooting](#troubleshooting)
10. [Resource Requirements](#resource-requirements)

---

## Overview

The docker-compose.yml file provides a **complete, production-ready deployment** with:

### All Container Names Prefixed with `WPSupport_`

✅ **Core Services** (3):
- `WPSupport_n8n` - Workflow automation engine
- `WPSupport_postgres` - PostgreSQL with pgvector for RAG
- `WPSupport_redis` - Caching and queue management

✅ **Storage Services** (2):
- `WPSupport_minio` - S3-compatible object storage for videos/media
- `WPSupport_minio_client` - Auto-creates storage buckets

✅ **Vector Database** (1):
- `WPSupport_qdrant` - Vector database for RAG

✅ **Reverse Proxy & SSL** (2):
- `WPSupport_nginx` - Reverse proxy
- `WPSupport_certbot` - SSL certificate management

✅ **Monitoring** (2):
- `WPSupport_prometheus` - Metrics collection
- `WPSupport_grafana` - Monitoring dashboards

✅ **Backup** (1):
- `WPSupport_postgres_backup` - Automated database backups

✅ **Development Tools** (2):
- `WPSupport_pgadmin` - PostgreSQL management UI
- `WPSupport_redis_commander` - Redis management UI

**Total: 13 containers** (core services always run, others are profile-based)

---

## Container Services

### Core Services (Always Running)

#### WPSupport_n8n
- **Purpose**: Workflow automation engine for WhatsApp AI agent
- **Image**: `n8nio/n8n:latest`
- **Port**: 5678
- **Features**:
  - Queue mode enabled for high performance
  - Enhanced payload limit (32MB) for video support
  - Metrics enabled for Prometheus monitoring
  - Auto-loads workflows from `/home/node/workflows/`
- **Resources**:
  - Limit: 2 CPU, 2GB RAM
  - Reservation: 0.5 CPU, 512MB RAM

#### WPSupport_postgres
- **Purpose**: Main database with pgvector extension for RAG
- **Image**: `ankane/pgvector:latest`
- **Port**: 5432
- **Features**:
  - Auto-initializes both base and enhanced schemas
  - Performance-tuned for production
  - Healthcheck enabled
  - Supports up to 200 connections
- **Resources**:
  - Limit: 2 CPU, 4GB RAM
  - Reservation: 0.5 CPU, 1GB RAM
- **Schemas Initialized**:
  - `01-base-schema.sql` - 8 core tables
  - `02-enhanced-schema.sql` - 10 v2.0 feature tables

#### WPSupport_redis
- **Purpose**: Caching, session storage, and n8n queue backend
- **Image**: `redis:7-alpine`
- **Port**: 6379
- **Features**:
  - Persistence enabled (AOF + RDB)
  - 512MB max memory with LRU eviction
  - Optional password protection
- **Resources**:
  - Limit: 1 CPU, 1GB RAM
  - Reservation: 0.25 CPU, 256MB RAM

### Storage Services (Profile: `storage` or `production`)

#### WPSupport_minio
- **Purpose**: S3-compatible object storage for videos, voice, and media files
- **Image**: `minio/minio:latest`
- **Ports**: 9000 (API), 9001 (Console)
- **Features**:
  - Web console for file management
  - S3-compatible API
  - Auto-creates buckets: `whatsapp-videos`, `whatsapp-voice`, `whatsapp-media`
- **Resources**:
  - Limit: 1 CPU, 2GB RAM
  - Reservation: 0.25 CPU, 512MB RAM

#### WPSupport_minio_client
- **Purpose**: One-time initialization of MinIO buckets
- **Image**: `minio/mc:latest`
- **Lifecycle**: Runs once and exits
- **Creates**:
  - `whatsapp-videos` (public download)
  - `whatsapp-voice` (public download)
  - `whatsapp-media` (public download)

### Vector Database (Profile: `rag` or `production`)

#### WPSupport_qdrant
- **Purpose**: Vector database for Retrieval Augmented Generation (RAG)
- **Image**: `qdrant/qdrant:latest`
- **Ports**: 6333 (HTTP), 6334 (gRPC)
- **Features**:
  - REST and gRPC APIs
  - Persistent storage
  - Optional API key authentication
- **Resources**:
  - Limit: 1 CPU, 2GB RAM
  - Reservation: 0.25 CPU, 512MB RAM

### Reverse Proxy & SSL (Profile: `production`)

#### WPSupport_nginx
- **Purpose**: Reverse proxy with SSL termination
- **Image**: `nginx:alpine`
- **Ports**: 80 (HTTP), 443 (HTTPS)
- **Features**:
  - SSL/TLS termination
  - Request routing to n8n
  - Static file serving
- **Configuration**: `nginx/nginx.conf`

#### WPSupport_certbot
- **Purpose**: Automatic SSL certificate management
- **Image**: `certbot/certbot:latest`
- **Features**:
  - Auto-renewal every 12 hours
  - Let's Encrypt integration
  - Wildcard certificate support

### Monitoring (Profile: `monitoring` or `production`)

#### WPSupport_prometheus
- **Purpose**: Metrics collection and time-series database
- **Image**: `prom/prometheus:latest`
- **Port**: 9090
- **Scrapes**:
  - n8n metrics
  - PostgreSQL metrics
  - Redis metrics
  - MinIO metrics
  - Qdrant metrics
- **Retention**: 30 days (configurable)
- **Configuration**: `monitoring/prometheus.yml`

#### WPSupport_grafana
- **Purpose**: Monitoring dashboards and visualization
- **Image**: `grafana/grafana:latest`
- **Port**: 3000
- **Features**:
  - Pre-configured datasources (Prometheus, PostgreSQL, Redis)
  - Custom dashboards
  - Alerting capabilities
- **Default Login**: admin/admin (change in production!)

### Backup (Profile: `backup` or `production`)

#### WPSupport_postgres_backup
- **Purpose**: Automated PostgreSQL database backups
- **Image**: `prodrigestivill/postgres-backup-local:latest`
- **Features**:
  - Daily automated backups (configurable schedule)
  - Retention policy: 7 days / 4 weeks / 6 months
  - Compression enabled
  - Healthcheck on port 8080
- **Backup Location**: `./backups/`

### Development Tools (Profile: `development` or `tools`)

#### WPSupport_pgadmin
- **Purpose**: PostgreSQL database management GUI
- **Image**: `dpage/pgadmin4:latest`
- **Port**: 8080
- **Default Login**: admin@wpsupport.local/admin
- **Features**:
  - Visual query builder
  - Schema browser
  - Data import/export

#### WPSupport_redis_commander
- **Purpose**: Redis management GUI
- **Image**: `rediscommander/redis-commander:latest`
- **Port**: 8081
- **Features**:
  - Key browser
  - Real-time monitoring
  - CLI interface

---

## Deployment Profiles

The docker-compose.yml uses **profiles** to enable optional services:

| Profile | Services Enabled | Use Case |
|---------|-----------------|----------|
| *(none)* | n8n, postgres, redis | Quick start, development |
| `storage` | + MinIO | Video/media support |
| `rag` | + Qdrant | Vector search, RAG |
| `monitoring` | + Prometheus, Grafana | Performance monitoring |
| `backup` | + postgres-backup | Automated backups |
| `production` | All production services | Full production deployment |
| `development` | + pgAdmin, Redis Commander | Development with tools |
| `tools` | + pgAdmin, Redis Commander | Management tools only |

### Combining Profiles

You can combine multiple profiles:

```bash
# Production with monitoring and backups
docker-compose --profile production --profile monitoring --profile backup up -d

# Development with all tools
docker-compose --profile development --profile storage --profile rag up -d
```

---

## Quick Start

### 1. Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM minimum
- 20GB disk space

### 2. Clone Repository

```bash
git clone https://github.com/yourusername/Claude2-WP-Support-agent.git
cd Claude2-WP-Support-agent
```

### 3. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Generate encryption key
openssl rand -hex 32

# Edit .env and set required variables
nano .env
```

**Required variables:**
```bash
# WhatsApp
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id
WHATSAPP_ACCESS_TOKEN=your_access_token
WHATSAPP_VERIFY_TOKEN=your_verify_token

# OpenAI
OPENAI_API_KEY=sk-your_key

# Database
DB_PASSWORD=your_secure_password

# n8n
N8N_ENCRYPTION_KEY=your_generated_key_from_step_above
N8N_BASIC_AUTH_PASSWORD=your_n8n_password
```

### 4. Start Core Services

```bash
# Start n8n, PostgreSQL, and Redis
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f WPSupport_n8n
```

### 5. Access n8n

Open browser: `http://localhost:5678`

Create account and import workflows:
- `whatsapp-support-agent-workflow.json`
- `workflows/proactive-messaging-workflow.json`

### 6. Configure Webhooks

Get your webhook URL: `http://localhost:5678/webhook/whatsapp-webhook`

For production, use your domain: `https://yourdomain.com/webhook/whatsapp-webhook`

---

## Production Deployment

### Full Production Stack

```bash
# Start all production services
docker-compose --profile production up -d
```

This includes:
- ✅ n8n, PostgreSQL, Redis (core)
- ✅ MinIO (video/media storage)
- ✅ Qdrant (vector database)
- ✅ Nginx + Certbot (SSL)
- ✅ Prometheus + Grafana (monitoring)
- ✅ PostgreSQL Backup

### Production Configuration Steps

#### 1. Domain Setup

```bash
# Update .env
NGINX_DOMAIN=yourdomain.com
CERTBOT_EMAIL=admin@yourdomain.com
N8N_WEBHOOK_URL=https://yourdomain.com
```

#### 2. SSL Certificate

First, start nginx without SSL:

```bash
docker-compose up -d WPSupport_nginx
```

Then obtain certificate:

```bash
docker-compose run --rm WPSupport_certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@yourdomain.com \
  --agree-tos \
  --no-eff-email \
  -d yourdomain.com
```

#### 3. Nginx SSL Configuration

Create `nginx/conf.d/n8n.conf`:

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://WPSupport_n8n:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### 4. Security Hardening

Update `.env`:

```bash
# Change default passwords
DB_PASSWORD=$(openssl rand -base64 32)
N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 16)
MINIO_ROOT_PASSWORD=$(openssl rand -base64 16)
GRAFANA_PASSWORD=$(openssl rand -base64 16)
PGADMIN_PASSWORD=$(openssl rand -base64 16)

# Enable security features
REDIS_PASSWORD=$(openssl rand -base64 16)
QDRANT_API_KEY=$(openssl rand -base64 32)
```

#### 5. Resource Limits

For production, adjust limits in `docker-compose.yml` based on your server:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
    reservations:
      cpus: '1'
      memory: 2G
```

---

## Configuration

### Environment Variables

See `.env.example` for all variables. Key sections:

#### Core Services
- `DB_*` - PostgreSQL configuration
- `REDIS_*` - Redis configuration
- `N8N_*` - n8n configuration

#### v2.0 Features
- `ENABLE_HUMAN_HANDOFF` - Human handoff feature
- `ENABLE_PROACTIVE_MESSAGING` - Proactive messaging
- `ENABLE_VOICE_RESPONSES` - Voice responses
- `ENABLE_VIDEO_SUPPORT` - Video support

#### Storage
- `MINIO_*` - MinIO S3-compatible storage
- `AWS_*` - AWS S3 (alternative to MinIO)

#### Monitoring
- `PROMETHEUS_*` - Prometheus configuration
- `GRAFANA_*` - Grafana configuration

### Volume Management

All volumes are prefixed with `wpsupport_`:

```bash
# List volumes
docker volume ls | grep wpsupport

# Backup volume
docker run --rm -v wpsupport_postgres_data:/data -v $(pwd)/backup:/backup alpine tar czf /backup/postgres_data.tar.gz /data

# Restore volume
docker run --rm -v wpsupport_postgres_data:/data -v $(pwd)/backup:/backup alpine tar xzf /backup/postgres_data.tar.gz -C /
```

### Network Configuration

All containers use the `wpsupport_network` bridge network:

- Subnet: 172.28.0.0/16
- Gateway: 172.28.0.1
- DNS: Automatic

Containers can reference each other by service name (e.g., `WPSupport_postgres:5432`).

---

## Monitoring

### Access Monitoring Tools

#### Grafana Dashboard
```
http://localhost:3000
Login: admin/admin (change password!)
```

#### Prometheus
```
http://localhost:9090
```

#### MinIO Console
```
http://localhost:9001
Login: minioadmin/minioadmin123
```

### Key Metrics to Monitor

1. **n8n Performance**
   - Execution queue length
   - Failed executions
   - Response time

2. **Database**
   - Connection pool usage
   - Query performance
   - Database size

3. **Redis**
   - Memory usage
   - Hit/miss ratio
   - Connected clients

4. **System Resources**
   - CPU usage
   - Memory usage
   - Disk I/O

---

## Backup & Restore

### Automated Backups

Backups run automatically based on `BACKUP_SCHEDULE`:

```bash
# Check backup logs
docker-compose logs WPSupport_postgres_backup

# List backups
ls -lh ./backups/
```

### Manual Backup

```bash
# Database backup
docker-compose exec WPSupport_postgres pg_dump -U n8n_user whatsapp_support_agent > backup_$(date +%Y%m%d).sql

# n8n data backup
docker run --rm -v wpsupport_n8n_data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/n8n_data_$(date +%Y%m%d).tar.gz /data

# All volumes backup
./scripts/backup-all.sh  # If you create this script
```

### Restore from Backup

```bash
# Stop services
docker-compose down

# Restore database
cat backup_20251214.sql | docker-compose exec -T WPSupport_postgres psql -U n8n_user whatsapp_support_agent

# Restore n8n data
docker run --rm -v wpsupport_n8n_data:/data -v $(pwd)/backups:/backup alpine tar xzf /backup/n8n_data_20251214.tar.gz -C /

# Restart services
docker-compose up -d
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs WPSupport_[service_name]

# Check resource usage
docker stats

# Verify environment variables
docker-compose config
```

### Database Connection Errors

```bash
# Check if PostgreSQL is healthy
docker-compose exec WPSupport_postgres pg_isready -U n8n_user

# Check connectivity from n8n
docker-compose exec WPSupport_n8n ping WPSupport_postgres

# View PostgreSQL logs
docker-compose logs WPSupport_postgres
```

### Webhook Not Receiving Messages

```bash
# Check if n8n is accessible
curl http://localhost:5678/healthz

# Check workflow is active
docker-compose exec WPSupport_n8n n8n list:workflow

# Check nginx logs (if using)
docker-compose logs WPSupport_nginx
```

### High Memory Usage

```bash
# Check container memory
docker stats --no-stream

# Reduce n8n payload limit
# In .env: N8N_PAYLOAD_SIZE_MAX=16

# Reduce Redis max memory
# In .env: REDIS_MAXMEMORY=256mb
```

### MinIO Connection Issues

```bash
# Check MinIO is running
docker-compose ps WPSupport_minio

# Test MinIO endpoint
curl http://localhost:9000/minio/health/live

# Check bucket creation
docker-compose logs WPSupport_minio_client
```

---

## Resource Requirements

### Minimum (Development)

- **CPU**: 2 cores
- **RAM**: 4GB
- **Disk**: 20GB
- **Services**: n8n, PostgreSQL, Redis

### Recommended (Production - Basic)

- **CPU**: 4 cores
- **RAM**: 8GB
- **Disk**: 50GB
- **Services**: Core + Storage + Backup

### Recommended (Production - Full Stack)

- **CPU**: 8 cores
- **RAM**: 16GB
- **Disk**: 100GB
- **Services**: All services with monitoring

### Per-Service Resources

| Service | CPU Limit | RAM Limit | Storage |
|---------|-----------|-----------|---------|
| n8n | 2 CPU | 2GB | 5GB |
| PostgreSQL | 2 CPU | 4GB | 10-50GB |
| Redis | 1 CPU | 1GB | 1GB |
| MinIO | 1 CPU | 2GB | 20-100GB |
| Qdrant | 1 CPU | 2GB | 5-20GB |
| Prometheus | 0.5 CPU | 1GB | 10GB |
| Grafana | 0.5 CPU | 512MB | 1GB |
| Nginx | 0.5 CPU | 256MB | 100MB |

---

## Useful Commands

```bash
# Start all services
docker-compose up -d

# Start with specific profile
docker-compose --profile production up -d

# Stop all services
docker-compose down

# Stop and remove volumes (DANGEROUS!)
docker-compose down -v

# Restart a single service
docker-compose restart WPSupport_n8n

# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f WPSupport_n8n

# Check service status
docker-compose ps

# Execute command in container
docker-compose exec WPSupport_postgres psql -U n8n_user

# Update images
docker-compose pull
docker-compose up -d

# Scale n8n workers (if using workers)
docker-compose up -d --scale n8n-worker=3

# Remove stopped containers
docker-compose rm

# Validate configuration
docker-compose config

# Show resource usage
docker stats $(docker-compose ps -q)
```

---

## Next Steps

1. ✅ Deploy with `docker-compose up -d`
2. ✅ Access n8n at `http://localhost:5678`
3. ✅ Import workflows
4. ✅ Configure WhatsApp webhook
5. ✅ Test with a message
6. ✅ Enable production profile for full features
7. ✅ Set up monitoring with Grafana
8. ✅ Configure automated backups

For detailed deployment instructions, see:
- **[DEPLOYMENT-V2.md](DEPLOYMENT-V2.md)** - Complete v2.0 deployment
- **[FEATURES.md](FEATURES.md)** - v2.0 features implementation
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Command reference

---

**Congratulations!** You now have a comprehensive understanding of the Docker Compose deployment for WhatsApp AI Support Agent v2.0! 🚀
