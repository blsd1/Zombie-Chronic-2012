import os
import re

dir = r"c:\Users\filip\Documents\GitHub\Epiczone-Zombie-Refurbished\Sub Plugins\Human Plugins"
pattern = re.compile(r'(engfunc\s*\(EngFunc_MessageBegin|message_begin\)\s*\([^,]+,\s*(?:g_MsgCurWeapon|get_user_msgid\("CurWeapon"\)).*?message_end\(\);?)', re.DOTALL)

for root, _, files in os.walk(dir):
    for f in files:
        if f.endswith(".sma"):
            path = os.path.join(root, f)
            with open(path, "r", encoding="utf-8", errors="ignore") as file:
                content = file.read()
            if "Fix_HUD_Ammo_Task" not in content and "zp_set_user_infinite_ammo" in content and "CurWeapon" in content:
                subs = pattern.findall(content)
                if subs:
                    print(f"Match found in {f}")
                else:
                    print(f"No match in {f}")
