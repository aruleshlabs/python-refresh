import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "examples"))

from plant import kpi  # noqa: E402
from plant.errors import InvalidCountError  # noqa: E402
from plant.machine import Machine  # noqa: E402


def test_availability():
    assert kpi.availability(480, 48) == pytest.approx(0.9)
    assert kpi.availability(0, 10) == 0.0


def test_quality_zero_total():
    assert kpi.quality(0, 0) == 0.0


def test_oee():
    assert kpi.oee(0.9, 0.95, 0.98) == pytest.approx(0.8379)


@pytest.mark.parametrize("bad", [-5, "abc", 2.5, True])
def test_produce_rejects_bad_counts(bad):
    m = Machine("M1", 100)
    m.start()
    with pytest.raises(InvalidCountError):
        m.produce(bad)
