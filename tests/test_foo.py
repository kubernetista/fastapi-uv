from fastapi_uv.foo import foo


def test_foo():
    assert foo("foo") == "foo"
