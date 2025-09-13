# INFRASTRUCTURE SETUP

## Infrastructure Setup Documentation

This document provides a detailed breakdown of the `docker-compose.yml` file and explains how the load testing monitoring stack is configured and orchestrated.

## **Docker Compose File Structure Overview**

This `docker-compose.yml` defines a complete load testing monitoring stack with 4 services that work together:

```
Locust → Metrics Exporter → Prometheus → Grafana
```

---

## **1. Services Section**

### **Service 1: Locust Load Tester**

```yaml
locust:
  image: locustio/locust
  ports:
    - "8089:8089"
  volumes:
    - ./load_tests/:/mnt/locust
  command: -f /mnt/locust/loadtest.py
  networks:
    - monitoring
  restart: unless-stopped
  read_only: true
```

**Line-by-line explanation:**
- `image: locustio/locust` - Uses the official Locust Docker image
- `ports: "8089:8089"` - Maps host port 8089 to container port 8089 (Locust web UI)
- `volumes: ./load_tests/:/mnt/locust` - Mounts local `load_tests/` folder to `/mnt/locust` in container
- `command: -f /mnt/locust/loadtest.py` - Runs Locust with the test file from mounted volume
- `networks: monitoring` - Connects to custom network for inter-service communication
- `restart: unless-stopped` - Automatically restarts container if it crashes
- `read_only: true` - Security hardening - container filesystem is read-only

---

### **Service 2: Metrics Exporter**

```yaml
locust-metrics-exporter:
  image: containersol/locust_exporter
  ports:
    - "9646:9646"
  environment:
    - LOCUST_EXPORTER_URI=http://locust:8089
  depends_on:
    - locust
  networks:
    - monitoring
  restart: unless-stopped
  read_only: true
```

**Line-by-line explanation:**
- `image: containersol/locust_exporter` - Third-party exporter that converts Locust metrics to Prometheus format
- `ports: "9646:9646"` - Exposes metrics endpoint on port 9646
- `environment: LOCUST_EXPORTER_URI=http://locust:8089` - Tells exporter where to find Locust API
  - Notice it uses `locust:8089` (service name) instead of `localhost` - Docker internal networking
- `depends_on: locust` - Ensures Locust starts before this service
- Other settings same as above for consistency

---

### **Service 3: Prometheus Time-Series Database**

```yaml
prometheus:
  image: prom/prometheus:latest
  container_name: prometheus
  volumes:
    - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
  ports:
    - "9090:9090"
  command:
    - '--config.file=/etc/prometheus/prometheus.yml'
  networks:
    - monitoring
  restart: unless-stopped
  read_only: true
```

**Line-by-line explanation:**
- `image: prom/prometheus:latest` - Official Prometheus image
- `container_name: prometheus` - Sets explicit container name (useful for networking)
- `volumes: ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro` - Mounts config file
  - `:ro` means read-only mount
- `ports: "9090:9090"` - Prometheus web UI and API port
- `command: '--config.file=/etc/prometheus/prometheus.yml'` - Specifies config file location
- Same network and restart policies

---

### **Service 4: Grafana Visualization**

```yaml
grafana:
  image: grafana/grafana:latest
  container_name: grafana
  ports:
    - "3000:3000"
  volumes:
    - grafana_data:/var/lib/grafana
    - ./Dashboard/dashboard.json:/etc/grafana/provisioning/dashboards/dashboard.json:ro
    - ./Dashboard/provisioning/dashboards.yml:/etc/grafana/provisioning/dashboards/dashboards.yml:ro
    - ./Dashboard/provisioning/datasources.yml:/etc/grafana/provisioning/datasources/datasources.yml:ro
  environment:
    - GF_SECURITY_ADMIN=${GF_SECURITY_ADMIN:-admin}
    - GF_SECURITY_PASSWORD=${GF_SECURITY_PASSWORD:-admin}
  depends_on:
    - prometheus
  networks:
    - monitoring
  restart: unless-stopped
  read_only: true
```

**Line-by-line explanation:**
- `image: grafana/grafana:latest` - Official Grafana image
- `ports: "3000:3000"` - Grafana web UI port
- **Multiple volumes for different purposes:**
  - `grafana_data:/var/lib/grafana` - Named volume for persistent data storage
  - `./Dashboard/dashboard.json:...` - Pre-built dashboard configuration
  - `./Dashboard/provisioning/dashboards.yml:...` - Dashboard auto-provisioning config
  - `./Dashboard/provisioning/datasources.yml:...` - Prometheus datasource auto-config
- **Environment variables for credentials:**
  - `GF_SECURITY_ADMIN=${GF_SECURITY_ADMIN:-admin}` - Admin username (default: "admin")
  - `GF_SECURITY_PASSWORD=${GF_SECURITY_PASSWORD:-admin}` - Admin password (default: "admin")
  - The `${VAR:-default}` syntax means "use environment variable VAR, or 'default' if not set"
- `depends_on: prometheus` - Ensures Prometheus is running first

---

## **2. Named Volumes Section**

```yaml
volumes:
  grafana_data:
```

**Explanation:**
- Creates a named volume called `grafana_data`
- This persists Grafana data (dashboards, users, settings) even when containers are recreated
- Docker manages this volume's lifecycle independently of containers

---

## **3. Networks Section**

```yaml
networks:
  monitoring:
    driver: bridge
```

**Explanation:**
- Creates a custom network called `monitoring`
- Uses `bridge` driver (default for single-host networking)
- All services can communicate using service names (e.g., `http://locust:8089`)
- Isolates this stack from other Docker containers

---

## **Data Flow Architecture**

Here's how the services interact:

1. **Locust** (`localhost:8089`) runs load tests and exposes stats API
2. **Metrics Exporter** (`localhost:9646`) polls Locust API every few seconds, converts to Prometheus format
3. **Prometheus** (`localhost:9090`) scrapes metrics from exporter every 5 seconds, stores time-series data
4. **Grafana** (`localhost:3000`) queries Prometheus for data and displays dashboards

## **Key Design Patterns**

1. **Service Discovery**: Services use container names for internal communication
2. **Configuration as Code**: All configs mounted from host filesystem
3. **Security Hardening**: Read-only containers, custom networks
4. **Zero-Config Setup**: Grafana auto-provisions dashboards and datasources
5. **Persistence**: Only Grafana data is persisted; metrics are ephemeral

## **Port Summary**

| Service | Port | Purpose |
|---------|------|---------|
| `8089` | Locust | Web UI for load testing |
| `9646` | Metrics Exporter | Prometheus metrics endpoint |
| `9090` | Prometheus | Time-series database UI |
| `3000` | Grafana | Dashboard visualization |

## **Container Dependencies**

```
grafana
  └── depends_on: prometheus
      └── (no dependencies)

locust-metrics-exporter
  └── depends_on: locust
      └── (no dependencies)
```

## **Volume Mounts**

### Host to Container Mounts
- `./load_tests/` → `/mnt/locust` (Locust test files)
- `./prometheus/prometheus.yml` → `/etc/prometheus/prometheus.yml` (Prometheus config)
- `./Dashboard/dashboard.json` → `/etc/grafana/provisioning/dashboards/dashboard.json` (Pre-built dashboard)
- `./Dashboard/provisioning/` → `/etc/grafana/provisioning/` (Auto-provisioning configs)

### Named Volumes
- `grafana_data` → `/var/lib/grafana` (Persistent Grafana data)

## **Environment Configuration**

### Grafana Credentials
```bash
# Default credentials
GF_SECURITY_ADMIN=admin
GF_SECURITY_PASSWORD=admin

# Custom credentials (set before running docker-compose)
export GF_SECURITY_ADMIN=myusername
export GF_SECURITY_PASSWORD=mypassword
```

### Service URLs (Internal Network)
- Locust API: `http://locust:8089`
- Metrics Exporter: `http://locust-metrics-exporter:9646`
- Prometheus: `http://prometheus:9090`
- Grafana: `http://grafana:3000`

## **Startup Sequence**

1. **Network Creation**: `monitoring` bridge network is created
2. **Volume Creation**: `grafana_data` named volume is created
3. **Service Startup** (respecting dependencies):
   - `locust` starts first (no dependencies)
   - `locust-metrics-exporter` starts after locust
   - `prometheus` starts (no dependencies, but after network/volumes)
   - `grafana` starts after prometheus

## **Common Operations**

### Start the stack
```bash
docker-compose up -d
```

### View logs
```bash
docker-compose logs [service-name]
docker-compose logs -f  # Follow logs for all services
```

### Check service status
```bash
docker-compose ps
```

### Scale services (if needed)
```bash
docker-compose up -d --scale locust=2
```

### Stop and cleanup
```bash
docker-compose down        # Stop containers
docker-compose down -v     # Stop containers and remove volumes
```

## **Security Features**

1. **Read-only containers**: All containers use `read_only: true`
2. **Isolated networking**: Custom `monitoring` network
3. **Minimal attack surface**: No unnecessary ports exposed
4. **Configuration isolation**: Configs mounted read-only
5. **Credential management**: Environment variable based auth

This setup provides a complete, production-ready monitoring stack that starts with a single `docker-compose up -d` command!