---
title: Connect CI
nav_order: 3
---

# Connect your CI workflow

Complete [deployment and model download](deployment.md) first. Add the
following workflow to a private GitHub repository configured in your
deployment.

## Workflow

{% raw %}
```yaml
name: compliance-scan
on: pull_request
permissions:
  contents: read
jobs:
  precommiteu:
    runs-on: [self-hosted, precommiteu]
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - uses: AlexandruGirlea/precommiteu@v0.3.2
      - uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: precommiteu-reports
          path: |
            precommiteu.sarif
            precommiteu-summary.md
```
{% endraw %}

The runner image already provides the scanner, CUDA runtime and `/models`.
Do not add a job `container:` block; that would replace this runtime.
Reports are uploaded even when findings fail the scan. GitHub code-scanning
upload is optional and requires that feature for your repository; artifacts
do not require it.

Set `precommiteu` as a required check in your branch protection or ruleset.
Confirmed findings exit 1, configuration errors exit 2, and incomplete scans
exit 3. Advisories never gate merges. Start with a small PR containing a known
violation to verify the customer's permissions, report access and merge gate.

If you changed `regulations`, set the action's `regulations` input to the same
packs, comma-separated.

See [operations](operations.md) for updating versions, choosing packs and
protecting runner access. For other CI platforms or an existing runner, see
the [scanner CI guide](https://alexandrugirlea.github.io/precommiteu/ci.html).
