import pytest

from plant import plc
from plant.errors import PLCConnectionError
from plant.plc import MitsubishiPLC, SiemensPLC, read_with_retry


@pytest.fixture(autouse=True)
def no_sleep(monkeypatch):
    """Replace time.sleep so retry tests run instantly."""
    monkeypatch.setattr(plc.time, "sleep", lambda s: None)


def test_polymorphism():
    assert SiemensPLC("10.0.0.1").read("DB10.DBW0").startswith("S7")
    assert MitsubishiPLC("10.0.0.2").read("D100").startswith("SLMP")


def test_base_plc_read_not_implemented():
    with pytest.raises(NotImplementedError):
        plc.PLC("10.0.0.3").read("X")


def test_retry_succeeds_on_third_try():
    calls = []

    def flaky(tag):  # a fake PLC: fails twice, then answers
        calls.append(tag)
        if len(calls) < 3:
            raise PLCConnectionError("offline")
        return 42

    assert read_with_retry(flaky, "DB10.DBW0") == 42
    assert len(calls) == 3


def test_retry_gives_up():
    def dead(tag):
        raise PLCConnectionError("offline")

    with pytest.raises(PLCConnectionError, match="Gave up"):
        read_with_retry(dead, "DB10.DBW0", retries=2)
