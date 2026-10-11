#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"
cd "${repo_root}"

# Named volumes are created as root. Hand only the mounted tool directories to
# the non-root development user; do not authenticate or provision from here.
sudo chown -R vscode:vscode \
    /home/vscode/.aws \
    /home/vscode/.codex \
    /home/vscode/.databricks \
    /home/vscode/.cache/uv \
    /home/vscode/.local/share/uv/python

chmod 700 \
    /home/vscode/.aws \
    /home/vscode/.codex \
    /home/vscode/.databricks

if [[ -f pyproject.toml ]]; then
    if [[ -f uv.lock ]]; then
        uv sync --locked --all-extras
    else
        uv sync --all-extras
    fi
elif [[ ! -x .venv/bin/python ]]; then
    uv venv --python 3.12 .venv
fi

printf '%s\n' \
    "Development container toolchain:" \
    "  $(terraform version | head -n 1)" \
    "  $(aws --version 2>&1)" \
    "  $(databricks version)" \
    "  $(uv --version)" \
    "  $(java -version 2>&1 | head -n 1)" \
    "" \
    "Container ready. Authenticate explicitly with AWS and Databricks when needed."
