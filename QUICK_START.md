# ⚡ Quick Start Guide

## 🎯 Start Everything in 3 Steps

### 1️⃣ Start All Services
```powershell
docker compose up -d --build
```

### 2️⃣ Send Test Events
```powershell
.\test_events.ps1
```

### 3️⃣ View Dashboard
Open your browser: **http://localhost:3000**

---

## 📊 What You'll See

### After 5-10 minutes (ETL processing time):
- 📈 **Total Sessions** card with count
- 👥 **Active Users** card with count
- ⏱️ **Avg Session Duration** card with time
- 📄 **Page Views** card with count
- 📈 **Session Trends** line chart
- 📄 **Top Pages** bar chart
- 🖱️ **Click Analytics** bar chart & table

---

## 🔗 Service URLs

| Service | URL |
|---------|-----|
| **Dashboard** | http://localhost:3000 |
| **API Ingestion** | http://localhost:8000 |
| **API Health Check** | http://localhost:8000/health |

---

## 📤 Send Custom Event

```powershell
curl -X POST http://localhost:8000/api/events `
     -H "Content-Type: application/json" `
     -d '{\"event_type\": \"page_visited\", \"user_id\": \"user_123\", \"session_id\": \"session_456\", \"page_path\": \"/dashboard\"}'
```

---

## 🛑 Stop Everything

```powershell
# Stop (keeps data)
docker compose down

# Stop and delete all data
docker compose down -v
```

---

## 📋 View Logs

```powershell
# All services
docker compose logs -f

# Specific service
docker compose logs -f nextjs-dashboard
docker compose logs -f ingestion-api
docker compose logs -f pyspark-cron
```

---

## 🐛 Troubleshooting

### Dashboard shows "Error connecting to analytics API"
1. Wait 2-3 minutes for services to start
2. Check if Postgres is healthy: `docker compose ps postgres`
3. Restart dashboard: `docker compose restart nextjs-dashboard`

### No data appears
1. Send events: `.\test_events.ps1`
2. Wait 5-10 minutes for ETL to process
3. Check consumer logs: `docker compose logs python-consumer`
4. Check ETL logs: `docker compose logs pyspark-cron`

### Port already in use
```powershell
# Find what's using port 3000
netstat -ano | findstr :3000

# Stop that process or change port in docker-compose.yml
```

---

## 🎓 Next Steps

1. ✅ Platform running
2. ✅ Events flowing
3. ✅ Dashboard showing data
4. 📊 Customize metrics in `pyspark_cron/etl_job.py`
5. 🎨 Update UI in `frontend/app/page.tsx`
6. 📈 Add new charts in `frontend/app/components/Charts.tsx`
7. 🔌 Integrate with your application

---

**That's it! You're analytics platform is live! 🎉**

