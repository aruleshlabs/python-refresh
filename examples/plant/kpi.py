"""Production KPI functions (Lesson 1: functions)."""


def availability(planned_min, downtime_min):
    """Run time / planned time. Returns 0.0 if nothing was planned."""
    if planned_min <= 0:
        return 0.0
    return (planned_min - downtime_min) / planned_min


def quality(good, total):
    """Good parts / total parts. Returns 0.0 if nothing was produced."""
    if total <= 0:
        return 0.0
    return good / total


def oee(availability, performance, quality=1.0):
    """OEE = Availability x Performance x Quality, as a fraction (0 to 1)."""
    return availability * performance * quality


def shift_stats(counts):
    """Return (total, best hour, worst hour) for a list of hourly counts."""
    return sum(counts), max(counts), min(counts)


if __name__ == "__main__":
    a = availability(480, 45)
    q = quality(950, 1000)
    print(f"A={a:.3f}  Q={q:.3f}  OEE={oee(a, 0.92, q):.1%}")
