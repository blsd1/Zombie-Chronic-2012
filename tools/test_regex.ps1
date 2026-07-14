$dir = "c:\Users\filip\Documents\GitHub\Epiczone-Zombie-Refurbished\Sub Plugins\Human Plugins"
$files = Get-ChildItem -Path $dir -Filter "*.sma" -Recurse

$pattern = '(?s)(engfunc\s*\(EngFunc_MessageBegin|message_begin\)\s*\([^,]+,\s*(g_MsgCurWeapon|get_user_msgid\("CurWeapon"\)).*?message_end\(\);?)'

foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f.FullName)
    if ($content -match "zp_set_user_infinite_ammo" -and $content -match "CurWeapon" -and $content -notmatch "Fix_HUD_Ammo_Task") {
        $mc = [regex]::Matches($content, $pattern)
        if ($mc.Count -gt 0) {
            Write-Host "Match found in $($f.Name)"
        } else {
            Write-Host "No match in $($f.Name)"
        }
    }
}
