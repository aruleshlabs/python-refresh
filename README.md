# Python Refresh

A fast Python refresher with industrial examples (machines, PLCs, OEE). It is Phase 0 of my rebuild journey: relearn the fundamentals, then rebuild industrial automation, AI and RPA projects as reusable templates.

## Lessons

| # | Topic | Notes |
|---|-------|-------|
| 01 | Functions, classes, modules, exceptions | [lessons/01](lessons/01_functions_classes_modules_exceptions.md) |
| 02 | venv, pip, requirements.txt, logging | [lessons/02](lessons/02_venv_pip_requirements_logging.md) |
| 03 | pytest basics | [lessons/03](lessons/03_pytest_basics.md) |
| 04 | Git basics + GitHub profile | [lessons/04](lessons/04_git_basics.md) |
| 05 | SQL: schema design, keys, indexes | [lessons/05](lessons/05_sql_schema_keys_indexes.md) |
| 06 | SQL: joins, GROUP BY, time buckets (hourly/shift) | [lessons/06](lessons/06_sql_joins_groupby_time_buckets.md) |

## Project layout

```text
python-refresh/
├── lessons/            # notes for each topic
├── examples/           # runnable reference code
│   ├── main.py         # demo: machine, OEE, PLC polymorphism, retry, logging
│   ├── logger_setup.py # console + rotating file logging
│   └── plant/          # package: kpi, machine, plc, errors
├── sql/                # MySQL: factory schema, seed data, queries
├── tests/              # pytest: fixtures, parametrize, monkeypatch, caplog
├── pytest.ini
├── requirements.txt
└── requirements-dev.txt
```

## Run it (Windows PowerShell)

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt

cd examples; python main.py; cd ..  # writes logs\app.log
pytest -v
```

