---
title: Accuracy, cost and speed
nav_order: 4
---

# Accuracy, cost and speed

## Detection quality

The scanner's 3 November 2026 evaluation used a built 0.3.0 wheel and the
released model bundle on 450 balanced synthetic cases. It measured whether
each case raised a confirmed finding; advisories were excluded.

| Metric | Result |
|---|---|
| Case-level precision | 95.5%: 192 of 201 flagged cases were positive |
| Recall on completed positives | 85.7%: 192 of 224 completed positive cases |
| False-positive rate on clean cases | 4%: 9 of 225 clean cases were flagged |
| Accuracy across all attempts | 90.7%: 408 of 450 decisions matched the labels |
| Exact article-set matches | 79.1%: 356 of 450 cases |

One positive case did not complete; counting it as a miss gives 85.3% recall.
The aggregate includes overlapping standalone and combined CRA/DMA/NIS2
datasets: 450 runs contain 440 unique snippets. All cases took the direct
route, so this evaluation does not measure cross-file reasoning or CI
integration. It is not a prediction of production accuracy or legal sign-off.

[Full method, per-pack results and limitations](https://alexandrugirlea.github.io/precommiteu/detection-evaluation.html).

## Cost and speed

Budget **about $52–60 a month for 100 pull requests averaging 1,000 changed
lines across roughly 10 files**, scanning one regulation pack. This assumes
12–15 minutes per PR and USD list prices in Sweden Central, checked on
4 November 2026:

| Item | Per PR | 100 PRs / month |
|---|---|---|
| T4 GPU, $0.342/hour | $0.07–0.09 | $7–9 |
| 8 vCPU and 56 GiB RAM, $1.296/hour | $0.26–0.32 | $26–32 |
| Compute subtotal | $0.33–0.41 | $33–41 |
| Premium LRS model share, 100 GB at $0.192/GB/month | — | $19.20 |
| Total | — | **$52–60** |

[Azure bills GPU usage in addition to active CPU and RAM](https://azure.microsoft.com/en-us/pricing/details/container-apps/).
Rates were checked against the
[Azure Retail Prices API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices).
This estimate excludes free grants, discounts, taxes, network charges,
storage bursts, model-download executions and retries. Use your Azure offer
for a final quote.

The timing is extrapolated from the measured five-file, roughly 560-line PR
below, which took about 10.5 minutes. Allow about 6 minutes for runner startup
and model loading, about 2 minutes for the first file, then 3–50 seconds per
further file. The scanner reads each changed file whole, so file size and
count matter more than changed-line count. An extra 30 seconds costs about
$0.014 per PR. More regulation packs mean additional scan passes.

## How we tested 0.2.0

The Azure test used scanner 0.3.1. This release pins 0.3.2, a documentation
and metadata update with unchanged scanner logic, prompts and model weights.

We deployed both the Terraform module and the Pulumi component into fresh
resource groups on Azure, and re-running `terraform plan` and `pulumi preview`
showed no changes. Then we built the runner image from this release's
Dockerfile and opened a real pull request against the Terraform deployment,
adding the five files of precommitEU's `risky_code` test fixture:

| Step | Time |
|---|---|
| Job queued until a runner started | 18 s |
| Runner up and registered with GitHub | 2 min |
| Models loaded | 4 min |
| Five files scanned, four GDPR issues found | 4 min |

The scan reported four GDPR findings and the check failed, as it should. On a
CPU-only runner the same scan ran out of time on four of the five files, which
is why 0.2.0 moves to a GPU.
