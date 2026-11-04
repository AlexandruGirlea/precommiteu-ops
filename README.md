<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/AlexandruGirlea/precommiteu/main/docs/assets/img/bat-hero-dark.png">
    <img src="https://raw.githubusercontent.com/AlexandruGirlea/precommiteu/main/docs/assets/img/bat-hero-light.png" alt="precommitEU" width="160" height="160">
  </picture>
</p>

<h1 align="center">precommitEU ops</h1>

<p align="center">
  <strong>AI compliance scanning. Your infrastructure. Your control.<br>
  Review every pull request with models you run yourself.</strong>
</p>

<p align="center">
  <a href="https://alexandrugirlea.github.io/precommiteu-ops/"><strong>Documentation</strong></a>
  &nbsp;&middot;&nbsp;
  <a href="https://alexandrugirlea.github.io/precommiteu-ops/deployment.html">Deploy</a>
  &nbsp;&middot;&nbsp;
  <a href="#accuracy-and-cost">Accuracy and cost</a>
  &nbsp;&middot;&nbsp;
  <a href="https://github.com/AlexandruGirlea/precommiteu">Explore the scanner</a>
  &nbsp;&middot;&nbsp;
  <a href="https://alexandrugirlea.github.io/precommiteu/">Scanner docs</a>
</p>

<p align="center">
  <a href="https://github.com/AlexandruGirlea/precommiteu-ops/releases/latest"><img src="https://img.shields.io/github/v/release/AlexandruGirlea/precommiteu-ops" alt="Latest release"></a>
  <a href="https://github.com/AlexandruGirlea/precommiteu-ops/actions/workflows/ci.yml"><img src="https://github.com/AlexandruGirlea/precommiteu-ops/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/AlexandruGirlea/precommiteu-ops" alt="License"></a>
</p>

[precommitEU](https://github.com/AlexandruGirlea/precommiteu) uses generative AI
to review source code for potential violations across eight EU regulations.
**Ops brings that scanner into your team's GitHub workflow**, running the
models in your own Azure subscription.

## What it gives your organization

- **Earlier feedback for engineers.** Review potential issues before code
  merges, with findings that quote the relevant code.
- **A shared review process.** Give engineering, security and compliance teams
  reports they can inspect, and make the scan a required merge check.
- **Control over your code and models.** Inference stays on your runner.
  You choose the regulation packs and when to upgrade.
- **Software without subscription fees.** The scanner, model weights and
  deployment code are Apache-2.0. You pay for your Azure resources; GPU compute
  scales to zero between scans.

Coverage includes GDPR, the EU AI Act, Data Act, DORA, DSA, CRA, DMA and NIS2.
Select the packs relevant to your business.

<a id="cost-and-speed"></a>

## Accuracy and cost

| Measure | What to expect |
|---|---|
| Detection quality | **95.5% precision**, **85.7% recall**, **4% false-positive rate** on clean cases in the 450-case evaluation |
| Estimated monthly cost | **$52–60 for 100 PRs**, averaging 1,000 changed lines across roughly 10 files, with one regulation pack |
| Estimated time per PR | **12–15 minutes**, extrapolated from a measured five-file PR that took about 10.5 minutes |

Quality figures are case-level results from a balanced synthetic evaluation
of scanner 0.3.0 with the released model bundle. Recall excludes one incomplete
positive case; including it gives 85.3%. These results guide evaluation, not
legal sign-off or a guarantee for your codebase.

Cost estimates include GPU, CPU, memory and the model share at Sweden Central
list prices checked on 4 November 2026. They exclude taxes, network charges,
setup downloads, retries and credits.
[See the evidence and assumptions](https://alexandrugirlea.github.io/precommiteu-ops/performance.html).

<a id="terraform"></a>
<a id="pulumi"></a>
<a id="workflow"></a>

## Start with one repository

Your platform team deploys with **Terraform or Pulumi**, then connects a
private GitHub repository. Start with one regulation pack, review the findings
with your team, and enable merge gating when it fits your process.

**[Deployment guide](https://alexandrugirlea.github.io/precommiteu-ops/deployment.html)** ·
**[Connect your CI workflow](https://alexandrugirlea.github.io/precommiteu-ops/ci.html)**

The scanner can run fully offline after installation. This Azure/GitHub
integration uses local inference and needs GitHub connectivity.
[Network access and offline options](https://alexandrugirlea.github.io/precommiteu-ops/operations.html#network-access).

[Changelog](CHANGELOG.md) · [Contributing](CONTRIBUTING.md) ·
[Security policy](SECURITY.md) · [precommit.eu](https://precommit.eu)
