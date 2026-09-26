"""Run from the examples folder:  python main.py"""
import logging

from logger_setup import setup_logging
from plant import kpi
from plant.errors import InvalidCountError, PLCConnectionError
from plant.machine import Machine
from plant.plc import MitsubishiPLC, SiemensPLC, read_with_retry

setup_logging(level="INFO")
log = logging.getLogger(__name__)


def flaky_read(tag, _calls=[0]):  # deliberately fails twice (demo only)
    _calls[0] += 1
    if _calls[0] < 3:
        raise PLCConnectionError("PLC offline")
    return 42


def main():
    m1 = Machine("M1", ideal_rate=100)
    m1.start()
    m1.produce(90)
    for bad in (-5, "abc"):
        try:
            m1.produce(bad)
        except InvalidCountError:
            log.exception("Rejected count")
    m1.stop("Material shortage")
    log.info(m1.report())

    a = kpi.availability(480, 45)
    q = kpi.quality(950, 1000)
    log.info("OEE = %.1f%%", kpi.oee(a, m1.performance(1), q) * 100)

    for plc in (SiemensPLC("192.168.0.1"), MitsubishiPLC("192.168.0.2")):
        log.info(plc.read("D100"))

    log.info("Value after retries: %s", read_with_retry(flaky_read, "DB10.DBW0", delay=0.1))


if __name__ == "__main__":
    main()
