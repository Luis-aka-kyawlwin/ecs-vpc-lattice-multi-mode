#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <mode-a-http|mode-b-https|mode-c-tls> <plan|apply|destroy> [tfvars_file]"
  exit 1
fi

MODE="$1"
ACTION="$2"
TFVARS_FILE="${3:-terraform.tfvars}"
ENV_DIR="terraform/environments/${MODE}"

if [[ ! -d "${ENV_DIR}" ]]; then
  echo "Invalid mode: ${MODE}"
  exit 1
fi

if [[ ! -f "${ENV_DIR}/${TFVARS_FILE}" ]]; then
  echo "Missing vars file: ${ENV_DIR}/${TFVARS_FILE}"
  echo "Copy ${ENV_DIR}/terraform.tfvars.example first."
  exit 1
fi

pushd "${ENV_DIR}" >/dev/null

echo "==> terraform init (${MODE})"
terraform init

case "${ACTION}" in
  plan)
    terraform plan -var-file="${TFVARS_FILE}" -out=tfplan
    ;;
  apply)
    terraform apply -var-file="${TFVARS_FILE}" -auto-approve
    ;;
  destroy)
    terraform destroy -var-file="${TFVARS_FILE}" -auto-approve
    ;;
  *)
    echo "Invalid action: ${ACTION}"
    exit 1
    ;;
esac

popd >/dev/null
