# VPC Lattice ECS Cross-VPC Demo (Terraform)

This repository implements the architecture from `PROJECT_SPEC.md` using modular Terraform.

## Structure

- `applications/`: application folders (`dashboard-service`, `counting-service`)
- `terraform/modules/`: reusable modules
- `terraform/environments/`: independent stacks for each mode
- `certificates/`: certificate workflow placeholders
- `scripts/`: helper script placeholders
- `tests/`: integration test placeholders
- `docs/`: design and runbooks

## Terraform Modes

- `mode-a-http`: HTTP end-to-end via VPC Lattice
- `mode-b-https`: HTTPS listener with TLS termination at VPC Lattice using ACM certificate imported from local OpenSSL cert
- `mode-c-tls`: compatibility stack using HTTPS listener with current app images

## Usage

Run from one environment folder at a time:

```bash
cd terraform/environments/mode-a-http
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

Use `mode-b-https` or `mode-c-tls` the same way.

Helper scripts are available for mode-by-mode workflow:

```bash
./scripts/build_and_push_images.sh <dockerhub_user> <image_tag> <aws_account_id> <aws_region> <ecr_repo_prefix>
./scripts/deploy_mode.sh <mode-a-http|mode-b-https|mode-c-tls> <plan|apply|destroy>
./scripts/verify_mode.sh <mode-a-http|mode-b-https|mode-c-tls>
```

## Notes

- This repo only provides Infrastructure as Code; it does not run deployments automatically.
- Replace container image values in `terraform.tfvars` with your dashboard/counting images.
- Mode B certificate workflow:
  - generate certs with `./certificates/mode-b/generate_self_signed.sh`
  - import into ACM with `./certificates/mode-b/import_to_acm.sh`
  - set `certificate_arn` in `terraform/environments/mode-b-https/terraform.tfvars`
- Current `dashboard-service` and `counting-service` are HTTP applications; true TLS passthrough + mTLS requires TLS-enabled backend/client app changes.
- Current Mode C stack is intentionally configured for app compatibility (HTTPS at Lattice, HTTP to backend).
- Full rollout sequence is documented in `docs/DEPLOYMENT_WORKFLOW.md`.
