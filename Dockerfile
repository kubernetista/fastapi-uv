# syntax=docker/dockerfile:1
FROM python:3.12-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Change the working directory to the `app` directory
WORKDIR /app

# Copy the lockfile and `pyproject.toml` into the image
ADD uv.lock /app/uv.lock
ADD pyproject.toml /app/pyproject.toml

# Install dependencies
RUN uv sync --frozen --no-install-project

# Copy pyproject into the image
ADD pyproject.toml /app/

# Copy the project into the image
ADD ./src/ /app

# Copy the README.md into the image
ADD README.md /app/

# Sync the project
RUN uv sync --locked

# set the environment variables
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Run the application
CMD [ "python", "fastapi_uv/main.py"]
