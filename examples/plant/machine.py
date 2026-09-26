"""Machine model (Lesson 1: classes) with logging (Lesson 2)."""
import logging
from datetime import datetime

from .errors import InvalidCountError

log = logging.getLogger(__name__)


class Machine:
    plant = "C-101"  # class attribute, shared by all machines

    def __init__(self, name, ideal_rate):
        self.name = name
        self.ideal_rate = ideal_rate  # parts per hour
        self.count = 0
        self.state = "IDLE"
        self.downtime_log = []

    def start(self):
        self.state = "RUN"
        log.info("%s started", self.name)

    def stop(self, reason):
        self.state = "STOP"
        self.downtime_log.append((datetime.now(), reason))
        log.warning("%s stopped: %s", self.name, reason)

    def produce(self, n=1):
        if not isinstance(n, int) or isinstance(n, bool) or n < 0:
            raise InvalidCountError(f"{self.name}: invalid count {n!r}")
        if self.state != "RUN":
            raise RuntimeError(f"{self.name} is not running")
        self.count += n
        log.debug("%s +%d -> %d", self.name, n, self.count)

    def performance(self, hours):
        if hours <= 0:
            return 0.0
        return self.count / (self.ideal_rate * hours)

    def report(self):
        return (f"{self.name}: count={self.count}, state={self.state}, "
                f"stops={len(self.downtime_log)}")

    def __repr__(self):
        return f"Machine({self.name}, {self.state}, count={self.count})"
