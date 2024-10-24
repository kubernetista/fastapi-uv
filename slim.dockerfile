# syntax=docker/dockerfile:1
FROM ubuntu:latest

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Install uv
# apk add curl
# curl -LsSf https://astral.sh/uv/install.sh | sh
# source $HOME/.cargo/env
# uv python install 3.12

# Install Python
RUN uv python install 3.12

# Change the working directory to the `app` directory
WORKDIR /app

# Copy `pyproject.toml` and the lockfile
COPY pyproject.toml /app/
COPY uv.lock /app/

# Install dependencies
RUN uv version ; uv sync --locked --no-install-project

# Copy the project into the image
COPY ./src/ /app

# set the environment variables
ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

# Run the app
# CMD [ "python", "fastapi_uv/main.py"]
CMD ["fastapi", "run", "fastapi_uv/main.py", "--proxy-headers", "--port", "8001"]
