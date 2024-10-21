import os

import uvicorn
from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def get_root() -> dict[str, str]:
    return {"message": "OK"}


if __name__ == "__main__":
    host = os.getenv("HOST", "0.0.0.0")  # noqa: S104  # nosec B104
    port = int(os.getenv("PORT", 8001))
    uvicorn.run(app, host=host, port=port, lifespan="off")
