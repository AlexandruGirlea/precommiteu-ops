import hashlib
import re
from typing import TypedDict

import pulumi
from pulumi_azure_native import app, resources, storage

OPS_VERSION = "0.1.0"
SCANNER_VERSION = "0.3.1"
MODELS_REVISION = "v0.3.0"
IMAGE = "ghcr.io/alexandrugirlea/precommiteu"


class RunnerArgs(TypedDict):
    resource_group_name: pulumi.Input[str]
    location: pulumi.Input[str]
    github_owner: str
    github_repos: list[str]
    github_pat: pulumi.Input[str]
    regulations: list[str] | None
    workload_profile_type: str | None
    cpu: float | None
    memory: str | None


class Runner(pulumi.ComponentResource):
    download_job_name: pulumi.Output[str]

    def __init__(
        self,
        name: str,
        args: RunnerArgs,
        opts: pulumi.ResourceOptions | None = None,
    ) -> None:
        super().__init__("precommiteu:index:Runner", name, {}, opts)
        child = pulumi.ResourceOptions(parent=self)
        rg = args["resource_group_name"]
        location = args["location"]
        owner = args["github_owner"]
        regulations = args.get("regulations") or ["gdpr"]
        profile = "precommiteu"

        rg_id = resources.get_resource_group_output(resource_group_name=rg).id
        account = storage.StorageAccount(
            f"{name}-models",
            account_name=rg_id.apply(
                lambda i: (
                    "precommiteu" + hashlib.sha1(i.encode()).hexdigest()[:13]
                )
            ),
            resource_group_name=rg,
            location=location,
            kind="FileStorage",
            sku=storage.SkuArgs(name="Premium_LRS"),
            opts=child,
        )
        share = storage.FileShare(
            f"{name}-models",
            account_name=account.name,
            resource_group_name=rg,
            share_name="models",
            share_quota=100,
            opts=child,
        )
        key = (
            storage.list_storage_account_keys_output(
                account_name=account.name, resource_group_name=rg
            )
            .keys[0]
            .value
        )
        env = app.ManagedEnvironment(
            f"{name}-env",
            environment_name="precommiteu",
            resource_group_name=rg,
            location=location,
            workload_profiles=[
                app.WorkloadProfileArgs(
                    name=profile,
                    workload_profile_type=args.get("workload_profile_type")
                    or "E8",
                    minimum_count=0,
                    maximum_count=len(args["github_repos"]),
                )
            ],
            opts=child,
        )
        storages = {
            mode: app.ManagedEnvironmentsStorage(
                f"{name}-{mode.lower()}",
                environment_name=env.name,
                resource_group_name=rg,
                storage_name=f"models-{mode.lower()}",
                properties=app.ManagedEnvironmentStoragePropertiesArgs(
                    azure_file=app.AzureFilePropertiesArgs(
                        account_name=account.name,
                        account_key=pulumi.Output.secret(key),
                        share_name=share.name,
                        access_mode=mode,
                    )
                ),
                opts=child,
            )
            for mode in ("ReadOnly", "ReadWrite")
        }
        mount = app.VolumeMountArgs(volume_name="models", mount_path="/models")

        def job(job_name, mode, configuration, container):
            return app.Job(
                f"{name}-{job_name}",
                job_name=job_name,
                resource_group_name=rg,
                location=location,
                environment_id=env.id,
                workload_profile_name=profile,
                configuration=configuration,
                template=app.JobTemplateArgs(
                    containers=[container],
                    volumes=[
                        app.VolumeArgs(
                            name="models",
                            storage_type="AzureFile",
                            storage_name=storages[mode].name,
                        )
                    ],
                ),
                opts=child,
            )

        download = job(
            "precommiteu-models",
            "ReadWrite",
            app.JobConfigurationArgs(
                trigger_type="Manual",
                replica_timeout=3600,
                manual_trigger_config=app.JobConfigurationManualTriggerConfigArgs(
                    parallelism=1, replica_completion_count=1
                ),
            ),
            app.ContainerArgs(
                name="download",
                image=f"{IMAGE}:{SCANNER_VERSION}",
                command=[
                    "hf",
                    "download",
                    "AlexandruGirlea/precommiteu-models",
                    "base.gguf",
                    "orchestrator.gguf",
                    *[f"{r}/detector-adapter.gguf" for r in regulations],
                    "--revision",
                    MODELS_REVISION,
                    "--local-dir",
                    "/models",
                ],
                resources=app.ContainerResourcesArgs(cpu=2, memory="4Gi"),
                volume_mounts=[mount],
            ),
        )

        pat = pulumi.Output.secret(args["github_pat"])
        for repo in args["github_repos"]:
            rule = app.JobScaleRuleArgs(
                name="github-runner",
                type="github-runner",
                metadata={
                    "owner": owner,
                    "runnerScope": "repo",
                    "repos": repo,
                    "labels": "precommiteu",
                },
                auth=[
                    app.ScaleRuleAuthArgs(
                        secret_ref="github-pat",
                        trigger_parameter="personalAccessToken",
                    )
                ],
            )
            trigger = app.JobConfigurationEventTriggerConfigArgs(
                parallelism=1,
                replica_completion_count=1,
                scale=app.JobScaleArgs(
                    min_executions=0, max_executions=1, rules=[rule]
                ),
            )
            job(
                re.sub(r"[^a-z0-9]+", "-", f"runner-{repo}".lower())[:32].rstrip(
                    "-"
                ),
                "ReadOnly",
                app.JobConfigurationArgs(
                    trigger_type="Event",
                    replica_timeout=7200,
                    secrets=[app.SecretArgs(name="github-pat", value=pat)],
                    event_trigger_config=trigger,
                ),
                app.ContainerArgs(
                    name="runner",
                    image=f"{IMAGE}-runner:{OPS_VERSION}",
                    resources=app.ContainerResourcesArgs(
                        cpu=args.get("cpu") or 6,
                        memory=args.get("memory") or "32Gi",
                    ),
                    env=[
                        app.EnvironmentVarArgs(
                            name="GITHUB_PAT", secret_ref="github-pat"
                        ),
                        app.EnvironmentVarArgs(
                            name="GITHUB_REPO", value=f"{owner}/{repo}"
                        ),
                    ],
                    volume_mounts=[mount],
                ),
            )

        self.download_job_name = download.name
        self.register_outputs({"download_job_name": download.name})
