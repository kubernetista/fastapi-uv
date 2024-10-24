# NOTE: it's recommended to move your code into other files in this package
# and keep __init__.py for imports only, according to Python's convention.
# The only requirement is that Dagger needs to be able to import a package
# called "main" (i.e., src/main/).
#
# For example, to import from src/main/main.py:
# >>> from .main import FastapiUv as FastapiUv

# import random
from typing import Annotated

import dagger
from dagger import Doc, dag, function, object_type


@object_type
class FastapiUv:
    @function
    def container_echo(self, string_arg: str) -> dagger.Container:
        """Returns a container that echoes whatever string argument is provided 🚀"""
        return dag.container().from_("alpine:latest").with_exec(["echo", string_arg])

    # @function
    # async def grep_dir(self, directory_arg: dagger.Directory, pattern: str) -> str:
    #     """Returns lines that match a pattern in the files of the provided Directory"""
    #     return await (
    #         dag.container()
    #         .from_("alpine:latest")
    #         .with_mounted_directory("/mnt", directory_arg)
    #         .with_workdir("/mnt")
    #         .with_exec(["grep", "-R", pattern, "."])
    #         .stdout()
    #     )

    @function
    async def build(
        self,
        src: Annotated[
            dagger.Directory,
            Doc("location of directory containing Dockerfile"),
        ],
    ) -> dagger.Container:
        """Build and publish image from existing Dockerfile"""
        ref = (
            dag.container()
            .with_directory(".", src)
            .with_workdir("/")
            .directory(".")
            .docker_build()  # build from Dockerfile
            .with_registry_auth("ttl.sh")
            # .with_registry("ghcr.io")
            # .publish("ttl.sh/hello-dagger")
        )
        return await ref

    # dagger call publish --registry=registry.gitlab.com --username=acola --password=env:GITLAB_TOKEN --path "/fastapi-uv" --image "my-nginx-2" --tag "v1"
    @function
    async def publish(
        self,
        registry: Annotated[str, Doc("Registry address")],
        username: Annotated[str, Doc("Registry username")],
        password: Annotated[dagger.Secret, Doc("Registry password")],
        path: Annotated[str, Doc("Path to image")],
        image: Annotated[str, Doc("Image name")],
        tag: Annotated[str, Doc("Image tag")],
    ) -> str:
        """Publish a container image to a private registry"""
        return await (
            dag.container()
            .from_("nginx:1-alpine")
            .with_new_file(
                "/usr/share/nginx/html/index.html",
                "Hello from Dagger!",
                permissions=0o400,
            )
            .with_registry_auth(registry, username, password)
            .publish(f"{registry}/{path}/{image}:{tag}")
        )
