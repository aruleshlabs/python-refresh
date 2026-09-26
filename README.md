# Python Refresh

A fast Python refresher with industrial examples (machines, PLCs, OEE).
It is Phase 0 of my rebuild journey: relearn the fundamentals, then rebuild
industrial automation, AI and RPA projects as reusable templates.

## Lessons

| # | Topic | Notes |
|---|-------|-------|
| 01 | Functions, classes, modules, exceptions | [lessons/01](lessons/01_functions_classes_modules_exceptions.md) |
| 02 | venv, pip, requirements.txt, logging | [lessons/02](lessons/02_venv_pip_requirements_logging.md) |

Exercises: [exercises/EXERCISES.md](exercises/EXERCISES.md)

## Project layout

```
python-refresh/
├── lessons/            # notes for each topic
├── examples/           # runnable reference code
│   ├── main.py         # demo: machine, OEE, PLC polymorphism, retry, logging
│   ├── logger_setup.py # console + rotating file logging
│   └── plant/          # package: kpi, machine, plc, errors
├── exercises/          # my practice work
├── tests/              # pytest tests for the examples
├── requirements.txt
└── requirements-dev.txt
```

## Run it (Windows PowerShell)

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt

cd examples; python main.py; cd ..     # writes logs\app.log
pytest -v
```

## Topics coming next

pytest basics · Git workflow · SQL on MySQL
