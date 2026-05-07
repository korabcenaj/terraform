# Portfolio Sync Integration

This repository dispatches portfolio content sync events to `korabcenaj/portfolio-container` after a successful `Terraform Apply` run on `main`.

## Workflow

The integration is defined in `.github/workflows/portfolio-sync-dispatch.yml`.

Behavior:
- waits for `Terraform Apply` to complete,
- runs only when the workflow conclusion is `success`,
- only dispatches for branch `main`,
- sends `sync-portfolio-content` to the portfolio repository.

## Apply Workflow

The apply workflow is defined in `.github/workflows/terraform-apply.yml`.

Behavior:
- manual `workflow_dispatch` only,
- requires `confirm=APPLY`,
- requires `KUBECONFIG_B64`,
- runs `terraform plan -out=tfplan`,
- applies the saved plan with `terraform apply tfplan`.

## Required Secrets

Add this repository secret:

- `PORTFOLIO_DISPATCH_TOKEN`

Recommended token scope:
- fine-grained personal access token with access to `korabcenaj/portfolio-container`
- repository permissions sufficient to dispatch workflow events / write contents on the target repository

## Manual Dispatch

You can also dispatch directly with the helper in the portfolio repository:

```bash
GH_TOKEN=*** \
TERRAFORM_REPO=korabcenaj/terraform \
TERRAFORM_REF=main \
/home/korab/portfolio-container/trigger-portfolio-sync.sh
```
