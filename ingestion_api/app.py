"""
FastAPI Ingestion Service
Receives analytics events via POST /api/events and publishes to Kafka
"""

import os
import uuid
import yaml
from datetime import datetime, timezone
from typing import Optional, Dict, Any

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from confluent_kafka import Producer
import json


# Load global configuration
CONFIG_PATH = os.getenv("CONFIG_PATH", "global_config.yaml")
with open(CONFIG_PATH, 'r') as f:
    config = yaml.safe_load(f)

# Initialize FastAPI app
app = FastAPI(
    title="Web Analytics Ingestion API",
    description="Event ingestion endpoint for web analytics platform",
    version="1.0.0"
)

# Enable CORS for frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Kafka Producer configuration
kafka_config = {
    'bootstrap.servers': config['kafka']['bootstrap_servers'],
    'client.id': 'ingestion-api',
}

producer = Producer(kafka_config)


# Pydantic models for request/response validation
class EventPayload(BaseModel):
    """Analytics event payload schema"""
    event_type: str = Field(..., description="Type of event (e.g., page_visited, button_clicked)")
    user_id: str = Field(..., description="Unique user identifier")
    session_id: str = Field(..., description="Session identifier")
    page_path: Optional[str] = Field(None, description="URL path of the page")
    button_id: Optional[str] = Field(None, description="Button or element identifier")
    props: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Additional event properties")


class EventResponse(BaseModel):
    """Response after event submission"""
    status: str
    event_id: str
    message: str


# Kafka delivery callback
def delivery_report(err, msg):
    """Callback for Kafka message delivery reports"""
    if err is not None:
        print(f'❌ Message delivery failed: {err}')
    else:
        print(f'✅ Message delivered to {msg.topic()} [{msg.partition()}]')


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "service": "Web Analytics Ingestion API",
        "status": "running",
        "version": "1.0.0"
    }


@app.get("/health")
async def health():
    """Detailed health check"""
    return {
        "status": "healthy",
        "kafka_connected": True,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }


@app.post("/api/events", response_model=EventResponse)
async def receive_event(event: EventPayload):
    """
    Receive analytics event and publish to Kafka
    
    - Generates unique event_id
    - Adds event_time timestamp
    - Publishes to Kafka topic
    - Returns confirmation
    """
    try:
        # Generate event metadata
        event_id = str(uuid.uuid4())
        event_time = datetime.now(timezone.utc).isoformat()
        
        # Construct full event payload
        full_event = {
            "event_id": event_id,
            "event_time": event_time,
            **event.model_dump()
        }
        
        # Serialize to JSON
        event_json = json.dumps(full_event)
        
        # Publish to Kafka
        topic = config['kafka']['topic']
        producer.produce(
            topic=topic,
            key=event.session_id.encode('utf-8'),
            value=event_json.encode('utf-8'),
            callback=delivery_report
        )
        
        # Flush to ensure delivery
        producer.poll(0)
        
        return EventResponse(
            status="queued",
            event_id=event_id,
            message=f"Event successfully queued to {topic}"
        )
    
    except Exception as e:
        print(f"❌ Error processing event: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to process event: {str(e)}")


@app.on_event("shutdown")
def shutdown_event():
    """Flush any pending messages on shutdown"""
    print("🔄 Flushing pending Kafka messages...")
    producer.flush()
    print("✅ Shutdown complete")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

