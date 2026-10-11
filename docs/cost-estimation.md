# Cost estimation

## 72-hour development estimate

Reviewed on 2026-10-11 for `us-east-1`. Always recheck current prices.

| Resource | Assumption | Estimate |
| --- | --- | ---: |
| NAT Gateway | 72 hours at $0.045 per hour | $3.24 |
| Public IPv4 address | 72 hours at $0.005 per hour | $0.36 |
| Fixed subtotal | No compute | $3.60 |

The fixed estimate leaves about `$6.40` under the target. That margin can be
consumed by NAT data processing, cross-zone traffic, internet data transfer, S3
storage and requests, or Databricks billing. No dollar amount is guaranteed.

## Ongoing charges

The NAT Gateway and its public IPv4 address accrue charges while allocated,
even if no cluster is running. A partial NAT Gateway hour is billed as a full
hour. Delete both promptly through Terraform when the lab ends.

The S3 gateway endpoint has no hourly or data-processing charge. S3 itself is
usage based. Databricks billing depends on the linked plan and usage. The code
does not launch compute, so it does not intentionally create DBU or EC2 runtime
usage.

## Single NAT trade-off

One zonal NAT Gateway is cheaper than a NAT Gateway per Availability Zone. It is
not highly available, and traffic from the other zone can incur cross-zone data
transfer charges if compute is later launched. This trade-off is acceptable only
for the temporary learning lab.

## Budget alerts

Before deployment, create an AWS cost budget for `$10` with actual and forecast
alerts. Suggested thresholds are 50 percent, 80 percent, and 100 percent.
AWS Budget alerts are notifications, not hard spending limits.

Official pricing: [Amazon VPC pricing](https://aws.amazon.com/vpc/pricing/).
