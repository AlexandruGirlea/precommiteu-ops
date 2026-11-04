---
title: Overview
nav_order: 1
---

<section class="ops-hero" aria-labelledby="ops-title">
  <div>
    <p class="ops-eyebrow">precommitEU ops · Enterprise CI</p>
    <h1 id="ops-title">AI scanning.<br>Your infrastructure.<br>Your control.</h1>
    <p class="ops-lead">Review every pull request for EU regulatory risks
      with AI you run yourself. Your code and models stay on your Azure
      runner. No external LLM API.</p>
    <p class="ops-actions">
      <a class="btn btn-primary" href="{{ '/deployment.html' | relative_url }}">Deploy for your team</a>
      <a class="btn" href="{{ '/ci.html' | relative_url }}">Connect GitHub</a>
    </p>
    <p class="ops-tags">Apache-2.0 · Eight EU regulations · Self-hosted AI</p>
  </div>
  <img class="ops-mascot" src="{{ '/assets/img/bat.png' | relative_url }}"
    alt="The precommitEU bat surrounded by twelve EU stars" width="360" height="360">
</section>

<div class="ops-metrics" aria-label="Evaluation results and estimates">
  <a href="{{ '/performance.html#detection-quality' | relative_url }}">
    <strong>95.5%</strong><span>Case-level precision in our evaluation</span>
  </a>
  <a href="{{ '/performance.html#cost-and-speed' | relative_url }}">
    <strong>$52–60</strong><span>Estimated monthly cost for 100 PRs</span>
  </a>
  <a href="{{ '/performance.html#cost-and-speed' | relative_url }}">
    <strong>12–15 min</strong><span>Estimated time per pull request</span>
  </a>
</div>

<p class="ops-evidence">Quality was measured on 450 synthetic cases.
  Cost and timing assume one regulation pack and roughly 10 changed files
  per PR. <a href="{{ '/performance.html' | relative_url }}">Read the evidence,
  assumptions and limitations.</a></p>

## From pull request to review

A pull request queues a scan. An ephemeral GPU runner checks the changed
files with local models, writes findings with quoted code evidence, and
returns a check result and downloadable reports. Your organization decides
which checks must pass before merging.

The scanner, weights and deployment code are Apache-2.0. There is no software
subscription or LLM API fee; your organization provides the compute and
controls its software and model versions.

## From evaluation to everyday use

<div class="ops-guides">
  <a href="{{ '/deployment.html' | relative_url }}">
    <span class="ops-guide-number">01</span>
    <strong>Deploy your infrastructure</strong>
    <span>Azure prerequisites, Terraform or Pulumi, and model setup.</span>
  </a>
  <a href="{{ '/ci.html' | relative_url }}">
    <span class="ops-guide-number">02</span>
    <strong>Connect your workflow</strong>
    <span>GitHub Actions, downloadable reports and required merge checks.</span>
  </a>
  <a href="{{ '/performance.html' | relative_url }}">
    <span class="ops-guide-number">03</span>
    <strong>Evaluate quality and cost</strong>
    <span>Measured results, estimated spend and the Azure deployment test.</span>
  </a>
  <a href="{{ '/operations.html' | relative_url }}">
    <span class="ops-guide-number">04</span>
    <strong>Operate with confidence</strong>
    <span>Version control, network access, updates and runner security.</span>
  </a>
</div>

The current deployment uses ops **0.2.0**, scanner **0.3.2** and models
**v0.3.0**.

The scanner can run **air-gapped after installation**. This CI deployment
connects to GitHub while keeping AI inference on your own runner.
See [network access](operations.md#network-access) for the boundary.

## The precommitEU projects

- [Scanner and local UI](https://github.com/AlexandruGirlea/precommiteu)
- [Scanner documentation](https://alexandrugirlea.github.io/precommiteu/)
- [Model bundle](https://huggingface.co/AlexandruGirlea/precommiteu-models)
- [Ops source and releases](https://github.com/AlexandruGirlea/precommiteu-ops)
