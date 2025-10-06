#!/bin/bash

# Sample bash script to send logs to Logstash
# Usage: ./sample_bash_logger.sh "Your log message" [log_level]

LOGSTASH_HOST="localhost"
LOGSTASH_PORT=5000

MESSAGE="${1:-Sample log message}"
LEVEL="${2:-info}"

# Create JSON log entry
LOG_JSON=$(cat <<EOF
{
  "message": "$MESSAGE",
  "level": "$LEVEL",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
  "application": "sample-bash-script",
  "hostname": "$(hostname)",
  "user": "$(whoami)"
}
EOF
)

# Send to Logstash
echo "$LOG_JSON" | nc -q 1 $LOGSTASH_HOST $LOGSTASH_PORT

if [ $? -eq 0 ]; then
    echo "Log sent successfully: $MESSAGE"
else
    echo "Failed to send log"
    exit 1
fi
