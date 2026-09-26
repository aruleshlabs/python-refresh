"""One-time logging setup: console + rotating file (Lesson 2)."""
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path


def setup_logging(level="INFO", log_dir="logs", name="app"):
    Path(log_dir).mkdir(exist_ok=True)
    fmt = logging.Formatter("%(asctime)s | %(levelname)-8s | %(name)s | %(message)s")

    file_h = RotatingFileHandler(f"{log_dir}/{name}.log",
                                 maxBytes=1_000_000, backupCount=5, encoding="utf-8")
    file_h.setFormatter(fmt)
    file_h.setLevel(logging.DEBUG)  # file gets everything

    console_h = logging.StreamHandler()
    console_h.setFormatter(fmt)
    console_h.setLevel(level)  # console shows less

    root = logging.getLogger()
    root.setLevel(logging.DEBUG)
    root.handlers.clear()  # avoid duplicate lines if called twice
    root.addHandler(file_h)
    root.addHandler(console_h)
