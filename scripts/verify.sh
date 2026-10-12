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
public_subnet_id="$(value '.public_subnet_id')"
nat_gateway_id="$(value '.nat_gateway_id')"
security_group_id="$(value '.security_group_id')"
s3_gateway_endpoint_id="$(value '.s3_gateway_endpoint_id')"
mapfile -t private_subnet_ids < <(jq -r '.private_subnet_ids[]' <<<"${summary}")

printf 'Verifying AWS networking in %s\n' "${aws_region}"
aws sts get-caller-identity --output table
aws ec2 describe-vpcs \
    --region "${aws_region}" \
    --vpc-ids "${vpc_id}" \
    --query 'Vpcs[0].{VpcId:VpcId,CidrBlock:CidrBlock,State:State}' \
    --output table
aws ec2 describe-subnets \
    --region "${aws_region}" \
    --subnet-ids "${public_subnet_id}" "${private_subnet_ids[@]}" \
    --query 'Subnets[].{SubnetId:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone,PublicIpOnLaunch:MapPublicIpOnLaunch}' \
    --output table
aws ec2 describe-route-tables \
    --region "${aws_region}" \
    --filters "Name=vpc-id,Values=${vpc_id}" \
    --query 'RouteTables[].{RouteTableId:RouteTableId,Associations:Associations[].SubnetId,Routes:Routes[].{Destination:DestinationCidrBlock,Gateway:GatewayId,Nat:NatGatewayId,State:State}}' \
    --output json
aws ec2 describe-nat-gateways \
    --region "${aws_region}" \
    --nat-gateway-ids "${nat_gateway_id}" \
    --query 'NatGateways[0].{NatGatewayId:NatGatewayId,State:State,SubnetId:SubnetId,PublicIp:NatGatewayAddresses[0].PublicIp}' \
    --output table
aws ec2 describe-security-group-rules \
    --region "${aws_region}" \
    --filters "Name=group-id,Values=${security_group_id}" \
    --query 'SecurityGroupRules[].{Egress:IsEgress,Protocol:IpProtocol,From:FromPort,To:ToPort,Cidr:CidrIpv4,ReferencedGroup:ReferencedGroupInfo.GroupId}' \
    --output table

if [[ -n "${s3_gateway_endpoint_id}" && "${s3_gateway_endpoint_id}" != "null" ]]; then
    aws ec2 describe-vpc-endpoints \
        --region "${aws_region}" \
        --vpc-endpoint-ids "${s3_gateway_endpoint_id}" \
        --query 'VpcEndpoints[0].{Id:VpcEndpointId,State:State,Type:VpcEndpointType,Service:ServiceName}' \
        --output table
fi

mkdir -p "${artifact_dir}"
umask 077
printf '%s\n' "${summary}" >"${artifact_dir}/dev-deployment.json"
printf 'Saved deployment summary to %s\n' \
    "${artifact_dir}/dev-deployment.json"
