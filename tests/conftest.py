"""Shared fixtures: pytest loads this file automatically for every test."""
import pytest

from plant.machine import Machine


@pytest.fixture
def machine():
    """A fresh machine for each test (no state leaks between tests)."""
    return Machine("M1", ideal_rate=100)


@pytest.fixture
def running_machine(machine):
    """Fixtures can use other fixtures."""
    machine.start()
    return machine
