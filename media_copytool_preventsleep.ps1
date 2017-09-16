# Get all error-outputs in English:
[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'

# DEFINITION: For button-emulation:
$myShell = New-Object -com "Wscript.Shell"

while($true){
    $myShell.sendkeys("{F15}")
    Start-Sleep -Seconds 150
}
