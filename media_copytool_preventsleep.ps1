# Get all error-outputs in English:
[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'

# DEFINITION: For button-emulation:
$MyShell = New-Object -ComObject "Wscript.Shell"

while($true){
    $MyShell.sendkeys("{F15}")
    Start-Sleep -Seconds 150
}
