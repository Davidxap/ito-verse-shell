#!/usr/bin/env python3
"""Beta QA: set every option of the look one value at a time on the LIVE shell, and after each option ask Health
whether a new error appeared. Restores ito-style.json at the end (a backup is kept in /tmp/ito-sweep/).

    python3 scripts/qa/sweep-settings.py
"""
import json, subprocess, time, shutil, re, os
M = os.path.expanduser("~/.config/omarchy/bar/modules/bin/")
STYLE = os.path.expanduser("~/.config/omarchy/bar/modules/ito-style.json")
shutil.copy(STYLE, "/tmp/ito-sweep-style.backup.json")
def cfg(*a): subprocess.run([M + "ito-config"] + list(a), capture_output=True)
def errors():
    out = subprocess.run([M + "ito-health"], capture_output=True, text=True).stdout
    try: checks = json.loads(out)
    except ValueError: return {"health-json": 1}
    res = {}
    for c in checks:
        if c["status"] != "ok":
            if c.get("items"):
                for i in c["items"]: res[f"{c['id']}: {i['title']} {i['file']} :: {i['message'][:110]}"] = i["count"]
            else: res[f"{c['id']}: {c['detail'][:140]}"] = 1
    return res
marks = re.findall(r'key: "([\w-]+)"', open(os.path.expanduser("~/.config/omarchy/bar/modules/ItoMarks.js")).read())
SWEEP = [
 ("style", ["numerals","orbs","eyes","remina","uzumaki","dots","halo","flauros"]),
 ("mediaFx", ["blood","spiral","eyes","fog","static"]),
 ("valueStyle", ["percent","amount","number","off"]),
 ("valueLabels", ["false","true"]),
 ("workspaceCount", ["1","10","5"]),
 ("workspaceShow", ["used","count"]),
 ("barSize", ["52","40"]),
 ("barGap", ["airy","normal","tight"]),
 ("barRadius", ["square","soft","round"]),
 ("iconScale", ["0.8","0.5","0.62"]),
 ("vibrance", ["0.4","1.7","1"]),
 ("light", ["0","2","1"]),
 ("fxSpeed", ["0.4","2.5","1"]),
 ("fxStrength", ["0.4","2","1"]),
 ("popupSeconds", ["0","15","3"]),
 ("icon:awake", ["coffee","radio","flashlight"]),
 ("icon:night", ["moon","fog"]),
 ("icon:record", ["eye","tape"]),
 ("aiStyle", ["brain","hemispheres","neurons","eye","spiral"]),
 ("netIcon", ["auto","wifi","cable"]),
 ("accentSource", ["accent","color1","color4","ito"]),
 ("colorMode", ["ito","theme"]),
 ("fxWhen", ["always","hover"]),
 ("fxMark", ["auto","pulse","sway","none"]),
 ("fxSeal", ["auto","pulse","sway","none"]),
 ("fxVeins", ["auto","pulse","sway","none"]),
 ("fxTorn", ["true","false"]), ("fxFog", ["true","false"]), ("fxPlate", ["false","true"]), ("fxBorder", ["true","false"]),
 ("fxGrain", ["true","false"]), ("fxPills", ["true","false"]), ("fxBlood", ["true","false"]), ("fxWood", ["true","false"]),
 ("fxPaper", ["true","false"]), ("fxGlass", ["true","false"]), ("fxTone", ["true","false"]), ("fxCalm", ["true","false"]),
 ("barShadow", ["true","false"]), ("barFloat", ["true","false"]), ("tooltipBlood", ["true","false"]), ("motion", ["off","calm","lively"]),
]
seals = ["tomie","uzumaki","ito","silent","remina"]
SWEEP += [("seal", seals)]
decos = re.findall(r'key: "([\w-]+)", wide', open(os.path.expanduser("~/.config/omarchy/bar/modules/ItoMarks.js")).read())
SWEEP += [("sealDeco", decos)]
SWEEP += [("menuMark", ["uzumaki","tomie","remina","amigara","metatron","metatron-mini","halo","flauros","spiral"])]
base = errors()
print("baseline:", base, flush=True)
for key, vals in SWEEP:
    before = errors()
    for v in vals:
        cfg("set", key, v); time.sleep(1.4)
    after = errors()
    new = {k: c for k, c in after.items() if c > before.get(k, 0)}
    print(("FAIL " if new else "ok   ") + key + " " + ",".join(vals), flush=True)
    for k, c in new.items(): print("      ->", k, flush=True)
shutil.copy("/tmp/ito-sweep-style.backup.json", STYLE)
print("restored", flush=True)
