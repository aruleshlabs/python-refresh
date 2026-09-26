import logging

import pytest

from plant.errors import InvalidCountError


def test_new_machine_is_idle(machine):
    assert machine.state == "IDLE"
    assert machine.count == 0


def test_produce_adds_count(running_machine):
    running_machine.produce(90)
    assert running_machine.count == 90
    assert running_machine.performance(1) == pytest.approx(0.9)


def test_produce_when_idle_raises(machine):
    with pytest.raises(RuntimeError, match="not running"):
        machine.produce(5)


@pytest.mark.parametrize("bad", [-5, "abc", 2.5, True])
def test_produce_rejects_bad_counts(running_machine, bad):
    with pytest.raises(InvalidCountError):
        running_machine.produce(bad)


def test_stop_records_reason_and_logs_warning(running_machine, caplog):
    with caplog.at_level(logging.WARNING):
        running_machine.stop("Material shortage")
    assert running_machine.state == "STOP"
    assert running_machine.downtime_log[0][1] == "Material shortage"
    assert "Material shortage" in caplog.text
