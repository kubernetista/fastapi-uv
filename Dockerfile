# syntax=docker/dockerfile:1
# Use the official Python image
FROM python:3.12-slim

# Labels
LABEL org.opencontainers.image.source=https://github.com/kubernetista/fastapi-uv
LABEL org.opencontainers.image.description="FastAPI built with UV package manager"

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Change the working directory to the `app` directory
WORKDIR /app

# Copy `pyproject.toml` and the lockfile
COPY pyproject.toml /app/
COPY uv.lock /app/

# Install the application dependencies
RUN uv version ; uv sync --frozen --no-cache --no-dev --no-install-project

# Copy the project into the image
COPY ./src/ /app

# set the environment variables
ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

# Run the app
# CMD [ "python", "fastapi_uv/main.py"]
# CMD ["/app/.venv/bin/fastapi", "run", "app/main.py", "--port", "80", "--host", "0.0.0.0"]
CMD ["fastapi", "run", "fastapi_uv/main.py", "--proxy-headers", "--port", "8001"]
