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
    async def build(
        self,
        src: Annotated[
            dagger.Directory,
            Doc("location of directory containing Dockerfile"),
        ],
    ) -> dagger.Container:
        """Build image from existing Dockerfile"""
        ref = (
            dag.container()
            .with_directory(".", src)
            .with_workdir("/")
            .directory(".")
            .docker_build()  # build from Dockerfile
        )
        return await ref

    # dagger call publish --registry=registry.gitlab.com --username=acola \
    #   --password=env:GITLAB_TOKEN --path "acola/fastapi-uv" --image "my-nginx-2" \
    #   --tag "v1"
    @function
    async def build_push(
        self,
        src: Annotated[
            dagger.Directory,
            Doc("location of directory containing Dockerfile"),
        ],
        registry: Annotated[str, Doc("Registry address")],
        username: Annotated[str, Doc("Registry username")],
        password: Annotated[dagger.Secret, Doc("Registry password")],
        path: Annotated[str, Doc("Path to image")],
        image: Annotated[str, Doc("Image name")],
        tag: Annotated[str, Doc("Image tag")],
    ) -> str:
        """Publish a container image to a private registry"""
        container = await self.build(src)
        return await container.with_registry_auth(registry, username, password).publish(
            f"{registry}/{path}/{image}:{tag}"
        )
