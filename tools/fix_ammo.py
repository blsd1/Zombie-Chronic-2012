import os
import re

directory = r"c:\Users\filip\Documents\GitHub\Epiczone-Zombie-Refurbished\Sub Plugins\Human Plugins"

# Regex to find the CurWeapon message block
# It looks something like:
# message_begin(MSG_ONE..., g_MsgCurWeapon, ...)
# write_byte(...)
# write_byte(...)
# write_byte(...)
# message_end()
pattern = re.compile(
    r'(?:engfunc\(EngFunc_MessageBegin|message_begin\)\s*\([^,]+,\s*(?:g_MsgCurWeapon|get_user_msgid\("CurWeapon"\)).*?message_end\(\);?)',
    re.DOTALL
)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Find if it has zp_set_user_infinite_ammo
    if "zp_set_user_infinite_ammo" not in content or "CurWeapon" not in content:
        return

    # Check if we already patched it
    if "Fix_HUD_Ammo_Task" in content:
        return

    original = content
    
    # We will replace the immediate CurWeapon block with a set_task
    # But wait! We need the clip amount and CSW_ID.
    # The CurWeapon block typically has:
    # write_byte(1)
    # write_byte(CSW_AK47)
    # write_byte(30)
    # We can parse the parameters if they are static or global, but it's simpler to just
    # read the player's current weapon and clip in the task.
    # So we can replace the ENTIRE block with:
    # set_task(0.1, "Fix_HUD_Ammo_Task", id)
    # and then inject the task function at the end of the file.

    def replacer(match):
        return "set_task(0.1, \"Fix_HUD_Ammo_Task\", id)"

    content, num_subs = pattern.subn(replacer, content)

    if num_subs > 0:
        # Append the global task function to the end of the file
        task_func = """
public Fix_HUD_Ammo_Task(id)
{
\tif(!is_user_alive(id)) 
\t\treturn;
\t
\tnew clip, ammo, wep = get_user_weapon(id, clip, ammo);
\tif(wep <= 0)
\t\treturn;
\t\t
\tmessage_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id)
\twrite_byte(1)
\twrite_byte(wep)
\twrite_byte(clip)
\tmessage_end()
}
"""
        content += task_func

        print(f"Patched {num_subs} CurWeapon blocks in {os.path.basename(filepath)}")
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

for root, dirs, files in os.walk(directory):
    for file in files:
        if file.endswith('.sma'):
            process_file(os.path.join(root, file))
