"""Module read and parse the data.json file."""
import json

with open('./data.json', encoding='utf-8') as f:
    data = json.load(f)

# Example of Display
# Skirmish: 41 / 84 ( 43 left )
#     Red:   156 VP
#     Green: 184 VP
#     Blue:  152 VP
# 1st Victory Ratio: 74 % (Green)
#     Difference: 28 VP (+30 VPd req.)
#     Difficulty: 34%/66%
# 2nd Victory Ratio: 40 % (Red)
#     Difference: 4 VP (+41 VPd req.)
#     Difficulty: 48%/52%
# 3rd Victory Ratio: 35 % (Blue)

MATCH = 2
red = data[MATCH]['victory_points']['red']
green = data[MATCH]['victory_points']['green']
blue = data[MATCH]['victory_points']['blue']
score = [red, green, blue]

# Alternative?
# score = []
# for i in data["victory_points"]:
#    score.append(data["victory_points"][i])

score.sort()
frst = score.pop()
scnd = score.pop()
thrd = score.pop()

SKIRMISH_TOTAL = 84
skirmish_done = int((frst+scnd+thrd) / (3+4+5))
skirmish_remaining = SKIRMISH_TOTAL - skirmish_done
vp_remaining = skirmish_remaining * 2

print("Skirmish:", skirmish_done, "/", SKIRMISH_TOTAL,
      "(", skirmish_remaining, "left )")
print("Red:", red, "VP")
print("Green:", green, "VP")
print("Blue:", blue, "VP")

vp_max = skirmish_done * 5
vp_min = skirmish_done * 3

frst_victory_ratio = int(10000 * (frst-vp_min) / (vp_max-vp_min)) / 100
frst_vp_difference = frst - scnd
frst_tie = int((vp_remaining-frst_vp_difference) / 2)
frst_secure = frst_tie + 1
frst_difficulty = int(10000*frst_secure/vp_remaining) / 100

print()
print("1st Victory Ratio:", frst_victory_ratio, "%")
print("VP difference with 2nd:", frst_vp_difference)
print("Will require", frst_tie, "VP for a tie, and one more to secure position")
print("Difficulty:", frst_difficulty, "%")

scnd_victory_ratio = int(10000 * (scnd-vp_min) / (vp_max-vp_min)) / 100
scnd_vp_difference = scnd - thrd
scnd_tie = int((vp_remaining-scnd_vp_difference) / 2)
scnd_secure = scnd_tie + 1
scnd_difficulty = int(10000*scnd_secure/vp_remaining) / 100

print()
print("2nd Victory Ratio:", scnd_victory_ratio, "%")
print("VP difference with 3rd:", scnd_vp_difference)
print("Will require", scnd_tie, "VP for a tie, and one more to secure position")
print("Difficulty:", scnd_difficulty, "%")

thrd_victory_ratio = int(10000 * (thrd-vp_min) / (vp_max-vp_min)) / 100
thrd_vp_difference = thrd - frst
thrd_tie = int((vp_remaining-thrd_vp_difference) / 2)
thrd_secure = thrd_tie + 1
thrd_difficulty = int(10000*thrd_secure/vp_remaining) / 100

print()
print("3rd Victory Ratio:", thrd_victory_ratio, "%")
print("VP difference with 1st:", thrd_vp_difference)
print("Will require more than", thrd_tie, "VP to catch up with 1st")
print("Difficulty:", thrd_difficulty, "%")
