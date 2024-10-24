# Justfile

# Initialization
set shell := ["zsh", "-l", "-cu"]
### set shell := ["zsh", "-l", "-c"]
### set shell := ["bash", "-c"]

# set script-interpreter := ['bash', '-eu']

# Variables
VAR_IMAGE_NAME     := "fastapi-uv"
VAR_CONTAINER_NAME := "fastapi-uv-container"

# VAR_DOCKERFILE     := "Dockerfile"
VAR_DOCKERFILE     := "alpine.dockerfile"
# VAR_DOCKERFILE     := "ubuntu.dockerfile"

VAR_BUILD_OPTS     := ""
# VAR_BUILD_OPTS     := "--no-cache"

# VAR_IMAGE_TAG      := "latest"
# VAR_IMAGE_TAG      := "standard"
VAR_IMAGE_TAG      := "alpine"
# VAR_IMAGE_TAG      := "ubuntu"

VAR_PORT           := "8001"
VAR_PORT_DEV       := "8008"
VAR_PORT_DOC       := "8009"

# List 📜 all recipes (this!)
help:
    @just --list

# Install 🧱 the virtual environment and install the pre-commit hooks
code-install:
    @echo "🚀 Creating virtual environment using uv"
    uv sync
    uv run pre-commit install

# Run 🛠️ the app in development mode with reload ♻️  (alias: dev)
code-run:
    @/bin/echo -e "\n🚀 Running app in development mode (with reload)\n"
    #@ uv run --with "fastapi[standard]" fastapi dev ./src/fastapi_uv/main.py --port {{VAR_PORT_DEV}}
    uv run fastapi dev ./src/fastapi_uv/main.py --port {{VAR_PORT_DEV}}
    @# @uv run uvicorn src.fastapi_uv.main:app --reload --port {{VAR_PORT_DEV}}

alias dev := code-run

# Test 🧪 code and generate test Coverage report  (alias: test)
code-test:
    @echo -e "\n🚀 Testing code: Running pytest with coverage\n"
    uv run python -m pytest --cov --cov-config=pyproject.toml --cov-report=xml

alias test := code-test

# Upgrade 🎈 dependencies
code-upgrade-dependencies:
    @echo "🚀 Upgrading dependencies"
    uv sync --upgrade

# Run 🔎 pre-commit checks
code-pre-commit-check:
    @echo "🚀 Running pre-commit checks"
    uv run pre-commit run --all-files

# Run 🔎 code quality tools
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

## Container recipes
# Build 📦 the container
container-build:
    @echo -e "\n🚀 Building container\n"
    docker build {{VAR_BUILD_OPTS}} . -f {{VAR_DOCKERFILE}} -t {{VAR_IMAGE_NAME}}:{{VAR_IMAGE_TAG}} --load

# Start 🚀 the container
container-start: container-build
    @echo -e "\n🚀 Starting the container {{VAR_CONTAINER_NAME}}"
    docker run --rm --name {{VAR_CONTAINER_NAME}} --detach -p {{VAR_PORT}}:8001 {{VAR_IMAGE_NAME}}:{{VAR_IMAGE_TAG}}
    @echo -e "\n🎁 Container available: 🔗 http://localhost:{{VAR_PORT}}"

# Push 📦 the container to Docker registry
container-push:
    @echo "📦 Pushing container to Docker registry"
    docker push {{VAR_IMAGE_NAME}}:{{VAR_IMAGE_TAG}}

# Stop 🛑 the running container
container-stop:
    @echo -e "\n🛑 Stopping container"
    -docker stop {{VAR_CONTAINER_NAME}}
    @echo -e "\n🗑️ Removing container"
    -docker rm {{VAR_CONTAINER_NAME}}

# Shell into 🚪 the container
container-shell:
    @echo -e "\n🚪 Connecting to container shell"
    docker exec -it  {{VAR_CONTAINER_NAME}} /bin/bash

# Remove 🗑️ the container
container-remove:
    @echo -e "🗑️ Removing container\n"
    docker rm {{VAR_CONTAINER_NAME}}

# Remove 🗑️ the Docker image
container-image-remove:
    @echo -e "🗑️ Removing container image\n"
    docker rmi {{VAR_IMAGE_NAME}}:{{VAR_IMAGE_TAG}}
    @echo -e "\n🗑️ Container image removed"

# View 📜 logs of the running container
container-logs:
    @echo "📜 View logs of the running container"
    docker logs {{VAR_CONTAINER_NAME}}

# View 📜 and follow 🍿 logs of the running container
container-logs-f:
    @echo "📜 View and follow logs of the running container"
    docker logs -f {{VAR_CONTAINER_NAME}}

# Scan 🕵🏻‍♂️  the container for vulnerabilities using Trivy 🎯
container-scan-trivy: container-build
    @echo -e "\n🕵🏻‍♂️  Scanning container for vulnerabilities using Trivy 🎯\n"
    # @trivy image {{VAR_IMAGE_NAME}}
    # @trivy image --severity HIGH,CRITICAL {{VAR_IMAGE_NAME}}
    trivy image --severity MEDIUM,HIGH,CRITICAL --ignore-unfixed {{VAR_IMAGE_NAME}}:{{VAR_IMAGE_TAG}}

# Scan 🕵🏻‍♂️  the container for vulnerabilities using Grype 👾
container-scan-grype: container-build
    @echo -e "\n🕵🏻‍♂️  Scanning container for vulnerabilities using Grype 👾\n"
    grype --only-fixed {{VAR_IMAGE_NAME}}:{{VAR_IMAGE_TAG}}


## Documentation recipes
# Test 📚 if documentation can be built without warnings or errors
docs-test:
    uv run mkdocs build -s

# Build 📚 and serve the documentation
docs:
    @echo "📚 Serving documentation on 🔗 http://127.0.0.1:{{VAR_PORT_DOC}}"
    uv run mkdocs serve -a 127.0.0.1:{{VAR_PORT_DOC}}
