#!/usr/bin/env python3
"""
Event Simulator for Web Analytics Platform
Generates realistic user events with probabilistic behavior
"""

import os
import sys
import yaml
import json
import time
import uuid
import random
import requests
import threading
from datetime import datetime, timedelta
from collections import defaultdict
from typing import Dict, List, Optional, Tuple


class EventSimulator:
    """Simulates realistic user behavior with configurable probabilities"""
    
    def __init__(self, config_path: str = "event_simulator_config.yaml"):
        """Initialize simulator with configuration"""
        self.load_config(config_path)
        self.stats = {
            'total_events': 0,
            'events_by_type': defaultdict(int),
            'active_sessions': 0,
            'completed_sessions': 0,
            'errors': 0,
            'start_time': time.time()
        }
        self.active_users = {}
        self.running = True
        
    def load_config(self, config_path: str):
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as f:
                self.config = yaml.safe_load(f)
            print(f"✅ Configuration loaded from {config_path}")
        except FileNotFoundError:
            print(f"❌ Configuration file not found: {config_path}")
            sys.exit(1)
        except yaml.YAMLError as e:
            print(f"❌ Error parsing configuration: {e}")
            sys.exit(1)
    
    def send_event(self, event_data: Dict) -> bool:
        """Send event to the ingestion API"""
        api_url = self.config['simulation']['api_url']
        timeout = self.config['simulation']['timeout']
        retry = self.config['advanced']['retry_on_failure']
        max_retries = self.config['advanced']['max_retries']
        
        for attempt in range(max_retries if retry else 1):
            try:
                response = requests.post(
                    api_url,
                    json=event_data,
                    timeout=timeout,
                    headers={'Content-Type': 'application/json'}
                )
                
                if response.status_code == 200:
                    self.stats['total_events'] += 1
                    self.stats['events_by_type'][event_data['event_type']] += 1
                    return True
                else:
                    if self.config['advanced']['verbose']:
                        print(f"⚠️  API returned status {response.status_code}")
                    
            except requests.exceptions.RequestException as e:
                if attempt < max_retries - 1:
                    time.sleep(0.5 * (attempt + 1))  # Exponential backoff
                else:
                    if self.config['advanced']['verbose']:
                        print(f"❌ Failed to send event: {e}")
                    self.stats['errors'] += 1
        
        return False
    
    def save_event_to_file(self, event_data: Dict):
        """Save event to local file as backup"""
        if self.config['advanced']['save_to_file']:
            output_file = self.config['advanced']['output_file']
            with open(output_file, 'a') as f:
                f.write(json.dumps(event_data) + '\n')
    
    def create_event(self, event_type: str, user_id: str, session_id: str, 
                     page_path: Optional[str] = None, 
                     button_id: Optional[str] = None) -> Dict:
        """Create event payload"""
        event = {
            'event_type': event_type,
            'user_id': user_id,
            'session_id': session_id,
            'props': {}
        }
        
        if page_path:
            event['page_path'] = page_path
        
        if button_id:
            event['button_id'] = button_id
        
        return event
    
    def select_user_journey(self) -> Dict:
        """Select a user journey based on probabilities"""
        journeys = self.config['user_journeys']
        probabilities = [j['probability'] for j in journeys]
        selected = random.choices(journeys, weights=probabilities)[0]
        return selected
    
    def simulate_user_session(self, user_id: str):
        """Simulate a complete user session with realistic behavior"""
        verbose = self.config['advanced']['verbose']
        
        # Generate session ID
        session_id = f"session_{uuid.uuid4().hex[:12]}"
        
        # Select user journey
        journey = self.select_user_journey()
        
        # Determine session parameters
        behavior = self.config['user_behavior']
        session_duration = random.randint(
            behavior['session_duration_min'],
            behavior['session_duration_max']
        )
        num_pages = random.randint(
            behavior['pages_per_session_min'],
            behavior['pages_per_session_max']
        )
        
        # Track session state
        self.active_users[user_id] = {
            'session_id': session_id,
            'current_page': None,
            'pages_visited': 0
        }
        self.stats['active_sessions'] += 1
        
        if verbose:
            print(f"\n👤 User {user_id[:8]} started session {session_id[:8]}")
            print(f"   Journey: {journey.get('path', ['random'])}")
            print(f"   Duration: ~{session_duration}s, Pages: {num_pages}")
        
        # Send session start event
        event = self.create_event('session_created', user_id, session_id)
        self.send_event(event)
        self.save_event_to_file(event)
        
        session_start_time = time.time()
        
        # Simulate browsing behavior
        for page_num in range(num_pages):
            if not self.running or (time.time() - session_start_time) > session_duration:
                break
            
            # Determine next page
            if journey['path'] and page_num < len(journey['path']):
                page_path = journey['path'][page_num]
            else:
                page_path = random.choice(self.config['pages'])
            
            # Close previous page if any
            if self.active_users[user_id]['current_page']:
                old_page = self.active_users[user_id]['current_page']
                event = self.create_event('page_closed', user_id, session_id, old_page)
                self.send_event(event)
                self.save_event_to_file(event)
            
            # Visit new page
            event = self.create_event('page_visited', user_id, session_id, page_path)
            self.send_event(event)
            self.save_event_to_file(event)
            
            self.active_users[user_id]['current_page'] = page_path
            self.active_users[user_id]['pages_visited'] += 1
            
            if verbose:
                print(f"   📄 Page {page_num + 1}/{num_pages}: {page_path}")
            
            # Time spent on page
            time_on_page = random.randint(
                behavior['time_per_page_min'],
                behavior['time_per_page_max']
            )
            
            # Simulate interactions on page
            num_clicks = random.randint(
                behavior['clicks_per_page_min'],
                behavior['clicks_per_page_max']
            )
            
            for click_num in range(num_clicks):
                if not self.running:
                    break
                
                # Wait before click (simulate reading/scrolling)
                click_delay = time_on_page / (num_clicks + 1)
                if self.config['advanced']['human_like_delays']:
                    # Add human-like variance
                    click_delay *= random.uniform(0.5, 1.5)
                
                time.sleep(min(click_delay, 5))  # Cap at 5 seconds
                
                # Select button to click
                if journey['likely_clicks'] and random.random() > 0.3:
                    button_id = random.choice(journey['likely_clicks'])
                else:
                    button_id = random.choice(self.config['buttons'])
                
                event = self.create_event(
                    'button_clicked', user_id, session_id, 
                    page_path, button_id
                )
                self.send_event(event)
                self.save_event_to_file(event)
                
                if verbose:
                    print(f"      🖱️  Click: {button_id}")
            
            # Wait remaining time on page
            if page_num < num_pages - 1:
                remaining_time = max(0, time_on_page - (num_clicks * click_delay))
                time.sleep(min(remaining_time, 10))
        
        # Close last page
        if self.active_users[user_id]['current_page']:
            last_page = self.active_users[user_id]['current_page']
            event = self.create_event('page_closed', user_id, session_id, last_page)
            self.send_event(event)
            self.save_event_to_file(event)
        
        # End session
        event = self.create_event('session_ended', user_id, session_id)
        self.send_event(event)
        self.save_event_to_file(event)
        
        # Update stats
        self.stats['active_sessions'] -= 1
        self.stats['completed_sessions'] += 1
        del self.active_users[user_id]
        
        if verbose:
            print(f"   ✅ Session ended: {self.active_users.get(user_id, {}).get('pages_visited', 0)} pages visited")
    
    def user_thread(self, user_id: str):
        """Thread function for simulating a single user"""
        sim_config = self.config['simulation']
        duration = sim_config['duration_seconds']
        start_time = time.time()
        
        while self.running:
            # Check if simulation duration exceeded
            if duration > 0 and (time.time() - start_time) >= duration:
                break
            
            # Simulate a user session
            try:
                self.simulate_user_session(user_id)
            except Exception as e:
                print(f"❌ Error in user {user_id}: {e}")
                self.stats['errors'] += 1
            
            # Wait before starting new session (user returns later)
            if self.running:
                wait_time = random.randint(10, 60)  # 10-60 seconds between sessions
                time.sleep(wait_time)
    
    def print_stats(self):
        """Print simulation statistics"""
        elapsed = time.time() - self.stats['start_time']
        
        print("\n" + "=" * 70)
        print("📊 Simulation Statistics")
        print("=" * 70)
        print(f"⏱️  Elapsed Time:        {int(elapsed)}s")
        print(f"📤 Total Events:        {self.stats['total_events']}")
        print(f"📈 Events/sec:          {self.stats['total_events'] / elapsed:.2f}")
        print(f"🔄 Active Sessions:     {self.stats['active_sessions']}")
        print(f"✅ Completed Sessions:  {self.stats['completed_sessions']}")
        print(f"❌ Errors:              {self.stats['errors']}")
        print()
        print("Event Breakdown:")
        for event_type, count in sorted(self.stats['events_by_type'].items()):
            percentage = (count / self.stats['total_events'] * 100) if self.stats['total_events'] > 0 else 0
            print(f"  • {event_type:20s}: {count:6d} ({percentage:5.1f}%)")
        print("=" * 70 + "\n")
    
    def stats_thread(self):
        """Thread for printing periodic statistics"""
        interval = self.config['advanced']['stats_interval']
        
        while self.running:
            time.sleep(interval)
            if self.running:
                self.print_stats()
    
    def run(self):
        """Run the simulation"""
        num_users = self.config['simulation']['num_users']
        duration = self.config['simulation']['duration_seconds']
        
        print("\n" + "=" * 70)
        print("🚀 Event Simulator Starting")
        print("=" * 70)
        print(f"👥 Number of Users:     {num_users}")
        print(f"⏱️  Duration:            {duration}s ({duration // 60} minutes)" if duration > 0 else "⏱️  Duration:            Indefinite (Ctrl+C to stop)")
        print(f"🎯 Target API:          {self.config['simulation']['api_url']}")
        print("=" * 70 + "\n")
        
        # Start stats thread
        stats_thread = threading.Thread(target=self.stats_thread, daemon=True)
        stats_thread.start()
        
        # Start user threads
        threads = []
        for i in range(num_users):
            user_id = f"user_{uuid.uuid4().hex[:8]}"
            thread = threading.Thread(target=self.user_thread, args=(user_id,))
            thread.daemon = True
            thread.start()
            threads.append(thread)
            time.sleep(0.1)  # Stagger thread starts
        
        try:
            # Wait for all threads or duration
            if duration > 0:
                time.sleep(duration)
            else:
                # Run indefinitely until Ctrl+C
                while any(t.is_alive() for t in threads):
                    time.sleep(1)
        except KeyboardInterrupt:
            print("\n⚠️  Stopping simulation (Ctrl+C detected)...")
        
        # Cleanup
        self.running = False
        
        # Wait for threads to finish (with timeout)
        print("⏳ Waiting for active sessions to complete...")
        for thread in threads:
            thread.join(timeout=10)
        
        # Final stats
        self.print_stats()
        
        print("=" * 70)
        print("✅ Simulation Complete!")
        print("=" * 70)
        print(f"📊 Dashboard: http://localhost:3000")
        print(f"⏱️  Wait 5-10 minutes for ETL to process {self.stats['total_events']} events")
        print("=" * 70 + "\n")


def main():
    """Main entry point"""
    config_file = "event_simulator_config.yaml"
    
    # Check if config file exists
    if not os.path.exists(config_file):
        print(f"❌ Configuration file not found: {config_file}")
        print("Please ensure event_simulator_config.yaml is in the current directory.")
        sys.exit(1)
    
    # Create and run simulator
    simulator = EventSimulator(config_file)
    simulator.run()


if __name__ == "__main__":
    main()

