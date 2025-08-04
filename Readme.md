# CPterraform

> Terraform code to provision all AWS infrastructure for the CP Notejam application  
> (ECS Fargate, RDS Multi-AZ, VPC, ALB, CloudFront + S3 for static assets, CI/CD with GitHub OIDC)

---

## 🚀 Quick Start

1. **Clone & CD**  
   ```bash
   git clone git@github.com:Joshua-Igoni/CPterraform.git
   cd CPterraform
   ```
2. **Configure your AWS credentials**
We recommend using GitHub Actions OIDC. Locally you can also set:

```bash
export AWS_PROFILE=your-profile
export AWS_REGION=eu-central-1
```
3. **Bootstrap the backend**

```bash
terraform init
Plan & Apply
```
*You must supply:*

**container_image** – full ECR URI of the Docker image pushed by the app pipeline

**db_password** – strong Postgres password (or point to a Secrets Manager ARN)

```bash
terraform plan \
  -var "container_image=123456789012.dkr.ecr.eu-central-1.amazonaws.com/cpapp:latest" \
  -var "db_password=${POSTGRES_PASSWORD}" \
  -out=tfplan
```
terraform apply tfplan
Wait ~5–10 minutes for RDS, ECS & CloudFront to stabilize, then visit your CloudFront URL.

📁 Repo Structure
```graphql
.
├── backend.tf        # S3/DynamoDB remote‐state configuration
├── provider.tf       # AWS provider & Terraform settings
├── variables.tf      # all input variables
├── versions.tf       # Terraform & provider version constraints
├── main.tf           # root modules wiring: network, alb, ecs, rds, edge (CloudFront)
├── outputs.tf        # outputs: ALB DNS, CF domain, S3 bucket name, etc.
└── modules/
    ├── network/      # VPC, subnets, IGW, NAT GW, route tables
    ├── alb/          # Application Load Balancer + target group + listeners
    ├── ecs/          # ECS cluster, task/service definitions, IAM roles
    ├── rds/          # Multi-AZ RDS PostgreSQL + Secrets Manager
    └── edge/         # S3 static assets bucket + CloudFront distribution + OAC
```
## Alternatively

**Requirements**
1. have a backend bucket for terraform to store tf state (pipeline flow)
2. github OICD role for authentication to aws, attach permissions "policy.json"

- Fork both terraform and application: you can fork both repos into your account/org
- make sure you have github OIDC integrated into your aws account
- Store OIDC aws arn in secrets, region in variables, terraform pipeline will need it to authenticate and create/read resources.
- give OIDC role the miminum amount of permissions it needs, you can do this as in-line policy docoment following least privilegde, permissions are found in policy.json
- when you have this go to the application repo that you forked [📁 notejam-django](https://github.com/Joshua-Igoni/CPnotejam) specifically CPassignment branch for the rest of steps to start the flow.