# Project 04. Auto-Healing SRE System

IaC & Infrastructure Deployment Automation 기반 Auto-Healing SRE Monitoring System

> Terraform과 GitHub Actions로 AWS Infrastructure Provisioning을 자동화하고, Prometheus 기반 Health Signal과 Docker Auto-Healer를 연결하여 Failure Detection → Recovery Action을 구현한 SRE/DevOps 프로젝트입니다.

## Architecture

```text
Git Push
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
       GET /health
            ↓
      Failure Detection
            ↓
       docker restart web
```

## What this project implements

- **Infrastructure as Code** — `main.tf` defines the AWS EC2 instance and Security Group.
- **Infrastructure Deployment Automation** — pushes to `main` trigger GitHub Actions, which runs `terraform init` and `terraform apply -auto-approve`.
- **Bootstrap Automation** — EC2 `user_data` installs Docker/Docker Compose, clones the repository, and starts the workload.
- **Container Runtime** — Docker Compose runs the Flask app, Prometheus, Grafana, and Auto-Healer.
- **Observability** — the Flask app exposes `/metrics`; Prometheus scrapes it every 5 seconds and Grafana visualizes the collected metrics.
- **Health-based Recovery** — the Auto-Healer checks `/health` every 10 seconds and restarts the `web` container when the response is unhealthy.
- **Controlled Failure Injection** — `/kill` switches the application into an unhealthy state so the recovery flow can be validated safely.

## Repository structure

```text
SRE_project/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docs/
│   ├── architecture.md
│   └── limitations.md
├── app.py
├── healer.py
├── main.tf
├── docker-compose.yml
├── prometheus.yml
├── Dockerfile
├── .gitignore
└── README.md
```

## Core flow

### 1. Infrastructure deployment

`main.tf` defines the AWS resources. GitHub Actions runs Terraform automatically after a push to `main`.

```text
Git Push → GitHub Actions → Terraform Apply → AWS EC2 / Security Group
```

### 2. Runtime bootstrap

After EC2 creation, `user_data` prepares the Docker runtime and starts the Compose stack.

```text
EC2 Created → user_data → Docker Setup → docker-compose up -d --build
```

### 3. Observability

The Flask application exposes Prometheus metrics at `/metrics`.

```text
Flask /metrics → Prometheus → Grafana
```

### 4. Auto-Healing

The Auto-Healer polls `/health` every 10 seconds. A non-200 response triggers a container restart through the Docker socket.

```text
/health → Auto-Healer → Failure Detection → Docker Socket → Container Restart
```

The 10-second value is the **health-check interval**, not a guaranteed recovery time.

### 5. Recovery validation

The `/kill` endpoint intentionally changes the app into an unhealthy state. This is a controlled failure simulation used to validate the recovery pipeline; it is not a real production outage or attack.

## Technology stack

- AWS EC2
- Terraform
- GitHub Actions
- Docker / Docker Compose
- Python / Flask
- Prometheus
- Grafana

## Design decisions

| Problem | Decision | Reason |
|---|---|---|
| Manual AWS resource creation | Terraform | Manage infrastructure configuration as code |
| Manual Terraform execution | GitHub Actions | Connect repository workflow with infrastructure deployment |
| Manual EC2 setup | `user_data` | Automate instance bootstrap |
| Multiple runtime services | Docker Compose | Manage application and monitoring services together |
| Recovery decision signal | `/health` | Provide a simple, explicit health signal |
| Metrics collection | Prometheus | Collect application metrics |
| Metric visualization | Grafana | Inspect application behavior |
| Manual restart | Python Auto-Healer | Connect failure detection to a recovery action |

## Scope and limitations

This repository demonstrates a **container-level Auto-Healing prototype**, not a production-grade self-healing infrastructure platform.

Key limitations include:

- AWS authentication currently uses repository secrets with long-lived IAM access keys.
- The current Security Group allows ports 22, 5000, 3000, and 9090 from `0.0.0.0/0`.
- The Auto-Healer mounts `/var/run/docker.sock`, which grants powerful access to the host Docker daemon.
- Application, monitoring, and recovery components depend on a single EC2 instance.
- Recovery is based on container restart and does not address repeated application logic failures or infrastructure-level failures.

See [docs/limitations.md](docs/limitations.md) for details.

## Portfolio

Detailed engineering notes, screenshots, architecture evolution, and validation evidence are documented in Notion.

[Project 04 Notion Portfolio](https://app.notion.com/p/3b059c94122580ca9c23f4efac60b2a7)

## Engineering journey

```text
Project 01  BUILD
     ↓
Project 02  SECURE
     ↓
Project 03  OBSERVE
     ↓
Project 04  AUTOMATE
```

Project 04 focuses on coding and automating the infrastructure provisioning and recovery lifecycle that remained operationally manual in the previous stages.
