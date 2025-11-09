"""
Python Kafka Consumer
Consumes events from Kafka and writes them to JSON Lines (.jsonl) files
"""

import os
import json
import yaml
from pathlib import Path
from datetime import datetime
from confluent_kafka import Consumer, KafkaError
import signal
import sys


# Load global configuration
CONFIG_PATH = os.getenv("CONFIG_PATH", "global_config.yaml")
with open(CONFIG_PATH, 'r') as f:
    config = yaml.safe_load(f)

# Kafka consumer configuration
consumer_config = {
    'bootstrap.servers': config['kafka']['bootstrap_servers'],
    'group.id': config['kafka']['consumer_group'],
    'auto.offset.reset': config['kafka'].get('auto_offset_reset', 'earliest'),
    'enable.auto.commit': True,
    'auto.commit.interval.ms': 5000,
}

# Initialize Kafka consumer
consumer = Consumer(consumer_config)
topic = config['kafka']['topic']
consumer.subscribe([topic])

# Ensure log directories exist
logs_dir = Path(config['paths']['logs_dir'])
logs_dir.mkdir(parents=True, exist_ok=True)

# Global flag for graceful shutdown
running = True


def signal_handler(sig, frame):
    """Handle shutdown signals gracefully"""
    global running
    print("\n🛑 Shutdown signal received. Closing consumer...")
    running = False


def get_log_file_path(event_type: str) -> Path:
    """
    Determine which log file to write to based on event type
    Sessions events go to sessions.jsonl, others to events.jsonl
    """
    logs_dir = Path(config['paths']['logs_dir'])
    
    if 'session' in event_type.lower():
        return logs_dir / 'sessions.jsonl'
    else:
        return logs_dir / 'events.jsonl'


def write_event_to_log(event_data: dict):
    """
    Write event to appropriate JSON Lines file
    """
    try:
        event_type = event_data.get('event_type', 'unknown')
        log_file = get_log_file_path(event_type)
        
        # Append event as single line JSON
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(event_data) + '\n')
        
        return True
    except Exception as e:
        print(f"❌ Error writing to log: {e}")
        return False


def consume_messages():
    """
    Main consumer loop - polls Kafka and writes events to log files
    """
    print(f"🚀 Starting Kafka consumer...")
    print(f"📊 Subscribed to topic: {topic}")
    print(f"📁 Logs directory: {logs_dir}")
    print(f"⏳ Waiting for messages...\n")
    
    message_count = 0
    
    while running:
        try:
            # Poll for messages (timeout 1 second)
            msg = consumer.poll(timeout=1.0)
            
            if msg is None:
                continue
            
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    # End of partition - not an error
                    continue
                else:
                    print(f"❌ Consumer error: {msg.error()}")
                    continue
            
            # Parse message value
            try:
                event_data = json.loads(msg.value().decode('utf-8'))
                
                # Write to log file
                if write_event_to_log(event_data):
                    message_count += 1
                    event_type = event_data.get('event_type', 'unknown')
                    event_id = event_data.get('event_id', 'N/A')
                    
                    print(f"✅ [{message_count}] Logged {event_type} | ID: {event_id[:8]}...")
                
            except json.JSONDecodeError as e:
                print(f"❌ Failed to decode message: {e}")
            except Exception as e:
                print(f"❌ Error processing message: {e}")
        
        except KeyboardInterrupt:
            print("\n⚠️ Keyboard interrupt received")
            break
        except Exception as e:
            print(f"❌ Unexpected error in consumer loop: {e}")
    
    print(f"\n📊 Total messages processed: {message_count}")


def main():
    """
    Main entry point
    """
    # Register signal handlers for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        consume_messages()
    finally:
        print("🔄 Closing consumer...")
        consumer.close()
        print("✅ Consumer closed successfully")


if __name__ == "__main__":
    main()

