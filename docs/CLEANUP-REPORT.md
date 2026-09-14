AWS project cost cleanup — September 13, 2026

Cleanup was limited to the Ads-Platform project's identified cost sources. Free configuration and source code were preserved. Actions used AWS APIs rather than a blanket Terraform destroy.

## Verified results

| Resource | Result |
|---|---|
| ECS service | Desired, running, and pending tasks all zero; service and cluster retained. |
| Application Load Balancer | Deleted; attached listeners removed with it. |
| Allocated public IPv4 addresses | No allocations remain in us-east-1 after load-balancer removal. |
| RDS PostgreSQL | Permanently deleted after explicit approval to discard data without a final snapshot. No DB instances, snapshots, or automated backups remain in us-east-1. |
| ECR images | Image list empty; repository retained for future builds. |
| Grafana AWS access key | Inactive, preventing this credential from continuing paid CloudWatch metric queries; IAM user and key retained. |

Additional inventory found no EC2 instances, EBS volumes, NAT gateways, Secrets Manager secrets, metric alarms, or CloudWatch dashboards in us-east-1, and no S3 buckets. The CloudWatch log group was retained with seven-day retention and approximately 315 KB of logs. The billed CloudWatch usage was metric queries, not log storage.

Preserved: GitHub and local source, Terraform files/state, VPC, subnets, routes, security groups, IAM identities, certificates, ECS configuration, ECR repository, target group, and the domain. Cloudflare/Grafana subscription tiers and domain renewal were not audited or changed.

## Cost evidence and limits

Cost Explorer's estimated September 1–13 usage was approximately $7.24, offset by approximately $7.24 in credits. A near-zero net bill therefore did not mean resources were free. CloudWatch metric queries accounted for $0.14439. Billing data can arrive after deletion; these figures are historical, not a guarantee of a zero future account balance.

The live resource audit covered the project region, us-east-1, plus global S3 bucket inventory. It was not an exhaustive all-region, all-service or subscription audit. Identified project compute, database/storage, load balancer, allocated IP, image-storage, and Grafana polling cost sources have been removed or disabled.

## Rebuild implications

The root Terraform state includes the Grafana resources; only the root state and its backup were found in the inspected project. Historical questions about how the files were consolidated remain separate from current ownership.

Direct AWS cleanup intentionally leaves Terraform drift. The configuration still describes resources that were deleted and a desired task count of one. A future Terraform apply can recreate chargeable infrastructure. Do not treat the saved state as proof those resources still exist. No state entries were manually removed.