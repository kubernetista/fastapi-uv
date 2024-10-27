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
from dagger import DaggerError, Doc, dag, function, object_type


@object_type
class FastapiUv:
    # dagger call test --src .
    @function
    async def test(
        self,
        src: Annotated[
            dagger.Directory,
            Doc("root directory of the project"),
        ],
    ) -> str:
        """Test a python project with uv, pre-commit, etc"""

        try:
            await (
                dag.container()
                .from_("python:3.12")
                .with_exec([
                    "sh",
                    "-c",
                    "curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR='/usr/local' sh",
                ])
                .with_directory("/src", src, exclude=[".venv/", ".mypy_cache/", "dist/", ".tox/"])
                .with_workdir("/src")
                # .with_exec(["sh", "-c", "uv lock --locked"])
                .with_exec(["sh", "-c", "uv lock --frozen"])
                .with_exec(["sh", "-c", "uv run pre-commit run --all-files"])
                .with_exec(["sh", "-c", "uv run mypy ./src"])
                .with_exec(["sh", "-c", "uv run deptry ./src"])
                .with_exec(["sh", "-c", "uv run --with pyright pyright ./src"])
                # the result of `sync` is the container, which allows continued chaining
                .sync()
            )
        except DaggerError as e:
            # DaggerError is the base class for all errors raised by Dagger
            msg = "Unexpected Dagger error"
            raise RuntimeError(msg) from e
        else:
            return "Test completed successfully"

    # dagger call build --src .
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

    # dagger call build-push --registry=registry.gitlab.com --username=acola \
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
        image_name = f"{registry}/{path}/{image}:{tag}"
        return await container.with_registry_auth(registry, username, password).publish(image_name)
