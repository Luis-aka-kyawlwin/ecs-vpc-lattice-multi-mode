#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/certificates/mode-b/out"
AWS_REGION="${AWS_REGION:-us-east-1}"
DOMAIN_NAME="${1:-mode-b.local}"
SAN_DNS_2="${2:-*.mode-b.local}"

mkdir -p "${OUT_DIR}"

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "${OUT_DIR}/certificate.key" \
  -out "${OUT_DIR}/certificate.crt" \
  -sha256 \
  -days 365 \
  -subj "/CN=${DOMAIN_NAME}/O=vpc-lattice-ecs-demo/C=US" \
  -addext "subjectAltName=DNS:${DOMAIN_NAME},DNS:${SAN_DNS_2}"

# Self-signed cert has no CA chain. Keep an empty placeholder for ACM import script compatibility.
: > "${OUT_DIR}/certificate_chain.crt"

echo "Generated:"
echo "  ${OUT_DIR}/certificate.crt"
echo "  ${OUT_DIR}/certificate.key"
echo "  ${OUT_DIR}/certificate_chain.crt"
echo
echo "Next step:"
echo "  AWS_REGION=${AWS_REGION} ./certificates/mode-b/import_to_acm.sh"
