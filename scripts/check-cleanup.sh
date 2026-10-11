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
role_name="$(value '.cross_account_role_name')"
bucket_name="$(value '.root_bucket_name')"
workspace_id="$(value '.workspace_id')"
project_name="$(value '.project_name')"
environment="$(value '.environment')"
found=0
unverified=0

check_absent() {
    local label="$1"
    local expected_not_found="$2"
    shift
    shift

    local output
    if output="$("$@" 2>&1)"; then
        printf '[FOUND] %s\n' "${label}"
        found=1
    else
        if [[ "${output}" =~ ${expected_not_found} ]]; then
            printf '[ABSENT] %s\n' "${label}"
        else
            printf '[ERROR] Could not verify %s: %s\n' "${label}" "${output}" >&2
            exit 2
        fi
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
else
    if [[ "${nat_state}" =~ InvalidNatGatewayID\.NotFound ]]; then
        printf '[ABSENT] NAT Gateway %s\n' "${nat_gateway_id}"
    else
        printf '[ERROR] Could not verify NAT Gateway %s: %s\n' "${nat_gateway_id}" "${nat_state}" >&2
        exit 2
    fi
fi

check_absent "Elastic IP ${public_ip}" 'InvalidAddress\.NotFound' \
    aws ec2 describe-addresses --region "${aws_region}" --public-ips "${public_ip}"
check_absent "IAM role ${role_name}" 'NoSuchEntity' \
    aws iam get-role --role-name "${role_name}"
check_absent "S3 bucket ${bucket_name}" '(404|Not Found)' \
    aws s3api head-bucket --bucket "${bucket_name}"

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

if command -v databricks >/dev/null 2>&1; then
    check_absent "Databricks workspace ${workspace_id}" '(NOT_FOUND|RESOURCE_DOES_NOT_EXIST|404)' \
        databricks account workspaces get "${workspace_id}" --output json
else
    printf '[ERROR] Databricks workspace check could not run because the CLI is unavailable\n' >&2
    unverified=1
fi

if ((found > 0)); then
    printf '%s\n' 'Cleanup is incomplete. Review every FOUND item without deleting unrelated resources.' >&2
    exit 1
fi

if ((unverified > 0)); then
    printf '%s\n' 'Cleanup could not be fully verified.' >&2
    exit 2
fi

printf '%s\n' 'Cleanup checks passed for the recorded project resources.'
