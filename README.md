AWS Terraform VPC Infrastructure

Overview

This project provisions AWS networking infrastructure using Terraform. It demonstrates Infrastructure as Code (IaC), reusable configuration, remote state management, and version control with Git and GitHub.

Architecture

The infrastructure is deployed in the AWS Mumbai region ("ap-south-1").

- VPC: Provides an isolated virtual network with CIDR block "10.0.0.0/16".
- Public subnets: Host resources that may need internet connectivity through an Internet Gateway and public routing.
- Private subnets: Provide network segments intended for resources that should not be directly exposed to the internet.
- Internet Gateway: Provides an internet gateway for the VPC.
- Route tables: Define network traffic routing.
- Route table associations: Connect the appropriate subnets to their route tables.
- Terraform state: Stored remotely in Amazon S3, with bucket versioning and public-access blocking configured.
- State locking: Uses Terraform's S3 backend lockfile support.

Architecture Diagram

flowchart TD
    A[Terraform Configuration] --> B[AWS Provider]
    B --> C[VPC 10.0.0.0/16]
    C --> D[Public Subnet A]
    C --> E[Public Subnet B]
    C --> F[Private Subnets]
    D --> G[Public Route Table]
    E --> G
    G --> H[Internet Gateway]
    F --> I[Private Routing]
    J[Terraform State] <--> K[Amazon S3 Backend]

Note: The diagram represents the intended logical architecture. Private subnet routing and internet access depend on the actual Terraform configuration.

Technologies Used

- Amazon Web Services (AWS)
- Terraform
- AWS CLI
- Ubuntu on WSL2
- Git and GitHub
- Amazon S3 remote state backend

Repository Structure

aws-terraform-infra/
├── main.tf
├── provider.tf
├── versions.tf
├── vpc.tf
├── subnets.tf
├── networking.tf
├── .gitignore
├── .terraform.lock.hcl
└── README.md

Prerequisites

- An AWS account with appropriate permissions
- AWS CLI configured with an authorized identity
- Terraform installed
- Git installed
- An S3 bucket configured for Terraform remote state

Deployment

Clone the repository and enter the project directory:

git clone <YOUR_GITHUB_REPOSITORY_URL>
cd aws-terraform-infra

Initialize Terraform:

terraform init

Validate the configuration:

terraform validate

Review the proposed infrastructure changes:

terraform plan

Apply the configuration after reviewing the plan:

terraform apply

Verify the deployed resources:

terraform state list
terraform plan

A successful final plan should report that no changes are required when the deployed infrastructure matches the configuration.

Remote State Management

Terraform state is stored in an Amazon S3 backend rather than only on the local machine. The backend is configured with a state key and AWS region.

The backend bucket was created separately before Terraform initialization. Bucket versioning and public-access blocking were enabled. Terraform's S3 lockfile support is configured to help prevent concurrent state modifications.

Do not commit state files, AWS credentials, secret keys, or saved Terraform plan files to GitHub.

Security Considerations

- Follow the principle of least privilege for IAM permissions.
- Avoid embedding AWS credentials in Terraform files.
- Keep the Terraform state bucket private.
- Review security groups, subnet routing, and public exposure before deploying workloads.
- Check AWS costs before creating additional services.

Cleanup

When the infrastructure is no longer needed, review the resources managed by Terraform before removing them.

terraform plan -destroy

Only if you intend to remove the Terraform-managed infrastructure and have reviewed the consequences, run:

terraform destroy

The separately created remote-state S3 bucket may not be managed by this Terraform configuration and may need separate handling. Do not delete the backend bucket while you still need the Terraform state.

Learning Outcomes

- Provisioning AWS infrastructure with Terraform
- Designing VPC and subnet networking
- Configuring internet routing
- Managing Terraform state remotely
- Validating and planning infrastructure changes
- Tracking infrastructure code using Git and GitHub
