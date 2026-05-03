# Cloud Resume Challenge on Azure

This project is a hands-on Azure implementation of the Cloud Resume Challenge. The goal is to build and publish a personal resume website while learning how real cloud services fit together in a practical, end-to-end project.

## Project Goal

The main objective is to host a professional resume in Azure and use the project as a real portfolio piece. Instead of only studying cloud theory, this project focuses on building something that demonstrates skills in cloud infrastructure, security, automation, and deployment.

## What This Project Is Meant To Show

This project is designed to prove the ability to:

- Build and host a static website in Azure.
- Use Azure services in a way that reflects real-world cloud architecture.
- Connect a frontend site to backend services.
- Track and automate infrastructure changes.
- Apply security and operational best practices.
- Create a portfolio project that supports a move into cloud or cloud security roles.

## Planned Azure Architecture

The project will likely include most or all of the following Azure components:

- **Azure Storage Account** to host the static website.
- **Azure CDN or Front Door** to improve delivery speed and user access.
- **Custom domain and HTTPS** for a polished public-facing site.
- **Azure Functions** for backend logic, such as a visitor counter API.
- **Azure Cosmos DB or Table Storage** to store visitor count data.
- **Azure DNS** for domain management.
- **GitHub Actions** for CI/CD so updates can be deployed automatically.
- **Infrastructure as Code** using Terraform or Bicep to define Azure resources.
- **Monitoring and logging** using Azure Monitor, Application Insights, or Log Analytics where appropriate.

## Core Features

The finished project should include these core outcomes:

1. A live resume website accessible from a custom domain.
2. Clean frontend content that presents experience, skills, and certifications.
3. A backend visitor counter that updates dynamically.
4. Automated deployment from GitHub to Azure.
5. Reproducible infrastructure managed as code.
6. Documentation that explains architecture, setup, and lessons learned.

## Learning Objectives

This project is being used to go deeper in Azure by practicing:

- Static web hosting
- Serverless computing
- Cloud networking basics
- DNS and domain configuration
- Secure deployment workflows
- CI/CD pipelines
- Infrastructure as Code
- Monitoring and troubleshooting
- Cloud project documentation

## Why This Project Matters

A certification can show knowledge, but a working cloud project shows execution. This project bridges that gap by turning Azure concepts into something visible, testable, and useful in a job search.

For example, instead of saying “I know Azure Functions,” this project can show a deployed function that supports a live website. That makes the learning concrete and easier to explain to recruiters, hiring managers, and other engineers.

## Project Phases

### Phase 1: Foundation

- Create the resume content.
- Set up the GitHub repository.
- Host the static site in Azure.
- Verify the site is publicly reachable.

### Phase 2: Backend Integration

- Build a visitor counter API.
- Store count data in an Azure data service.
- Connect the frontend to the backend.
- Test end-to-end functionality.

### Phase 3: Automation

- Add GitHub Actions for deployment.
- Automate frontend and backend updates.
- Reduce manual configuration steps.

### Phase 4: Infrastructure as Code

- Define Azure resources with Terraform or Bicep.
- Rebuild the environment from code.
- Version infrastructure changes through GitHub.

### Phase 5: Security and Operations

- Enable HTTPS and secure DNS setup.
- Review access controls and secrets handling.
- Add monitoring, logs, and basic alerting.
- Improve reliability and maintainability.

## Success Criteria

This project will be successful when it:

- Is live and publicly accessible.
- Uses Azure services intentionally, not just minimally.
- Has automated deployment workflows.
- Can be explained clearly in interviews and on a resume.
- Demonstrates both technical skill and project ownership.

## Long-Term Value

Beyond completing the Cloud Resume Challenge, this project can become a base for future improvements such as:

- Better frontend design and responsiveness.
- Stronger security controls.
- Additional Azure services.
- More detailed monitoring and analytics.
- Expansion into a broader cloud portfolio.

## Repository Purpose

This repository documents the build process, configuration, architecture decisions, and lessons learned while creating a cloud-hosted resume on Azure. It is both a learning project and a professional portfolio artifact.
