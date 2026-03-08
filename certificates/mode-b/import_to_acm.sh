#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/certificates/mode-b/out"
AWS_REGION="${AWS_REGION:-us-east-1}"

CERT_FILE="${OUT_DIR}/certificate.crt"
KEY_FILE="${OUT_DIR}/certificate.key"
CHAIN_FILE="${OUT_DIR}/certificate_chain.crt"

if [[ ! -f "${CERT_FILE}" || ! -f "${KEY_FILE}" ]]; then
  echo "Missing certificate files. Run:"
  echo "  ./certificates/mode-b/generate_self_signed.sh"
  exit 1
fi

if [[ -s "${CHAIN_FILE}" ]]; then
  ACM_ARN="$(aws acm import-certificate \
    --region "${AWS_REGION}" \
    --certificate "fileb://${CERT_FILE}" \
    --private-key "fileb://${KEY_FILE}" \
    --certificate-chain "fileb://${CHAIN_FILE}" \
    --query 'CertificateArn' --output text)"
else
  ACM_ARN="$(aws acm import-certificate \
    --region "${AWS_REGION}" \
    --certificate "fileb://${CERT_FILE}" \
    --private-key "fileb://${KEY_FILE}" \
    --query 'CertificateArn' --output text)"
fi

echo "Imported ACM certificate ARN:"
echo "  ${ACM_ARN}"
echo
echo "Set in mode-b tfvars:"
echo "  certificate_arn = \"${ACM_ARN}\""
