import os

import uvicorn
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

app = FastAPI()

app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
def get_root() -> dict[str, str]:
    return {"message": "OK"}


@app.get("/favicon.ico")
async def favicon() -> FileResponse:
    file_name = "favicon.ico"
    file_path = os.path.join(app.root_path, "static", file_name)
    return FileResponse(path=file_path, headers={"Content-Disposition": "attachment; filename=" + file_name})


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8001)
