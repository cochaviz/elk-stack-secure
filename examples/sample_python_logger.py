#!/usr/bin/env python3
"""
Sample Python application that sends logs to Logstash.

This script demonstrates how to integrate your application with the ELK stack.
"""

import socket
import json
import time
import random
from datetime import datetime

LOGSTASH_HOST = 'localhost'
LOGSTASH_PORT = 5000

def send_log(message, level='info', metadata=None):
    """Send a log message to Logstash via TCP."""
    log_entry = {
        'message': message,
        'level': level,
        'timestamp': datetime.utcnow().isoformat(),
        'application': 'sample-python-app'
    }
    
    if metadata:
        log_entry.update(metadata)
    
    try:
        sock = socket.socket(socket.SOCK_STREAM)
        sock.connect((LOGSTASH_HOST, LOGSTASH_PORT))
        sock.send(json.dumps(log_entry).encode() + b'\n')
        sock.close()
        print(f"Sent: {log_entry}")
    except Exception as e:
        print(f"Failed to send log: {e}")

def main():
    """Generate sample log messages."""
    print(f"Sending sample logs to Logstash at {LOGSTASH_HOST}:{LOGSTASH_PORT}")
    print("Press Ctrl+C to stop\n")
    
    log_levels = ['info', 'warning', 'error', 'debug']
    actions = ['user_login', 'api_call', 'database_query', 'file_upload', 'email_sent']
    
    try:
        while True:
            # Simulate different types of log messages
            action = random.choice(actions)
            level = random.choice(log_levels)
            
            metadata = {
                'user_id': random.randint(1, 1000),
                'action': action,
                'duration_ms': random.randint(10, 5000),
                'ip_address': f"192.168.1.{random.randint(1, 255)}"
            }
            
            message = f"User performed action: {action}"
            
            send_log(message, level, metadata)
            
            # Wait a bit before sending the next log
            time.sleep(random.uniform(0.5, 2.0))
            
    except KeyboardInterrupt:
        print("\nStopped sending logs")

if __name__ == '__main__':
    main()
