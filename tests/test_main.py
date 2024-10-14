from fastapi_uv.main import get_root


def test_get_root() -> None:
    assert get_root() == {"message": "OK"}
