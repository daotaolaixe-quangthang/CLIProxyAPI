Dim oShell, oFSO, scriptDir, exePath, configPath

Set oShell = CreateObject("Wscript.Shell")
Set oFSO   = CreateObject("Scripting.FileSystemObject")

' Lay thu muc chua file .vbs nay (tuong doi, chay duoc moi noi)
scriptDir  = oFSO.GetParentFolderName(WScript.ScriptFullName)
exePath    = scriptDir & "\cli-proxy-api.exe"

' Lay duong dan config theo bien moi truong USERPROFILE (chuan moi may Windows)
configPath = oShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\.cli-proxy-api\config.yaml"

oShell.Run """" & exePath & """ --config """ & configPath & """", 0, False

Set oFSO   = Nothing
Set oShell = Nothing
