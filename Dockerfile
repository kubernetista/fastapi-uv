# syntax=docker/dockerfile:1
FROM python:3.12-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Change the working directory to the `app` directory
WORKDIR /app

# Copy the lockfile and `pyproject.toml` into the image
COPY uv.lock /app/
COPY pyproject.toml /app/

# Install dependencies
RUN uv version ; uv sync --frozen --no-install-project

# Copy pyproject into the image
COPY pyproject.toml /app/

# Copy the project into the image
COPY ./src/ /app

# Copy the README.md into the image
COPY README.md /app/

# Sync the project
RUN uv sync --locked

# set the environment variables
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Run the application
CMD [ "python", "fastapi_uv/main.py"]
