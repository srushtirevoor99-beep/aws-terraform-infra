::: {align="center"}
# AWS Terraform VPC Infrastructure

**Infrastructure as Code for a structured AWS network**

Provision and manage AWS networking resources with Terraform, remote
state in Amazon S3, and Git-based version control.

![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-ap--south--1-232F3E?logo=amazonaws&logoColor=white)
![GitHub](https://img.shields.io/badge/Version%20Control-GitHub-181717?logo=github&logoColor=white)
:::

------------------------------------------------------------------------

## Overview

This project uses **Terraform** to define and deploy networking
infrastructure in Amazon Web Services (AWS). It demonstrates core
Infrastructure as Code practices: defining resources declaratively,
reviewing changes before deployment, managing state remotely, and
tracking configuration changes in Git.

The deployment is configured for the **AWS Mumbai Region
(`ap-south-1`)**.

## Architecture

``` mermaid
flowchart TB
    Dev["Developer / CLI"] --> TF["Terraform Configuration"]
    TF --> AWS["AWS Provider · ap-south-1"]
    AWS --> VPC["VPC · 10.0.0.0/16"]

    VPC --> PubA["Public Subnet A"]
    VPC --> PubB["Public Subnet B"]
    VPC --> PrivA["Private Subnet A"]
    VPC --> PrivB["Private Subnet B"]

    PubA --> RT["Public Route Table"]
    PubB --> RT
    RT --> IGW["Internet Gateway"]

    TF <--> State["Amazon S3 Remote State"]
```

> **Architecture note:** This is a logical overview of the project.
> Confirm the actual subnet CIDRs, route-table associations, and
> private-subnet routing in the Terraform files before using this
> diagram as a production design. A private subnet does not
> automatically have outbound internet access; that requires an
> explicitly configured route and supporting service such as a NAT
> gateway.

## What It Provisions

-   **VPC** --- an isolated virtual network using CIDR block
    `10.0.0.0/16`.
-   **Public subnets** --- subnets configured for public IP assignment
    and associated with public routing.
-   **Private subnets** --- separate subnet segments for workloads
    intended not to be directly exposed to the internet.
-   **Internet Gateway** --- provides an internet gateway attachment for
    the VPC.
-   **Route tables and routes** --- define how network traffic is
    routed.
-   **Subnet associations** --- associate subnets with their intended
    route tables.
-   **Remote Terraform state** --- stores state in an Amazon S3 backend,
    with versioning and public-access blocking configured on the backend
    bucket.
-   **State locking** --- uses the S3 backend lockfile capability
    configured by Terraform.

## Technology Stack

  Technology       Purpose
  ---------------- --------------------------------------------
  Terraform        Infrastructure as Code
  Amazon VPC       Isolated AWS networking
  Amazon S3        Remote Terraform state
  AWS CLI          AWS authentication and command-line access
  Git and GitHub   Version control and source hosting
  Ubuntu on WSL2   Local development environment

## Repository Layout

``` text
aws-terraform-infra/
├── main.tf                 # Main resource definitions (if used)
├── provider.tf             # AWS provider configuration
├── versions.tf             # Terraform/provider version constraints
├── vpc.tf                  # VPC configuration
├── subnets.tf              # Public and private subnet definitions
├── networking.tf           # Gateways, routes, and associations
├── .terraform.lock.hcl     # Provider dependency lock file
├── .gitignore              # Excludes local/generated files
└── README.md               # Project documentation
```

> File names can vary by implementation. Keep this tree aligned with the
> files that actually exist in the repository.

## Prerequisites

Before deploying, install and configure:

-   An AWS account and an IAM identity with the required least-privilege
    permissions.
-   AWS CLI with credentials configured locally.
-   Terraform.
-   Git.

Verify your AWS identity before making changes:

``` bash
aws sts get-caller-identity
```

Do not place access keys, secret keys, session tokens, or other
credentials in this repository.

## Deployment Guide

Run these commands from the project directory.

### 1. Clone the repository

``` bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd aws-terraform-infra
```

Replace the placeholder with your repository URL.

### 2. Initialize Terraform

``` bash
terraform init
```

This installs the required provider and initializes the configured
backend.

### 3. Format and validate

``` bash
terraform fmt -recursive
terraform validate
```

### 4. Review the proposed changes

``` bash
terraform plan
```

Review every proposed addition, update, and deletion before applying. Do
not approve an unexpected replacement or deletion.

### 5. Deploy

``` bash
terraform apply
```

Read the plan shown by Terraform and enter `yes` only when the changes
are expected.

### 6. Verify

``` bash
terraform state list
terraform plan
```

When the deployed infrastructure matches the configuration, Terraform
should report that no changes are needed.

## Remote State and Security

The Terraform backend is configured to store state in Amazon S3. The
backend bucket is created separately from the resources managed by this
project.

Current setup notes:

-   S3 bucket versioning was enabled for the state bucket.
-   S3 Block Public Access was enabled for the state bucket.
-   The backend uses an S3 state key in the configured AWS region.
-   S3 lockfile support is configured with `use_lockfile = true`.

Terraform state can contain sensitive infrastructure information. Keep
the backend private and restrict access to the people and automation
that need it.

**Repository hygiene**

-   Do not commit `.tfstate` files, credentials, `.terraform/`, or saved
    plan files.
-   Keep generated plan files such as `tfplan` ignored by Git.
-   Commit `.terraform.lock.hcl` so provider selections are
    reproducible.
-   Use least-privilege IAM policies instead of broad administrator
    permissions.
-   Review security groups, routes, and public exposure before deploying
    workloads.

## Useful Commands

  Command                      Purpose
  ---------------------------- ----------------------------------------------
  `terraform init`             Initialize the working directory and backend
  `terraform fmt -recursive`   Format Terraform files
  `terraform validate`         Check configuration syntax and consistency
  `terraform plan`             Preview infrastructure changes
  `terraform apply`            Apply a reviewed plan
  `terraform state list`       List resources tracked in state
  `terraform output`           Display configured outputs
  `git status`                 Inspect local Git changes

## Cleanup

Only destroy resources when you intentionally want to remove the
infrastructure.

First review the destroy plan:

``` bash
terraform plan -destroy
```

If the plan is correct and you are sure the resources are no longer
needed:

``` bash
terraform destroy
```

The S3 backend bucket was created separately and may not be managed by
this Terraform configuration. Do **not** delete the state bucket while
you still need the Terraform state. Check for remaining AWS resources
and possible charges after cleanup.

## Validation Status

The project deployment was applied successfully, and a subsequent
`terraform plan` reported:

> No changes. Your infrastructure matches the configuration.

This status reflects the last verification performed; run
`terraform plan` again after any configuration or infrastructure
changes.

## Learning Outcomes

-   Defining AWS resources declaratively with Terraform.
-   Building a VPC with public and private subnet segments.
-   Configuring internet gateways, routes, and subnet associations.
-   Managing remote Terraform state with Amazon S3.
-   Reviewing plans before applying infrastructure changes.
-   Tracking infrastructure code and documentation with Git and GitHub.

------------------------------------------------------------------------

::: {align="center"}
**Built as a hands-on AWS and Infrastructure as Code learning project.**
:::
