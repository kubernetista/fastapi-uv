import os

import tomli
import uvicorn
from fastapi import FastAPI
from pyproject_metadata import StandardMetadata

app = FastAPI()

# Load and parse pyproject.toml using tomli
with open("pyproject.toml", "rb") as f:
    parsed_pyproject = tomli.load(f)

# Extract standardized metadata
metadata = StandardMetadata.from_pyproject(
    parsed_pyproject, allow_extra_keys=False, all_errors=True, metadata_version="2.3"
)


@app.get("/")
def get_root() -> dict[str, str]:
    return {
        "status": "OK",
        "app-name": metadata.name,
        "version": str(metadata.version),
    }


if __name__ == "__main__":
    host = os.getenv("HOST", "0.0.0.0")  # noqa: S104  # nosec B104
    port = int(os.getenv("PORT", 8001))
    uvicorn.run(app, host=host, port=port, lifespan="off")
