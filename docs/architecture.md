# Architecture

## End-to-End Flow

```text
Developer
   │
   └─ git push
        ↓
GitHub Actions
        ↓
Terraform
        ↓
AWS EC2 + Security Group
        ↓
EC2 user_data
        ↓
Docker Compose
 ├─ Flask Web Application
 ├─ Prometheus
 ├─ Grafana
 └─ Auto-Healer
        ↓
Application /health
        ↓
Failure Detection
        ↓
Docker Socket
        ↓
Container Restart
```

## Responsibility Boundaries

### Terraform

Responsible for AWS infrastructure definition and provisioning.

Current resources:

- AWS provider in `ap-northeast-2`
- EC2 `t3.micro`
- Security Group
- EC2 bootstrap through `user_data`

Terraform is used as Infrastructure as Code. Docker Compose is not treated as IaC in this project.

### GitHub Actions

`.github/workflows/deploy.yml` runs on pushes to `main` and performs:

1. Checkout
2. Terraform setup
3. AWS authentication
4. `terraform init`
5. `terraform apply -auto-approve`

Its main responsibility is infrastructure deployment automation rather than a full application build/test/release pipeline.

### EC2 user_data

After instance creation, the bootstrap script installs the container runtime, clones this repository, and runs the Compose stack.

### Docker Compose

The Compose stack contains four services:

- `web` — Flask application
- `prometheus` — metric collection
- `grafana` — visualization
- `healer` — health polling and recovery action

### Application health and metrics

The Flask application exposes:

- `/` — basic application response
- `/health` — recovery decision signal
- `/metrics` — Prometheus metrics
- `/kill` — controlled failure injection for validation

`/metrics` and `/health` intentionally have different responsibilities:

```text
/metrics → Observability
/health  → Recovery Decision
```

### Prometheus and Grafana

Prometheus scrapes the `web:5000` target every 5 seconds. Grafana is used to inspect collected application metrics such as `http_requests_total`.

### Auto-Healer

The Python Auto-Healer requests `http://web:5000/health` every 10 seconds.

If the application returns a non-200 response or the request fails, the healer executes:

```text
docker restart web
```

The healer accesses the Docker daemon through the mounted `/var/run/docker.sock` socket.

The 10-second value is the polling interval and must not be interpreted as a guaranteed recovery time.

## Validation Model

The `/kill` endpoint does not terminate the operating system process. It switches the application's internal health flag so `/health` begins returning HTTP 500.

This provides a controlled way to validate:

```text
Healthy App
   ↓
/kill
   ↓
Unhealthy /health
   ↓
Auto-Healer detects failure
   ↓
Container restart
   ↓
New process starts with healthy state
```

This is a controlled failure simulation for the container-level recovery flow.
