$dir = "c:\Users\filip\Documents\GitHub\Epiczone-Zombie-Refurbished\Sub Plugins\Human Plugins"
$files = Get-ChildItem -Path $dir -Filter "*.sma" -Recurse

$pattern = '(?s)(?:engfunc\s*\(EngFunc_MessageBegin|message_begin)\s*\([^,]+,\s*(?:g_MsgCurWeapon|g_Msg_CurWeapon|get_user_msgid\("CurWeapon"\)).*?message_end\(\);?'

$replacement = 'set_task(0.1, "Fix_HUD_Ammo_Task", id)'

$appendedCode = @"

public Fix_HUD_Ammo_Task(id)
{
`tif(!is_user_alive(id)) return;
`tnew clip, ammo, wep = get_user_weapon(id, clip, ammo);
`tif(wep <= 0) return;
`tmessage_begin(MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), _, id);
`twrite_byte(1);
`twrite_byte(wep);
`twrite_byte(clip);
`tmessage_end();
}
"@

foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f.FullName)
    if ($content -match "zp_set_user_infinite_ammo" -and $content -match "CurWeapon" -and $content -notmatch "Fix_HUD_Ammo_Task") {
        $mc = [regex]::Matches($content, $pattern)
        if ($mc.Count -gt 0) {
            $newContent = [regex]::Replace($content, $pattern, $replacement)
            $newContent += $appendedCode
            [System.IO.File]::WriteAllText($f.FullName, $newContent)
            Write-Host "Patched $($f.Name)"
        }
    }
}
