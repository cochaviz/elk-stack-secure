# elk-stack-secure

ELK stack definition with security enabled, ready to deploy with for example dokploy.

## Overview

This repository contains a complete, production-ready ELK (Elasticsearch, Logstash, Kibana) stack deployment using Docker Compose with security features enabled, including:

- **Elasticsearch**: Full-text search and analytics engine
- **Logstash**: Data processing pipeline for ingesting, transforming, and sending data
- **Kibana**: Data visualization and exploration interface
- **Security**: SSL/TLS encryption, authentication, and secure communication between services

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB of RAM available for Docker
- Linux kernel settings configured (see below)

## Quick Start

### 1. Configure System Settings

For production use, you need to increase the `vm.max_map_count` kernel setting:

```bash
# Temporary (until reboot)
sudo sysctl -w vm.max_map_count=262144

# Permanent
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 2. Set Up Environment Variables

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit the `.env` file and update the following variables:
- `ELASTIC_PASSWORD`: Password for the 'elastic' superuser (minimum 6 characters)
- `KIBANA_PASSWORD`: Password for the 'kibana_system' user (minimum 6 characters)
- `ENCRYPTION_KEY`: Generate a new one with: `openssl rand -hex 32`

**Important:** Use strong passwords in production!

### 3. Start the Stack

```bash
docker-compose up -d
```

The first startup will:
1. Create SSL/TLS certificates for secure communication
2. Set up the Elasticsearch cluster
3. Configure user passwords
4. Start all services

This process may take several minutes.

### 4. Access the Services

Once all services are healthy:

- **Kibana**: https://localhost:5601
  - Username: `elastic`
  - Password: (the value you set in `.env` for `ELASTIC_PASSWORD`)

- **Elasticsearch**: https://localhost:9200
  - Username: `elastic`
  - Password: (the value you set in `.env` for `ELASTIC_PASSWORD`)
  - Note: HTTPS is required. Your browser will warn about self-signed certificates.

- **Logstash**: 
  - TCP/UDP port 5000 for log ingestion
  - Port 9600 for metrics API

## Architecture

### Security Features

1. **SSL/TLS Encryption**: All communication between Elasticsearch nodes and clients uses SSL/TLS
2. **Authentication**: Built-in user authentication with customizable passwords
3. **Self-signed Certificates**: Automatically generated on first startup
4. **Encrypted Data**: Kibana saved objects are encrypted at rest

### Service Configuration

#### Elasticsearch
- Single-node cluster (can be extended for production)
- Security features enabled with SSL/TLS
- Data persisted in Docker volume `esdata`
- Exposed on port 9200

#### Kibana
- Connected to Elasticsearch via HTTPS
- Secured with SSL certificate verification
- Data persisted in Docker volume `kibanadata`
- Exposed on port 5601

#### Logstash
- Configured to forward logs to Elasticsearch
- Input: TCP/UDP on port 5000 (JSON format)
- Output: Elasticsearch with SSL/TLS
- Pipeline configuration in `logstash/pipeline/logstash.conf`

## Usage

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f elasticsearch
docker-compose logs -f kibana
docker-compose logs -f logstash
```

### Stopping the Stack

```bash
docker-compose down
```

To also remove volumes (WARNING: this deletes all data):

```bash
docker-compose down -v
```

### Sending Logs to Logstash

Example using `netcat`:

```bash
echo '{"message":"Hello ELK","level":"info"}' | nc localhost 5000
```

Example using Python:

```python
import socket
import json

log_data = {
    "message": "Test log message",
    "level": "info",
    "application": "my-app"
}

sock = socket.socket(socket.SOCK_STREAM)
sock.connect(('localhost', 5000))
sock.send(json.dumps(log_data).encode() + b'\n')
sock.close()
```

### Accessing Elasticsearch API

With curl (accepting self-signed certificate):

```bash
curl -k -u elastic:changeme https://localhost:9200
```

### Customizing Logstash Pipeline

Edit `logstash/pipeline/logstash.conf` to customize:
- Input sources
- Filters and transformations
- Output destinations

After changes, restart Logstash:

```bash
docker-compose restart logstash
```

## Configuration Files

- `docker-compose.yml`: Main orchestration file
- `.env`: Environment variables (created from `.env.example`)
- `logstash/config/logstash.yml`: Logstash service configuration
- `logstash/pipeline/logstash.conf`: Logstash pipeline definition

## Troubleshooting

### Elasticsearch fails to start

Check if `vm.max_map_count` is set correctly:

```bash
sysctl vm.max_map_count
```

Should return at least `262144`.

### Out of memory errors

Increase the `MEM_LIMIT` in `.env` file or allocate more memory to Docker.

### Certificate errors

If you need to regenerate certificates:

```bash
docker-compose down -v
docker-compose up -d
```

This will recreate all volumes including certificates.

### Connection refused errors

Wait for all services to become healthy:

```bash
docker-compose ps
```

All services should show "healthy" status.

## Production Considerations

1. **Use strong passwords**: Change default passwords in `.env`
2. **Resource limits**: Adjust `MEM_LIMIT` based on your workload
3. **Backup data**: Regularly backup Elasticsearch indices
4. **Certificate management**: Consider using proper certificates instead of self-signed
5. **Cluster mode**: For production, configure multi-node Elasticsearch cluster
6. **Monitoring**: Enable Elastic Stack monitoring features
7. **Update policy**: Keep the stack version up to date

## License

This configuration is provided as-is for use with the Elastic Stack components, which are subject to the Elastic License.

## Support

For issues specific to this configuration, please open an issue in this repository.

For Elastic Stack documentation:
- [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Logstash](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Kibana](https://www.elastic.co/guide/en/kibana/current/index.html)
