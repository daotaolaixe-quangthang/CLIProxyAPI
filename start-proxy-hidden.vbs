Dim oShell
Set oShell = CreateObject("Wscript.Shell")
oShell.Run "E:\CLIProxyAPI\cli-proxy-api.exe --config ""C:\Users\Admin\.cli-proxy-api\config.yaml""", 0, False
Set oShell = Nothing
