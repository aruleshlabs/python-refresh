# Lesson 02 — venv, pip, requirements.txt, logging

All commands are for Windows PowerShell.

## 1. venv (virtual environment)

- **Problem:** every project shares one global Python, so project A needs `pandas 1.5` while project B needs `pandas 2.2`, and they break each other.
- **Fix:** each project gets its own private Python + libraries in `.venv`.

```powershell
python -m venv .venv  # create (once per project)
.\.venv\Scripts\Activate.ps1  # activate (every new terminal)
python -c "import sys; print(sys.prefix)"  # should end with \.venv
deactivate
```

If activation fails with *"running scripts is disabled"*, run this once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Rules:

- One `.venv` per project, inside the project folder.
- Never commit `.venv` (it is in `.gitignore`); it can always be recreated.
- VS Code: `Ctrl+Shift+P` → *Python: Select Interpreter* → `.venv`.
- A broken venv? Delete the folder and recreate it.

## 2. pip

```powershell
pip install python-snap7  # latest
pip install pandas==2.2.2  # exact version
pip install "fastapi>=0.110,<1.0"  # range
pip install -U pandas  # upgrade
pip uninstall pandas
pip list
pip show python-snap7
python -m pip install --upgrade pip  # safest form: python -m pip
```

Offline install (factories without internet):

```powershell
pip download -r requirements.txt -d wheels\  # PC with internet
pip install --no-index --find-links wheels\ -r requirements.txt  # offline PC
```

## 3. requirements.txt

```powershell
pip freeze > requirements.txt  # save exact versions
pip install -r requirements.txt  # recreate anywhere
```

- Pin exact versions (`==`) for anything delivered to clients.
- Keep dev-only tools in `requirements-dev.txt` (this repo does).

**New-project routine:**

```powershell
mkdir myproject; cd myproject
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install <what you need>
pip freeze > requirements.txt
```

## 4. logging

`print()` has no timestamp, no severity, can't be switched off, and vanishes when the app runs as a service. At a factory, the log file is how you find out *why it stopped at 3 AM*.

| Level | Use for |
|---|---|
| `DEBUG` | Detail while developing (raw PLC bytes) |
| `INFO` | Normal events (connected, 500 rows saved) |
| `WARNING` | Odd but still working (retrying) |
| `ERROR` | An operation failed (insert failed) |
| `CRITICAL` | App can't continue (config missing) |

```python
import logging
logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s")
log = logging.getLogger(__name__)  # one logger per module

log.info("Connected to PLC %s", "192.168.0.1")  # use %s args, not f-strings
try:
    1 / 0
except ZeroDivisionError:
    log.exception("KPI calculation failed")  # ERROR + full traceback
```

**Production setup:** console + rotating file. See [`examples/logger_setup.py`](../examples/logger_setup.py). Configure **once** in `main.py`; every other module only does `log = logging.getLogger(__name__)`. For one file per day use `TimedRotatingFileHandler(..., when="midnight")`.
