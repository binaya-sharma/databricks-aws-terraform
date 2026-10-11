#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
environment_dir="${repo_root}/infrastructure/environments/dev"
artifact_dir="${repo_root}/.artifacts"

for command_name in terraform aws jq; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "${command_name}" >&2
        exit 1
    fi
done

summary="$(terraform -chdir="${environment_dir}" output -json deployment_summary)"

value() {
    jq -r "$1" <<<"${summary}"
}

aws_region="$(value '.aws_region')"
vpc_id="$(value '.vpc_id')"
nat_gateway_id="$(value '.nat_gateway_id')"
security_group_id="$(value '.security_group_id')"
role_name="$(value '.cross_account_role_name')"
bucket_name="$(value '.root_bucket_name')"
workspace_id="$(value '.workspace_id')"
workspace_url="$(value '.workspace_url')"

mapfile -t private_subnet_ids < <(jq -r '.private_subnet_ids[]' <<<"${summary}")

printf 'Verifying AWS resources in %s\n' "${aws_region}"
aws ec2 describe-vpcs \
    --region "${aws_region}" \
    --vpc-ids "${vpc_id}" \
    --query 'Vpcs[0].{VpcId:VpcId,CidrBlock:CidrBlock,State:State}'

aws ec2 describe-subnets \
    --region "${aws_region}" \
    --subnet-ids "${private_subnet_ids[@]}" \
    --query 'Subnets[].{SubnetId:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone,PublicIpOnLaunch:MapPublicIpOnLaunch}'

aws ec2 describe-route-tables \
    --region "${aws_region}" \
    --filters "Name=association.subnet-id,Values=${private_subnet_ids[0]},${private_subnet_ids[1]}" \
    --query 'RouteTables[].{RouteTableId:RouteTableId,Routes:Routes}'

aws ec2 describe-nat-gateways \
    --region "${aws_region}" \
    --nat-gateway-ids "${nat_gateway_id}" \
    --query 'NatGateways[0].{NatGatewayId:NatGatewayId,State:State,SubnetId:SubnetId,PublicIp:NatGatewayAddresses[0].PublicIp}'

aws ec2 describe-security-group-rules \
    --region "${aws_region}" \
    --filters "Name=group-id,Values=${security_group_id}" \
    --query 'SecurityGroupRules[].{Egress:IsEgress,Protocol:IpProtocol,From:FromPort,To:ToPort,Cidr:CidrIpv4,ReferencedGroup:ReferencedGroupInfo.GroupId}'

aws s3api head-bucket --bucket "${bucket_name}"
aws iam get-role --role-name "${role_name}" --query 'Role.{RoleName:RoleName,Arn:Arn}'

printf 'Verifying Databricks account workspace %s\n' "${workspace_id}"
databricks account workspaces get "${workspace_id}" --output json \
    | jq '{workspace_id, workspace_name, workspace_status, workspace_status_message, workspace_url}'

if [[ -n "${DATABRICKS_WORKSPACE_PROFILE:-}" ]]; then
    clusters="$(databricks clusters list --profile "${DATABRICKS_WORKSPACE_PROFILE}" --output json)"
    cluster_count="$(jq 'length' <<<"${clusters}")"
    printf 'Clusters returned for the last 30 days: %s\n' "${cluster_count}"
    jq '[.[] | {cluster_id, cluster_name, state}]' <<<"${clusters}"
else
    printf '%s\n' \
        "Cluster verification skipped." \
        "Set DATABRICKS_WORKSPACE_PROFILE to a profile for ${workspace_url} and run again."
fi

mkdir -p "${artifact_dir}"
umask 077
printf '%s\n' "${summary}" >"${artifact_dir}/dev-deployment.json"
printf 'Saved non-sensitive cleanup evidence to %s\n' \
    "${artifact_dir}/dev-deployment.json"
