# Lesson 01 — Functions, Classes, Modules, Exceptions

Runnable versions of every example are in [`examples/`](../examples).

## 1. Functions

A function is a named, reusable block: inputs in, output out.

```python
def oee(availability, performance, quality=1.0):  # default value
    """Return OEE as a fraction (0 to 1)."""
    return availability * performance * quality

oee(0.9, 0.95)  # positional → 0.855
oee(quality=0.98, availability=0.9, performance=0.95)  # keyword, any order
```

```python
# Return several values (packed into a tuple) and unpack them
def shift_stats(counts):
    return sum(counts), max(counts), min(counts)
total, best, worst = shift_stats([120, 135, 98])

# *args = any positional arguments, **kwargs = any keyword arguments
def log(msg, *tags, **extra):
    print(msg, tags, extra)
log("Alarm", "M1", "HIGH", code=504)  # Alarm ('M1', 'HIGH') {'code': 504}

# Never use a mutable default like [] (it is shared between calls)
def add_alarm(a, history=None):
    if history is None:
        history = []
    history.append(a)
    return history

# lambda = tiny one-line function, often used as a sort key
machines = [("M1", 88), ("M2", 95), ("M3", 72)]
machines.sort(key=lambda m: m[1], reverse=True)
```

## 2. Classes

A class is a blueprint bundling **data** (attributes) and **behaviour** (methods). Each object made from it is an *instance*.

```python
class Machine:
    plant = "C-101"  # class attribute (shared)

    def __init__(self, name, ideal_rate):  # constructor
        self.name = name  # instance attributes
        self.ideal_rate = ideal_rate
        self.count = 0
        self.state = "IDLE"

    def start(self):
        self.state = "RUN"

    def produce(self, n=1):
        if self.state != "RUN":
            raise RuntimeError(f"{self.name} is not running")
        self.count += n

    def performance(self, hours):
        return self.count / (self.ideal_rate * hours)

    def __repr__(self):
        return f"Machine({self.name}, {self.state}, count={self.count})"
```

**Inheritance + polymorphism** is the exact pattern for the multi-protocol PLC connector (T1):

```python
class PLC:
    def __init__(self, ip):
        self.ip = ip
    def read(self, tag):
        raise NotImplementedError

class SiemensPLC(PLC):
    def read(self, tag):
        return f"S7 read {tag} from {self.ip}"

class MitsubishiPLC(PLC):
    def read(self, tag):
        return f"SLMP read {tag} from {self.ip}"

for plc in [SiemensPLC("192.168.0.1"), MitsubishiPLC("192.168.0.2")]:
    print(plc.read("D100"))  # same call, different behaviour
```

**Dataclass**, a shortcut for classes that mostly hold data:

```python
from dataclasses import dataclass

@dataclass
class Tag:
    name: str
    address: str
    dtype: str = "INT"
```

## 3. Modules

A **module** is a `.py` file; a **package** is a folder of modules with an `__init__.py`.

```text
examples/
├── main.py
└── plant/
    ├── __init__.py
    ├── machine.py
    └── kpi.py
```

```python
from plant.machine import Machine  # import one name
from plant import kpi  # import the module → kpi.oee(...)
import datetime as dt  # alias
```

The `__main__` guard: code under it runs only when the file is run directly, not when imported.

```python
if __name__ == "__main__":
    print(oee(0.9, 0.95, 0.98))
```

Standard-library modules you will use constantly: `os`, `pathlib`, `json`, `csv`, `datetime`, `time`, `logging`, `struct` (PLC bytes), `socket` (SLMP), `sqlite3`.

## 4. Exceptions

```python
try:
    value = int("12a")
except ValueError as e:  # specific error
    print("Bad number:", e)
else:
    print("Only if NO error")
finally:
    print("ALWAYS runs: close connections here")
```

Custom exceptions + retry with reconnect (goes straight into the T2 logger):

```python
class PLCConnectionError(Exception):
    """PLC not reachable."""

def read_with_retry(read_fn, tag, retries=3, delay=2):
    for attempt in range(1, retries + 1):
        try:
            return read_fn(tag)
        except PLCConnectionError as e:
            print(f"Attempt {attempt} failed: {e}")
            time.sleep(delay)
    raise PLCConnectionError(f"Gave up on {tag} after {retries} tries")
```

`with` closes resources automatically, even on error:

```python
with open("log.txt", "a") as f:
    f.write("shift started\n")
```

**Rules:** catch *specific* exceptions; never use a bare `except:`; only catch what you can actually handle.
