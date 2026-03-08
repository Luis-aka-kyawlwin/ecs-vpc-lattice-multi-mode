#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <mode-a-http|mode-b-https|mode-c-tls>"
  exit 1
fi

MODE="$1"
ENV_DIR="terraform/environments/${MODE}"

if [[ ! -d "${ENV_DIR}" ]]; then
  echo "Invalid mode: ${MODE}"
  exit 1
fi

pushd "${ENV_DIR}" >/dev/null

DASHBOARD_CLUSTER="$(terraform output -raw dashboard_cluster_name)"
COUNTING_CLUSTER="$(terraform output -raw counting_cluster_name)"
DASHBOARD_SERVICE="$(terraform output -raw dashboard_service_name)"
COUNTING_SERVICE="$(terraform output -raw counting_service_name)"
TG_ARN="$(terraform output -raw lattice_target_group_arn)"
DNS_NAME="$(terraform output -raw counting_service_dns)"

echo "==> ECS service stability"
aws ecs describe-services --cluster "${DASHBOARD_CLUSTER}" --services "${DASHBOARD_SERVICE}" \
  --query 'services[0].{status:status,running:runningCount,desired:desiredCount,events:events[0].message}' --output table

aws ecs describe-services --cluster "${COUNTING_CLUSTER}" --services "${COUNTING_SERVICE}" \
  --query 'services[0].{status:status,running:runningCount,desired:desiredCount,events:events[0].message}' --output table

echo "==> VPC Lattice target health"
aws vpc-lattice list-targets --target-group-identifier "${TG_ARN}" \
  --query 'items[].{id:id,status:status,reason:reasonCode,lastUpdated:lastUpdatedAt}' --output table

echo "==> DNS endpoint (use from within VPC)"
if [[ "${MODE}" == "mode-a-http" ]]; then
  echo "http://${DNS_NAME}"
else
  echo "https://${DNS_NAME}"
fi

popd >/dev/null
