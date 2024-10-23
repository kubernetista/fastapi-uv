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
            # .publish("ttl.sh/hello-dagger")
        )
        return await ref
