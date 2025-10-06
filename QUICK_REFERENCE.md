# Quick Reference Guide

## Starting the Stack

```bash
# Option 1: Use the setup script (recommended for first time)
./setup.sh

# Option 2: Manual setup
cp .env.example .env
# Edit .env with your passwords
docker-compose up -d
```

## Accessing Services

- **Kibana UI**: https://localhost:5601
- **Elasticsearch API**: https://localhost:9200
- **Logstash**: Port 5000 (TCP/UDP)

**Default credentials:**
- Username: `elastic`
- Password: Set in `.env` file

## Common Commands

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f elasticsearch
docker-compose logs -f kibana
docker-compose logs -f logstash

# Check service status
docker-compose ps

# Stop services (keep data)
docker-compose down

# Stop services and remove data
docker-compose down -v

# Restart a service
docker-compose restart kibana
```

## Sending Logs to Logstash

### Using netcat (nc)
```bash
echo '{"message":"Test log","level":"info"}' | nc localhost 5000
```

### Using Python
```python
import socket
import json

log = {"message": "Test from Python", "level": "info"}
sock = socket.socket(socket.SOCK_STREAM)
sock.connect(('localhost', 5000))
sock.send(json.dumps(log).encode() + b'\n')
sock.close()
```

### Using curl (to Elasticsearch directly)
```bash
curl -k -u elastic:yourpassword -X POST "https://localhost:9200/my-index/_doc" \
  -H 'Content-Type: application/json' \
  -d '{"message": "Direct to Elasticsearch", "timestamp": "2025-01-01T00:00:00"}'
```

## Customizing Logstash

1. Edit `logstash/pipeline/logstash.conf`
2. Restart Logstash: `docker-compose restart logstash`

### Example: Add file input
```
input {
  file {
    path => "/var/log/myapp.log"
    start_position => "beginning"
  }
}
```

### Example: Add filter
```
filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
  date {
    match => [ "timestamp", "ISO8601" ]
  }
}
```

## Troubleshooting

### Services won't start
```bash
# Check vm.max_map_count
sysctl vm.max_map_count

# Should be at least 262144, if not:
sudo sysctl -w vm.max_map_count=262144
```

### Out of memory
```bash
# Increase memory limit in .env
MEM_LIMIT=2147483648  # 2GB

# Then recreate services
docker-compose up -d --force-recreate
```

### Certificate errors
```bash
# Regenerate certificates
docker-compose down -v
docker-compose up -d
```

### Reset everything
```bash
# WARNING: Deletes all data!
docker-compose down -v
rm -rf esdata/ kibanadata/ logstashdata/ certs/
```

## Viewing Data in Kibana

1. Open https://localhost:5601
2. Login with elastic user
3. Go to Management > Stack Management > Index Patterns
4. Create index pattern: `logstash-*`
5. Go to Analytics > Discover to view logs

## Production Checklist

- [ ] Change all passwords in `.env`
- [ ] Generate new encryption key: `openssl rand -hex 32`
- [ ] Set up proper SSL certificates (not self-signed)
- [ ] Configure backup strategy
- [ ] Set appropriate memory limits
- [ ] Enable monitoring
- [ ] Configure log retention policies
- [ ] Set up access controls and roles
- [ ] Review security settings

## Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `STACK_VERSION` | Elastic Stack version | 8.11.3 |
| `CLUSTER_NAME` | Elasticsearch cluster name | docker-cluster |
| `LICENSE` | License type (basic/trial) | basic |
| `ES_PORT` | Elasticsearch port | 9200 |
| `KIBANA_PORT` | Kibana port | 5601 |
| `LOGSTASH_PORT` | Logstash port | 5000 |
| `MEM_LIMIT` | Memory limit per service (bytes) | 1073741824 |
| `ELASTIC_PASSWORD` | Elastic user password | changeme |
| `KIBANA_PASSWORD` | Kibana system password | changeme |
| `ENCRYPTION_KEY` | Kibana encryption key | (generated) |

## Health Check Endpoints

```bash
# Elasticsearch
curl -k -u elastic:password https://localhost:9200/_cluster/health

# Kibana
curl http://localhost:5601/api/status

# Logstash
curl http://localhost:9600/_node/stats
```
