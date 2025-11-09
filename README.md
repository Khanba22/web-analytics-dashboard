# 📊 Web Analytics Platform

A complete event-driven web analytics platform that collects, processes, and visualizes user interaction data using **Kafka**, **Python** (FastAPI + PySpark), and **Next.js**.

![Architecture](https://img.shields.io/badge/Architecture-Event--Driven-blue)
![Stack](https://img.shields.io/badge/Stack-Kafka%20%7C%20Python%20%7C%20Next.js-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 🎯 Features

- **Real-time Event Ingestion**: FastAPI endpoint accepts analytics events via HTTP POST
- **Event Stream Processing**: Kafka handles event distribution and durability
- **Persistent Logging**: Python consumer writes events to JSON Lines files
- **Batch Analytics**: PySpark ETL computes session metrics, page engagement, and CTR
- **Data Warehouse**: PostgreSQL stores aggregated analytics
- **Beautiful Dashboard**: Next.js frontend visualizes metrics with interactive charts
- **Containerized Deployment**: Complete Docker Compose orchestration

## 🧩 Architecture

```
[External SDKs/Services] 
        ↓ 
   HTTP POST /api/events
        ↓
   FastAPI Ingestion Service
        ↓
      Kafka Topic: web_events
        ↓
Python Consumer → *.jsonl logs
        ↓
PySpark ETL Job (every 5 min)
        ↓
     Postgres Database
        ↓
   Next.js Dashboard
```

## 📁 Project Structure

```
web-analytics-platform/
├── docker-compose.yml           # Orchestrates all services
├── global_config.yaml           # Shared configuration
├── postgres_init/               # Database schema initialization
│   └── 01_schema.sql
├── ingestion_api/               # FastAPI event ingestion service
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── python_consumer/             # Kafka consumer logging service
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── pyspark_cron/                # PySpark ETL batch processor
│   ├── etl_job.py
│   ├── etl_entrypoint.py
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/                    # Next.js Analytics Dashboard (TypeScript + App Router)
│   ├── app/
│   │   ├── api/analytics/
│   │   ├── components/
│   │   ├── page.tsx
│   │   └── layout.tsx
│   ├── package.json
│   └── Dockerfile
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+)
./s- **Python 3.7+** (for event simulator)
- At least **4GB RAM** available for containers

### 1️⃣ Clone or Navigate to Project

```bash
cd kafka-based-webanalytics
```

### 2️⃣ Configure Environment

Copy the example environment file and adjust values if needed:

```bash
cp .env.example .env
```

The defaults expose services on:
- Backend (ingestion API): `http://localhost:8000` (internal alias `http://backend:8000`)
- Frontend dashboard: `http://localhost:3000`
- Postgres: `localhost:5432`

Each service folder also contains an `.env.example` describing service-specific options:

| Service            | Example file                            |
|--------------------|------------------------------------------|
| Ingestion API      | `ingestion_api/.env.example`             |
| Python Consumer    | `python_consumer/.env.example`           |
| PySpark ETL        | `pyspark_cron/.env.example`              |
| Next.js Dashboard  | `frontend/.env.example`                  |

### 3️⃣ Start All Services

**Option A: Automated Setup (Recommended)**

Windows PowerShell:
```powershell
.\setup_and_start.ps1
```

Linux/Mac:
```bash
chmod +x setup_and_start.sh
./setup_and_start.sh
```

**Option B: Manual Start**

```bash
docker compose up -d --build
```

This command will:
- Build all Docker images
- Start Zookeeper and Kafka
- Initialize PostgreSQL with analytics schema
- Launch FastAPI ingestion service
- Start Python Kafka consumer
- Begin PySpark ETL scheduler
- Deploy Next.js dashboard

**⏱️ Initial startup takes ~2-3 minutes** for all services to become healthy.

### 3️⃣ Verify Services

Check that all containers are running:

```bash
docker compose ps
```

Expected output:
```
NAME                 STATUS
zookeeper            Up (healthy)
kafka                Up (healthy)
postgres             Up (healthy)
ingestion-api        Up
python-consumer      Up
pyspark-cron         Up
nextjs-dashboard     Up
```

### 4️⃣ Access the Dashboard

Open your browser and navigate to:

🌐 **http://localhost:3000**

You should see the analytics dashboard (initially empty until events are sent).

## 📤 Sending Test Events

### Option 1: Event Simulator (Recommended)

The event simulator generates realistic user behavior with configurable patterns.

**Install dependencies:**
```bash
pip install -r requirements-simulator.txt
```

**Run simulator:**
```bash
python event_simulator.py
```

**Configure simulation:**
Edit `event_simulator_config.yaml` to customize:
- Number of users (default: 10)
- Duration (default: 5 minutes)
- Event probabilities
- User behavior patterns

See [SIMULATOR_GUIDE.md](SIMULATOR_GUIDE.md) for detailed documentation.

---

### Option 2: Quick Test Script

Windows:
```powershell
.\test_events.ps1
```

Linux/Mac:
```bash
./test_events.sh
```

---

### Option 3: Manual curl Commands

#### Using curl (Windows PowerShell)

```powershell
# Session created event
curl -X POST http://localhost:8000/api/events `
     -H "Content-Type: application/json" `
     -d '{\"event_type\": \"session_created\", \"user_id\": \"user_001\", \"session_id\": \"session_001\"}'

# Page visited event
curl -X POST http://localhost:8000/api/events `
     -H "Content-Type: application/json" `
     -d '{\"event_type\": \"page_visited\", \"user_id\": \"user_001\", \"session_id\": \"session_001\", \"page_path\": \"/home\"}'

# Button clicked event
curl -X POST http://localhost:8000/api/events `
     -H "Content-Type: application/json" `
     -d '{\"event_type\": \"button_clicked\", \"user_id\": \"user_001\", \"session_id\": \"session_001\", \"page_path\": \"/home\", \"button_id\": \"signup_btn\"}'

# Page closed event
curl -X POST http://localhost:8000/api/events `
     -H "Content-Type: application/json" `
     -d '{\"event_type\": \"page_closed\", \"user_id\": \"user_001\", \"session_id\": \"session_001\", \"page_path\": \"/home\"}'

# Session ended event
curl -X POST http://localhost:8000/api/events `
     -H "Content-Type: application/json" `
     -d '{\"event_type\": \"session_ended\", \"user_id\": \"user_001\", \"session_id\": \"session_001\"}'
```

### Using curl (Linux/Mac)

```bash
# Session created event
curl -X POST http://localhost:8000/api/events \
     -H "Content-Type: application/json" \
     -d '{"event_type": "session_created", "user_id": "user_001", "session_id": "session_001"}'

# Page visited event
curl -X POST http://localhost:8000/api/events \
     -H "Content-Type: application/json" \
     -d '{"event_type": "page_visited", "user_id": "user_001", "session_id": "session_001", "page_path": "/home"}'

# Button clicked event
curl -X POST http://localhost:8000/api/events \
     -H "Content-Type: application/json" \
     -d '{"event_type": "button_clicked", "user_id": "user_001", "session_id": "session_001", "page_path": "/home", "button_id": "signup_btn"}'
```

### Bulk Test Script

Create a test script to send multiple events:

**Windows (PowerShell):**
```powershell
# test_events.ps1
1..10 | ForEach-Object {
    $userId = "user_$(Get-Random -Minimum 1 -Maximum 100)"
    $sessionId = "session_$(Get-Random -Minimum 1 -Maximum 50)"
    
    curl -X POST http://localhost:8000/api/events `
         -H "Content-Type: application/json" `
         -d "{`"event_type`": `"page_visited`", `"user_id`": `"$userId`", `"session_id`": `"$sessionId`", `"page_path`": `"/home`"}"
    
    Start-Sleep -Milliseconds 100
}
```

**Linux/Mac (Bash):**
```bash
#!/bin/bash
# test_events.sh

for i in {1..10}; do
    USER_ID="user_$(shuf -i 1-100 -n 1)"
    SESSION_ID="session_$(shuf -i 1-50 -n 1)"
    
    curl -X POST http://localhost:8000/api/events \
         -H "Content-Type: application/json" \
         -d "{\"event_type\": \"page_visited\", \"user_id\": \"$USER_ID\", \"session_id\": \"$SESSION_ID\", \"page_path\": \"/home\"}"
    
    sleep 0.1
done
```

---

### Internal Service Hostnames

Within the Docker network, services communicate via predefined aliases:

| Service           | Hostname     | Port |
|-------------------|--------------|------|
| Ingestion API      | `backend`    | 8000 |
| Kafka Broker       | `broker`     | 9092 |
| PostgreSQL         | `database`   | 5432 |
| PySpark ETL        | `etl`        | n/a  |
| Python Consumer    | `log-writer` | n/a  |
| Next.js Dashboard  | `frontend`   | 3000 |

For example, containers can queue events by sending HTTP requests to `http://backend:8000/api/events`.

## 📊 Event Schema

All events must include these fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `event_type` | string | ✅ | Type of event (e.g., `page_visited`, `button_clicked`) |
| `user_id` | string | ✅ | Unique user identifier |
| `session_id` | string | ✅ | Session identifier |
| `page_path` | string | ❌ | URL path (e.g., `/home`, `/products`) |
| `button_id` | string | ❌ | Button/element identifier |
| `props` | object | ❌ | Additional custom properties |

**Automatically added by API:**
- `event_id`: UUID v4
- `event_time`: ISO8601 timestamp (UTC)

## 🔍 Monitoring & Logs

### View Service Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f ingestion-api
docker compose logs -f python-consumer
docker compose logs -f pyspark-cron
docker compose logs -f nextjs-dashboard
```

### Check Event Logs (JSON Lines)

The Python consumer writes events to `/data/logs/`:

```bash
# View logs inside container
docker compose exec python-consumer cat /data/logs/events.jsonl
docker compose exec python-consumer cat /data/logs/sessions.jsonl
```

### Query Postgres Directly

```bash
# Connect to Postgres
docker compose exec postgres psql -U analytics -d analytics

# Example queries
SELECT * FROM session_metrics ORDER BY date DESC LIMIT 10;
SELECT * FROM page_engagement ORDER BY total_visits DESC LIMIT 10;
SELECT * FROM click_through_rates WHERE ctr > 0 ORDER BY ctr DESC LIMIT 10;
```

## ⚙️ Configuration

All services read from `global_config.yaml`. Key settings:

```yaml
kafka:
  bootstrap_servers: "kafka:9092"
  topic: "web_events"

cron:
  etl_interval_seconds: 300  # Run ETL every 5 minutes

postgres:
  host: "postgres"
  port: 5432
  db: "analytics"
  user: "analytics"
  password: "analytics_password"
```

**To change ETL frequency:**
1. Edit `etl_interval_seconds` in `global_config.yaml`
2. Restart PySpark service: `docker compose restart pyspark-cron`

## 🧪 Analytics Metrics Computed

| Metric | Description | Table |
|--------|-------------|-------|
| **Page Engagement** | Total visits, time spent, unique users per page | `page_engagement` |
| **Session Metrics** | Total sessions, avg duration, avg page views per day | `session_metrics` |
| **Click-Through Rate** | CTR = (clicks / views) × 100 for each button | `click_through_rates` |

## 🛠️ Troubleshooting

### Dashboard shows no data

1. **Wait 5-10 minutes** after sending events (ETL runs every 5 minutes)
2. Check if events were received:
   ```bash
   docker compose logs ingestion-api | grep "queued"
   ```
3. Verify consumer is logging events:
   ```bash
   docker compose logs python-consumer
   ```
4. Check ETL job execution:
   ```bash
   docker compose logs pyspark-cron
   ```

### Kafka connection errors

```bash
# Restart Kafka and dependent services
docker compose restart kafka
docker compose restart ingestion-api python-consumer
```

### Postgres connection errors

```bash
# Check Postgres is healthy
docker compose ps postgres

# Restart if needed
docker compose restart postgres pyspark-cron nextjs-dashboard
```

### Reset everything and start fresh

```bash
# Stop and remove all containers, volumes, and networks
docker compose down -v

# Rebuild and restart
docker compose up -d --build
```

## 🔌 API Endpoints

### FastAPI Ingestion Service (Port 8000)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/health` | GET | Detailed health status |
| `/api/events` | POST | Submit analytics event |

**Example Response:**
```json
{
  "status": "queued",
  "event_id": "a3b2c1d4-e5f6-7890-abcd-ef1234567890",
  "message": "Event successfully queued to web_events"
}
```

### Next.js Dashboard (Port 3000)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Dashboard homepage |
| `/api/analytics` | GET | Fetch analytics data (JSON) |

## 📦 Ports Used

| Service | Port | URL |
|---------|------|-----|
| FastAPI Ingestion | 8000 | http://localhost:8000 |
| Next.js Dashboard | 3000 | http://localhost:3000 |
| Postgres | 5432 | `localhost:5432` |
| Kafka | 9092 | `localhost:9092` |
| Zookeeper | 2181 | `localhost:2181` |

## 🎨 Dashboard Features

- **Real-time Updates**: Auto-refreshes every 60 seconds
- **Summary Cards**: Sessions, users, avg duration, page views (last 7 days)
- **Session Trends**: Line chart showing sessions and users over time
- **Page Engagement**: Bar chart of top pages by visits
- **Click Analytics**: Top clicked buttons with CTR percentages
- **Responsive Design**: Modern dark theme with smooth animations

## 🚧 Optional Enhancements (TODO)

Future improvements marked for implementation:

- [ ] **API Key Authentication**: Protect ingestion endpoint
- [ ] **Dead-Letter Queue**: Handle failed events
- [ ] **Spark Structured Streaming**: Real-time ETL instead of batch
- [ ] **ClickHouse Integration**: OLAP database for faster analytics
- [ ] **WebSocket Updates**: Real-time dashboard without polling
- [ ] **User Session Tracking**: Enhanced user journey analytics
- [ ] **Geolocation Data**: Track user locations
- [ ] **Custom Dashboard Filters**: Date range, user segments
- [ ] **Export Functionality**: CSV/PDF reports
- [ ] **Alerting System**: Notifications for anomalies

## 📄 License

MIT License - feel free to use this project for learning or commercial purposes.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## 📧 Support

For questions or issues:
1. Check the **Troubleshooting** section above
2. Review Docker logs: `docker compose logs`
3. Open an issue on GitHub

---

**Built with ❤️ using Kafka, Python, PySpark, Next.js, and Docker**

🚀 Happy Analytics!

#   w e b - a n a l y t i c s - d a s h b o a r d  
 