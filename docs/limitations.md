# Limitations and Security Notes

This repository is a portfolio prototype for infrastructure deployment automation and container-level recovery. It should not be interpreted as a production-ready self-healing platform.

## 1. AWS authentication

The current GitHub Actions workflow authenticates with:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

stored as GitHub Repository Secrets.

This avoids committing credentials to source code, but it still relies on long-lived IAM credentials.

A stronger production pattern would be:

```text
GitHub Actions
    ↓
OIDC
    ↓
IAM Role
    ↓
Temporary Credentials
```

## 2. IAM permission scope

The original prototype used broad AWS permissions to simplify initial provisioning. Production use should restrict the IAM policy to only the resources and actions Terraform actually requires.

## 3. Security Group exposure

The current Terraform configuration allows inbound access from `0.0.0.0/0` to:

- 22 / SSH
- 5000 / Flask
- 3000 / Grafana
- 9090 / Prometheus

This is intentionally documented as a limitation rather than presented as a secure production configuration.

A production design should limit administrative ports to trusted sources, avoid direct public exposure of internal monitoring services, and place services behind appropriate network boundaries or reverse proxies.

## 4. Docker socket privilege

The Auto-Healer mounts:

```text
/var/run/docker.sock
```

This provides powerful control over the host Docker daemon. A compromised healer container could potentially affect other containers or the host runtime.

Production environments should prefer a more constrained orchestration or recovery mechanism with explicit authorization boundaries.

## 5. Single-instance dependency

The Flask application, Prometheus, Grafana, and Auto-Healer all depend on the same EC2 instance.

Therefore container restart cannot recover failures such as:

- EC2 instance failure
- Availability Zone failure
- host-level Docker failure
- network failure

Potential next steps include Auto Scaling Groups, ECS Services, Kubernetes, or multi-AZ architecture depending on the target operating model.

## 6. Restart-based recovery

The current recovery action is:

```text
docker restart web
```

This can recover some runtime failures, but it does not remove the root cause of repeated application logic errors, memory exhaustion, bad configuration, or external dependency failures.

A more mature recovery policy would add:

- retry limits
- exponential backoff
- failure classification
- alert escalation
- restart-loop detection

## 7. Recovery timing

The healer sleeps for 10 seconds between health checks. This means 10 seconds is the polling interval, not a measured or guaranteed recovery objective.

This repository does not claim:

- guaranteed recovery within 10 seconds
- zero downtime
- measured MTTR improvement
- infrastructure-level self-healing

## 8. Controlled failure injection

The `/kill` endpoint changes an in-memory health flag so `/health` returns HTTP 500. It does not simulate every real production failure mode.

Its purpose is to provide a repeatable, controlled validation path for the container-level recovery mechanism.
