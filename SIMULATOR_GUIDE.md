# 🎮 Event Simulator Guide

## Overview

The Event Simulator generates realistic user behavior patterns with configurable probabilities to test your analytics platform under realistic load.

---

## 🚀 Quick Start

### 1. Install Python Dependencies

```bash
pip install -r requirements-simulator.txt
```

### 2. Configure Simulation (Optional)

Edit `event_simulator_config.yaml` to customize:
- Number of users
- Simulation duration
- Event probabilities
- User behavior patterns

### 3. Run Simulator

```bash
python event_simulator.py
```

---

## 📊 Configuration Guide

### Basic Settings (`event_simulator_config.yaml`)

```yaml
simulation:
  num_users: 10              # Number of concurrent users
  duration_seconds: 300      # 5 minutes (0 = indefinite)
  api_url: "http://localhost:8000/api/events"
```

### Event Probabilities

Events are generated with realistic frequencies:

| Event Type | Default Probability | Frequency |
|------------|---------------------|-----------|
| `session_start` | 5% | Rare |
| `session_end` | 5% | Rare |
| `page_visit` | 25% | Medium |
| `page_close` | 20% | Medium |
| `button_click` | 40% | High |
| `link_click` | 5% | Low |

**Total must sum to 1.0 (100%)**

### User Behavior Patterns

```yaml
user_behavior:
  session_duration_min: 60      # 1 minute
  session_duration_max: 600     # 10 minutes
  
  pages_per_session_min: 3
  pages_per_session_max: 15
  
  time_per_page_min: 10         # seconds
  time_per_page_max: 120        # seconds
  
  clicks_per_page_min: 0
  clicks_per_page_max: 8
```

---

## 🎯 Realistic User Journeys

The simulator includes predefined user journeys that mimic real user behavior:

### Journey 1: Shopping Flow (30%)
```
Home → Products → Product Detail → Cart
Clicks: add_to_cart, checkout_btn
```

### Journey 2: Content Reading (20%)
```
Home → Blog → Blog Post
Clicks: subscribe_btn, share_btn
```

### Journey 3: Signup Flow (25%)
```
Home → Pricing → Signup
Clicks: get_started_btn, signup_btn
```

### Journey 4: Contact Flow (15%)
```
Home → About → Contact
Clicks: contact_us_btn
```

### Journey 5: Random Browsing (10%)
```
Random pages with random clicks
```

---

## 📈 How It Works

### 1. Session Lifecycle

```
1. User starts session (session_created)
   ↓
2. Visits multiple pages
   - page_visited
   - Multiple button_clicks per page
   - page_closed
   ↓
3. Ends session (session_ended)
```

### 2. Realistic Timing

- **Human-like delays**: Random variance in actions
- **Staggered starts**: Users don't all start simultaneously
- **Variable sessions**: Different session durations per user
- **Natural pauses**: Time between page loads and clicks

### 3. Multi-threaded Execution

- Each user runs in a separate thread
- Concurrent user activity (like real traffic)
- Configurable number of simultaneous users

---

## 📊 Statistics Dashboard

The simulator prints real-time statistics:

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
  • link_click         : 119 ( 5.0%)
======================================================================
```

---

## 🔧 Advanced Configuration

### Save Events to File

```yaml
advanced:
  save_to_file: true
  output_file: "simulated_events.jsonl"
```

### Verbose Logging

```yaml
advanced:
  verbose: true  # Prints detailed event logs
```

### Error Handling

```yaml
advanced:
  retry_on_failure: true
  max_retries: 3
```

### Statistics Interval

```yaml
advanced:
  stats_interval: 30  # Print stats every 30 seconds
```

---

## 🎮 Usage Examples

### Example 1: Quick Test (10 users, 5 minutes)

```yaml
simulation:
  num_users: 10
  duration_seconds: 300
```

```bash
python event_simulator.py
```

### Example 2: Load Test (100 users, 1 hour)

```yaml
simulation:
  num_users: 100
  duration_seconds: 3600
```

```bash
python event_simulator.py
```

### Example 3: Continuous Simulation

```yaml
simulation:
  num_users: 20
  duration_seconds: 0  # Run indefinitely
```

```bash
python event_simulator.py
# Press Ctrl+C to stop
```

### Example 4: High Interaction Rate

```yaml
event_probabilities:
  session_start: 0.03
  session_end: 0.03
  page_visit: 0.20
  page_close: 0.15
  button_click: 0.55  # More clicks!
  link_click: 0.04
```

---

## 📋 Testing Scenarios

### Scenario 1: Normal Traffic
```yaml
num_users: 10
duration_seconds: 300
button_click: 0.40
```
**Use case**: Daily traffic simulation

### Scenario 2: High Traffic Spike
```yaml
num_users: 100
duration_seconds: 600
button_click: 0.50
```
**Use case**: Test system under load

### Scenario 3: Browsing Behavior
```yaml
num_users: 20
pages_per_session_max: 30
time_per_page_max: 180
clicks_per_page_max: 15
```
**Use case**: Heavy readers/researchers

### Scenario 4: Quick Visitors
```yaml
num_users: 50
session_duration_max: 120
pages_per_session_max: 5
clicks_per_page_max: 2
```
**Use case**: Bounce-heavy traffic

---

## 🐛 Troubleshooting

### Issue: Connection Errors

```
❌ Failed to send event: Connection refused
```

**Solution**: Ensure ingestion API is running
```bash
docker compose ps ingestion-api
curl http://localhost:8000/health
```

### Issue: Slow Event Generation

**Solution**: Reduce human-like delays
```yaml
advanced:
  human_like_delays: false
```

### Issue: Too Many Errors

**Solution**: Check API logs
```bash
docker compose logs ingestion-api
```

### Issue: Unrealistic Event Distribution

**Solution**: Verify probabilities sum to 1.0
```python
# Quick check
probabilities = [0.05, 0.05, 0.25, 0.20, 0.40, 0.05]
assert sum(probabilities) == 1.0
```

---

## 📊 Monitoring Results

### 1. Check Real-time Ingestion

```bash
# View ingestion API logs
docker compose logs -f ingestion-api
```

### 2. Check Consumer Logs

```bash
# Verify events are being logged
docker compose logs -f python-consumer
```

### 3. Check ETL Processing

```bash
# Monitor ETL job
docker compose logs -f pyspark-cron
```

### 4. View Dashboard

Open http://localhost:3000 (wait 5-10 minutes for ETL)

---

## 🎯 Performance Metrics

### Expected Throughput

| Users | Events/sec | Total (5 min) |
|-------|------------|---------------|
| 10    | 15-20      | ~5,000       |
| 50    | 75-100     | ~25,000      |
| 100   | 150-200    | ~50,000      |
| 500   | 750-1000   | ~250,000     |

### System Requirements

| Users | CPU | RAM | Network |
|-------|-----|-----|---------|
| 1-10  | Low | 512MB | < 1 Mbps |
| 11-50 | Medium | 1GB | 1-5 Mbps |
| 51-100 | Medium-High | 2GB | 5-10 Mbps |
| 100+ | High | 4GB+ | 10+ Mbps |

---

## 🚀 Best Practices

### 1. Start Small
Begin with 10 users to verify everything works

### 2. Gradual Scaling
Increase users incrementally (10 → 25 → 50 → 100)

### 3. Monitor Resources
Watch Docker stats: `docker stats`

### 4. Allow ETL Time
Wait 5-10 minutes between simulations for ETL processing

### 5. Realistic Probabilities
Keep button clicks > page visits > session events

### 6. Use Journeys
Define realistic user flows for your application

---

## 📚 API Integration

### Custom Event Types

Add your own event types to `event_simulator_config.yaml`:

```yaml
event_probabilities:
  session_start: 0.05
  session_end: 0.05
  page_visit: 0.20
  page_close: 0.15
  button_click: 0.30
  form_submit: 0.10      # Custom event
  video_play: 0.08       # Custom event
  search_query: 0.07     # Custom event
```

Then update `event_simulator.py` to generate these events.

---

## 🎉 Success Criteria

Your simulation is successful when:

- ✅ Events send without errors
- ✅ Statistics show expected distribution
- ✅ All sessions complete properly
- ✅ Dashboard shows data after ETL runs
- ✅ No service crashes or timeouts

---

**Happy Simulating! 🎮**

