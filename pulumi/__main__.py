from pulumi.provider.experimental import component_provider_host

from runner import OPS_VERSION, Runner

if __name__ == "__main__":
    component_provider_host([Runner], "precommiteu", version=OPS_VERSION)
