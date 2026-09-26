# Exercises

Write your answers in this folder (`exercises/`). Tick each box when it works.

## Lesson 01: Functions, Classes, Modules, Exceptions

- [ ] **1. Functions:** write `availability(planned_min, downtime_min)` and
      `quality(good, total)`; guard against division by zero (return `0.0`).
      Compute OEE for: 480 min planned, 45 min down, performance 0.92,
      950 good out of 1000.
- [ ] **2. Classes:** extend `Machine` with `stop(reason)`, which records
      `(time, reason)` in `downtime_log`, and `report()`, which prints name,
      count, state and number of stops.
- [ ] **3. Modules:** put `Machine` in `plant/machine.py` and the KPI functions
      in `plant/kpi.py`; import both in `main.py` and run it.
- [ ] **4. Exceptions:** create `InvalidCountError`; `produce(n)` must raise it
      if `n` is negative or not an int. Call it with `-5` and `"abc"` inside
      `try/except` and print friendly messages.
- [ ] **5. Bonus:** read a CSV of `machine,count` rows with the `csv` module,
      skip bad rows with `try/except ValueError`, and print the total per machine.
      Use [`sample_counts.csv`](sample_counts.csv).

## Lesson 02: venv, pip, requirements.txt, logging

- [ ] **1.** Create `.venv`, activate it, run `pip install pyyaml pytest`, then
      `pip freeze > requirements.txt`, and check the versions.
- [ ] **2.** Delete `.venv`, recreate it, run `pip install -r requirements.txt`,
      and confirm with `pip list`.
- [ ] **3.** Create `logger_setup.py` + `main.py`; run it and find `logs\app.log`.
- [ ] **4.** Add logging to `Machine`: `start()` logs INFO, a bad count uses
      `log.exception`, and `stop(reason)` logs WARNING.
- [ ] **5.** Set `maxBytes=500`, log 200 lines, and watch `app.log.1`…`app.log.5` appear.
- [ ] **6.** Set the console level to `WARNING` and confirm INFO goes only to the file.

Stuck? The reference solution for Lesson 01 is in [`../examples`](../examples);
try without it first.
