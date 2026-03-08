# Scripts

- `build_and_push_images.sh`: build from `applications/`, push to Docker Hub and ECR.
- `deploy_mode.sh`: run terraform `plan|apply|destroy` for one mode environment.
- `verify_mode.sh`: verify ECS service health and VPC Lattice target health for one mode.
- `create_mode_branch.sh`: create a per-mode branch (`feat/mode-a-http`, etc.) in a git repo.
