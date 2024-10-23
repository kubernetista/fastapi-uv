# Justfile

# Variables
VAR_IMAGE_NAME := "fastapi-uv:latest"
VAR_CONTAINER_NAME := "fastapi-uv-container"
VAR_PORT := "8001"
VAR_PORT_DEV := "8008"
VAR_PORT_DOC := "8009"

# List 📜 all recipes (this!)
help:
    @just --list

# Install 🧱 the virtual environment and install the pre-commit hooks
install:
    @echo "🚀 Creating virtual environment using uv"
    @uv sync
    @uv run pre-commit install

# Upgrade 🎈 dependencies
upgrade-dependencies:
    @echo "🚀 Upgrading dependencies"
    @uv sync --upgrade

# Run 🔎 pre-commit checks
pre-commit-check:
    @echo "🚀 Running pre-commit checks"
    @uv run pre-commit run --all-files

# Run 🔎 code quality tools
check:
    @echo -e "\n🚀 Checking lock file consistency with 'pyproject.toml'"
    @uv lock --locked
    @echo -e "\n🚀 Linting code: Running pre-commit"
    @uv run pre-commit run --all-files
    @echo -e "\n🚀 Static type checking: Running mypy"
    @uv run mypy ./src
    @echo -e "\n🚀 Checking for obsolete dependencies: Running deptry"
    @uv run deptry ./src
    @echo -e "\n🚀 Running Pyright for type checking"
    @uv run --with pyright pyright ./src

# Test 🧪 code and generate test Coverage report
test:
    @echo -e "\n🚀 Testing code: Running pytest with coverage\n"
    @uv run python -m pytest --cov --cov-config=pyproject.toml --cov-report=xml

# Scan 🕵🏻‍♂️ the code for security issues using Bandit
scan-code-bandit:
    @echo -e "🕵🏻‍♂️ Scanning code for security issues using Bandit\n"
    -@uvx bandit -r ./src/

# Scan 🕵🏻‍♂️ the code for security issues using Semgrep
scan-code-semgrep:
    @echo -e "🕵🏻‍♂️ Scanning code for security issues using Semgrep\n"
    @uvx --with semgrep semgrep --config=auto src/

# # Run SonarQube scan
# scan-code-sonarqube:
#     @echo "🚀 Running SonarQube scan"
#     @docker run --rm -d --name sonarqube -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true -p 9000:9000 sonarqube:latest
#     @sleep 60
#     @sonar-scanner
#     @docker stop sonarqube

# Build 📦 wheel file
build-pacakge:
    @echo "🚀 Creating wheel file"
    @uvx --from build pyproject-build --installer uv

# Clean 🧹 build artifacts
clean-build:
    @echo "🚀 Removing build artifacts"
    @uv run python -c "import shutil; import os; shutil.rmtree('dist') if os.path.exists('dist') else None"

# Publish 📰 a release to PyPI (requires API token)
publish-pacakge:
    @echo "🚀 Publishing."
    @hatch publish

# Build 📦 and publish 📰
build-publish-pacakge: build-pacakge publish-pacakge

# Test 📚 if documentation can be built without warnings or errors
docs-test:
    @uv run mkdocs build -s

# Build 📚 and serve the documentation
docs:
    @echo "📚 Serving documentation on 🔗 http://127.0.0.1:{{VAR_PORT_DOC}}"
    @uv run mkdocs serve -a 127.0.0.1:{{VAR_PORT_DOC}}

# Run 🛠️ the app in development mode with reload ♻️  (alias: dev)
code-run:
    @echo -e "\n🚀 Running app in development mode (with reload)\n"
    #@ uv run --with "fastapi[standard]" fastapi dev ./src/fastapi_uv/main.py --port {{VAR_PORT_DEV}}
    @ uv run fastapi dev ./src/fastapi_uv/main.py --port {{VAR_PORT_DEV}}
    @# @uv run uvicorn src.fastapi_uv.main:app --reload --port {{VAR_PORT_DEV}}

alias dev := code-run

# Build 📦 the container
container-build:
    @echo -e "\n🚀 Building container\n"
    docker build . -t {{VAR_IMAGE_NAME}} --load

# Scan 🕵🏻‍♂️  the container for vulnerabilities using Trivy 🎯
scan-container-trivy: container-build
    @echo -e "\n🕵🏻‍♂️  Scanning container for vulnerabilities using Trivy 🎯\n"
    # @trivy image {{VAR_IMAGE_NAME}}
    # @trivy image --severity HIGH,CRITICAL {{VAR_IMAGE_NAME}}
    @trivy image --severity MEDIUM,HIGH,CRITICAL --ignore-unfixed {{VAR_IMAGE_NAME}}

# Scan 🕵🏻‍♂️  the container for vulnerabilities using Grype 👾
scan-container-grype: container-build
    @echo -e "\n🕵🏻‍♂️  Scanning container for vulnerabilities using Grype 👾\n"
    @grype --only-fixed {{VAR_IMAGE_NAME}}

# Push 📦 the container to Docker registry
container-push:
    @echo "📦 Pushing container to Docker registry"
    @docker push {{VAR_IMAGE_NAME}}

# Start 🚀 the container
container-start: container-build
    @echo -e "\n🚀 Starting the container {{VAR_CONTAINER_NAME}}\n"
    docker run --rm --name {{VAR_CONTAINER_NAME}} --detach -p {{VAR_PORT}}:8001 {{VAR_IMAGE_NAME}}
    @echo -e "\nContainer \"{{VAR_CONTAINER_NAME}}\" is accessible at http://localhost:{{VAR_PORT}}"

# Stop 🛑 the running container
container-stop:
    @echo -e "\n🛑 Stopping running container\n"
    @docker stop {{VAR_CONTAINER_NAME}}
    @echo -e "\nContainer \"{{VAR_CONTAINER_NAME}}\" removed"

# Remove 🗑️ the container
container-remove:
    @echo "🗑️ Removing container"
    @docker rm {{VAR_CONTAINER_NAME}}

# Remove 🗑️ the Docker image
image-remove:
    @echo "🗑️ Removing Docker image"
    @docker rmi {{VAR_IMAGE_NAME}}
    @echo "\nContainer image \"{{VAR_IMAGE_NAME}}\" removed"

# View 📜 logs of the running container
container-logs:
    @echo "📜 View logs of the running container"
    @docker logs {{VAR_CONTAINER_NAME}}

# View 📜 and follow 🍿 logs of the running container
container-logs-f:
    @echo "📜 View and follow logs of the running container"
    @docker logs -f {{VAR_CONTAINER_NAME}}
