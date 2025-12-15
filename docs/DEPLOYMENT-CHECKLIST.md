# Deployment Checklist - WhatsApp AI Support Agent v2.0

**Print this checklist and check off items as you complete them**

---

## 📋 Pre-Deployment Preparation

### Server Setup
- [ ] Server provisioned (4GB RAM, 2 CPU cores, 40GB SSD minimum)
- [ ] Ubuntu 22.04 LTS installed
- [ ] SSH access configured
- [ ] Firewall rules set up (ports 22, 80, 443)
- [ ] Domain name registered
- [ ] DNS A record pointing to server IP
- [ ] DNS propagation verified (`ping your-domain.com`)

### Software Installation
- [ ] Docker installed (`docker --version`)
- [ ] Docker Compose installed (`docker-compose --version`)
- [ ] Git installed (`git --version`)
- [ ] Basic tools installed (curl, wget, openssl)
- [ ] User added to docker group (`groups $USER`)

### Accounts Created
- [ ] Meta Business Account
- [ ] Meta Developer Account
- [ ] OpenAI Account with API access
- [ ] Slack Workspace (optional, for handoffs)
- [ ] AWS Account (optional, for video storage)
- [ ] SMTP/Email account (optional, for notifications)

---

## 🔐 Credentials Collection

### WhatsApp Business API
- [ ] Phone Number ID: `____________________`
- [ ] Business Account ID: `____________________`
- [ ] Permanent Access Token: `____________________`
- [ ] Verify Token (generated): `____________________`

### OpenAI
- [ ] API Key: `sk-____________________`
- [ ] Account has sufficient credits
- [ ] API key has required permissions

### Database
- [ ] Database password generated: `____________________`
- [ ] Password saved securely

### n8n
- [ ] Basic auth username: `____________________`
- [ ] Basic auth password: `____________________`
- [ ] Encryption key generated: `____________________`

### Optional Services
- [ ] Slack Webhook URL: `____________________`
- [ ] SMTP credentials configured
- [ ] AWS Access Key ID: `____________________`
- [ ] AWS Secret Access Key: `____________________`
- [ ] S3 Bucket name: `____________________`

---

## 🚀 Phase 1: Repository & Environment

- [ ] Repository cloned: `git clone <repo-url>`
- [ ] Changed to project directory: `cd whatsapp-n8n-agent`
- [ ] Environment file created: `cp .env.example .env`
- [ ] All required variables filled in `.env`
- [ ] Encryption key generated and added
- [ ] Verify token generated and added
- [ ] Strong passwords set for all services
- [ ] `.env` file permissions set: `chmod 600 .env`

**Verification:**
```bash
cat .env | grep -E "WHATSAPP_|OPENAI_|DB_|N8N_" | head -20
```

---

## 💾 Phase 2: Database Setup

### PostgreSQL Container
- [ ] Start PostgreSQL: `docker-compose up -d postgres`
- [ ] Wait 30 seconds for initialization
- [ ] Verify running: `docker-compose ps postgres`
- [ ] Check logs: `docker-compose logs postgres | tail -20`

### Base Schema
- [ ] Copy base schema: `docker cp database-schema.sql postgres:/tmp/`
- [ ] Execute base schema: `docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent -f /tmp/database-schema.sql`
- [ ] Verify tables: `docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent -c "\dt"`
- [ ] Check sample data: Knowledge base entries visible
- [ ] Check sample data: Message templates visible

### Enhanced Schema
- [ ] Copy enhanced schema: `docker cp database-schema-enhanced.sql postgres:/tmp/`
- [ ] Execute enhanced schema: `docker-compose exec postgres psql -U n8n_user -d whatsapp_support_agent -f /tmp/database-schema-enhanced.sql`
- [ ] Verify new tables exist (handoff_requests, scheduled_messages, etc.)
- [ ] Check sample agents: `SELECT * FROM agent_availability;`
- [ ] Verify analytics views: `\dv`

**Verification:**
```sql
-- Should return 18+ tables
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
```

---

## 🔧 Phase 3: n8n Installation

### Service Startup
- [ ] Start all core services: `docker-compose up -d n8n postgres redis`
- [ ] Wait 60 seconds for n8n initialization
- [ ] Verify all services running: `docker-compose ps`
- [ ] Check n8n logs: `docker-compose logs n8n | tail -50`
- [ ] Access n8n UI: `http://YOUR_IP:5678`

### n8n Initial Setup
- [ ] Owner account created
- [ ] Email saved: `____________________`
- [ ] Password saved: `____________________`
- [ ] Successfully logged in to n8n

### Credentials Configuration
- [ ] **WhatsApp Business Cloud** credential created
  - [ ] Access Token added
  - [ ] Phone Number ID added
  - [ ] Credential saved

- [ ] **OpenAI** credential created
  - [ ] API Key added
  - [ ] Credential saved
  - [ ] Test connection successful

- [ ] **PostgreSQL** credential created
  - [ ] Host: `postgres`
  - [ ] Database: `whatsapp_support_agent`
  - [ ] User: `n8n_user`
  - [ ] Password from .env
  - [ ] Port: `5432`
  - [ ] SSL: Disabled
  - [ ] Test connection successful ✅

**Verification:**
```bash
curl http://localhost:5678/healthz
# Should return 200 OK
```

---

## 🔄 Phase 4: Workflow Deployment

### Main Workflow
- [ ] File located: `whatsapp-support-agent-workflow.json`
- [ ] Import workflow in n8n UI
- [ ] All nodes visible (20+ nodes)
- [ ] Update WhatsApp credentials in all orange nodes
- [ ] Update OpenAI credentials in all purple nodes
- [ ] Update PostgreSQL credentials in all database nodes
- [ ] No credential errors remaining
- [ ] Workflow saved
- [ ] Workflow activated (toggle to green)
- [ ] Webhook URL copied: `____________________`

### Proactive Messaging Workflow
- [ ] File located: `workflows/proactive-messaging-workflow.json`
- [ ] Import workflow in n8n UI
- [ ] Update all credentials
- [ ] Schedule trigger configured (every 5 minutes)
- [ ] No errors
- [ ] Workflow saved
- [ ] Workflow activated

**Verification:**
```bash
# Check webhook is accessible
curl -X GET http://localhost:5678/webhook/whatsapp-webhook?hub.mode=subscribe&hub.verify_token=YOUR_TOKEN&hub.challenge=test
# Should return "test"
```

---

## 🎯 Phase 5: Enhanced Features

### Human Handoff Setup

**Option A: Slack Integration**
- [ ] Slack app created
- [ ] Incoming webhook enabled
- [ ] Webhook URL obtained
- [ ] Added to .env: `SLACK_WEBHOOK_URL=...`
- [ ] Channel created: `#customer-support`
- [ ] Test message sent successfully

**Option B: Email Integration**
- [ ] SMTP settings configured in .env
- [ ] Test email sent successfully

**Option C: Custom Webhook**
- [ ] Webhook URL configured
- [ ] Authentication configured
- [ ] Test request successful

**Agents Added:**
- [ ] Added at least one agent to database
- [ ] Agent status set to 'online'
- [ ] Verified: `SELECT * FROM agent_availability;`

### Proactive Messaging
- [ ] Proactive messaging workflow active
- [ ] Template variables configured
- [ ] Test message scheduled
- [ ] Test message sent successfully
- [ ] Message status verified in database

### Voice Responses (Optional)
- [ ] `ENABLE_VOICE_RESPONSES=true` in .env
- [ ] Voice preference configured
- [ ] Test user voice enabled in database
- [ ] Voice response received and working

### Video Support (Optional)
- [ ] `ENABLE_VIDEO_SUPPORT=true` in .env
- [ ] Cloud storage configured (AWS S3/GCS/Azure)
- [ ] Bucket created and accessible
- [ ] Credentials configured
- [ ] Test video upload successful

**Restart Services:**
- [ ] Services restarted: `docker-compose down && docker-compose up -d`
- [ ] All services running: `docker-compose ps`
- [ ] No errors in logs

---

## 🔗 Phase 6: WhatsApp Integration

### Webhook Configuration
- [ ] Meta Developer Dashboard accessed
- [ ] Navigate to WhatsApp → Configuration
- [ ] Webhook section found
- [ ] Click "Edit"
- [ ] Callback URL entered: `https://your-domain.com/webhook/whatsapp-webhook`
- [ ] Verify token entered (from .env)
- [ ] Click "Verify and Save"
- [ ] Status shows "✅ Verified"
- [ ] Click "Manage"
- [ ] Subscribe to "messages" field ✅
- [ ] Changes saved

### Test Phone Number
- [ ] Test number added in WhatsApp API Setup
- [ ] Verification code received
- [ ] Number verified successfully

**Verification:**
- [ ] Check n8n Executions tab for verification request
- [ ] Should see successful execution

---

## ✅ Phase 7: Testing

### Basic Messaging
- [ ] **Test 1:** Send "Hello" from phone
- [ ] Response received within 5 seconds
- [ ] Response is relevant AI-generated text
- [ ] Execution visible in n8n
- [ ] All nodes in execution are green

### Multimodal Support
- [ ] **Test 2:** Send voice message "What is n8n?"
- [ ] Voice transcribed correctly
- [ ] Response relevant to question
- [ ] Entry in messages table

- [ ] **Test 3:** Send image with caption
- [ ] Image analyzed
- [ ] Response describes image
- [ ] Entry in messages table

- [ ] **Test 4:** Send PDF document
- [ ] Document acknowledged
- [ ] Entry in messages table

- [ ] **Test 5:** Send video (if enabled)
- [ ] Video received and processed
- [ ] Entry in video_processing table

### Conversation Memory
- [ ] **Test 6:** Send "My name is John"
- [ ] Send "What's my name?"
- [ ] Bot remembers "John"
- [ ] Conversation history saved

### Human Handoff
- [ ] **Test 7:** Send "I want to speak to a human"
- [ ] Handoff triggered
- [ ] Notification received (Slack/Email)
- [ ] Entry in handoff_requests table

### Proactive Messaging
- [ ] **Test 8:** Schedule message for +2 minutes
- [ ] Wait 5-7 minutes
- [ ] Message received on WhatsApp
- [ ] Status updated to 'sent' in database

### Voice Response (if enabled)
- [ ] **Test 9:** Ask long question
- [ ] Audio response received
- [ ] Audio plays correctly
- [ ] Entry in voice_responses table

### Analytics
- [ ] **Test 10:** Check message_stats view
- [ ] Today's stats show all test messages
- [ ] ai_performance_stats has data
- [ ] active_users_stats shows 1+ user

**All Tests Passed:** [ ]

---

## 🔒 Phase 8: Production Hardening

### SSL Certificate
- [ ] Certbot installed
- [ ] SSL certificate obtained for domain
- [ ] Certificate files exist in `/etc/letsencrypt/live/`
- [ ] Certificate valid (check expiry date)
- [ ] Auto-renewal configured in cron

### Nginx Setup
- [ ] Nginx configuration updated with domain name
- [ ] SSL paths updated in nginx.conf
- [ ] Nginx container started: `docker-compose --profile production up -d nginx`
- [ ] Nginx running: `docker-compose ps nginx`
- [ ] HTTPS accessible: `curl https://your-domain.com/healthz`

### Security
- [ ] Default passwords changed in .env
- [ ] Database password changed
- [ ] n8n auth password changed
- [ ] Services restarted with new passwords
- [ ] `.env` file permissions: `chmod 600 .env`
- [ ] Root SSH login disabled
- [ ] Fail2ban installed and running
- [ ] UFW firewall configured and enabled

### WhatsApp HTTPS Update
- [ ] Meta webhook updated to HTTPS URL
- [ ] Re-verified successfully
- [ ] Test message works via HTTPS

**Production Verification:**
- [ ] `curl https://your-domain.com/healthz` returns 200
- [ ] SSL certificate valid (no browser warnings)
- [ ] WhatsApp messages working via HTTPS

---

## 📊 Phase 9: Monitoring Setup

### Automated Backups
- [ ] Backup directory created: `/opt/backups`
- [ ] Backup script created: `/opt/backups/backup-whatsapp-agent.sh`
- [ ] Script executable: `chmod +x`
- [ ] Script tested manually
- [ ] Backup files created successfully
- [ ] Cron job scheduled (daily 2 AM)
- [ ] Verified cron: `crontab -l`

### Database Maintenance
- [ ] Maintenance script created: `/opt/backups/db-maintenance.sh`
- [ ] Script executable
- [ ] Script tested manually
- [ ] Cron job scheduled (weekly Sunday 3 AM)

### Health Checks
- [ ] Health check script created: `/usr/local/bin/check-whatsapp-agent.sh`
- [ ] Script executable
- [ ] Script tested manually
- [ ] All services detected correctly
- [ ] Cron job scheduled (every 5 minutes)

### Log Management
- [ ] Log rotation configured: `/etc/logrotate.d/docker-containers`
- [ ] Log rotation tested
- [ ] Old logs being compressed

### Monitoring Dashboard (Optional)
- [ ] Monitoring tool installed (Grafana/Prometheus)
- [ ] Dashboard accessible
- [ ] Key metrics visible

---

## 📝 Phase 10: Documentation

### Internal Documentation
- [ ] Server details documented
  - IP address: `____________________`
  - Domain: `____________________`
  - SSH key location: `____________________`

- [ ] Credentials documented securely
  - Location: `____________________`
  - Backup location: `____________________`

- [ ] Team trained on system
  - Admin access: `____________________`
  - Support access: `____________________`

### Emergency Contacts
- [ ] Primary admin: `____________________ / ____________________`
- [ ] Secondary admin: `____________________ / ____________________`
- [ ] Hosting provider support: `____________________`
- [ ] Meta support case ID (if any): `____________________`

---

## 🎯 Final Validation

### System Health
- [ ] All containers running: `docker-compose ps`
- [ ] No errors in logs: `docker-compose logs --tail=100`
- [ ] Disk space adequate: `df -h` (>50% free)
- [ ] Memory usage normal: `free -h` (<80% used)
- [ ] CPU usage normal: `htop` (<50% avg)

### Database Health
- [ ] Database accessible
- [ ] All tables present (18+ tables)
- [ ] Sample data present
- [ ] Analytics views working
- [ ] Queries executing quickly (<100ms)

### Workflow Health
- [ ] Both workflows active
- [ ] No execution errors in last 24 hours
- [ ] Recent test executions successful
- [ ] Webhook responding correctly

### Feature Health
- [ ] WhatsApp messages working ✅
- [ ] AI responses relevant and fast ✅
- [ ] Voice transcription working (if tested) ✅
- [ ] Image analysis working (if tested) ✅
- [ ] Human handoff working (if tested) ✅
- [ ] Proactive messaging working (if tested) ✅
- [ ] Voice responses working (if enabled) ✅
- [ ] Video processing working (if enabled) ✅

### Production Readiness
- [ ] HTTPS working correctly
- [ ] SSL certificate valid
- [ ] Backups running daily
- [ ] Monitoring in place
- [ ] Alerts configured
- [ ] Documentation complete
- [ ] Team trained
- [ ] Support plan in place

---

## ✅ Deployment Complete!

**Date Completed:** `____________________`

**Deployed By:** `____________________`

**Production URL:** `____________________`

**Notes:**
```
_________________________________________________________________________

_________________________________________________________________________

_________________________________________________________________________

_________________________________________________________________________
```

---

## 📞 Support Resources

### Documentation
- [ ] README.md - Overview and features
- [ ] DEPLOYMENT-V2.md - Complete deployment guide
- [ ] FEATURES.md - Enhanced features guide
- [ ] QUICK-REFERENCE.md - Command reference
- [ ] ARCHITECTURE.md - System architecture

### Community Support
- [ ] n8n Community: https://community.n8n.io
- [ ] WhatsApp Business Docs: https://developers.facebook.com/docs/whatsapp
- [ ] OpenAI API Docs: https://platform.openai.com/docs

### Commercial Support
- [ ] n8n Enterprise Support (if subscribed)
- [ ] Custom development support contact: `____________________`

---

## 🔄 Post-Deployment Tasks

### Week 1
- [ ] Monitor error logs daily
- [ ] Check cost usage daily
- [ ] Verify backups working
- [ ] Review analytics data
- [ ] Collect user feedback

### Week 2
- [ ] Review performance metrics
- [ ] Optimize slow queries
- [ ] Adjust AI prompts based on feedback
- [ ] Fine-tune handoff triggers

### Month 1
- [ ] Review monthly costs
- [ ] Analyze usage patterns
- [ ] Plan feature enhancements
- [ ] Update documentation based on learnings
- [ ] Schedule maintenance window

---

**🎉 Congratulations! Your WhatsApp AI Support Agent v2.0 is now fully deployed and operational!**

Keep this checklist for future reference and for deploying additional instances.
