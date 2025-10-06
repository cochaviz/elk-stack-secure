#!/bin/bash

# ELK Stack Setup Script
# This script helps set up the ELK stack with proper configuration

set -e

echo "==================================="
echo "ELK Stack Secure - Setup Script"
echo "==================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check system requirements
echo "Checking system requirements..."

# Check vm.max_map_count
current_max_map_count=$(sysctl -n vm.max_map_count 2>/dev/null || echo "0")
required_max_map_count=262144

if [ "$current_max_map_count" -lt "$required_max_map_count" ]; then
    echo ""
    echo "Warning: vm.max_map_count is set to $current_max_map_count"
    echo "Elasticsearch requires at least $required_max_map_count"
    echo ""
    echo "To fix this, run:"
    echo "  sudo sysctl -w vm.max_map_count=$required_max_map_count"
    echo ""
    echo "To make it permanent, add to /etc/sysctl.conf:"
    echo "  echo 'vm.max_map_count=$required_max_map_count' | sudo tee -a /etc/sysctl.conf"
    echo ""
    
    read -p "Do you want to set vm.max_map_count now? (requires sudo) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo sysctl -w vm.max_map_count=$required_max_map_count
        echo "vm.max_map_count has been set to $required_max_map_count (temporary, until reboot)"
    else
        echo "Please set vm.max_map_count manually before starting the stack."
        exit 1
    fi
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo ""
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    
    # Generate a random encryption key
    if command -v openssl &> /dev/null; then
        ENCRYPTION_KEY=$(openssl rand -hex 32)
        sed -i.bak "s/ENCRYPTION_KEY=.*/ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env
        rm .env.bak 2>/dev/null || true
        echo "Generated new encryption key"
    fi
    
    echo ""
    echo "============================================"
    echo "IMPORTANT: Please update the .env file with secure passwords!"
    echo "============================================"
    echo ""
    echo "Edit .env and change:"
    echo "  - ELASTIC_PASSWORD (current: changeme)"
    echo "  - KIBANA_PASSWORD (current: changeme)"
    echo ""
    
    read -p "Press Enter to continue after updating passwords, or Ctrl+C to exit..."
else
    echo ".env file already exists"
fi

# Verify passwords are not default
if grep -q "ELASTIC_PASSWORD=changeme" .env || grep -q "KIBANA_PASSWORD=changeme" .env; then
    echo ""
    echo "============================================"
    echo "WARNING: You are using default passwords!"
    echo "============================================"
    echo ""
    echo "For security, please update passwords in .env file"
    echo ""
    
    read -p "Continue anyway? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. Please update passwords in .env and run this script again."
        exit 1
    fi
fi

# Start the stack
echo ""
echo "Starting ELK stack..."
echo "This may take several minutes on first run..."
echo ""

docker-compose up -d

echo ""
echo "Waiting for services to become healthy..."
echo "This can take 2-5 minutes..."
echo ""

# Wait for services
max_wait=300
elapsed=0
while [ $elapsed -lt $max_wait ]; do
    if docker-compose ps | grep -q "unhealthy"; then
        echo "Some services are still starting... ($elapsed seconds)"
        sleep 10
        elapsed=$((elapsed + 10))
    elif docker-compose ps | grep -q "(health: starting)"; then
        echo "Services are initializing... ($elapsed seconds)"
        sleep 10
        elapsed=$((elapsed + 10))
    else
        break
    fi
done

echo ""
echo "==================================="
echo "ELK Stack Setup Complete!"
echo "==================================="
echo ""
echo "Services:"
echo "  - Kibana:        https://localhost:5601"
echo "  - Elasticsearch: https://localhost:9200"
echo "  - Logstash:      tcp/udp port 5000"
echo ""
echo "Login credentials:"
echo "  - Username: elastic"
echo "  - Password: (check your .env file)"
echo ""
echo "Note: Your browser will warn about self-signed certificates."
echo "      This is expected - you can safely proceed."
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop:      docker-compose down"
echo ""

# Show service status
docker-compose ps
