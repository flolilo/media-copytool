# Get all error-outputs in English:
[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'

# DEFINITION: For button-emulation:
$MyShell = New-Object -ComObject "Wscript.Shell"

while($true){
    $MyShell.sendkeys("{F15}")
    # DEFINITION:/CREDIT: https://superuser.com/a/1023836/703240
    Start-Sleep -Seconds 90
}
