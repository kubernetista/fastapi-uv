from fastapi_uv.main import root_route


def test_root_route() -> None:
    assert root_route() == {"message": "OK"}
