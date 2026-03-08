#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <dockerhub_user> <dockerhub_tag> <aws_account_id> <aws_region> <ecr_repo_prefix>"
  echo "Example: $0 myuser v1 123456789012 us-east-1 vpc-lattice-ecs-demo"
  exit 1
fi

DOCKERHUB_USER="$1"
IMAGE_TAG="$2"
AWS_ACCOUNT_ID="$3"
AWS_REGION="$4"
ECR_PREFIX="$5"

DASHBOARD_APP_DIR="applications/dashboard-service"
COUNTING_APP_DIR="applications/counting-service"

DASHBOARD_LOCAL_IMAGE="dashboard-service:${IMAGE_TAG}"
COUNTING_LOCAL_IMAGE="counting-service:${IMAGE_TAG}"

DASHBOARD_DOCKERHUB_IMAGE="${DOCKERHUB_USER}/dashboard-service:${IMAGE_TAG}"
COUNTING_DOCKERHUB_IMAGE="${DOCKERHUB_USER}/counting-service:${IMAGE_TAG}"

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
DASHBOARD_ECR_REPO="${ECR_PREFIX}-dashboard-service"
COUNTING_ECR_REPO="${ECR_PREFIX}-counting-service"
DASHBOARD_ECR_IMAGE="${ECR_REGISTRY}/${DASHBOARD_ECR_REPO}:${IMAGE_TAG}"
COUNTING_ECR_IMAGE="${ECR_REGISTRY}/${COUNTING_ECR_REPO}:${IMAGE_TAG}"

echo "==> Building local images"
docker build -t "${DASHBOARD_LOCAL_IMAGE}" "${DASHBOARD_APP_DIR}"
docker build -t "${COUNTING_LOCAL_IMAGE}" "${COUNTING_APP_DIR}"

echo "==> Tagging Docker Hub images"
docker tag "${DASHBOARD_LOCAL_IMAGE}" "${DASHBOARD_DOCKERHUB_IMAGE}"
docker tag "${COUNTING_LOCAL_IMAGE}" "${COUNTING_DOCKERHUB_IMAGE}"

echo "==> Pushing Docker Hub images"
docker push "${DASHBOARD_DOCKERHUB_IMAGE}"
docker push "${COUNTING_DOCKERHUB_IMAGE}"

echo "==> Logging in to ECR"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

echo "==> Ensuring ECR repositories exist"
aws ecr describe-repositories --repository-names "${DASHBOARD_ECR_REPO}" --region "${AWS_REGION}" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "${DASHBOARD_ECR_REPO}" --region "${AWS_REGION}" >/dev/null

aws ecr describe-repositories --repository-names "${COUNTING_ECR_REPO}" --region "${AWS_REGION}" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "${COUNTING_ECR_REPO}" --region "${AWS_REGION}" >/dev/null

echo "==> Tagging ECR images"
docker tag "${DASHBOARD_LOCAL_IMAGE}" "${DASHBOARD_ECR_IMAGE}"
docker tag "${COUNTING_LOCAL_IMAGE}" "${COUNTING_ECR_IMAGE}"

echo "==> Pushing ECR images"
docker push "${DASHBOARD_ECR_IMAGE}"
docker push "${COUNTING_ECR_IMAGE}"

echo ""
echo "Images ready:"
echo "dashboard Docker Hub: ${DASHBOARD_DOCKERHUB_IMAGE}"
echo "counting  Docker Hub: ${COUNTING_DOCKERHUB_IMAGE}"
echo "dashboard ECR: ${DASHBOARD_ECR_IMAGE}"
echo "counting  ECR: ${COUNTING_ECR_IMAGE}"
