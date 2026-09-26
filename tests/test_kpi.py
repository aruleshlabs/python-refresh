import pytest

from plant import kpi


def test_availability():
    assert kpi.availability(480, 48) == pytest.approx(0.9)


def test_availability_nothing_planned():
    assert kpi.availability(0, 10) == 0.0


def test_quality_zero_total():
    assert kpi.quality(0, 0) == 0.0


def test_oee():
    assert kpi.oee(0.9, 0.95, 0.98) == pytest.approx(0.8379)


@pytest.mark.parametrize("planned, down, expected", [
    (480, 0, 1.0),
    (480, 480, 0.0),
    (480, 120, 0.75),
])
def test_availability_cases(planned, down, expected):
    assert kpi.availability(planned, down) == pytest.approx(expected)


def test_shift_stats():
    assert kpi.shift_stats([120, 135, 98]) == (353, 135, 98)
