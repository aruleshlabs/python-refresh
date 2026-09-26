# Lesson 03 — pytest Basics

**Why test?** When you change the OEE formula or the PLC retry logic, you want to know in
1 second that nothing else broke. At a factory, a bug found by a test costs you nothing; a bug
found on the line costs a production day.

## 1. How pytest finds tests

- Files named `test_*.py` (or `*_test.py`)
- Functions named `test_*`
- Classes named `Test*` (optional; plain functions are fine)

```python
# tests/test_kpi.py
from plant import kpi

def test_quality_zero_total():
    assert kpi.quality(0, 0) == 0.0     # plain assert, no special methods
```

If the assert fails, pytest shows both sides of the comparison. No `print` needed.

## 2. Running tests

```powershell
pytest                     # run everything
pytest -v                  # verbose: one line per test
pytest tests/test_kpi.py   # one file
pytest tests/test_kpi.py::test_oee   # one test
pytest -k "retry"          # tests whose name contains "retry"
pytest -x                  # stop at first failure
pytest --lf                # re-run only last failures
pytest -s                  # show print() output
```

Project config lives in [`pytest.ini`](../pytest.ini):

```ini
[pytest]
testpaths = tests
pythonpath = examples      # so tests can "import plant" without sys.path hacks
addopts = -ra              # summary of skipped/failed at the end
```

## 3. Floats: `pytest.approx`

`0.9 * 0.95 * 0.98 == 0.8379` is **False** in floating point. Always compare floats with approx:

```python
assert kpi.oee(0.9, 0.95, 0.98) == pytest.approx(0.8379)
```

## 4. Testing errors: `pytest.raises`

```python
def test_produce_when_idle_raises(machine):
    with pytest.raises(RuntimeError, match="not running"):   # match = regex on message
        machine.produce(5)
```

The test **fails** if the error is *not* raised.

## 5. Parametrize: one test, many inputs

```python
@pytest.mark.parametrize("planned, down, expected", [
    (480, 0, 1.0),
    (480, 480, 0.0),
    (480, 120, 0.75),
])
def test_availability_cases(planned, down, expected):
    assert kpi.availability(planned, down) == pytest.approx(expected)
```

Each row shows up as its own test: `test_availability_cases[480-120-0.75]`.

## 6. Fixtures: reusable setup

A fixture builds something a test needs. Tests ask for it **by argument name**.
Put shared fixtures in `tests/conftest.py`; pytest loads it automatically.

```python
# tests/conftest.py
@pytest.fixture
def machine():
    return Machine("M1", ideal_rate=100)     # fresh object for every test

@pytest.fixture
def running_machine(machine):                # fixtures can use fixtures
    machine.start()
    return machine
```

```python
def test_produce_adds_count(running_machine):
    running_machine.produce(90)
    assert running_machine.count == 90
```

Fixtures with cleanup use `yield`: code after `yield` runs after the test, even if it failed
(perfect for closing DB/PLC connections):

```python
@pytest.fixture
def db():
    conn = sqlite3.connect(":memory:")
    yield conn
    conn.close()
```

## 7. Built-in fixtures you will use

| Fixture | What it gives you |
|---|---|
| `tmp_path` | A fresh temporary folder (`pathlib.Path`) for file tests |
| `monkeypatch` | Temporarily replace functions/attributes/env vars |
| `caplog` | Captures log messages so you can assert on them |
| `capsys` | Captures `print()` output |

**monkeypatch:** make retry tests instant by replacing `time.sleep`:

```python
@pytest.fixture(autouse=True)            # autouse = applies to every test in the file
def no_sleep(monkeypatch):
    monkeypatch.setattr(plc.time, "sleep", lambda s: None)
```

**caplog:** check that a warning was logged:

```python
def test_stop_logs_warning(running_machine, caplog):
    with caplog.at_level(logging.WARNING):
        running_machine.stop("Material shortage")
    assert "Material shortage" in caplog.text
```

## 8. Fakes: testing PLC code without a PLC

Pass a fake function/object instead of the real PLC. This is how the whole rebuild is tested
without hardware:

```python
def test_retry_succeeds_on_third_try():
    calls = []
    def flaky(tag):                       # fake PLC: fails twice, then answers
        calls.append(tag)
        if len(calls) < 3:
            raise PLCConnectionError("offline")
        return 42

    assert read_with_retry(flaky, "DB10.DBW0") == 42
    assert len(calls) == 3
```

## Rules of thumb

- One behaviour per test; name it after the behaviour (`test_produce_when_idle_raises`).
- Arrange → Act → Assert.
- Test edge cases: zero, negative, empty, wrong type, connection lost.
- Tests must not depend on each other or on run order.
- Run `pytest` before every commit.

All examples above are real and live in [`tests/`](../tests); run `pytest -v`.
