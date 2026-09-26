"""Inheritance + polymorphism + retry pattern (Lesson 1)."""
import logging
import time

from .errors import PLCConnectionError

log = logging.getLogger(__name__)


class PLC:
    def __init__(self, ip):
        self.ip = ip

    def read(self, tag):
        raise NotImplementedError  # every child class must provide this


class SiemensPLC(PLC):
    def read(self, tag):
        return f"S7 read {tag} from {self.ip}"


class MitsubishiPLC(PLC):
    def read(self, tag):
        return f"SLMP read {tag} from {self.ip}"


def read_with_retry(read_fn, tag, retries=3, delay=0.5):
    """Call read_fn(tag); retry on PLCConnectionError, then give up."""
    for attempt in range(1, retries + 1):
        try:
            return read_fn(tag)
        except PLCConnectionError as e:
            log.warning("Attempt %d/%d failed: %s", attempt, retries, e)
            time.sleep(delay)
    raise PLCConnectionError(f"Gave up on {tag} after {retries} tries")
