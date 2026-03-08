# Deployment Workflow (Mode-by-Mode)

This workflow deploys and verifies exactly one mode at a time:

- `mode-a-http`
- `mode-b-https`
- `mode-c-tls`

## Prerequisites

- Docker, Terraform, AWS CLI installed.
- AWS credentials configured (`aws sts get-caller-identity` must work).
- Images built from `applications/dashboard-service` and `applications/counting-service`.
- `terraform.tfvars` created in each target mode directory.

## 1) Build and Push Images (Docker Hub + ECR)

```bash
./scripts/build_and_push_images.sh <dockerhub_user> <image_tag> <aws_account_id> <aws_region> <ecr_repo_prefix>
```

Example:

```bash
./scripts/build_and_push_images.sh myuser v20260308 123456789012 us-east-1 vpc-lattice-ecs-demo
```

Use the ECR image URIs in each mode's `terraform.tfvars`.

## 2) Deploy One Mode

```bash
./scripts/deploy_mode.sh mode-a-http plan
./scripts/deploy_mode.sh mode-a-http apply
```

Do not deploy multiple modes simultaneously unless intended.

## 3) Verify Mode

```bash
./scripts/verify_mode.sh mode-a-http
# or
./tests/mode-a-test.sh
```

Verification checks:

- ECS service status and task counts
- VPC Lattice target health
- service DNS endpoint output for in-VPC testing

## 4) Destroy Mode (optional before switching)

```bash
./scripts/deploy_mode.sh mode-a-http destroy
```

## 5) Repeat for Mode B then Mode C

Before Mode B deploy:

```bash
./certificates/mode-b/generate_self_signed.sh
AWS_REGION=us-east-1 ./certificates/mode-b/import_to_acm.sh
# set certificate_arn in terraform/environments/mode-b-https/terraform.tfvars
```

```bash
./scripts/deploy_mode.sh mode-b-https apply
./scripts/verify_mode.sh mode-b-https

./scripts/deploy_mode.sh mode-c-tls apply
./scripts/verify_mode.sh mode-c-tls
```

## Branching Strategy

Use one branch per mode rollout and validation:

- `feat/mode-a-http`
- `feat/mode-b-https`
- `feat/mode-c-tls`

Suggested sequence:

```bash
git checkout -b feat/mode-a-http
# commit mode A updates
# deploy + verify mode A
# push and open PR

git checkout main
git checkout -b feat/mode-b-https
# repeat

git checkout main
git checkout -b feat/mode-c-tls
# repeat
```

## Important Note on Mode C

Current applications are HTTP services. In this repository, `mode-c-tls` is configured as compatibility mode (HTTPS listener on VPC Lattice, HTTP backend). True TLS passthrough + mTLS requires TLS-enabled app changes.

## Important Note on Mode B

`mode-b-https` is configured with:

- HTTPS listener at VPC Lattice
- Local OpenSSL certificate imported into ACM and referenced by `certificate_arn`
- HTTP backend target group to counting service
