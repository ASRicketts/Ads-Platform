Ads-Platform build log

## Context

I worked through Sean Bradley's AWS platform engineering course using a fork of [Sean-Bradley/Ads-Platform](https://github.com/Sean-Bradley/Ads-Platform). The application and instructional architecture came from the course. My work was implementing the lessons in my own environment, configuring services, committing changes, and troubleshooting the problems I encountered.

This was a learning project, not a commercial production service. I completed the course, but I keep implementation evidence separate from things I have not independently verified yet.

## What I built and configured

The workload is a Python/FastAPI classified-ad application with Jinja2 templates and SQLAlchemy database access. I followed the progression from local environment configuration and SQLite to PostgreSQL, Docker Compose, and AWS deployment.

The AWS configuration includes:

- Terraform-managed VPC, public and private subnets across two availability zones, routing, and security groups.
- An Application Load Balancer forwarding to an ECS/Fargate application on port 8000.
- A Fargate service with one desired task and an execution role for container startup operations.
- RDS PostgreSQL in private subnets, with database access limited to the application security group.
- An Amazon ECR image registry used by the deployment workflow.
- CloudWatch logging configuration and a Grafana IAM user with CloudWatch read access.
- ACM certificate configuration, HTTPS listener/HTTP redirect configuration, and Python response-security headers.

The Fargate tasks use public subnets and public IPs; their application port accepts traffic only from the ALB security group. The database is not publicly accessible. The two-AZ subnet layout is not a claim that I deployed a highly available multi-task or Multi-AZ database service.

## Build progression

| Stage | Work and repository evidence |
|---|---|
| Environment configuration | Added configuration loaded from environment variables and a Python startup entry point. [PR](https://github.com/ASRicketts/Ads-Platform/pull/1) |
| PostgreSQL | Changed database connection configuration, added the PostgreSQL driver, and kept SQLite-specific engine settings conditional. [PR](https://github.com/ASRicketts/Ads-Platform/pull/2) |
| Local containers | Added Compose services, a persistent PostgreSQL volume, and database-readiness gating for the web service. [PR](https://github.com/ASRicketts/Ads-Platform/pull/3) |
| AWS networking | Added VPC, subnet, routing, and security-group configuration. [PR](https://github.com/ASRicketts/Ads-Platform/pull/4) |
| Managed containers | Added ECS/Fargate and load-balancer infrastructure. [PR](https://github.com/ASRicketts/Ads-Platform/pull/5) |
| Managed database | Added private RDS PostgreSQL configuration. [PR](https://github.com/ASRicketts/Ads-Platform/pull/6) |
| Automated delivery | Added GitHub Actions, image build/push, and ECS revision deployment. [PR](https://github.com/ASRicketts/Ads-Platform/pull/7) |
| Workflow repair | Corrected SHA syntax used for image tags. [PR](https://github.com/ASRicketts/Ads-Platform/pull/13) |
| Observability | Added CloudWatch log configuration and Grafana IAM resources. [PR](https://github.com/ASRicketts/Ads-Platform/pull/14) |
| Configuration consolidation | Moved a nested Grafana Terraform file into the main AWS configuration folder and corrected ignore patterns. [Commit](https://github.com/ASRicketts/Ads-Platform/commit/b5496e3f32e3b4199302fd440cf89b0a99194b20) |
| HTTPS and hardening | Committed TLS/listener configuration and security headers; worked through Cloudflare DNS onboarding. [Commit](https://github.com/ASRicketts/Ads-Platform/commit/67a6628451956e75010ffb26278cbe1c218a6f9a) |

## How delivery works

A push to main triggers GitHub Actions. The workflow builds a Docker image tagged with the short commit SHA, pushes it to ECR, downloads an ECS task definition, updates its container image, registers a revision, and updates the ECS service.

Terraform establishes infrastructure, while the deployment workflow handles routine task revisions. The service configuration ignores Terraform task-definition changes for that reason. The workflow does not apply Terraform or wait for service stability, so a successful job is not by itself an end-to-end health test.

## Problems I worked through

**Python startup:** Import and indentation errors prevented application startup. Reading the traceback and saving the corrected file allowed Uvicorn to reload; logs then showed successful startup and HTTP 200 responses.

**Git and GitHub:** This was my biggest learning area. I worked through feature branches, staged changes, pushes, PRs, merges, and syncing main. I also learned why a fork's comparison screen can target upstream when I intended to merge into my own repository. A PR submitted to Sean's upstream repository was closed without merging; the completed course-stage merges were in my fork.

**Commit identity:** GitHub blocked a push that would reveal my private email. With guidance, I corrected the author identity and amended the commit before continuing.

**CI/CD syntax:** I corrected the difference between GitHub expressions and shell SHA substring syntax so build, tag, push, and deployment used consistent image references. The fix was followed by a successful Actions run.

**Missing logs:** A task was running, but its deployed JSON had no logging configuration. My source did contain it. Comparing the deployed revision, code, Terraform plan, and working directory exposed unapplied changes and nested Terraform configuration. This taught me to distinguish running tasks from working telemetry.

**DNS migration:** Cloudflare's scan missed an AWS certificate-validation CNAME. Comparing it against GoDaddy's list helped identify the missing record, which I copied with DNS-only status. I also located and deleted old DNSSEC delegation records at GoDaddy after switching nameservers.

## What I learned

The project helped connect source code, containers, infrastructure, deployment revisions, networking, persistence, and DNS. More importantly, I learned to ask which layer had actually changed: saving a file, pushing a commit, registering a task definition, and updating a running service are separate steps.

I used the course and AI assistance while doing the hands-on work. My next goal is to apply what I remember to an application of my own on Google Cloud; that is future work.

## Closeout status — September 13, 2026

- Course completed, and the latest inspected [Deploy to ECS run](https://github.com/ASRicketts/Ads-Platform/actions/runs/34772433674) succeeded.
- Final log ingestion, Grafana dashboards/alerts, Cloudflare activation, and the HTTPS connection still need explicit evidence in this log.
- Review found an extra closing brace in the committed `terraform/aws/alb.tf`; local configuration must be checked and validated before claiming reproducibility.
- Root Terraform state inspection confirmed ownership of the Grafana resources.
- Cost cleanup completed for the identified project resources: zero ECS tasks, deleted load balancer and database, released allocated IPs, and emptied ECR images. Database data was discarded with explicit approval; no snapshots or automated backups remain in the project region.
- Disabled the Grafana AWS credential to stop paid metric polling. Preserved free configuration and the log group with seven-day retention.
- Historical usage was approximately $7.24, offset by credits. Billing can lag; this is not an account-wide zero-charge guarantee. See [cleanup report](CLEANUP-REPORT.md) for scope and verification.
- A blanket Terraform destroy was not used. Direct cleanup leaves state drift; a future apply can recreate billable resources.