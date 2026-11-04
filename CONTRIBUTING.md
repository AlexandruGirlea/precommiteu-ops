# Contributing

## Checks

CI runs these from the repository root. Run them before opening a pull request
(needs shellcheck, Terraform and ruff 0.15.16):

```bash
shellcheck entrypoint.sh
terraform fmt -check terraform/ && terraform -chdir=terraform init -backend=false && terraform -chdir=terraform validate
ruff check --line-length 82 --extend-select E501 pulumi/ && ruff format --check --line-length 82 pulumi/
ops=$(sed -n 's/^ *ops_version *= "\(.*\)"$/\1/p' terraform/main.tf) && scanner=$(sed -n 's/^ *scanner_version *= "\(.*\)"$/\1/p' terraform/main.tf) && models=$(sed -n 's/^ *models_revision *= "\(.*\)"$/\1/p' terraform/main.tf) && grep -qxF "ARG SCANNER_VERSION=$scanner" Dockerfile && grep -qxF "SCANNER_VERSION = \"$scanner\"" pulumi/runner.py && grep -qxF "MODELS_REVISION = \"$models\"" pulumi/runner.py && grep -qxF "OPS_VERSION = \"$ops\"" pulumi/runner.py && test "$(grep -m1 -o '^## \[[0-9][^]]*\]' CHANGELOG.md)" = "## [$ops]"
```

The last command checks that the scanner version matches across the
`Dockerfile`, Terraform and Pulumi, the models revision across Terraform and
Pulumi, and the ops version across Terraform, Pulumi and the top
`CHANGELOG.md` release.

## Releasing

1. Bump the ops version: `ops_version` in `terraform/main.tf`, `OPS_VERSION` in
   `pulumi/runner.py`, and a new `CHANGELOG.md` section.
2. Merge to `main`.
3. Push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`. The release
   workflow checks the versions, pushes
   `ghcr.io/alexandrugirlea/precommiteu-runner:X.Y.Z` and creates the GitHub
   Release from the CHANGELOG section.
4. After the very first release only, make the `precommiteu-runner` package
   public in its GHCR package settings.

## New scanner version

Change `ARG SCANNER_VERSION` in the `Dockerfile`, `scanner_version` in
`terraform/main.tf` and `SCANNER_VERSION` in `pulumi/runner.py`, then release a
new ops version with a CHANGELOG entry naming the scanner version. The image
build fails if the scanner's model-server start limit can no longer be raised;
update that `sed` line to match the new scanner.
Update `models_revision` and `MODELS_REVISION` only when the model bundle
changes; scanner-only releases can reuse the existing model revision.
