# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
import logging

import pytest

LOGGER = logging.getLogger(__name__)


@pytest.mark.parametrize(
    "name,command",
    [
        (
            "print version",
            "import torch;print(torch.__version__)",
        ),
        (
            "Create tensor with random values",
            "import torch;x = torch.rand(5, 3);print(x)",   
        ),
    ],
)
def test_pytorch(container, name, command):
    """Basic pytorch tests"""
    LOGGER.info(f"Testing pytorch: {name} ...")
    c = container.run(tty=True, command=["start.sh", "conda", "run", "-n", "pytorch", "python", "-c", command])
    rv = c.wait(timeout=30)
    assert rv == 0 or rv["StatusCode"] == 0, f"Command {command} failed"
    logs = c.logs(stdout=True).decode("utf-8")
    LOGGER.debug(logs)


def _run_as_jovyan(c, *command):
    rc, out = c.exec_run(list(command), user="jovyan")
    return rc, out.decode()


def _start_notebook(container, http_client, nb_prefix, volume):
    """Start the image with its default command on the home volume and wait until start-custom.sh has finished,
    which is when it starts the server."""
    c = container.run(volumes={volume.name: {"bind": "/home/jovyan", "mode": "rw"}})
    http_client.get(f"http://localhost:8888{nb_prefix}/").raise_for_status()
    errors = [line for line in c.logs().decode().splitlines() if line.startswith("ERROR")]
    assert not errors, f"start-custom.sh reported errors: {errors}"
    return c


def _envs_dirs(c):
    rc, out = _run_as_jovyan(c, "conda", "config", "--show", "envs_dirs")
    assert rc == 0, out
    dirs = [line[len("  - "):] for line in out.splitlines() if line.startswith("  - ")]
    assert len(dirs) == len(set(dirs)), f"envs_dirs lists a directory twice: {dirs}"
    return dirs


def _stop_notebook(container):
    container.remove()
    container.container = None


def test_pytorch_env_after_start(container, docker_client, http_client, nb_prefix):
    """After start-custom.sh has run, conda lists the image's pytorch env and the envs saved in ~/envs, and an env in
    ~/envs takes precedence over the image's env of the same name. Covers the first start with an empty home volume
    and a restart with the same volume."""
    volume = docker_client.volumes.create()
    try:
        c = _start_notebook(container, http_client, nb_prefix, volume)
        dirs = _envs_dirs(c)
        assert "/home/jovyan/.conda/envs" in dirs and "/opt/conda/envs" in dirs, f"first start: envs_dirs is {dirs}"
        rc, out = _run_as_jovyan(c, "conda", "env", "list")
        assert rc == 0 and "/opt/conda/envs/pytorch" in out, f"first start: pytorch env is not listed:\n{out}"
        rc, out = _run_as_jovyan(c, "conda", "run", "-n", "pytorch", "python", "-c", "import torch")
        assert rc == 0, f"first start: import torch in the pytorch env failed:\n{out}"

        # an environment saved on the persistent volume with the same name as the image's environment
        rc, out = _run_as_jovyan(c, "conda", "create", "-y", "-q", "--offline", "-p", "/home/jovyan/envs/pytorch")
        assert rc == 0, f"could not create /home/jovyan/envs/pytorch:\n{out}"
        _stop_notebook(container)

        c = _start_notebook(container, http_client, nb_prefix, volume)
        dirs = _envs_dirs(c)
        assert {"/home/jovyan/.conda/envs", "/home/jovyan/envs", "/opt/conda/envs"} <= set(dirs), \
            f"second start: envs_dirs is {dirs}"
        assert dirs.index("/home/jovyan/envs") < dirs.index("/opt/conda/envs"), \
            f"second start: ~/envs must come before /opt/conda/envs: {dirs}"
        rc, out = _run_as_jovyan(c, "conda", "env", "list")
        assert rc == 0 and "/home/jovyan/envs/pytorch" in out and "/opt/conda/envs/pytorch" in out, \
            f"second start: both pytorch envs should be listed:\n{out}"
        rc, out = _run_as_jovyan(c, "conda", "run", "-n", "pytorch", "printenv", "CONDA_PREFIX")
        assert rc == 0 and out.strip().splitlines()[-1] == "/home/jovyan/envs/pytorch", \
            f"second start: `-n pytorch` should resolve to the env in ~/envs:\n{out}"
        rc, out = _run_as_jovyan(c, "conda", "run", "-p", "/opt/conda/envs/pytorch", "python", "-c", "import torch")
        assert rc == 0, f"second start: import torch in the image's pytorch env failed:\n{out}"
    finally:
        _stop_notebook(container)
        volume.remove(force=True)
