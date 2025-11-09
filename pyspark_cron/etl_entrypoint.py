"""
ETL Entrypoint
Runs the ETL job periodically based on configured interval
"""

import os
import yaml
import time
import signal
import sys
from datetime import datetime

# Import the ETL job
from etl_job import run_etl


# Load global configuration
CONFIG_PATH = os.getenv("CONFIG_PATH", "global_config.yaml")
with open(CONFIG_PATH, 'r') as f:
    config = yaml.safe_load(f)

# Get interval from config
INTERVAL_SECONDS = config['cron']['etl_interval_seconds']

# Global flag for graceful shutdown
running = True


def signal_handler(sig, frame):
    """Handle shutdown signals gracefully"""
    global running
    print("\n🛑 Shutdown signal received. Stopping ETL scheduler...")
    running = False


def wait_for_startup():
    """
    Wait for other services to be ready before starting ETL
    """
    print("⏳ Waiting 30 seconds for services to initialize...")
    time.sleep(30)


def main():
    """
    Main scheduler loop
    """
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    print("=" * 70)
    print("🔄 PySpark ETL Scheduler Starting")
    print(f"⏱️  Interval: {INTERVAL_SECONDS} seconds ({INTERVAL_SECONDS // 60} minutes)")
    print("=" * 70)
    
    # Wait for other services
    wait_for_startup()
    
    iteration = 0
    
    while running:
        try:
            iteration += 1
            print(f"\n{'='*70}")
            print(f"🔄 ETL Iteration #{iteration}")
            print(f"⏰ Started at: {datetime.now()}")
            print(f"{'='*70}")
            
            # Run the ETL job
            run_etl()
            
            if not running:
                break
            
            # Wait for next iteration
            print(f"\n⏳ Sleeping for {INTERVAL_SECONDS} seconds until next run...")
            
            # Sleep in small increments to allow graceful shutdown
            sleep_counter = 0
            while sleep_counter < INTERVAL_SECONDS and running:
                time.sleep(1)
                sleep_counter += 1
        
        except KeyboardInterrupt:
            print("\n⚠️ Keyboard interrupt received")
            break
        except Exception as e:
            print(f"\n❌ Error in ETL scheduler: {e}")
            import traceback
            traceback.print_exc()
            
            # Wait before retry on error
            if running:
                print(f"⏳ Waiting 60 seconds before retry...")
                time.sleep(60)
    
    print("\n" + "=" * 70)
    print("✅ ETL Scheduler stopped gracefully")
    print("=" * 70)


if __name__ == "__main__":
    main()

