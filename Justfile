# Justfile

# Initialization
set shell := ["zsh", "-l", "-cu"]
### set shell := ["zsh", "-l", "-c"]
### set shell := ["bash", "-c"]

# set script-interpreter := ['bash', '-eu']

# Variables
JUST_IMAGE_NAME     := "fastapi-uv"
JUST_CONTAINER_NAME := "fastapi-uv-container"
JUST_REGISTRY:= "registry.gitlab.com"
JUST_REG_USERNAME:= "acola"
JUST_REG_PASSWORD:= "env:GITLAB_TOKEN"
JUST_REG_PATH:= "acola/fastapi-uv"
# JUST_CONTAINER_TAG:= "$(git rev-parse --short=8 HEAD)"
JUST_CONTAINER_TAG:= "$(git describe --tags --abbrev=4)"
JUST_CONTAINER_SRC:= "."

# JUST_DOCKERFILE     := "Dockerfile"         # Python 3.12 image
JUST_DOCKERFILE     := "alpine.dockerfile"    # Python 3.12 Alpine image
# JUST_DOCKERFILE     := "ubuntu.dockerfile"  # Ubuntu:latest image

JUST_BUILD_OPTS     := ""
# JUST_BUILD_OPTS     := "--no-cache"

JUST_IMAGE_TAG      := "latest"
# JUST_IMAGE_TAG      := "standard"
# JUST_IMAGE_TAG      := "alpine"
# JUST_IMAGE_TAG      := "ubuntu"

JUST_PORT           := "8001"
JUST_PORT_DEV       := "8008"
JUST_PORT_DOC       := "8009"

# List 📜 all recipes (this!)
help:
    @just --list

# Install 🧱 the virtual environment and install the pre-commit hooks
code-install:
    @echo "🚀 Creating virtual environment using uv"
    uv sync
    uv run pre-commit install

# Run 🛠️ the app in development mode with reload ♻️  (alias: dev)
code-run-dev:
    @/bin/echo -e "\n🚀 Running app in development mode (with reload)\n"
    #@ uv run --with "fastapi[standard]" fastapi dev ./src/fastapi_uv/main.py --port {{JUST_PORT_DEV}}
    uv run fastapi dev ./src/fastapi_uv/main.py --port {{JUST_PORT_DEV}}
    @# @uv run uvicorn src.fastapi_uv.main:app --reload --port {{JUST_PORT_DEV}}

alias dev := code-run-dev

# Test 🧪 code and generate test Coverage report  (alias: test)
code-test:
    @echo -e "\n🚀 Testing code: Running pytest with coverage\n"
    uv run python -m pytest --cov --cov-config=pyproject.toml --cov-report=xml

alias test := code-test

# Upgrade 🎈 Python packages
code-upgrade-packages:
    @echo "🚀 Upgrading Python packages with UV"
    uv sync --upgrade

# Run 🔎 pre-commit checks
code-pre-commit-check:
    @echo "🚀 Running pre-commit checks"
    uv run pre-commit run --all-files

# Run 🔎 code quality tools  (alias: check)
code-check:
    @echo -e "\n🚀 Checking lock file consistency with 'pyproject.toml'"
    uv lock --locked
    @echo -e "\n🚀 Linting code: Running pre-commit"
    uv run pre-commit run --all-files
    @echo -e "\n🚀 Static type checking: Running mypy"
    uv run mypy ./src
    @echo -e "\n🚀 Checking for obsolete dependencies: Running deptry"
    uv run deptry ./src
    @echo -e "\n🚀 Running Pyright for type checking"
    uv run --with pyright pyright ./src

alias check := code-check

# Scan 🕵🏻‍♂️ the code for security issues using Bandit
code-scan-bandit:
    @echo -e "🕵🏻‍♂️ Scanning code for security issues using Bandit\n"
    -uvx bandit -r ./src/

# Scan 🕵🏻‍♂️ the code for security issues using Semgrep
code-scan-semgrep:
    @echo -e "🕵🏻‍♂️ Scanning code for security issues using Semgrep\n"
    uvx --with semgrep semgrep --config=auto src/

# # Run SonarQube scan
# scan-code-sonarqube:
#     @echo "🚀 Running SonarQube scan"
#     @docker run --rm -d --name sonarqube -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true -p 9000:9000 sonarqube:latest
#     @sleep 60
#     @sonar-scanner
#     @docker stop sonarqube

# Build 📦 wheel file
code-package-build:
    @echo -e "🚀 Creating wheel file\n"
    uvx --from build pyproject-build --installer uv

# Clean 🧹 build artifacts
code-package-clean:
    @echo -e "🚀 Removing build artifacts"
    uv run python -c "import shutil; import os; shutil.rmtree('dist') if os.path.exists('dist') else None"

# Publish 📰 a release to PyPI (requires API token)
code-package-publish:
    @echo -e "🚀 Publishing\n"
    hatch publish

# Build 📦 and publish 📰
code-package-build-publish:  code-package-build  code-package-publish

# 🏷️ Update app version in pyproject.toml
code-bump-version:
    @echo -e "🚀 Updating app version in pyproject.toml\n"
    uv run -q --with tomli_w ./scripts/update_version.py
    uv lock
    git add pyproject.toml uv.lock
    git commit -m "Bump version"

alias bump := code-bump-version

# 🎯 Test the app connecting to the the API with a curl GET
code-app-test:
    @echo -e "\n🚀 Testing the app connecting to the the API\n"
    curl -s http://localhost:{{JUST_PORT}} | jq

alias app-test := code-app-test

## Container recipes
# Build 📦 the container  (alias: build)
container-build *build-options:
    @echo -e "\n🚀 Building container\n"
    docker build {{JUST_BUILD_OPTS}} {{build-options}} . -f {{JUST_DOCKERFILE}} -t {{JUST_IMAGE_NAME}}:{{JUST_IMAGE_TAG}} --load

alias build := container-build

# Start 🚀 the container  (alias: start)
container-start: container-build
    @echo -e "\n🚀 Starting the container {{JUST_CONTAINER_NAME}}"
    docker run --rm --name {{JUST_CONTAINER_NAME}} --detach -p {{JUST_PORT}}:8001 {{JUST_IMAGE_NAME}}:{{JUST_IMAGE_TAG}}
    @echo -e "\n🎁 Container available: 🔗 http://localhost:{{JUST_PORT}}"

alias start := container-start

# Start 🚀 the container from the image (i.e: ghcr.io/user/app:latest)
container-start-from-image $ARG_IMAGE_NAME:
    #!/usr/bin/env bash
    echo -e "\n🚀 Starting {{JUST_CONTAINER_NAME}} from image:\n➡️ {{ARG_IMAGE_NAME}}\n"
    docker run --rm --name {{JUST_CONTAINER_NAME}} --detach -p {{JUST_PORT}}:8001 {{ARG_IMAGE_NAME}}
    if [[ $? -eq 125 ]]; then
        echo -e "\n🚨 Error: container {{JUST_CONTAINER_NAME}} already exists. Fix:\n  just stop"
    else
        echo -e "\n🎁 Container available: 🔗 http://localhost:{{JUST_PORT}}"
    fi

alias start-image := container-start-from-image

# Push 📦 the container to Docker registry
container-push:
    @echo "📦 Pushing container to Docker registry"
    docker push {{JUST_IMAGE_NAME}}:{{JUST_IMAGE_TAG}}

# Stop 🛑 the running container  (alias: stop)
container-stop:
    @echo -e "\n🛑 Stopping container"
    -docker stop {{JUST_CONTAINER_NAME}}
    @echo -e "\n🗑️ Removing container"
    -docker rm {{JUST_CONTAINER_NAME}}

alias stop := container-stop

# Shell into 🚪 the container
container-shell:
    @echo -e "\n🚪 Connecting to container shell"
    docker exec -it  {{JUST_CONTAINER_NAME}} /bin/bash

# Remove 🗑️ the container
container-remove:
    @echo -e "🗑️ Removing container\n"
    docker rm {{JUST_CONTAINER_NAME}}

# Remove 🗑️ the Docker image
container-image-remove:
    @echo -e "🗑️ Removing container image\n"
    docker rmi {{JUST_IMAGE_NAME}}:{{JUST_IMAGE_TAG}}
    @echo -e "\n🗑️ Container image removed"

# View 📜 logs of the running container
container-logs:
    @echo "📜 View logs of the running container"
    docker logs {{JUST_CONTAINER_NAME}}

# View 📜 and follow 🍿 logs of the running container
container-logs-f:
    @echo "📜 View and follow logs of the running container"
    docker logs -f {{JUST_CONTAINER_NAME}}

# Scan 🕵🏻‍♂️  the container for vulnerabilities using Trivy 🎯
container-scan-trivy: container-build
    @echo -e "\n🕵🏻‍♂️  Scanning container for vulnerabilities using Trivy 🎯\n"
    # @trivy image {{JUST_IMAGE_NAME}}
    # @trivy image --severity HIGH,CRITICAL {{JUST_IMAGE_NAME}}
    trivy image --severity MEDIUM,HIGH,CRITICAL --ignore-unfixed {{JUST_IMAGE_NAME}}:{{JUST_IMAGE_TAG}}

# Scan 🕵🏻‍♂️  the container for vulnerabilities using Grype 👾
container-scan-grype: container-build
    @echo -e "\n🕵🏻‍♂️  Scanning container for vulnerabilities using Grype 👾\n"
    grype --only-fixed {{JUST_IMAGE_NAME}}:{{JUST_IMAGE_TAG}}


## Documentation recipes
# Test 📚 if documentation can be built without warnings or errors
docs-test:
    uv run mkdocs build -s

# Build 📚 and serve the documentation
docs:
    @echo "📚 Serving documentation on 🔗 http://127.0.0.1:{{JUST_PORT_DOC}}"
    uv run mkdocs serve -a 127.0.0.1:{{JUST_PORT_DOC}}

# 🗡️ Build the container with Dagger
dagger-build:
    @echo "\n🗡️ Dagger build\n"
    dagger call build --src {{JUST_CONTAINER_SRC}}

# 🗡️ Build and push the container to the registry with Dagger
dagger-build-push:
    @echo "\n🗡️ Dagger build and push\n"
    dagger call build-push --registry={{JUST_REGISTRY}} --username={{JUST_REG_USERNAME}} --password={{JUST_REG_PASSWORD}} --path {{JUST_REG_PATH}} --image {{JUST_IMAGE_NAME}} --tag {{JUST_CONTAINER_TAG}} --src {{JUST_CONTAINER_SRC}}

# 🗡️ Test the container with Dagger 🧪
dagger-test:
    @echo "\n🗡️ Dagger test 🧪\n"
    dagger call test --src {{JUST_CONTAINER_SRC}}
