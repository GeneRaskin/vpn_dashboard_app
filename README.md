# VPN Dashboard Application

A VPN management application built with AWS serverless infrastructure. This application provides a web interface for managing VPN configurations of subscribers.

## Architecture

The application consists of:
- Frontend: S3-hosted static website
- Backend: AWS Lambda functions
- Database: DynamoDB for user configuration storage
- Infrastructure: Managed with Terraform

## Prerequisites

- AWS Account
- Terraform >= 1.5.0
- Node.js >= 18
- AWS CLI configured with appropriate credentials
- GitHub account (for CI/CD)

## Local Development Setup

1. Clone the repository:
```bash
git clone https://github.com/GeneRaskin/vpn_dashboard_app.git
cd vpn_app
```

2. Initialize the backend infrastructure:
```bash
./scripts/init-backend.sh
# Follow the prompts for:
# - AWS Region
# - Organization Name
```

3. Initialize the project:
```bash
./scripts/init-project.sh
# Follow the prompts for:
# - AWS Region
# - Environment (dev/prod)
# - Project Name
```

4. Deploy the project:
```bash
./scripts/deploy-project.sh
```

5. Remove either a single project or all projects within a specific region:
```bash
./scripts/cleanup-aws.sh
# Follow the prompts for:
# - AWS Region
# - Whether you want to destroy the backend and clean up all projects or only a single project
# - Environment (dev/prod)
# - Project name
```

6. Run this script to clean Node.js build artifacts:
```bash
./scripts/cleanup-build.sh
# This script cleans up build artifacts (such as the generated script.js file)
# inside the backend/get_user_config directory.
```

## Project Structure

```
.
├── backend/               # Lambda functions
│   └── get_user_config/  # User configuration retrieval
├── frontend/             # Static website files
├── infra/               # Terraform infrastructure code
├── modules/             # Reusable Terraform modules
└── scripts/             # Deployment and utility scripts
```

## Infrastructure

The project utilizes the following AWS services:
- S3 for static website hosting
- API Gateway for HTTP requests from the frontend
- Lambda for serverless compute
- DynamoDB for data storage
- IAM for access management

## CI/CD Pipeline

The project includes GitHub Actions workflows for:
- Automated testing
- Infrastructure deployment
- CORS validation
- Production promotion via PR

### Environments
- `dev`: Development environment
- `prod`: Production environment

## Security

- CORS configured for frontend origin only
- IAM roles with least privilege principles

## Contributing

1. Create a new feature branch from `dev`:
```bash
git checkout -b feature/your-feature-name dev
```

2. Make your changes and commit:
```bash
git commit -m "Description of changes"
```

3. Push and create a PR to `dev`:
```bash
git push origin feature/your-feature-name
```

4. After PR approval and merge to `dev`, the CI/CD pipeline will:
   - Run integration tests
   - Create a PR to `main` for production deployment

## Environment Variables

Required GitHub Secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `PROJECT_NAME`
- `ORGANIZATION_NAME`
- `DYNAMODB_TABLE_BASENAME`
- `GH_BOT_TOKEN`: This token is used to create a pull request
- SMTP settings for notifications:
  - `SMTP_SERVER`
  - `SMTP_PORT`
  - `SMTP_USERNAME`
  - `SMTP_PASSWORD`
  - `NOTIFICATION_EMAIL`

Note that the variables `AWS_REGION` and `ORGANIZATION_NAME` are used to set up the Terraform backend (they determine the name of the S3 bucket used internally by Terraform to track its state, along with the DynamoDB lock table).


