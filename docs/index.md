---
title: Overview
nav_order: 1
---

# precommitEU ops

Deploy local GenAI compliance scanning for your engineering organization.
[precommitEU](https://github.com/AlexandruGirlea/precommiteu) reviews source
code against eight EU regulations; ops puts that scanner into your private
GitHub repositories using GPUs in your own Azure subscription.

## From pull request to review

A pull request queues a scan. An ephemeral GPU runner checks the changed
files with local models, writes findings with quoted code evidence, and
returns a check result and downloadable reports. Your organization decides
which checks must pass before merging.

The scanner, weights and deployment code are Apache-2.0. There is no software
subscription or LLM API fee; your organization provides the compute and
controls its software and model versions.

## Choose your next step

| Guide | What it covers |
|---|---|
| [Deploy](deployment.md) | Azure prerequisites, GitHub permissions, Terraform or Pulumi, model download |
| [Connect CI](ci.md) | Copyable workflow, reports and required merge checks |
| [Accuracy, cost and speed](performance.md) | Evaluation results, estimated spend and the measured Azure test |
| [Operate](operations.md) | Infrastructure, network access, version pins, updates and security |

The current deployment uses ops **0.2.0**, scanner **0.3.2** and models
**v0.3.0**. Budget about **$52–60/month for 100 PRs** under the
[documented assumptions](performance.md#cost-and-speed).

The scanner supports offline operation after installation. This deployment
connects to GitHub for CI while running inference locally.
See [network access](operations.md#network-access) for the boundary.

## The precommitEU projects

- [Scanner and local UI](https://github.com/AlexandruGirlea/precommiteu)
- [Scanner documentation](https://alexandrugirlea.github.io/precommiteu/)
- [Model bundle](https://huggingface.co/AlexandruGirlea/precommiteu-models)
- [Ops source and releases](https://github.com/AlexandruGirlea/precommiteu-ops)
