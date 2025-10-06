# Examples

This directory contains sample scripts demonstrating how to send logs to the ELK stack.

## Python Example

Send logs from a Python application:

```bash
# Run the sample logger
python3 examples/sample_python_logger.py
```

This will continuously send random log messages to Logstash. Press Ctrl+C to stop.

### Using in Your Python Application

```python
import socket
import json
from datetime import datetime

def send_log_to_elk(message, level='info', **kwargs):
    log_entry = {
        'message': message,
        'level': level,
        'timestamp': datetime.utcnow().isoformat(),
        'application': 'my-app',
        **kwargs
    }
    
    sock = socket.socket(socket.SOCK_STREAM)
    sock.connect(('localhost', 5000))
    sock.send(json.dumps(log_entry).encode() + b'\n')
    sock.close()

# Usage
send_log_to_elk("User logged in", level="info", user_id=123)
```

## Bash Example

Send a single log message from bash:

```bash
# Send a simple log
./examples/sample_bash_logger.sh "Application started" "info"

# Send an error log
./examples/sample_bash_logger.sh "Connection failed" "error"
```

### Using in Your Bash Scripts

```bash
# Add this function to your scripts
send_log() {
    local message="$1"
    local level="${2:-info}"
    
    echo "{\"message\":\"$message\",\"level\":\"$level\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" | \
        nc -q 1 localhost 5000
}

# Usage
send_log "Backup completed successfully" "info"
send_log "Backup failed" "error"
```

## Node.js Example

```javascript
const net = require('net');

function sendLog(message, level = 'info', metadata = {}) {
    const log = {
        message,
        level,
        timestamp: new Date().toISOString(),
        application: 'my-node-app',
        ...metadata
    };
    
    const client = new net.Socket();
    client.connect(5000, 'localhost', () => {
        client.write(JSON.stringify(log) + '\n');
        client.destroy();
    });
}

// Usage
sendLog('Server started', 'info', { port: 3000 });
```

## cURL Example

Send logs directly to Elasticsearch (bypassing Logstash):

```bash
# Send a log entry
curl -k -u elastic:yourpassword \
  -X POST "https://localhost:9200/my-logs/_doc" \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "Direct log entry",
    "level": "info",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "application": "curl-test"
  }'
```

## Viewing Logs in Kibana

After sending logs:

1. Open https://localhost:5601
2. Login with username `elastic` and your password
3. Go to **Management** → **Stack Management** → **Index Patterns**
4. Create an index pattern: `logstash-*` (or `my-logs` if using cURL example)
5. Select `@timestamp` or `timestamp` as the time field
6. Go to **Analytics** → **Discover** to view your logs

## Advanced: Using Filebeat

For production applications, consider using Filebeat instead of direct connections:

```yaml
# filebeat.yml
filebeat.inputs:
  - type: log
    paths:
      - /var/log/myapp/*.log
    
output.logstash:
  hosts: ["localhost:5044"]
```

Then update the Logstash configuration to accept Filebeat input on port 5044.
