"""Custom exceptions (Lesson 1: exceptions)."""


class PLCConnectionError(Exception):
    """PLC not reachable."""


class InvalidCountError(ValueError):
    """Production count is negative or not an integer."""
