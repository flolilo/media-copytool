#requires -version 3

<#
    .SYNOPSIS
        Copy (and verify) user-defined filetypes from A to B (and optionally C).

    .DESCRIPTION
        Uses Windows' Robocopy and Xcopy for file-copy, then uses PowerShell's Get-FileHash (SHA1) for verifying that files were copied without errors.

    .NOTES
        Version:        1.4
        Author:         Florian Dolzer
        Creation Date:  25.7.2017
        Legal stuff: This program is free software. It comes without any warranty, to the extent permitted by
        applicable law. Most of the script was written by myself (or heavily modified by me when searching for solutions
        on the WWW). However, some parts are copies or modifications of very genuine code - see
        the "CREDIT"-tags to find them.

    .PARAMETER fileToCheck
        String. Path to file of script that uses process-mode. 
    .PARAMETER fileModeEnable
        Integer. Value of 1 enables file-mode.
    .PARAMETER mode
        String.
    .PARAMETER userProcessCount
        Integer.
    .PARAMETER userProcess
        Array.
    .PARAMETER userCPUlimit
        Integer.
    .PARAMETER timeBase
        Integer.
    .PARAMETER counterMax
        Integer.
    .PARAMETER shutdown
        Integer.

    .INPUTS
        .\fertig.txt
    .OUTPUTS
        None.

    .EXAMPLE
        TODO: all of these.
#>
param(
    [string]$fileToCheck = "$PSScriptRoot\fertig.txt",
    [ValidateRange(0,1)][int]$fileModeEnable = 0,
    [ValidateSet("process","specify","cpu","none")][string]$mode = "specify", # process, CPU, none, specify
    [ValidateRange(-1,1)][int]$userProcessCount = -1,
    [array]$userProcess = @(),
    [ValidateRange(-1,99)][int]$userCPUlimit = -1,
    [ValidateRange(10,3000)][int]$timeBase = 300,
    [ValidateRange(1,100)][int]$counterMax = 10,
    [ValidateRange(-1,1)][int]$shutdown = -1
)

# For button-emulation:
$MyShell = New-Object -com "Wscript.Shell"

# DEFINITION: Get Average CPU-usage:
Function Get-ComputerStats(){
    [array]$cpu = @()
    for($i = 0; $i -lt 3; $i++){
        $cpu += Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | ForEach-Object {$_.Average}
        Start-Sleep -Seconds 1
    }
    return ([math]::ceiling(($cpu[0] + $cpu[1] + $cpu[2]) / 3))
}

Write-Host "Flo's Preventsleep-Script v1.4 /" -ForegroundColor Cyan -NoNewline
Write-host "/ Flos Schlaf-Verhinder-Skript v1.4" -ForegroundColor Yellow
Write-Host "This script prevents the standby-mode while specified processes are running. /" -ForegroundColor Cyan -NoNewline
Write-Host "/ Dieses Skript verhindert, dass der Computer waehrend der Ausfuehrung der angegebenen Prozesse in den Standby wechselt." -ForegroundColor Yellow
Write-Host "PLEASE DON'T CLOSE THIS WINDOW! // BITTE FENSTER NICHT SCHLIESSEN!`r`n" -ForegroundColor Red -BackgroundColor White

# DEFINITION: After direct start:
if($mode -eq "specify"){
    while($true){
        Write-Host "Which mode? `"CPU`" for CPU-Usage or `"process`" for process-specific. (both w/o quotes): /" -NoNewline
        Write-Host "/ Welcher Modus? `"CPU`" fuer CPU-Auslastung oder `"process`" fuer Prozess-Ueberwachung. (beides ohne Anfuerhungszeichen):" -ForegroundColor DarkGray
        [string]$mode = Read-Host
        if($mode -eq "CPU" -or $mode -eq "process"){
            break
        }else{
            Write-Host "Invalid choice, please try again. // Ungueltige Angabe, bitte erneut versuchen." -ForegroundColor Magenta
            continue
        }
    }
}
if($mode -eq "cpu"){
    if($userCPUlimit -eq -1){
        while($true){
            Write-Host "Enter the CPU-threshold in %. (enter w/o %-sign) - Recommendation: 90%, -1% to run script forever: /" -NoNewline
            Write-Host "/ Grenzwert der CPU-AUslastung in % angeben? (Angabe ohne %-Zeichen) Empfehlung: 90%, -1% falls Skript ewig laufen soll:" -ForegroundColor DarkGray
            [int]$userCPUlimit = Read-Host
            if($userCPUlimit -in (-1..99)){
                break
            }else{
                Write-Host "Invalid choice, please try again. // Ungueltige Angabe, bitte erneut versuchen." -ForegroundColor Magenta
                continue
            }
        }
    }
}
if($mode -eq "process"){
    if($userProcessCount -eq -1){
        while($true){
            Write-Host "How many Processes? /" -NoNewLine
            Write-Host "/ Wieviele Prozesse?" -ForegroundColor DarkGray
            [int]$userProcessCount = Read-Host
            if($userProcessCount -in (1..100)){
                break
            }else{
                Write-Host "Invalid choice, please try again. // Ungueltige Angabe, bitte erneut versuchen." -ForegroundColor Magenta
                continue
            }
        }
    }
    if($userProcess.Length -eq 0){
        for($i = 0; $i -lt $userProcessCount; $i++){
            Write-Host "Please specify name of process No. $($i + 1): /" -NoNewline
            Write-Host "/ Bitte Namen von Prozess Nr. $($i + 1) eingeben:`t" -ForegroundColor DarkGray -NoNewline
            [array]$userProcess += Read-Host 
        }
    }
    if("powershell" -in $userProcess){
        [int]$compensation = 1
    }else{
        [int]$compensation = 0
    }
}
if($shutdown -eq -1){
    while($true){
        Write-Host "Shutdown when done? `"1`" for yes, `"0`" for no. /" -NoNewline
        Write-Host "/ Nach Abschluss herunterfahren? `"1`" fuer Ja, `"0`" fuer Nein." -ForegroundColor DarkGray
        [int]$shutdown = Read-Host
            if($shutdown -in (0..1)){
            break
        }else{
            Write-Host "Invalid choice, please try again. // Ungueltige Angabe, bitte erneut versuchen." -ForegroundColor Magenta
            continue
        }
    }
}
if($mode -eq "none" -and $fileModeEnable -eq 0){
    Write-Host "`r`nInvalid choice: if -mode is `"none`", then -fileModeEnable must be set to 1. ABORTING. // Ungueltige Auswahl: wenn -mode `"none`" ist, muss -fileModeEnable 1 sein." -ForegroundColor Red
    Pause
    Exit
}

# DEFINITION: Start it:
Write-Host " "
$counter = 0
while($counter -lt $counterMax){
    if($fileModeEnable -eq 1){
        if((Test-Path -Path $fileToCheck) -eq $true){
            $fileSaysDone = Get-Content -Path "$fileToCheck" -ErrorAction SilentlyContinue
            if($fileSaysDone -eq 0){
                Write-Host "$(Get-Date -Format 'dd.MM.yy, HH:mm:ss')" -NoNewline
                Write-Host " - File-based process unfinished, sleeping for $($timeBase / 10) seconds. // Datei-basierter Prozess noch nicht fertig, schlafe $($timeBase / 10) Sekunden." -ForegroundColor Yellow
            }else{
                Write-Host "$(Get-Date -Format 'dd.MM.yy, HH:mm:ss')" -NoNewline
                Write-Host " - File-based process done! Sleeping for $($timeBase / 10) seconds. // Datei-basierter Prozess fertig! Schlafe fuer $($timeBase / 10) Sekunden." -ForegroundColor Green
                $fileModeEnable = 0
            }
        }Else{
            $fileModeEnable = 0
            Write-Host "File `"$fileToCheck`" wasn't found. Changing into fileless mode. // Datei `"$fileToCheck`" konnte nicht gefunden werden. Wechsle in dateilosen Modus." -ForegroundColor DarkRed
        }
        $MyShell.sendkeys("{F15}")
        Start-Sleep -Seconds $($timeBase / 10)
    }
    if($fileModeEnable -eq 0 -and $mode -eq "process"){
        $activeProcessCounter = @(Get-Process -ErrorAction SilentlyContinue -Name $userProcess).count - $compensation
        if($activeProcessCounter -ne 0){
            Write-Host "$(Get-Date -Format 'dd.MM.yy, HH:mm:ss')" -NoNewline
            Write-Host " - Process(es) `"$userProcess`" not yet done, sleeping for $timeBase seconds. // Prozess(e) `"$userProcess`" noch nicht fertig, schlafe $timeBase Sekunden." -ForegroundColor Yellow
            $counter = 0
            $MyShell.sendkeys("{F15}")
            Start-Sleep -Seconds $($timeBase)
        }Else{
            Write-Host "$(Get-Date -Format 'dd.MM.yy, HH:mm:ss')" -NoNewline
            Write-Host " - Process(es) `"$userProcess`" done, sleeping for $($timeBase / 2) seconds. // Prozess(e) `"$userProcess`" fertig, schlafe $($timeBase / 2) Sekunden." -ForegroundColor Green
            Write-Host "$counter/$counterMax Passes without any activity. // $counter/$counterMax Durchgaenge ohne Aktivitaet." -ForegroundColor Green
            $counter ++
            $MyShell.sendkeys("{F15}")
            Start-Sleep -Seconds $($timeBase / 2)
        }
    }
    if($fileModeEnable -eq 0 -and $mode -eq "CPU"){
        $CPUstats = Get-ComputerStats
        if($CPUstats -gt $userCPUlimit){
            Write-Host "$(Get-Date -Format 'dd.MM.yy, HH:mm:ss')" -NoNewline
            Write-Host " - CPU usage is $($CPUstats)% = above $($userCPUlimit)%, sleeping for $timeBase seconds. // CPU-Auslastung $($CPUstats)% = ueber $($userCPUlimit)%, schlafe $timeBase Sekunden." -ForegroundColor Yellow
            $counter = 0
            $MyShell.sendkeys("{F15}")
            Start-Sleep -Seconds $($timeBase)
        }else{
            Write-Host "$(Get-Date -Format 'dd.MM.yy, HH:mm:ss')" -NoNewline
            Write-Host " - CPU usage $($CPUstats)% = below $($userCPUlimit)%, sleeping for $($timeBase / 2) seconds. // CPU-Auslastung $($CPUstats)% = unter $($userCPUlimit)%, schlafe $($timeBase / 2) Sekunden." -ForegroundColor Green
            $counter++
            $MyShell.sendkeys("{F15}")
            Start-Sleep -Seconds $($timeBase / 2)
        }
    }
    if($mode -eq "none"){
        Write-Host "Mode `"none`" selected, program therefore finished. // Modus `"none`" gewaehlt, Programm daher fertig." -ForegroundColor Cyan
        $counter = $counterMax
        break
    }
}

Write-Host "`r`n$(Get-Date -Format 'dd.MM.yy, HH:mm:ss')" -NoNewline
Write-Host " - Done! // Fertig!" -ForegroundColor Green

if((Test-Path -Path "$fileToCheck") -eq $true){
    Remove-Item -Path "$fileToCheck" -Force -Verbose
}
if($shutdown -eq 1){
    Write-Host "Shutting down... // Herunterfahren..." -ForegroundColor Red
    Start-Sleep -Seconds 10
    Stop-Computer
}
