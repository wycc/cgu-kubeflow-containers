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


def test_pytorch_env_after_start(container, docker_client, http_client, nb_prefix):
    """The image's pytorch env is usable after the notebook starts, both on the first start with an empty home
    volume and after a restart with the same volume."""
    volume = docker_client.volumes.create()
    try:
        for start in ("first", "second"):
            c = container.run(volumes={volume.name: {"bind": "/home/jovyan", "mode": "rw"}})
            # start-custom.sh configures conda before it starts the server
            http_client.get(f"http://localhost:8888{nb_prefix}/").raise_for_status()

            rc, out = c.exec_run(["conda", "env", "list"], user="jovyan")
            assert rc == 0 and b"/opt/conda/envs/pytorch" in out, \
                f"{start} start: pytorch env is not listed:\n{out.decode()}"
            rc, out = c.exec_run(["conda", "run", "-n", "pytorch", "python", "-c", "import torch"], user="jovyan")
            assert rc == 0, f"{start} start: import torch in the pytorch env failed:\n{out.decode()}"

            container.remove()
            container.container = None
    finally:
        container.remove()
        container.container = None
        volume.remove(force=True)
