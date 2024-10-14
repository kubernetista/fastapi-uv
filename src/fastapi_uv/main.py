import uvicorn
from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def get_root() -> dict[str, str]:
    return {"message": "OK"}


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8001)
