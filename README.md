<div align="center">

# AWS Terraform Infrastructure: VPC, ALB and Auto Scaling

**A load-balanced, auto-scaling web tier on AWS, built with Terraform and checked by a CI pipeline**

![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-VPC%20%7C%20ALB%20%7C%20ASG-FF9900?logo=amazonaws&logoColor=white)
![Region](https://img.shields.io/badge/Region-ap--south--1-232F3E)
![State](https://img.shields.io/badge/Remote%20State-Amazon%20S3-569A31?logo=amazons3&logoColor=white)
![CI](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)
![Checkov](https://img.shields.io/badge/Security%20scan-Checkov-5C4EE5)

</div>

---

## Overview

This project provisions a small, production-style web tier on AWS with **Terraform**. A single `terraform apply` builds:

- a **VPC** with public and private subnets across two availability zones
- an **Application Load Balancer** that accepts HTTP from the internet
- an **Auto Scaling Group** of Ubuntu instances that serve a page through nginx in Docker
- **security groups** so the instances only accept traffic from the load balancer

`terraform destroy` removes everything again.

Terraform state is stored remotely in an **Amazon S3 bucket**. Every change goes through a pull request, where **GitHub Actions** runs format, validate, a **Checkov** security scan and a `terraform plan` using **GitHub OIDC** (no stored AWS keys).

---

## Architecture

### Workflow

How a change travels from the developer's machine to AWS:

```mermaid
flowchart LR
    DEV["Developer<br/>Ubuntu on WSL2"]
    GH["GitHub<br/>Pull request"]
    CI["GitHub Actions<br/>fmt, validate, Checkov, plan"]
    TF["Terraform CLI"]
    AWS["AWS<br/>ap-south-1"]
    S3[("Amazon S3<br/>Remote state")]

    DEV -->|"git push"| GH
    GH --> CI
    CI -->|"OIDC, read-only plan"| AWS
    DEV -->|"terraform apply"| TF
    TF -->|"AWS provider API calls"| AWS
    TF <-->|"read and write state"| S3
```

### Network design

The infrastructure Terraform creates inside AWS:

```mermaid
flowchart TB
    INET(("Internet"))

    subgraph REGION["AWS Region: ap-south-1"]
        subgraph VPC["Amazon VPC"]
            IGW["Internet Gateway"]
            ALB["Application Load Balancer<br/>alb-sg: HTTP 80 from anywhere"]
            RTPUB["Public route table<br/>0.0.0.0/0 via Internet Gateway"]
            RTPRI["Private route table<br/>local routes only"]

            subgraph AZA["Availability Zone A"]
                PUBA["Public subnet A<br/>EC2 instance (app-sg)"]
                PRIA["Private subnet A"]
            end

            subgraph AZB["Availability Zone B"]
                PUBB["Public subnet B<br/>EC2 instance (app-sg)"]
                PRIB["Private subnet B"]
            end
        end
    end

    INET <--> IGW
    IGW --- ALB
    ALB -->|"HTTP 80"| PUBA
    ALB -->|"HTTP 80"| PUBB
    IGW --- RTPUB
    RTPUB --- PUBA
    RTPUB --- PUBB
    RTPRI --- PRIA
    RTPRI --- PRIB
```

### Architecture notes

- The **VPC** is an isolated virtual network. Its default security group is locked down (no rules).
- **Public subnets** route internet-bound traffic through the Internet Gateway. The ALB and the instances live here.
- **Private subnets** have a separate route table with local routes only. Nothing runs in them yet.
- The **ALB** accepts HTTP on port 80 and forwards to a target group with a health check on `/`.
- The **app security group** accepts HTTP **only from the ALB security group**, not from the internet.
- The **Auto Scaling Group** keeps 2 to 4 `t3.micro` instances running across both zones and scales on average CPU (target 50%).
- Instances run Ubuntu 22.04, require **IMDSv2**, install Docker on boot and serve a page from `nginx`.
- Instances sit in public subnets to avoid the cost of a NAT Gateway. A production setup would use private subnets with NAT.

---

## Resources Created

| Area | Terraform resource types | Purpose |
|---|---|---|
| Network | `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_route_table`, `aws_route`, `aws_route_table_association`, `aws_default_security_group` | VPC, four subnets, internet access, routing, locked-down default security group |
| Security groups | `aws_security_group`, `aws_vpc_security_group_ingress_rule`, `aws_vpc_security_group_egress_rule` | ALB and app security groups with explicit rules |
| Load balancer | `aws_lb`, `aws_lb_target_group`, `aws_lb_listener` | Public HTTP entry point and health-checked target group |
| Compute | `aws_launch_template`, `aws_autoscaling_group`, `aws_autoscaling_policy`, `aws_ami` (data) | Self-healing, CPU-scaled instances from the latest Ubuntu 22.04 AMI |

---

## Technology Stack

| Technology | Purpose |
|---|---|
| Terraform | Infrastructure as Code and resource provisioning |
| Amazon VPC, ALB, EC2 Auto Scaling | Network, load balancing and compute |
| Amazon S3 | Remote Terraform state storage |
| GitHub Actions | CI: format, validate, security scan and plan on every pull request |
| GitHub OIDC and AWS IAM | Short-lived credentials for CI, no access keys stored in GitHub |
| Checkov | Static security scanning of the Terraform code |
| Docker and nginx | Sample app served by each instance |
| AWS CLI | Credentials, identity checks and resource inspection |
| Ubuntu on WSL2 | Linux development environment |

---

## Project Structure

```text
aws-terraform-infra/
├── .github/workflows/
│   └── terraform.yml       # CI: validate, security-scan, plan
├── modules/
│   ├── vpc/                # VPC, subnets, Internet Gateway, route tables
│   ├── alb/                # Load balancer, target group, listener
│   └── asg/                # Launch template, Auto Scaling Group, scaling policy
├── main.tf                 # Wires the three modules together
├── security_groups.tf      # ALB and app security groups and their rules
├── outputs.tf              # Prints the ALB DNS name
├── provider.tf             # AWS provider configuration
├── versions.tf             # Terraform and provider versions, S3 backend
├── .terraform.lock.hcl     # Provider version lock (commit this file)
├── .gitignore              # Keeps state, plans and local files out of Git
└── README.md
```

---

## CI Pipeline

The workflow in `.github/workflows/terraform.yml` runs on every pull request and on every push to `main`.

| Job | What it does | When |
|---|---|---|
| `validate` | `terraform fmt -check -recursive`, `init -backend=false`, `validate` | Pull requests and `main` |
| `security-scan` | Runs Checkov on the Terraform code | Pull requests and `main` |
| `plan` | Assumes an AWS role through GitHub OIDC, then `terraform plan -lock=false` | Pull requests only, after `validate` passes |

Notes:

- The plan role is read-only, which is why the plan runs with `-lock=false` (a lock would need write access to the state bucket).
- Checkov is enforcing: any failed check fails the build and blocks the pull request. Findings that are accepted on purpose are skipped in code with a written reason.
- Accepted risks are documented in the code with `#checkov:skip=<ID>:<reason>` comments. Examples: HTTP-only listener (no domain or certificate), no WAF or access logging (cost), instances in public subnets (no NAT cost). Each skip has a reason next to it.
- There is no automatic `apply`. Changes are applied manually from the command line.

---

## Prerequisites

- An AWS account with IAM permissions to manage VPC, EC2, ELB and Auto Scaling resources and to read and write the state bucket
- [Terraform](https://developer.hashicorp.com/terraform/install) 1.10 or newer (native S3 state locking)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured
- Git installed
- Ubuntu/Linux or WSL2
- An existing S3 bucket for remote state (see [Remote State Management](#remote-state-management))

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/srushtirevoor99-beep/aws-terraform-infra.git
cd aws-terraform-infra
```

### 2. Configure AWS credentials

```bash
aws configure
```

Use the region configured for this project (`ap-south-1`), then verify your identity:

```bash
aws sts get-caller-identity
```

### 3. Point Terraform at your own state bucket

Edit the `backend "s3"` block in `versions.tf` and replace the bucket name with a bucket you own.

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Format and validate

```bash
terraform fmt -recursive
terraform validate
```

### 6. Review the execution plan

```bash
terraform plan
```

Read the plan carefully. `+` means create, `~` means change in place, and `-` means destroy.

### 7. Deploy

```bash
terraform apply
```

Type `yes` only when the proposed changes are expected.

### 8. Verify

```bash
terraform output alb_dns_name
curl http://$(terraform output -raw alb_dns_name)
```

Instances take a couple of minutes to install Docker and pass health checks, so the first request may return a 503. Repeat the `curl` a few times: the hostname in the response alternates between the two instances.

### 9. Clean up

```bash
terraform destroy
```

Destroy resources when you are done experimenting. The state bucket is kept separate and is not removed by this command.

---

## Remote State Management

Terraform state maps your configuration to real AWS resources. This project stores it in an **Amazon S3 backend** so it is durable, versioned and not tied to one machine.

Backend configuration (see `versions.tf`):

```hcl
terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "YOUR-STATE-BUCKET-NAME"
    key          = "aws-terraform-infra/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true   # native S3 locking, Terraform 1.10+
  }
}
```

The state bucket is created once, outside Terraform, with:

- **Versioning enabled**, so earlier state versions can be recovered
- **Public access blocked** on all four settings
- **Encryption** enabled for stored state

> **Important:** Terraform state can contain sensitive values. Restrict access to the bucket, and never commit `*.tfstate` files or saved plan files to Git.

---

## Security Best Practices

- Apply least-privilege IAM permissions. CI uses a separate read-only role through OIDC.
- Never commit AWS access keys, secret keys or credentials.
- Restrict access to the Terraform state bucket.
- Keep `.terraform/`, local state files and saved plans out of Git via `.gitignore`.
- Review every `terraform plan` before applying.
- Instances accept traffic only from the load balancer, and require IMDSv2.
- Every accepted Checkov finding is skipped explicitly in code with a written reason.
- Monitor AWS usage and delete resources you no longer need.

### Known limitations (demo trade-offs)

- HTTP only: there is no domain or ACM certificate, so no HTTPS.
- No WAF and no ALB access logs (cost and scope).
- No VPC flow logs.
- Instances are in public subnets with public IPs instead of private subnets behind a NAT Gateway.
- The ALB has no deletion protection, so `terraform destroy` works.

---

## Demo

The Auto Scaling Group launched two instances across two availability zones.
Refreshing the load balancer URL alternates between them, which shows the ALB
distributing traffic.

![Browser test](docs/browser-test.png)

![Curl test](docs/curl-test.png)

---

## Cost Notes

The VPC, subnets, Internet Gateway, route tables and security groups have no hourly charge, and the S3 state bucket costs very little at this scale. The **Application Load Balancer** and the **EC2 instances** do cost money while they run, and the instances need public IPv4 addresses, which are also billed. Set an AWS Budgets alert and run `terraform destroy` after each practice session.

---

## Learning Outcomes

- Infrastructure as Code with Terraform (resources, modules, references, state, plan and apply)
- AWS VPC design with public and private routing
- Load balancing and Auto Scaling with security groups chained ALB to instances
- Remote state management in Amazon S3
- CI with GitHub Actions: fmt, validate, plan and security scanning
- Keyless AWS access from CI using GitHub OIDC
- Reading and triaging Checkov findings, and documenting accepted risks

---

## Author

**Srushti Revoor**

GitHub: [srushtirevoor99-beep](https://github.com/srushtirevoor99-beep)

---

<div align="center">

*Built as a hands-on cloud engineering project focused on AWS networking, load balancing, Terraform and Infrastructure as Code.*

</div>
