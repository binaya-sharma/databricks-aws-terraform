#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
evidence_file="${1:-${repo_root}/.artifacts/dev-deployment.json}"

if [[ ! -f "${evidence_file}" ]]; then
    printf 'Cleanup evidence file not found: %s\n' "${evidence_file}" >&2
    printf '%s\n' 'Run scripts/verify.sh before terraform destroy.' >&2
    exit 1
fi

for command_name in aws jq; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "${command_name}" >&2
        exit 1
    fi
done

value() {
    jq -r "$1" "${evidence_file}"
}

aws_region="$(value '.aws_region')"
vpc_id="$(value '.vpc_id')"
nat_gateway_id="$(value '.nat_gateway_id')"
public_ip="$(value '.nat_gateway_public_ip')"
security_group_id="$(value '.security_group_id')"
s3_gateway_endpoint_id="$(value '.s3_gateway_endpoint_id')"
project_name="$(value '.project_name')"
environment="$(value '.environment')"
found=0

check_absent() {
    local label="$1"
    local expected_not_found="$2"
    shift 2

    local output
    if output="$("$@" 2>&1)"; then
        printf '[FOUND] %s\n' "${label}"
        found=1
    elif [[ "${output}" =~ ${expected_not_found} ]]; then
        printf '[ABSENT] %s\n' "${label}"
    else
        printf '[ERROR] Could not verify %s: %s\n' "${label}" "${output}" >&2
        exit 2
    fi
}

aws sts get-caller-identity --region "${aws_region}" >/dev/null

check_absent "VPC ${vpc_id}" 'InvalidVpcID\.NotFound' \
    aws ec2 describe-vpcs --region "${aws_region}" --vpc-ids "${vpc_id}"

if nat_state="$(aws ec2 describe-nat-gateways \
    --region "${aws_region}" \
    --nat-gateway-ids "${nat_gateway_id}" \
    --query 'NatGateways[0].State' \
    --output text 2>&1)"; then
    if [[ -z "${nat_state}" || "${nat_state}" == "None" || "${nat_state}" == "deleted" ]]; then
        printf '[ABSENT] NAT Gateway %s\n' "${nat_gateway_id}"
    else
        printf '[FOUND] NAT Gateway %s in state %s\n' "${nat_gateway_id}" "${nat_state}"
        found=1
    fi
elif [[ "${nat_state}" =~ InvalidNatGatewayID\.NotFound ]]; then
    printf '[ABSENT] NAT Gateway %s\n' "${nat_gateway_id}"
else
    printf '[ERROR] Could not verify NAT Gateway %s: %s\n' "${nat_gateway_id}" "${nat_state}" >&2
    exit 2
fi

check_absent "Elastic IP ${public_ip}" 'InvalidAddress\.NotFound' \
    aws ec2 describe-addresses --region "${aws_region}" --public-ips "${public_ip}"
check_absent "Security group ${security_group_id}" 'InvalidGroup\.NotFound' \
    aws ec2 describe-security-groups --region "${aws_region}" --group-ids "${security_group_id}"

if [[ -n "${s3_gateway_endpoint_id}" && "${s3_gateway_endpoint_id}" != "null" ]]; then
    check_absent "S3 Gateway Endpoint ${s3_gateway_endpoint_id}" 'InvalidVpcEndpointId\.NotFound' \
        aws ec2 describe-vpc-endpoints --region "${aws_region}" --vpc-endpoint-ids "${s3_gateway_endpoint_id}"
fi

instance_ids="$(aws ec2 describe-instances \
    --region "${aws_region}" \
    --filters \
        "Name=tag:Project,Values=${project_name}" \
        "Name=tag:Environment,Values=${environment}" \
        'Name=instance-state-name,Values=pending,running,stopping,stopped' \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)"
volume_ids="$(aws ec2 describe-volumes \
    --region "${aws_region}" \
    --filters \
        "Name=tag:Project,Values=${project_name}" \
        "Name=tag:Environment,Values=${environment}" \
    --query 'Volumes[].VolumeId' \
    --output text)"

if [[ -n "${instance_ids}" ]]; then
    printf '[FOUND] Tagged EC2 instances: %s\n' "${instance_ids}"
    found=1
else
    printf '[ABSENT] Tagged EC2 instances\n'
fi

if [[ -n "${volume_ids}" ]]; then
    printf '[FOUND] Tagged EBS volumes: %s\n' "${volume_ids}"
    found=1
else
    printf '[ABSENT] Tagged EBS volumes\n'
fi

if ((found > 0)); then
    printf '%s\n' 'Networking cleanup is incomplete. Review every FOUND item without deleting unrelated resources.' >&2
    exit 1
fi

printf '%s\n' 'Networking cleanup checks passed for the recorded project resources.'
