#!/usr/bin/env python3

"""
Build and test a dev container template

Structure of copied test directory for each template

================================
Repository structure
================================

test/
└── <template-id>/
    └── test.sh
└── utils/
    └── test-utils.sh

================================
Destination in the built container
================================

<workspace>/
└── test/
    ├── test.sh
    └── test-utils.sh
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
import logging
from typing import Optional

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger(__name__)

WORKSPACE_SRC = "src"
WORKSPACE_TEST_DIR = "test"
SMOKE_DIRECTORY = "test"
SMOKE_UTILS_DIRECTORY = "utils"
SMOKE_FILE = "test.sh"
SMOKE_UTILS_FILE = "test-utils.sh"
SMOKE_LABEL = "test-container"


class ActionBuildError(Exception):
    """Exception raised for errors during the build process."""

    pass


def run(cmd: list[str], env: dict[str, str] = None, cwd: Path = None) -> str:
    """Run a shell command"""

    logger.debug(f"Running: {' '.join(cmd)}")
    try:
        result = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            env=env,
            check=True,
            capture_output=True,
            text=True,
        )
        if result.stdout:
            return result.stdout.strip()
        if result.stderr:
            return result.stderr.strip()
        return ""
    except FileNotFoundError:
        logger.error(f"Command not found: {cmd[0]}")
        return ""
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed with exit code {e.returncode}")
        if e.stderr:
            logger.error(e.stderr.strip())
        return ""


def ensure_exists(path: Path, what: str) -> None:
    if not path.exists():
        logger.error(f"{what} not found: {path}")
        raise ActionBuildError(f"{what} not found: {path}")


def copy_tree(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst, symlinks=True)


def copy_contents(src_dir: Path, dest_dir: Path) -> None:
    dest_dir.mkdir(parents=True, exist_ok=True)
    for child in src_dir.iterdir():
        target = dest_dir / child.name
        if child.is_dir():
            shutil.copytree(child, target, dirs_exist_ok=True, symlinks=True)
        elif child.is_file():
            shutil.copy2(child, target)
        else:
            pass  # Skip special files (e.g., fifos, sockets)


def replace_in_files(root: Path, search_term: str, replacement: str) -> None:
    """
    Perform a literal replacement across all regular files under root.
    Uses binary-safe replacement to avoid encoding issues.
    """

    search_term_b = search_term.encode("utf-8")
    replacement_b = replacement.encode("utf-8")

    for path in root.rglob("*"):
        if not path.is_file():
            continue
        try:
            with path.open("rb") as f:
                content = f.read()
            if search_term_b in content:
                new_content = content.replace(search_term_b, replacement_b)
                if new_content != content:
                    with path.open("wb") as f:
                        f.write(new_content)
                    logger.debug(f"Replaced in: {path.relative_to(root)}")
        except Exception:
            logger.exception(f"Error processing file {path}")
            raise


def configure_template_options(workspace_dir: Path) -> None:
    """
    If devcontainer-template.json has an 'options' object, replace all
    ${templateOption:<key>} tokens with the 'default' values.
    """

    template_json = workspace_dir / "devcontainer-template.json"
    if not template_json.exists():
        logger.error(f"Template JSON not found: {template_json}")
        raise ActionBuildError(f"Template JSON not found: {template_json}")

    with template_json.open("r", encoding="utf-8") as f:
        data = json.load(f)
    options = data.get("options")

    if not options:
        return
    if not isinstance(options, dict) or len(options.keys()) == 0:
        return

    logger.debug(f"Configuring template options for '{workspace_dir.name}'")
    replace_template_placeholders(workspace_dir, options)


def replace_template_placeholders(workspace_dir, options):
    """Replace all ${templateOption:<key>} placeholders in files under workspace_dir"""

    for option_key in options.keys():
        placeholder = f"${{templateOption:{option_key}}}"
        option_spec = options.get(option_key, {})
        default_value = None
        if isinstance(option_spec, dict):
            default_value = option_spec.get("default")

        if default_value is None or (
            isinstance(default_value, str) and default_value.strip() == ""
        ):
            logger.error(
                f"Template '{workspace_dir.name}' is missing a default value for option '{option_key}'"
            )
            raise ActionBuildError(f"Missing default for option '{option_key}'")

        default_value_str = str(default_value)
        logger.debug(f"Replacing '{placeholder}' with '{default_value_str}'")
        replace_in_files(workspace_dir, placeholder, default_value_str)


def prepare_workspace(workspace_root_dir: Path, template_id: str) -> Path:
    """Copy the template to a temporary workspace and configure options."""

    source_dir = workspace_root_dir / WORKSPACE_SRC / template_id
    if not source_dir.exists():
        logger.error(f"Source template directory not found: {source_dir}")
        raise ActionBuildError(f"Source template directory not found: {source_dir}")

    workspace_dir = Path(tempfile.mkdtemp(prefix="smoke_")) / template_id
    logger.debug(f"Preparing workspace at: {workspace_dir}")
    copy_tree(source_dir, workspace_dir)
    configure_template_options(workspace_dir)
    return workspace_dir


def copy_test_directory(
    project_root: Path, template_id: str, workspace_dir: Path
) -> None:
    """If a test folder exists for the template, copy it into the workspace."""

    test_dir = project_root / SMOKE_DIRECTORY / template_id
    if not test_dir.is_dir():
        return

    logger.debug("Copying test folder")
    dest_dir = workspace_dir / WORKSPACE_TEST_DIR
    dest_dir.mkdir(parents=True, exist_ok=True)

    copy_contents(test_dir, dest_dir)

    utils_dir = project_root / SMOKE_DIRECTORY / SMOKE_UTILS_DIRECTORY
    if utils_dir.is_dir():
        copy_contents(utils_dir, dest_dir)


def ensure_devcontainers_cli(env: dict[str, str]) -> None:
    """Ensure @devcontainers/cli is installed globally via npm."""

    logger.debug("Installing @devcontainers/cli")
    npm = shutil.which("npm")
    if not npm:
        logger.error("npm is required but was not found on PATH.")
        raise ActionBuildError("npm is required but was not found on PATH.")

    run([npm, "install", "-g", "@devcontainers/cli"], env=env)


def devcontainer_up(workspace_dir: Path, template_id: str, env: dict[str, str]) -> None:
    """Start the dev container for the given workspace."""

    logger.debug("Building Dev Container")
    id_label = f"{SMOKE_LABEL}={template_id}"
    devcontainer = shutil.which("devcontainer") or "devcontainer"

    dev_container_execution_status = run(
        [
            devcontainer,
            "up",
            "--id-label",
            id_label,
            "--workspace-folder",
            str(workspace_dir),
        ],
        env=env,
    )
    if not dev_container_execution_status:
        logger.error("Container failed to start")
        raise ActionBuildError("Container failed to start")

    logger.debug("Container started")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build Dev Container from template with options configured."
    )
    parser.add_argument(
        "action",
        help="Action to perform (build, test)",
        choices=["build", "test"],
    )
    parser.add_argument(
        "template_id",
        help="Template identifier (directory under src/)",
    )
    parser.add_argument(
        "-t",
        "--tmpdir",
        help="Optional temp directory (defaults to system temp dir)",
        default=None,
    )
    return parser.parse_args()


def cleanup_docker_containers(template_id: str) -> None:
    container_ids = run(
        ["docker", "ps", "-a", "-q", "--filter", f"label={SMOKE_LABEL}={template_id}"]
    )
    if not container_ids:
        logger.debug(f"No containers found with label {SMOKE_LABEL}={template_id}")
        return
    container_id_list = container_ids.splitlines()

    logger.debug(f"Removing containers: {' '.join(container_id_list)}")
    removed_ids_status = run(["docker", "rm", "-f", *container_id_list])
    logger.debug(f"Removed containers execution status: {removed_ids_status}")


def exec_build_action(
    workspace_root_dir: Path, template_id: str, env: dict[str, str]
) -> None:
    workspace_dir = prepare_workspace(workspace_root_dir, template_id)
    copy_test_directory(workspace_root_dir, template_id, workspace_dir)
    ensure_devcontainers_cli(env)
    devcontainer_up(workspace_dir, template_id, env)

    return workspace_dir


def exec_test_action(workspace_dir: str, template_id: str) -> None:
    devcontainer = shutil.which("devcontainer") or "devcontainer"

    cmd = [
        devcontainer,
        "exec",
        "--workspace-folder",
        workspace_dir,
        "--id-label",
        f"{SMOKE_LABEL}={template_id}",
        "/bin/sh",
        "-c",
        f"if [ -f {SMOKE_DIRECTORY}/{SMOKE_FILE} ]; then chmod +x {SMOKE_DIRECTORY}/{SMOKE_FILE} && {SMOKE_DIRECTORY}/{SMOKE_FILE}; else echo 'No tests to run'; fi",
    ]

    logger.debug(f"Running: {' '.join(cmd)}")
    try:
        result = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
        )
        output = result.stdout.strip() if result.stdout else ""
        if output:
            print(output)

    except subprocess.CalledProcessError as e:
        logger.error("Tests failed inside the Dev Container")
        logger.error(f"Exit code: {e.returncode}")
        if e.stdout:
            logger.error("STDOUT:")
            logger.error(e.stdout)
        if e.stderr:
            logger.error("STDERR:")
            logger.error(e.stderr)
        raise ActionBuildError(f"Tests failed inside the Dev Container with exit code {e.returncode}")
    except FileNotFoundError:
        logger.error(f"Command not found: {cmd[0]}")
        raise ActionBuildError(f"Command not found: {cmd[0]}")

    cleanup_docker_containers(template_id)

    logger.debug("Cleaning up workspace directory")
    shutil.rmtree(workspace_dir, ignore_errors=True)

    logger.debug("Test completed")


def start_action(action: str, template_id: str, tmpdir: Optional[str] = None) -> None:
    """Return the action definition for the given action."""
    if action == "build":
        logger.debug(f"Building template: {template_id}")
        workspace_root_dir = Path.cwd()
        env = os.environ.copy()
        env["DOCKER_BUILDKIT"] = "1"

        workspace_dir = exec_build_action(workspace_root_dir, template_id, env)

        gha_output = os.getenv("GITHUB_OUTPUT")
        if gha_output:
            try:
                logger.debug(f"Writing workspace path to GITHUB_OUTPUT: {gha_output}")
                with open(gha_output, "a", encoding="utf-8") as f:
                    f.write(f"workspace={workspace_dir}\n")
            except Exception:
                logger.exception(f"Error writing to GITHUB_OUTPUT: {gha_output}")
                raise ActionBuildError(f"Error writing to GITHUB_OUTPUT: {gha_output}")
        else:
            logger.debug("GITHUB_OUTPUT not set")
            print(workspace_dir)

    if action == "test":
        logger.debug(f"Testing template: {template_id}")
        if not tmpdir:
            logger.error("The --tmpdir argument is required for 'test' action")
            raise ActionBuildError(
                "The --tmpdir argument is required for 'test' action"
            )
        workspace_dir = tmpdir
        exec_test_action(workspace_dir, template_id)


def main() -> None:
    args = parse_args()
    logger.debug(f"Args: {args}")
    try:
        action = args.action
        template_id = args.template_id
        tmpdir = args.tmpdir
        start_action(action, template_id, tmpdir)
    except ActionBuildError:
        logger.exception("Action failed")
        exit(1)
    except Exception:
        logger.exception("Unhandled error")
        exit(1)


if __name__ == "__main__":
    main()
