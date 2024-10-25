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
from dagger import DaggerError, Doc, dag, field, function, object_type

SCRIPT = """#!/bin/sh
echo "Test Suite"
echo "=========="
echo "Test 1: PASS" >> report.txt
echo "Test 2: FAIL" >> report.txt
echo "Test 3: PASS" >> report.txt
exit 0
"""


@object_type
class TestResult:
    report: dagger.File = field()
    exit_code: str = field()


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
        image_name = f"{registry}/{path}/{image}:{tag}"
        return await container.with_registry_auth(registry, username, password).publish(image_name)

    @function
    async def test(
        self,
        src: Annotated[
            dagger.Directory,
            Doc("root directory of the project"),
        ],
    ) -> TestResult:
        """Handle errors"""
        try:
            ctr = await (
                dag.container()
                # .from_("python:3.12-alpine")
                .from_("python:3.12")
                # .with_exec(["sh", "-c", "apk add --no-cache curl bash"])
                # .with_exec(["sh", "-c", "apt-get update && apt-get install -y curl bash"])
                .with_exec([
                    "sh",
                    "-c",
                    "curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR='/usr/local' sh",
                ])
                .with_directory("/src", src)
                .with_workdir("/src")
                # add script with execution permission to simulate a testing tool.
                # .with_new_file("run-tests", SCRIPT, permissions=0o750)
                # .terminal()
                # .terminal("/bin/bash")
                # .exec(["/usr/bin/bash"])
                # .terminal(["/usr/bin/bash"])
                # if the exit code isn't needed: "run-tests; true"
                .with_exec(["bash", "-c", "uv lock --locked"])
                .with_exec(["bash", "-c", "uv run pre-commit run --all-files"])
                .with_exec(["bash", "-c", "uv run mypy ./src"])
                .with_exec(["bash", "-c", "uv run deptry ./src"])
                .with_exec(["bash", "-c", "uv run --with pyright pyright ./src"])
                # the result of `sync` is the container, which allows continued chaining
                .sync()
            )

            # save report for inspection.
            report = ctr.file("report.txt")

            # use the saved exit code to determine if the tests passed.
            exit_code = await ctr.file("exit_code").contents()

            return TestResult(report=report, exit_code=exit_code)
        except DaggerError as e:
            # DaggerError is the base class for all errors raised by Dagger
            msg = "Unexpected Dagger error"
            raise RuntimeError(msg) from e

    @function
    async def test_test(
        self,
        src: Annotated[
            dagger.Directory,
            Doc("location of directory containing Dockerfile"),
        ],
    ) -> str:
        """Test function"""
        ref = (
            dag.container()
            .with_directory(".", src)
            .with_workdir("/")
            .directory(".")
            .docker_build()  # build from Dockerfile
        )
        return await ref


# ruff: noqa: RET505
