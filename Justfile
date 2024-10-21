# Justfile

# Variables
IMAGE_NAME := "fastapi-uv:latest"
CONTAINER_NAME := "fastapi-uv-container"
PORT := "8001"

# List 📜 all recipes (default)
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
    @echo "🚀 Checking lock file consistency with 'pyproject.toml'"
    @uv lock --locked
    @echo "🚀 Linting code: Running pre-commit"
    @uv run pre-commit run -a
    @echo "🚀 Static type checking: Running mypy"
    @uv run mypy ./src
    @echo "🚀 Checking for obsolete dependencies: Running deptry"
    @uv run deptry ./src

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
    @echo "📚 Serving documentation on http://127.0.0.1:8009"
    @uv run mkdocs serve -a 127.0.0.1:8009

# Run 🛠️ the app in development mode with reload ♻️
dev:
    @echo "🚀 Running app in development mode with reload"
    @uv run uvicorn src.fastapi_uv.main:app --reload --port 8008

# Build 📦 the container
build-container:
    @echo -e "\n🚀 Building container\n"
    docker build . -t {{IMAGE_NAME}} --load

# Scan 🕵🏻‍♂️  the container for vulnerabilities using Trivy 🎯
scan-container-trivy: build-container
    @echo -e "\n🕵🏻‍♂️  Scanning container for vulnerabilities using Trivy 🎯\n"
    # @trivy image {{IMAGE_NAME}}
    # @trivy image --severity HIGH,CRITICAL {{IMAGE_NAME}}
    @trivy image --severity MEDIUM,HIGH,CRITICAL --ignore-unfixed {{IMAGE_NAME}}

# Scan 🕵🏻‍♂️  the container for vulnerabilities using Grype 👾
scan-container-grype: build-container
    @echo -e "\n🕵🏻‍♂️  Scanning container for vulnerabilities using Grype 👾\n"
    @grype --only-fixed {{IMAGE_NAME}}

# Push 🚀 the container to Docker registry
push-container:
    @echo "🚀 Pushing container to Docker registry"
    @docker push {{IMAGE_NAME}}

# Run 🏃 the container locally
run-container: build-container
    @echo -e "\n🏃 Running container locally\n"
    docker run --rm --name {{CONTAINER_NAME}} --detach -p {{PORT}}:{{PORT}} {{IMAGE_NAME}}
    @echo -e "\nContainer \"{{CONTAINER_NAME}}\" is accessible at http://localhost:{{PORT}}"

# Stop 🛑 the running container
stop-container:
    @echo -e "\n🛑 Stopping running container\n"
    @docker stop {{CONTAINER_NAME}}
    @echo -e "\nContainer \"{{CONTAINER_NAME}}\" removed"

# Remove 🗑️ the container
remove-container:
    @echo "🗑️ Removing container"
    @docker rm {{CONTAINER_NAME}}

# Remove 🗑️ the Docker image
remove-image:
    @echo "🗑️ Removing Docker image"
    @docker rmi {{IMAGE_NAME}}
    @echo "\nContainer image \"{{IMAGE_NAME}}\" removed"

# View 📜 logs of the running container
container-logs:
    @echo "📜 Viewing logs of the running container"
    @docker logs {{CONTAINER_NAME}}

container-logs-f:
    @echo "📜 Viewing logs of the running container"
    @docker logs -f {{CONTAINER_NAME}}
