# 🎉 New Scripts Summary

Two powerful scripts have been created for your Web Analytics Platform:

---

## 1️⃣ Complete Setup & Start Script

### 📁 Files Created
- `setup_and_start.ps1` (Windows PowerShell)
- `setup_and_start.sh` (Linux/Mac Bash)

### 🎯 Purpose
**One-command setup** that handles everything from prerequisites checking to service startup.

### ✨ Features

#### Automated Checks
- ✅ Docker installation verification
- ✅ Docker daemon status
- ✅ Docker Compose availability
- ✅ System memory check (warns if < 4GB)
- ✅ Configuration file validation

#### Smart Cleanup
- Optional cleanup of previous installations
- Removes containers and volumes
- Preserves data by default

#### Build & Deploy
- Builds all Docker images
- Starts services with health checks
- Waits for services to be ready

#### Real-time Monitoring
- Shows service startup progress
- Health check status for each service
- Elapsed time tracking

#### Helpful Summary
- Access URLs for all services
- Next steps instructions
- Useful command references

### 🚀 Usage

**Windows:**
```powershell
# Basic usage
.\setup_and_start.ps1

# With options
.\setup_and_start.ps1 -Clean        # Clean previous installation
.\setup_and_start.ps1 -Rebuild      # Force rebuild all images
.\setup_and_start.ps1 -SkipChecks   # Skip prerequisite checks
```

**Linux/Mac:**
```bash
# Make executable (first time only)
chmod +x setup_and_start.sh

# Basic usage
./setup_and_start.sh

# With options
./setup_and_start.sh --clean        # Clean previous installation
./setup_and_start.sh --rebuild      # Force rebuild all images
./setup_and_start.sh --skip-checks  # Skip prerequisite checks
```

### 📊 Output Example

```
======================================================================
  🚀 Web Analytics Platform - Complete Setup & Start
======================================================================

📋 Step 1/5: Checking Prerequisites...
  ✅ Docker found: Docker version 24.0.6
  ✅ Docker daemon is running
  ✅ Docker Compose found: v2.23.0
  ✅ System memory: 16GB free

🧹 Step 2/5: Cleanup (Skipped)

📝 Step 3/5: Validating Configuration Files...
  ✅ docker-compose.yml
  ✅ global_config.yaml
  ✅ ingestion_api/app.py
  ✅ python_consumer/app.py
  ✅ pyspark_cron/etl_job.py
  ✅ frontend/package.json
  ✅ postgres_init/01_schema.sql

🏗️  Step 4/5: Building and Starting Services...
  ✅ All services started successfully!

⏳ Step 5/5: Waiting for Services to Initialize...
  ✅ Zookeeper: healthy
  ✅ Kafka: healthy
  ✅ Postgres: healthy
  ✅ Ingestion API: running
  ✅ Python Consumer: running
  ✅ PySpark ETL: running
  ✅ Dashboard: running

======================================================================
  ✅ Platform Started Successfully!
======================================================================

📊 Access Points:
  • Dashboard:    http://localhost:3000
  • API:          http://localhost:8000

📤 Send Test Events:
  • Simulator:    python event_simulator.py

🎉 Happy Analytics!
```

---

## 2️⃣ Event Simulator

### 📁 Files Created
- `event_simulator.py` (Python script)
- `event_simulator_config.yaml` (Configuration)
- `requirements-simulator.txt` (Dependencies)
- `SIMULATOR_GUIDE.md` (Detailed documentation)

### 🎯 Purpose
**Realistic event generator** that mimics real user behavior with probabilistic patterns.

### ✨ Key Features

#### Realistic User Behavior
- ✅ Multi-threaded concurrent users
- ✅ Complete session lifecycles
- ✅ Realistic timing and delays
- ✅ Human-like interaction patterns
- ✅ Configurable user journeys

#### Probabilistic Event Generation
Events are generated with realistic frequencies:

| Event Type | Probability | Real-world Analogy |
|------------|-------------|-------------------|
| Session Start/End | 5% each | Rare (entry/exit points) |
| Page Visit/Close | 25%/20% | Medium (navigation) |
| Button Click | 40% | High (interactions) |
| Link Click | 5% | Low (external links) |

#### User Journey Patterns
Pre-defined realistic flows:
1. **Shopping Flow** (30%): Home → Products → Detail → Cart
2. **Content Reading** (20%): Home → Blog → Post
3. **Signup Flow** (25%): Home → Pricing → Signup
4. **Contact Flow** (15%): Home → About → Contact
5. **Random Browsing** (10%): Exploratory navigation

#### Configurable Parameters
```yaml
simulation:
  num_users: 10              # Concurrent users
  duration_seconds: 300      # 5 minutes
  base_interval: 2.0         # Seconds between events

user_behavior:
  session_duration: 60-600s  # Variable session length
  pages_per_session: 3-15    # Pages visited
  time_per_page: 10-120s     # Time spent reading
  clicks_per_page: 0-8       # Interactions per page
```

#### Real-time Statistics
```
📊 Simulation Statistics
======================================================================
⏱️  Elapsed Time:        150s
📤 Total Events:        2,347
📈 Events/sec:          15.65
🔄 Active Sessions:     8
✅ Completed Sessions:  12
❌ Errors:              0

Event Breakdown:
  • button_clicked     : 938 (40.0%)
  • page_visited       : 587 (25.0%)
  • page_closed        : 469 (20.0%)
  • session_created    : 117 ( 5.0%)
  • session_ended      : 117 ( 5.0%)
======================================================================
```

### 🚀 Usage

#### 1. Install Dependencies
```bash
pip install -r requirements-simulator.txt
```

#### 2. Configure (Optional)
Edit `event_simulator_config.yaml`:
```yaml
simulation:
  num_users: 20           # Increase to 20 users
  duration_seconds: 600   # Run for 10 minutes
```

#### 3. Run Simulator
```bash
python event_simulator.py
```

#### 4. Monitor Progress
The simulator prints:
- Individual user sessions
- Page visits and clicks
- Periodic statistics (every 30s)
- Final summary

### 📊 Testing Scenarios

#### Small Test (10 users, 5 minutes)
```yaml
num_users: 10
duration_seconds: 300
```
**Expected**: ~5,000 events

#### Load Test (100 users, 1 hour)
```yaml
num_users: 100
duration_seconds: 3600
```
**Expected**: ~180,000 events

#### Continuous Simulation
```yaml
num_users: 20
duration_seconds: 0  # Run until Ctrl+C
```

---

## 🆚 Script Comparison

| Feature | setup_and_start | event_simulator |
|---------|-----------------|-----------------|
| **Purpose** | Setup & launch platform | Generate test data |
| **When to Use** | First time or restart | After platform is running |
| **Duration** | 2-3 minutes | 5 minutes to indefinite |
| **Prerequisites** | Docker | Python 3.7+ |
| **Output** | Running services | Analytics events |
| **Interactivity** | One-time execution | Continuous generation |

---

## 🔄 Complete Workflow

### Step 1: Setup Platform
```powershell
.\setup_and_start.ps1
```
**Wait**: 2-3 minutes for services to start

### Step 2: Generate Events
```bash
python event_simulator.py
```
**Wait**: Let it run for 5-10 minutes

### Step 3: View Analytics
**Wait**: 5-10 minutes for ETL to process
**Open**: http://localhost:3000

### Step 4: Monitor & Iterate
```bash
# View logs
docker compose logs -f

# Check specific service
docker compose logs pyspark-cron

# View live events
docker compose logs -f python-consumer
```

---

## 📁 All New Files

```
kafka-based-webanalytics/
├── setup_and_start.ps1              # Windows setup script
├── setup_and_start.sh               # Linux/Mac setup script
├── event_simulator.py               # Event generator
├── event_simulator_config.yaml      # Simulator configuration
├── requirements-simulator.txt       # Python dependencies
├── SIMULATOR_GUIDE.md              # Detailed simulator docs
├── test_events.sh                   # Linux/Mac quick test
└── NEW_SCRIPTS_SUMMARY.md          # This file
```

---

## 🎯 Quick Reference

### Common Commands

```bash
# Start everything
.\setup_and_start.ps1              # Windows
./setup_and_start.sh               # Linux/Mac

# Generate realistic traffic
python event_simulator.py

# Quick test (20 events)
.\test_events.ps1                  # Windows
./test_events.sh                   # Linux/Mac

# View logs
docker compose logs -f

# Stop everything
docker compose down

# Stop and clean data
docker compose down -v
```

### URLs

- 📊 **Dashboard**: http://localhost:3000
- 🔌 **API**: http://localhost:8000
- ❤️ **Health Check**: http://localhost:8000/health

---

## 🎓 Learning Resources

### For Setup Script
- See inline comments in `setup_and_start.ps1`
- Windows PowerShell documentation
- Docker Compose documentation

### For Event Simulator
- Read [SIMULATOR_GUIDE.md](SIMULATOR_GUIDE.md)
- Edit `event_simulator_config.yaml`
- Customize user journeys for your use case

---

## 💡 Pro Tips

### Tip 1: Use Setup Script Always
Instead of manual `docker compose up`, use the setup script:
- Catches issues early
- Provides better feedback
- Handles edge cases

### Tip 2: Customize Event Patterns
Edit probabilities to match your application:
```yaml
# E-commerce site (more clicks)
button_click: 0.50

# Blog site (more page visits)
page_visit: 0.35
```

### Tip 3: Monitor Resources
```bash
# Watch Docker resource usage
docker stats

# Check container health
docker compose ps
```

### Tip 4: Gradual Load Testing
Start small and scale up:
```
10 users → 25 users → 50 users → 100 users
```

### Tip 5: Save Simulation Data
```yaml
advanced:
  save_to_file: true
  output_file: "simulated_events.jsonl"
```

---

## 🐛 Troubleshooting

### Issue: "Docker not found"
**Solution**: Install Docker Desktop
- Windows: https://docs.docker.com/desktop/install/windows-install/
- Mac: https://docs.docker.com/desktop/install/mac-install/
- Linux: https://docs.docker.com/engine/install/

### Issue: "Port already in use"
**Solution**: Stop conflicting services
```bash
# Find what's using port 3000
netstat -ano | findstr :3000    # Windows
lsof -i :3000                   # Linux/Mac

# Change port in docker-compose.yml
ports:
  - "3001:3000"  # Use port 3001 instead
```

### Issue: Simulator connection errors
**Solution**: Ensure API is running
```bash
curl http://localhost:8000/health
docker compose logs ingestion-api
```

### Issue: No data in dashboard
**Solution**: Wait for ETL processing
- Events need 5-10 minutes to process
- Check ETL logs: `docker compose logs pyspark-cron`
- Verify events in Postgres:
  ```bash
  docker compose exec postgres psql -U analytics -d analytics
  SELECT COUNT(*) FROM events;
  ```

---

## ✅ Success Checklist

- [ ] Setup script completes without errors
- [ ] All services show "healthy" or "running"
- [ ] Dashboard accessible at http://localhost:3000
- [ ] Event simulator connects successfully
- [ ] Events appear in consumer logs
- [ ] ETL processes without errors
- [ ] Dashboard shows data after 5-10 minutes
- [ ] Statistics show expected event distribution

---

## 🎉 You're All Set!

Both scripts are ready to use:

1. **Launch platform**: `.\setup_and_start.ps1`
2. **Generate traffic**: `python event_simulator.py`
3. **View results**: http://localhost:3000

**Happy analyzing! 📊**

