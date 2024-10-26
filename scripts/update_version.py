import re
import subprocess

import tomli
import tomli_w


def get_git_version() -> str:
    """Retrieve and format the latest Git version in PEP 440 format."""
    try:
        result = subprocess.run(  # noqa: S603
            ["git", "describe", "--tags", "--abbrev=4"],  # noqa: S607
            check=True,
            capture_output=True,
            text=True,
        )
        version = result.stdout.strip()

        # Remove any leading "v" and replace '-' with '+' for PEP 440 compliance
        pep440_version = re.sub(r"^v", "", version).replace("-", "+", 1).replace("-", ".")

    except subprocess.CalledProcessError as e:
        print("Error retrieving version from git:", e)
        return "0.0.0"  # Fallback version if git fails
    else:
        return pep440_version


def update_pyproject_version(version: str, filepath="pyproject.toml"):
    """Update the version in pyproject.toml."""
    with open(filepath, "rb") as f:
        pyproject_data = tomli.load(f)

    # Update the version in the pyproject data
    pyproject_data["project"]["version"] = version

    with open(filepath, "wb") as f:
        tomli_w.dump(pyproject_data, f)

    print(f"Updated pyproject.toml with version: {version}")


if __name__ == "__main__":
    version = get_git_version()
    update_pyproject_version(version)
