"""Module testing various kdr for the bar_percent function."""
KDR = [
    0.0, 0.2, 0.5, 1.0,
    1.2, 2.0, 3.9, 888,
]

def bar_percent(ratio):
    """Will convert kd ratio into percentage"""
    if ratio <= 1:
        return ratio / 2
    return 1 - 1/(ratio*2)

for r in KDR:
    PERCENT = bar_percent(r)
    PERCENT_DECIMAL = int(1000 * PERCENT) / 10 # Displays float out of 100 with 1 decimal
    print(r, "kdr =>", PERCENT_DECIMAL, "%")