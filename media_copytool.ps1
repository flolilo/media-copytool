#requires -version 3

<#
    .SYNOPSIS
        Copy (and verify) user-defined filetypes from A (and B) to Y (and optionally Z).
    .DESCRIPTION
        Uses Windows' Robocopy and Copy-LongFile for file-copy, then uses PowerShell's Get-FileHash (SHA1) for verifying that files were copied without errors.
        CREDIT: Supports multithreading via Boe Prox's PoshRSJob-cmdlet (https://github.com/proxb/PoshRSJob)
        CREDIT: Supports long file paths via PSAlphaFS (https://github.com/v2kiran/PSAlphaFS)
    .NOTES
        Version:        1.0.1 (Beta)
        Author:         flolilo
        Creation Date:  2018-09-14
        Legal stuff: This program is free software. It comes without any warranty, to the extent permitted by
        applicable law. Most of the script was written by myself (or heavily modified by me when searching for solutions
        on the WWW). However, some parts are copies or modifications of very genuine code - see
        the "CREDIT:"-tags to find them.

    .PARAMETER ShowParams
        Cannot be specified in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it shows the pre-set parameters, so you can see what would happen if you e.g. try 'media_copytool.ps1 -EnableGUI "direct"'
    .PARAMETER EnableGUI
        Cannot be specified in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, GUI will be shown. Otherwise, the script will need to get its values through parameter-flags (e.g. "-InputPath C:\InputPath")
    .PARAMETER JSONParamPath
        Path to your json-file for parameters.
    .PARAMETER LoadParamPresetName
        Cannot be specified in mc_parameters.json. (Of course, as it is part of the preset's description).
        The name of the preset that the user wants to load. Default: preset. Valid characters: A-z,0-9,+,-,_ ; max. 64 characters
    .PARAMETER SaveParamPresetName
        Cannot be specified in mc_parameters.json. (Of course, as it is part of the preset's description).
        The name of the preset that the user wants to save to. Default: preset. Valid characters: A-z,0-9,+,-,_ ; max. 64 characters
    .PARAMETER RememberInPath
        Cannot be specified in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it remembers the value of -InputPath for future script-executions.
    .PARAMETER RememberOutPath
        Cannot be specified in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it remembers the value of -OutputPath for future script-executions.
    .PARAMETER RememberMirrorPath
        Cannot be specified in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it remembers the value of -MirrorPath for future script-executions.
    .PARAMETER RememberSettings
        Cannot be specified in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it remembers all parameters (excl. '-Remember*', '-ShowParams', and '-*Path') for future script-executions.
    .PARAMETER InfoPreference
        Cannot be specified in mc_parameters.json.
        Gives more verbose so one can see what is happening (and where it goes wrong).
        Valid options:
            0 - no debug (default)
            1 - only stop on end, show information
            2 - pause after every function, option to show files and their status
            3 - ???
    .PARAMETER InputPath
        Can be set in mc_parameters.json.
        Path(s) from which files will be copied.
    .PARAMETER OutputPath
        Can be set in mc_parameters.json.
        Path to copy the files to.
    .PARAMETER MirrorEnable
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it enables copying to a second output-path that is specified with -MirrorPath.
    .PARAMETER MirrorPath
        Can be set in mc_parameters.json.
        Second path to which files will  be copied. Only used if -MirrorEnable is set to 1
    .PARAMETER FormatPreference
        Can be set in mc_parameters.json.
        Set if you want to searc for all files, only certain files, or to exclude certain files in the input-path.
        Valid settings: "all","include","exclude"
    .PARAMETER FormatInExclude
        Can be set in mc_parameters.json.
        If -FormatPreference is set to "include" or "exclude", specify your formats here with wildcards and as array, e.g. @("*.cr2","*.jpg")
    .PARAMETER OutputSubfolderStyle
        Can be set in mc_parameters.json.
        Creation-style of subfolders for files in -OutputPath. The date will be taken from the file's last edit time.
        Valid options:
            ""          -   No subfolders in -OutputPath.
            "%n%"     -   Take the original subfolder-structure and copy it (like Robocopy's /MIR)
            "%y4%-%mo%-%d%"    -   E.g. 2017-01-31
            "%y4%_%mo%_%d%"    -   E.g. 2017_01_31
            "%y4%.%mo%.%d%"    -   E.g. 2017.01.31
            "%y4%%mo%%d%"      -   E.g. 20170131
            "%y2%-%mo%-%d%"      -   E.g. 17-01-31
            "%y2%_%mo%_%d%"      -   E.g. 17_01_31
            "%y2%.%mo%.%d%"      -   E.g. 17.01.31
            "%y2%%mo%%d%"        -   E.g. 170131
    .PARAMETER OutputFileStyle
        Can be set in mc_parameters.json.
        Renaming-style for input-files. The date and time will be taken from the file's last edit time.
        Valid options:
            "%n%"         -   Original file-name will be used.
            "%y4%-%mo%-%d%_%h%-%mi%-%s%"  -   E.g. 2017-01-31_13-59-58.ext
            "%y4%%mo%%d%_%h%%mi%%s%"     -   E.g. 20170131_135958.ext
            "%y4%%mo%%d%%h%%mi%%s%"      -   E.g. 20170131135958.ext
            "%y2%-%mo%-%d%_%h%-%mi%-%s%"    -   E.g. 17-01-31_13-59-58.ext
            "%y2%%mo%%d%_%h%%mi%%s%"       -   E.g. 170131_135958.ext
            "%y2%%mo%%d%%h%%mi%%s%"        -   E.g. 170131135958.ext
            "%h%-%mi%-%s%"          -   E.g. 13-59-58.ext
            "%h%_%mi%_%s%"          -   E.g. 13_59_58.ext
            "%h%%mi%%s%"            -   E.g. 135958.ext
    .PARAMETER HistFilePath
        Can be set in mc_parameters.json.
        Path to the JSON-file that represents the history-file.
    .PARAMETER UseHistFile
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        The history-file is a fast way to rule out the creation of duplicates by comparing the files from -InputPath against the values stored earlier.
        If enabled, it will use the history-file to prevent duplicates.
    .PARAMETER WriteHistFile
        Can be set in mc_parameters.json.
        The history-file is a fast way to rule out the creation of duplicates by comparing the files from -InputPath against the values stored earlier.
        Valid options:
            "No"        -   New values will NOT be added to the history-file, the old values will remain.
            "Yes"       -   Old + new values will be added to the history-file, with old values still saved.
            "Overwrite" -   Old values will be deleted, new values will be written. Best to use after the card got formatted, as it will make the history-file smaller and therefore faster.
    .PARAMETER HistCompareHashes
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it additionally checks for duplicates in the history-file via hash-calculation of all input-files (slow!)
    .PARAMETER CheckOutputDupli
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it checks for already copied files in the output-path (and its subfolders).
    .PARAMETER AvoidIdenticalFiles
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, identical files from the input-path will only get copied once.
    .PARAMETER AcceptTimeDiff
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it 3 seconds of time difference will not be considered a difference. Useful if you use multiple cards in your camera.
    .PARAMETER InputSubfolderSearch
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it enables file-search in subfolders of the input-path.
    .PARAMETER VerifyCopies
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, copied files will be checked for their integrity via SHA1-hashes. Disabling will increase speed, but there is no absolute guarantee that your files are copied correctly.
    .PARAMETER OverwriteExistingFiles
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, existing files will be overwritten. If disabled, new files will get a unique name.
    .PARAMETER EnableLongPaths
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, file names will not be restricted to Windows' usual 260 character limit. USE ONLY WITH WIN 10 WITH LONG PATHS ENABLED!
    .PARAMETER ZipMirror
        DEPRECATED/Unsupported. Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        Only enabled if -EnableMirror is enabled, too. Creates a zip-archive for archiving. Name will be <actual time>_Mirror.zip
    .PARAMETER UnmountInputDrive
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, safely removes the input-drive after finishing copying & verifying. Only use with external drives!
    .PARAMETER PreventStandby
        Can be set in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, automatic standby or shutdown is prevented as long as media-copytool is running.

    .INPUTS
        mc_parameters.json,
        any valid UTF8- *.json if -UseHistFile is 1 (file specified by -HistFilePath),
        mc_GUI.xaml if -EnableGUI is "GUI",
        File(s) must be located in the script's directory and must not be renamed.
    .OUTPUTS
        any valid UTF8- *.json if -WriteHistFile is "Yes" or "Overwrite" (file specified by -HistFilePath),
        mc_parameters.json if -Remember* is specified
        File(s) will be saved into the script's directory.

    .EXAMPLE
        See the preset/saved parameters of this script:
        media_copytool.ps1 -ShowParams 1
    .EXAMPLE
        Start Media-Copytool with the Graphical user interface:
        media_copytool.ps1 -EnableGUI 1
    .EXAMPLE
        Copy Canon's Raw-Files, Movies, JPEGs from G:\ to D:\Backup and prevent the computer from ging to standby:
        media_copytool.ps1 -FormatPreference "include" -FormatInExclude @("*.jpg","*.mov")" .InputPath "G:\" -OutputPath "D:\Backup" -PreventStandby 1
#>
param(
    [int]$ShowParams =              0,
    [int]$EnableGUI =               1,
    [string]$JSONParamPath =        "$($PSScriptRoot)\mc_parameters.json",
    [string]$LoadParamPresetName =  "default",
    [string]$SaveParamPresetName =  "",
    [int]$RememberInPath =          0,
    [int]$RememberOutPath =         0,
    [int]$RememberMirrorPath =      0,
    [int]$RememberSettings =        0,
    [int]$InfoPreference =          1,
    # From here on, parameters can be set both via parameters and via JSON file(s).
    [array]$InputPath =             @(),
    [string]$OutputPath =           "",
    [int]$MirrorEnable =            -1,
    [string]$MirrorPath =           "",
    [string]$FormatPreference =     "",
    [array]$FormatInExclude =       @(),
    [string]$OutputSubfolderStyle = "",
    [string]$OutputFileStyle =      "",
    [string]$HistFilePath =         "",
    [int]$UseHistFile =             -1,
    [string]$WriteHistFile =        "",
    [int]$HistCompareHashes =       -1,
    [int]$CheckOutputDupli =        -1,
    [int]$AvoidIdenticalFiles =     -1,
    [int]$AcceptTimeDiff =          -1,
    [int]$InputSubfolderSearch =    -1,
    [int]$VerifyCopies =            -1,
    [int]$OverwriteExistingFiles =  -1,
    [int]$EnableLongPaths =         -1,
    [int]$ZipMirror =               -1,
    [int]$UnmountInputDrive =       -1,
    [int]$PreventStandby =          -1
)
# DEFINITION: Combine all parameters into a hashtable, then delete the parameter variables:
    [hashtable]$UserParams = @{
        ShowParams =                $ShowParams
        EnableGUI =                 $EnableGUI
        JSONParamPath =             $JSONParamPath
        LoadParamPresetName =       $LoadParamPresetName
        SaveParamPresetName =       $SaveParamPresetName
        RememberInPath =            $RememberInPath
        RememberOutPath =           $RememberOutPath
        RememberMirrorPath =        $RememberMirrorPath
        RememberSettings =          $RememberSettings
        # From here on, parameters can be set both via parameters and via JSON file(s).
        InputPath =                 $InputPath
        OutputPath =                $OutputPath
        MirrorEnable =              $MirrorEnable
        MirrorPath =                $MirrorPath
        FormatPreference =          $FormatPreference
        FormatInExclude =           $FormatInExclude
        OutputSubfolderStyle =      $OutputSubfolderStyle
        OutputFileStyle =           $OutputFileStyle
        HistFilePath =              $HistFilePath
        UseHistFile =               $UseHistFile
        WriteHistFile =             $WriteHistFile
        HistCompareHashes =         $HistCompareHashes
        CheckOutputDupli =          $CheckOutputDupli
        AvoidIdenticalFiles =       $AvoidIdenticalFiles
        AcceptTimeDiff =            $AcceptTimeDiff
        InputSubfolderSearch =      $InputSubfolderSearch
        VerifyCopies =              $VerifyCopies
        OverwriteExistingFiles =    $OverwriteExistingFiles
        EnableLongPaths =           $EnableLongPaths
        ZipMirror =                 $ZipMirror
        UnmountInputDrive =         $UnmountInputDrive
    }
    Remove-Variable -Name ShowParams,EnableGUI,JSONParamPath,LoadParamPresetName,SaveParamPresetName,RememberInPath,RememberOutPath,RememberMirrorPath,RememberSettings,InputPath,OutputPath,MirrorEnable,MirrorPath,FormatPreference,FormatInExclude,OutputSubfolderStyle,OutputFileStyle,HistFilePath,UseHistFile,WriteHistFile,HistCompareHashes,InputSubfolderSearch,CheckOutputDupli,AcceptTimeDiff,VerifyCopies,OverwriteExistingFiles,EnableLongPaths,AvoidIdenticalFiles,ZipMirror,UnmountInputDrive

# DEFINITION: Various vars: getting GUI variables, ThreadCount,...
    # GUI path:
        [string]$GUIPath = "$($PSScriptRoot)\mc_GUI.xaml"
    # If you want to see the variables (buttons, checkboxes, ...) the GUI has to offer, set this to 1:
        [int]$GetWPF = 0
    # ThreadCount for xCopy / RoboCopy:
        [int]$ThreadCount = 4
    # Positive answers for users:
        [array]$PositiveAnswers = @("y","yes",1,"j","ja")
    # Accepted seconds of difference between same files (e.g. if files are same, but timestamps vary by X seconds)
        [int]$TimeDiff = 3
# DEFINITION: Setting up load and save names for parameter presets:
    $UserParams.LoadParamPresetName = $UserParams.LoadParamPresetName.ToLower() -Replace '[^A-Za-z0-9_+-]',''
    if($UserParams.LoadParamPresetName.Length -lt 1){
        $UserParams.LoadParamPresetName = "$(Get-Date -Format "yyyy-MM-dd_HH-mm")"
    }else{
        $UserParams.LoadParamPresetName = $UserParams.LoadParamPresetName.Substring(0, [math]::Min($UserParams.LoadParamPresetName.Length, 64))
    }

    $UserParams.SaveParamPresetName = $UserParams.SaveParamPresetName.ToLower() -Replace '[^A-Za-z0-9_+-]',''
    $UserParams.SaveParamPresetName = $UserParams.SaveParamPresetName.Substring(0, [math]::Min($UserParams.SaveParamPresetName.Length, 64))
    if($UserParams.SaveParamPresetName.Length -lt 1){
        $UserParams.SaveParamPresetName = $UserParams.LoadParamPresetName
    }

# DEFINITION: Get all error-outputs in English:
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Set default ErrorAction to Stop:
    # CREDIT: https://stackoverflow.com/a/21260623/8013879
    if($InfoPreference -eq 0){
        $PSDefaultParameterValues = @{}
        $PSDefaultParameterValues += @{'*:ErrorAction' = 'Stop'}
        $ErrorActionPreference = 'Stop'
    }

# DEFINITION: Load PoshRSJob & PSAlphaFS:
    try{
        Import-Module -Name "PoshRSJob" -NoClobber -Global -ErrorAction Stop
    }catch{
        try{
            [string]$PoshRSJobPath = Get-ChildItem -LiteralPath $PSScriptRoot\Modules\PoshRSJob -Recurse -Filter PoshRSJob.psm1 -ErrorAction Stop | Select-Object -ExpandProperty FullName
            Import-Module $PoshRSJobPath -NoClobber -Global -ErrorAction Stop
            Remove-Variable -Name PoshRSJobPath
        }catch{
            Write-Host "Could not load Module `"PoshRSJob`" - Please install it in an " -ForegroundColor Red -NoNewline
            Write-Host "administrative console " -ForegroundColor Yellow -NoNewline
            Write-Host "via " -ForegroundColor Red -NoNewline
            Write-Host "Install-Module PoshRSJob" -NoNewline
            Write-Host ", download it from " -ForegroundColor Red -NoNewline
            Write-Host "github.com/proxb/PoshRSJob/releases " -NoNewline
            Write-Host "and install it to " -ForegroundColor Red -NoNewline
            Write-Host "<SCRIPT_PATH>\Modules\PoshRSJob\<VERSION.NUMBER>" -NoNewline -ForegroundColor Gray
            Write-Host "." -ForegroundColor Red
            Pause
            Exit
        }
    }
    try{
        Import-Module -Name "PSAlphaFS" -NoClobber -Global -ErrorAction Stop
    }catch{
        try{
            [string]$PSAlphaFSPath = Get-ChildItem -LiteralPath $PSScriptRoot\Modules\PSAlphaFS -Recurse -Filter PSAlphaFS.psm1 -ErrorAction Stop | Select-Object -ExpandProperty FullName
            Import-Module $PSAlphaFSPath -NoClobber -Global -ErrorAction Stop
            Remove-Variable -Name PSAlphaFS
        }catch{
            Write-Host "Could not load Module `"PSAlphaFS`" - Please install it in an " -ForegroundColor Red -NoNewline
            Write-Host "administrative console " -ForegroundColor Yellow -NoNewline
            Write-Host "via " -ForegroundColor Red -NoNewline
            Write-Host "Install-Module PSAlphaFS" -NoNewline
            Write-Host ", download it from " -ForegroundColor Red -NoNewline
            Write-Host "github.com/v2kiran/PSAlphaFS/releases " -NoNewline
            Write-Host "and install it to " -ForegroundColor Red -NoNewline
            Write-Host "<SCRIPT_PATH>\Modules\PSAlphaFS\<VERSION.NUMBER>" -NoNewline -ForegroundColor Gray
            Write-Host "." -ForegroundColor Red
            Pause
            Exit
        }
    }

# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -TypeName System.Text.UTF8Encoding
    [Console]::InputEncoding = New-Object -TypeName System.Text.UTF8Encoding
# DEFINITION: Set current date and version number:
    $VersionNumber = "v1.0.1 (Beta) - 2018-09-14"

# ==================================================================================================
# ==============================================================================
#    Defining generic functions:
# ==============================================================================
# ==================================================================================================

# DEFINITION: Making Write-Host much, much faster:
Function Write-ColorOut(){
    <#
        .SYNOPSIS
            A faster version of Write-Host
        .DESCRIPTION
            Using the [Console]-commands to make everything faster.
        .NOTES
            Date: 2018-03-11

        .PARAMETER Object
            String to write out
        .PARAMETER ForegroundColor
            Color of characters. If not specified, uses color that was set before calling. Valid: White (PS-Default), Red, Yellow, Cyan, Green, Gray, Magenta, Blue, Black, DarkRed, DarkYellow, DarkCyan, DarkGreen, DarkGray, DarkMagenta, DarkBlue
        .PARAMETER BackgroundColor
            Color of background. If not specified, uses color that was set before calling. Valid: DarkMagenta (PS-Default), White, Red, Yellow, Cyan, Green, Gray, Magenta, Blue, Black, DarkRed, DarkYellow, DarkCyan, DarkGreen, DarkGray, DarkBlue
        .PARAMETER NoNewLine
            When enabled, no line-break will be created.

        .EXAMPLE
            Just use it like Write-Host.
    #>
    param(
        [string]$Object = "Write-ColorOut was called, but no string was transfered.",

        [ValidateSet("DarkBlue","DarkGreen","DarkCyan","DarkRed","Blue","Green","Cyan","Red","Magenta","Yellow","Black","DarkGray","Gray","DarkYellow","White","DarkMagenta")]
        [string]$ForegroundColor,

        [ValidateSet("DarkBlue","DarkGreen","DarkCyan","DarkRed","Blue","Green","Cyan","Red","Magenta","Yellow","Black","DarkGray","Gray","DarkYellow","White","DarkMagenta")]
        [string]$BackgroundColor,

        [switch]$NoNewLine=$false,

        [ValidateRange(0,48)]
        [int]$Indentation=0
    )

    if($ForegroundColor.Length -ge 3){
        $old_fg_color = [Console]::ForegroundColor
        [Console]::ForegroundColor = $ForegroundColor
    }
    if($BackgroundColor.Length -ge 3){
        $old_bg_color = [Console]::BackgroundColor
        [Console]::BackgroundColor = $BackgroundColor
    }
    if($Indentation -gt 0){
        [Console]::CursorLeft = $Indentation
    }

    if($NoNewLine -eq $false){
        [Console]::WriteLine($Object)
    }else{
        [Console]::Write($Object)
    }

    if($ForegroundColor.Length -ge 3){
        [Console]::ForegroundColor = $old_fg_color
    }
    if($BackgroundColor.Length -ge 3){
        [Console]::BackgroundColor = $old_bg_color
    }
}

# DEFINITION: For the auditory experience:
Function Start-Sound(){
    <#
        .SYNOPSIS
            Gives auditive feedback for fails and successes
        .DESCRIPTION
            Uses SoundPlayer and Windows's own WAVs to play sounds.
        .NOTES
            Date: 2018-02-25

        .PARAMETER Success
            1 plays Windows's "tada"-sound, 0 plays Windows's "chimes"-sound.

        .EXAMPLE
            For success: Start-Sound -Success 1
        .EXAMPLE
            For fail: Start-Sound -Success 0
    #>
    param(
        [int]$Success = $(Write-ColorOut "-Success is needed by Start-Sound!" -ForegroundColor Magenta)
    )

    try{
        $sound = New-Object System.Media.SoundPlayer -ErrorAction stop
        if($Success -eq 1){
            $sound.SoundLocation = "C:\Windows\Media\tada.wav"
        }else{
            $sound.SoundLocation = "C:\Windows\Media\chimes.wav"
        }
        $sound.Play()
    }catch{
        Write-Output "`a"
    }
}

# DEFINITION: Pause the programme if debug-var is active. Also, enable measuring times per command with -debug 3.c
Function Invoke-Pause(){
    if($script:InfoPreference -gt 0){
        Write-ColorOut "Processing-time:`t$($script:timer.elapsed.TotalSeconds)" -ForegroundColor Magenta
    }
    if($script:InfoPreference -gt 1){
        $script:timer.Reset()
        Pause
        $script:timer.Start()
    }
}

# DEFINITION: Exit the program (and close all windows) + option to pause before exiting.
Function Invoke-Close(){
    Write-ColorOut "Exiting - This could take some seconds. Please do not close this window!" -ForegroundColor Magenta
    if($script:PreventStandby -gt 1){
        Stop-Process -Id $script:PreventStandby -ErrorAction SilentlyContinue
    }
    if((Get-RSJob).count -gt 0){
        Get-RSJob | Stop-RSJob
        Start-Sleep -Milliseconds 5
        Get-RSJob | Remove-RSJob
    }
    if($script:InfoPreference -gt 0){
        Pause
    }

    $Host.UI.RawUI.WindowTitle = "Windows PowerShell"
    Exit
}

# DEFINITION: Start equivalent to PreventSleep.ps1:
Function Invoke-PreventSleep(){
    <#
        .NOTES
            v1.1 - 2018-02-25
    #>
    Write-ColorOut "$(Get-CurrentDate)  --  Starting preventsleep-script..." -ForegroundColor Cyan

# DEFINITION: For button-emulation:
# CREDIT: https://superuser.com/a/1023836/703240
$standby = @'
    Write-Host "(PID = $("{0:D8}" -f $pid))" -ForegroundColor Gray
    $MyShell = New-Object -ComObject "Wscript.Shell"
    while($true){
        Start-Sleep -Seconds 90
        $MyShell.sendkeys("{F15}")
    }
'@
    $standby = [System.Text.Encoding]::Unicode.GetBytes($standby)
    $standby = [Convert]::ToBase64String($standby)

    try{
        [int]$inter = (Start-Process powershell -ArgumentList "-EncodedCommand $standby" -WindowStyle Hidden -PassThru).Id
        if($script:InfoPreference -gt 0){
            Write-ColorOut "preventsleep-PID is $("{0:D8}" -f $inter)" -ForegroundColor Gray -BackgroundColor DarkGray -Indentation 4
        }
        Start-Sleep -Milliseconds 25

        if((Get-Process -Id $inter -ErrorVariable SilentlyContinue).count -eq 1){
            [int]$script:PreventStandby = $inter
        }else{
            Write-ColorOut "Cannot prevent standby" -ForegroundColor Magenta -Indentation 4
            Start-Sleep -Seconds 3
        }
    }catch{
        Write-ColorOut "Cannot prevent standby" -ForegroundColor Magenta -Indentation 4
        Start-Sleep -Seconds 3
    }
}

# DEFINITION: Getting date and time in pre-formatted string:
Function Get-CurrentDate(){
    return $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
}


# ==================================================================================================
# ==============================================================================
#    Defining specific functions:
# ==============================================================================
# ==================================================================================================

# DEFINITION: Get parameters from JSON file:
Function Read-JsonParameters(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Read-JsonParameters'),
        [ValidateRange(0,1)]
        [int]$Renew = $(throw 'Renew is required by Read-JsonParameters')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting parameter-values..." -ForegroundColor Cyan

    if((Test-Path -LiteralPath $UserParams.JSONParamPath -PathType Leaf -ErrorAction SilentlyContinue) -eq $true){
        try{
            $jsonparams = Get-Content -LiteralPath $UserParams.JSONParamPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            if($jsonparams.Length -eq 0){
                Write-ColorOut "$($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) is empty!" -ForegroundColor Magenta -Indentation 4
                throw '$UserParams.JSONParamPath is empty'
            }

            if($UserParams.LoadParamPresetName -in $jsonparams.ParamPresetName){
                $jsonparams = $jsonparams | Where-Object {$_.ParamPresetName -eq $UserParams.LoadParamPresetName}
                Write-ColorOut "Loaded preset `"$($UserParams.LoadParamPresetName)`" from $($UserParams.JSONParamPath.Replace("$($PSScriptRoot)","."))." -ForegroundColor Yellow -Indentation 4
            }elseif("default" -in $jsonparams.ParamPresetName){
                $jsonparams = $jsonparams | Where-Object {$_.ParamPresetName -eq "default"}
                Write-ColorOut "Loaded preset `"$($jsonparams.ParamPresetName)`", as `"$($UserParams.LoadParamPresetName)`" is not specified in $($UserParams.JSONParamPath.Replace("$($PSScriptRoot)","."))." -ForegroundColor Magenta -Indentation 4
                $UserParams.LoadParamPresetName = $jsonparams.ParamPresetName
            }else{
                $jsonparams = $jsonparams | Select-Object -Index 0
                Write-ColorOut "Loaded first preset (`"$($jsonparams.ParamPresetName)`") from $($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) (`"$($jsonparams.ParamPresetName.Replace("$($PSScriptRoot)","."))`"), as neither `"$($UserParams.LoadParamPresetName)`" nor `"default`" were found." -ForegroundColor Magenta -Indentation 4
                $UserParams.LoadParamPresetName = $jsonparams.ParamPresetName
            }
            $jsonparams = $jsonparams.ParamPresetValues

            if($Renew -eq 1){
                [string]$UserParams.SaveParamPresetName = $UserParams.LoadParamPresetName
            }
            if($UserParams.InputPath.Length -eq 0 -or $Renew -eq 1){
                [array]$UserParams.InputPath = @($jsonparams.InputPath)
            }
            if($UserParams.OutputPath.Length -eq 0 -or $Renew -eq 1){
                [string]$UserParams.OutputPath = $jsonparams.OutputPath
            }
            if($UserParams.MirrorEnable -eq -1 -or $Renew -eq 1){
                [int]$UserParams.MirrorEnable = $jsonparams.MirrorEnable
            }
            if($UserParams.MirrorPath.Length -eq 0 -or $Renew -eq 1){
                [string]$UserParams.MirrorPath = $jsonparams.MirrorPath
            }
            if($UserParams.FormatPreference.Length -lt 3 -or $Renew -eq 1){
                [string]$UserParams.FormatPreference = $jsonparams.FormatPreference
            }
            if($UserParams.FormatInExclude.Length -eq 0 -or $Renew -eq 1){
                [array]$UserParams.FormatInExclude = @($jsonparams.FormatInExclude)
            }
            if($UserParams.OutputSubfolderStyle.Length -eq 0 -or $Renew -eq 1){
                [string]$UserParams.OutputSubfolderStyle = $jsonparams.OutputSubfolderStyle
            }
            if($UserParams.OutputFileStyle.Length -eq 0 -or $Renew -eq 1){
                [string]$UserParams.OutputFileStyle = $jsonparams.OutputFileStyle
            }
            if($UserParams.HistFilePath.Length -eq 0 -or $Renew -eq 1){
                [string]$UserParams.HistFilePath = $jsonparams.HistFilePath.Replace('$($PSScriptRoot)',"$PSScriptRoot")
            }
            if($UserParams.UseHistFile -eq -1 -or $Renew -eq 1){
                [int]$UserParams.UseHistFile = $jsonparams.UseHistFile
            }
            if($UserParams.WriteHistFile.Length -eq 0 -or $Renew -eq 1){
                [string]$UserParams.WriteHistFile = $jsonparams.WriteHistFile
            }
            if($UserParams.HistCompareHashes -eq -1 -or $Renew -eq 1){
                [int]$UserParams.HistCompareHashes = $jsonparams.HistCompareHashes
            }
            if($UserParams.CheckOutputDupli -eq -1 -or $Renew -eq 1){
                [int]$UserParams.CheckOutputDupli = $jsonparams.CheckOutputDupli
            }
            if($UserParams.AvoidIdenticalFiles -eq -1 -or $Renew -eq 1){
                [int]$UserParams.AvoidIdenticalFiles = $jsonparams.AvoidIdenticalFiles
            }
            if($UserParams.AcceptTimeDiff -eq -1 -or $Renew -eq 1){
                [int]$UserParams.AcceptTimeDiff = $jsonparams.AcceptTimeDiff
            }
            if($UserParams.InputSubfolderSearch -eq -1 -or $Renew -eq 1){
                [int]$UserParams.InputSubfolderSearch = $jsonparams.InputSubfolderSearch
            }
            if($UserParams.VerifyCopies -eq -1 -or $Renew -eq 1){
                [int]$UserParams.VerifyCopies = $jsonparams.VerifyCopies
            }
            if($UserParams.OverwriteExistingFiles -eq -1 -or $Renew -eq 1){
                [int]$UserParams.OverwriteExistingFiles = $jsonparams.OverwriteExistingFiles
            }
            if($UserParams.EnableLongPaths -eq -1 -or $Renew -eq 1){
                [int]$UserParams.EnableLongPaths = $jsonparams.EnableLongPaths
            }
            if($UserParams.ZipMirror -eq -1 -or $Renew -eq 1){
                [int]$UserParams.ZipMirror = $jsonparams.ZipMirror
            }
            if($UserParams.UnmountInputDrive -eq -1 -or $Renew -eq 1){
                [int]$UserParams.UnmountInputDrive = $jsonparams.UnmountInputDrive
            }
            if($script:PreventStandby -eq -1 -or $Renew -eq 1){
                [int]$script:PreventStandby = $jsonparams.PreventStandby
            }
        }catch{
            Write-ColorOut "$($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) cannot be loaded - aborting!" -ForegroundColor Red -Indentation 4
            Write-ColorOut "(You can specify the path with -JSONParamPath (w/o GUI) - or use `"-EnableGUI 1`".)" -ForegroundColor Magenta -Indentation 4
            Start-Sleep -Seconds 5
            throw '$UserParams.JSONParamPath cannot be loaded'
        }
    }else{
        Write-ColorOut "$($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) does not exist - aborting!" -ForegroundColor Red -Indentation 4
        Write-ColorOut "(You can specify the path with -JSONParamPath (w/o GUI) - or use `"-EnableGUI 1`".)" -ForegroundColor Magenta -Indentation 4
        Start-Sleep -Seconds 5
        throw '$UserParams.JSONParamPath does not exist'
    }

    return $UserParams
}

# DEFINITION: Load and Start GUI:
Function Start-GUI(){
    <#
        .NOTES
            CREDIT: Syntax of calling the GUI derived from:
                    https://foxdeploy.com/series/learning-gui-toolmaking-series/
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]$GUIPath = $(throw 'GUIPath is required by Start-GUI'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Start-GUI')
    )
    # DEFINITION: "Select"-Window for buttons to choose a path.
    Function Get-GUIFolder(){
        param(
            [ValidateNotNullOrEmpty()]
            [string]$ToInfluence = $(throw 'ToInfluence is required by Get-GUIFolder'),
            [ValidateNotNullOrEmpty()]
            [hashtable]$GUIParams = $(throw 'GUIParams is required by Get-GUIFolder')
        )

        if($ToInfluence -ne "histfile"){
            [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
            $browse = New-Object System.Windows.Forms.FolderBrowserDialog
            $browse.rootfolder = "MyComputer"
            $browse.ShowNewFolderButton = $true
            if($ToInfluence -eq "input"){
                $browse.Description = "Select an input-path:"
            }elseif($ToInfluence -eq "output"){
                $browse.Description = "Select an output-path:"
            }elseif($ToInfluence -eq "mirror"){
                $browse.Description = "Select a mirror-path:"
            }

            if($browse.ShowDialog() -eq "OK"){
                if($ToInfluence -eq "input"){
                    $GUIParams.TeBx_Input.Text = $browse.SelectedPath
                }elseif($ToInfluence -eq "output"){
                    $GUIParams.TeBx_Output.Text = $browse.SelectedPath
                }elseif($ToInfluence -eq "mirror"){
                    $GUIParams.TeBx_Mirror.Text = $browse.SelectedPath
                }
            }
        }else{
            [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
            $browse = New-Object System.Windows.Forms.OpenFileDialog
            $browse.Multiselect = $false
            $browse.Filter = 'JSON (*.json)|*.json'

            if($browse.ShowDialog() -eq "OK"){
                if($browse.FileName -like "*.json"){
                    $GUIParams.TeBx_HistFile.Text = $browse.FileName
                }
            }
        }

        return $GUIParams
    }

    # DEFINITION: Load GUI layout from XAML-File
        if((Test-Path -LiteralPath $GUIPath -PathType Leaf) -eq $true){
            try{
                $inputXML = Get-Content -LiteralPath $GUIPath -Encoding UTF8 -ErrorAction Stop
            }catch{
                Write-ColorOut "Could not load $GUIPath - GUI can therefore not start." -ForegroundColor Red
                Pause
                throw 'Could not load $GUIPath - GUI can therefore not start.'
            }
        }else{
            Write-ColorOut "Could not find $GUIPath - GUI can therefore not start." -ForegroundColor Red
            Pause
            throw 'Could not find $GUIPath - GUI can therefore not start.'
        }

        try{
            [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
            [xml]$xaml = $inputXML -replace '\(\(MC_VERSION\)\)',"$script:VersionNumber" -replace 'mc:Ignorable="d"','' -replace "x:Name",'Name' -replace '^<Win.*', '<Window'
            $reader = (New-Object System.Xml.XmlNodeReader $xaml)
            $Form = [Windows.Markup.XamlReader]::Load($reader)
        }
        catch{
            Write-ColorOut "Unable to load Windows.Markup.XamlReader. Usually this means that you haven't installed .NET Framework. Please download and install the latest .NET Framework Web-Installer for your OS: " -ForegroundColor Red
            Write-ColorOut "https://duckduckgo.com/?q=net+framework+web+installer&t=h_&ia=web"
            Write-ColorOut "Alternatively, this script will now start in CLI-mode, which requires you to enter all variables via parameter flags (e.g. `"-Inputpath C:\InputPath`")." -ForegroundColor Yellow
            Pause
            throw 'Unable to load Windows.Markup.XamlReader.'
        }

        [hashtable]$GUIParams = @{}
        $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
            # Do not add TextBlocks, as those will not be altered and only mess around:
            if(($Form.FindName($_.Name)).ToString() -ne "System.Windows.Controls.TextBlock"){
                $GUIParams.Add($($_.Name), $Form.FindName($_.Name))
            }
        }

        if($script:getWPF -ne 0){
            Write-ColorOut "Found these interactable elements:" -ForegroundColor Cyan
            $GUIParams | Format-Table -AutoSize | Out-Host
            Pause
            Invoke-Close
        }

    # DEFINITION: Fill first page of GUI:
        # DEFINITION: Get presets from JSON:
            if((Test-Path -LiteralPath $UserParams.JSONParamPath -PathType Leaf) -eq $true){
                try{
                    $jsonparams = Get-Content -Path $UserParams.JSONParamPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                    if($jsonparams.ParamPresetName -is [array]){
                        $jsonparams.ParamPresetName | ForEach-Object {
                            $GUIParams.CoBx_LoadPreset.AddChild($_)
                        }
                        for($i=0; $i -lt $jsonparams.ParamPresetName.length; $i++){
                            if($jsonparams.ParamPresetName[$i] -eq $UserParams.LoadParamPresetName){
                                $GUIParams.CoBx_LoadPreset.SelectedIndex = $i
                            }
                        }
                    }else{
                        $GUIParams.CoBx_LoadPreset.AddChild($jsonparams.ParamPresetName)
                        $GUIParams.CoBx_LoadPreset.SelectedIndex = 0
                    }
                }catch{
                    Write-ColorOut "Getting preset-names from $($UserParams.JSONParamPath) failed - aborting!" -ForegroundColor Magenta -Indentation 4
                    throw 'Getting preset-names from $UserParams.JSONParamPath failed'
                }
            }else{
                Write-ColorOut "$($UserParams.JSONParamPath) does not exist - aborting!" -ForegroundColor  Magenta -Indentation 4
                throw '$UserParams.JSONParamPath does not exist'
            }

        try{
            $GUIParams.TeBx_SavePreset.Text =            $UserParams.SaveParamPresetName

            # DEFINITION: In-, out-, mirrorpath:
                $GUIParams.TeBx_Input.Text =             $UserParams.InputPath -join "|"
                $GUIParams.ChBx_RememberIn.IsChecked =   $UserParams.RememberInPath
                $GUIParams.TeBx_Output.Text =            $UserParams.OutputPath
                $GUIParams.ChBx_RememberOut.IsChecked =  $UserParams.RememberOutPath
                $GUIParams.ChBx_Mirror.IsChecked =       $UserParams.MirrorEnable
                $GUIParams.TeBx_Mirror.Text =            $UserParams.MirrorPath
                $GUIParams.ChBx_RememberMirror.IsChecked =   $UserParams.RememberMirrorPath
            # DEFINITION: History-file-path:
                $GUIParams.TeBx_HistFile.Text =          $UserParams.HistFilePath
    # DEFINITION: Second page of GUI:
            # DEFINITION: Formats:
                if($UserParams.FormatPreference -in @("include","in")){
                    $GUIParams.RaBn_Include.IsChecked =  $true
                    $GUIParams.TeBx_Include.Text =   $UserParams.FormatInExclude -join "|"
                    $GUIParams.TeBx_Exclude.Text =   $UserParams.FormatInExclude -join "|"
                }elseif($UserParams.FormatPreference -in @("exclude","ex")){
                    $GUIParams.RaBn_Exclude.IsChecked =  $true
                    $GUIParams.TeBx_Exclude.Text =   $UserParams.FormatInExclude -join "|"
                    $GUIParams.TeBx_Include.Text =   $UserParams.FormatInExclude -join "|"
                }else{
                    $GUIParams.RaBn_All.IsChecked =      $true
                    $GUIParams.TeBx_Include.Text =   $UserParams.FormatInExclude -join "|"
                    $GUIParams.TeBx_Exclude.Text =   $UserParams.FormatInExclude -join "|"
                }
            # DEFINITION: Duplicates:
                $GUIParams.ChBx_UseHistFile.IsChecked = $UserParams.UseHistFile
                $GUIParams.CoBx_WriteHistFile.SelectedIndex = $(
                    if("yes"            -eq $UserParams.WriteHistFile){0}
                    elseif("Overwrite"  -eq $UserParams.WriteHistFile){1}
                    elseif("no"         -eq $UserParams.WriteHistFile){2}
                    else{0}
                    )
                    $GUIParams.ChBx_CheckHashHist.IsChecked =        $UserParams.HistCompareHashes
                    $GUIParams.ChBx_OutputDupli.IsChecked =          $UserParams.CheckOutputDupli
                    $GUIParams.ChBx_AvoidIdenticalFiles.IsChecked =  $UserParams.AvoidIdenticalFiles
                    $GUIParams.ChBx_AcceptTimeDiff.IsChecked =       $UserParams.AcceptTimeDiff
                # DEFINITION: (Re)naming:
                    $GUIParams.TeBx_OutSubStyle.Text =   $UserParams.OutputSubfolderStyle
                    $GUIParams.TeBx_OutFileStyle.Text =  $UserParams.OutputFileStyle
                # DEFINITION: Other options:
                    $GUIParams.ChBx_InSubSearch.IsChecked =              $UserParams.InputSubfolderSearch
                    $GUIParams.ChBx_VerifyCopies.IsChecked =             $UserParams.VerifyCopies
                    $GUIParams.ChBx_OverwriteExistingFiles.IsChecked =   $UserParams.OverwriteExistingFiles
                    $GUIParams.ChBx_EnableLongPaths.IsChecked =          $UserParams.EnableLongPaths
                    $GUIParams.ChBx_ZipMirror.IsChecked =                $UserParams.ZipMirror
                    $GUIParams.ChBx_UnmountInputDrive.IsChecked =        $UserParams.UnmountInputDrive
                    $GUIParams.ChBx_PreventStandby.IsChecked =           $script:PreventStandby
                    $GUIParams.ChBx_RememberSettings.IsChecked =         $UserParams.RememberSettings
        # DEFINITION: Load-Preset-Button:
            $GUIParams.Butn_LoadPreset.Add_Click({
                if($jsonparams.ParamPresetName -is [array]){
                    for($i=0; $i -lt $jsonparams.ParamPresetName.Length; $i++){
                        if($i -eq $GUIParams.CoBx_LoadPreset.SelectedIndex){
                            [string]$UserParams.LoadParamPresetName = $jsonparams.ParamPresetName[$i]
                        }
                    }
                }else{
                    [string]$UserParams.LoadParamPresetName = $jsonparams.ParamPresetName
                }
                $Form.Close()
                Read-JsonParameters -UserParams $UserParams -Renew 1
                Start-Sleep -Milliseconds 2
                Start-GUI -GUIPath $GUIPath -UserParams $UserParams
            })
    # DEFINITION: InPath-Button:
            $GUIParams.Butn_SearchIn.Add_Click({
                try{
                    Get-GUIFolder -ToInfluence "input" -GUIParams $GUIParams
                }catch{
                    Write-ColorOut "Get-GUIFolder input failed." -ForegroundColor Red
                }
            })
    # DEFINITION: OutPath-Button:
            $GUIParams.Butn_SearchOut.Add_Click({
                try{
                    Get-GUIFolder -ToInfluence "output" -GUIParams $GUIParams
                }catch{
                    Write-ColorOut "Get-GUIFolder output failed." -ForegroundColor Red
                }
            })
    # DEFINITION: MirrorPath-Button:
            $GUIParams.Butn_SearchMirror.Add_Click({
                try{
                    Get-GUIFolder -ToInfluence "mirror" -GUIParams $GUIParams
                }catch{
                    Write-ColorOut "Get-GUIFolder mirror failed." -ForegroundColor Red
                }
            })
    # DEFINITION: HistoryPath-Button:
            $GUIParams.Butn_SearchHistFile.Add_Click({
                try{
                    Get-GUIFolder -ToInfluence "histfile" -GUIParams $GUIParams
                }catch{
                    Write-ColorOut "Get-GUIFolder histfile failed." -ForegroundColor Red
                }
            })
    # DEFINITION: Start-Button:
            $GUIParams.Butn_Start.Add_Click({
                [array]$UserParams.FormatInExclude = @()
                $separator = "|"
                $option = [System.StringSplitOptions]::RemoveEmptyEntries
                # $SaveParamPresetName
                $UserParams.SaveParamPresetName = $($GUIParams.TeBx_SavePreset.Text.ToLower() -Replace '[^A-Za-z0-9_+-]','')
                $UserParams.SaveParamPresetName = $UserParams.SaveParamPresetName.Substring(0, [math]::Min($UserParams.SaveParamPresetName.Length, 64))
                # $InputPath
                $UserParams.InputPath =     @($GUIParams.TeBx_Input.Text.Replace(" ",'').Split($separator,$option))
                # $OutputPath
                $UserParams.OutputPath =    $GUIParams.TeBx_Output.Text
                # $MirrorEnable
                $UserParams.MirrorEnable = $(
                    if($GUIParams.ChBx_Mirror.IsChecked -eq $true){1}
                    else{0}
                )
                # $MirrorPath
                if($GUIParams.ChBx_Mirror.IsChecked -eq $true){
                    $UserParams.MirrorPath = $GUIParams.TeBx_Mirror.Text
                }
                # $FormatPreference
                $UserParams.FormatPreference = $(
                    if($GUIParams.RaBn_All.IsChecked -eq          $true){"all"}
                    elseif($GUIParams.RaBn_Include.IsChecked -eq  $true){"include"}
                    elseif($GUIParams.RaBn_Exclude.IsChecked -eq  $true){"exclude"}
                )
                # $FormatInExclude
                $UserParams.FormatInExclude = $(
                    if($GUIParams.RaBn_All.IsChecked -eq          $true){@("*")}
                    elseif($GUIParams.RaBn_Include.IsChecked -eq  $true){
                        @($GUIParams.TeBx_Include.Text.Split($separator,$option))
                    }
                    elseif($GUIParams.RaBn_Exclude.IsChecked -eq  $true){
                        @($GUIParams.TeBx_Exclude.Text.Replace(" ",'').Split($separator,$option))
                    }
                )
                # $OutputSubfolderStyle
                $UserParams.OutputSubfolderStyle =  $GUIParams.TeBx_OutSubStyle.Text
                # $OutputFileStyle
                $UserParams.OutputFileStyle =       $GUIParams.TeBx_OutFileStyle.Text
                # $UseHistFile
                $UserParams.UseHistFile = $(
                    if($GUIParams.ChBx_UseHistFile.IsChecked -eq $true){1}
                    else{0}
                )
                # $WriteHistFile
                $UserParams.WriteHistFile = $(
                    if($GUIParams.CoBx_WriteHistFile.SelectedIndex -eq 0){"yes"}
                    elseif($GUIParams.CoBx_WriteHistFile.SelectedIndex -eq 1){"overwrite"}
                    elseif($GUIParams.CoBx_WriteHistFile.SelectedIndex -eq 2){"no"}
                )
                # $HistFilePath
                $UserParams.HistFilePath = $GUIParams.TeBx_HistFile.Text
                # $HistCompareHashes
                $UserParams.HistCompareHashes = $(
                    if($GUIParams.ChBx_CheckHashHist.IsChecked -eq $true){1}
                    else{0}
                )
                # $CheckOutputDupli
                $UserParams.CheckOutputDupli = $(
                    if($GUIParams.ChBx_OutputDupli.IsChecked -eq $true){1}
                        else{0}
                )
                # $AvoidIdenticalFiles
                $UserParams.AvoidIdenticalFiles = $(
                    if($GUIParams.ChBx_AvoidIdenticalFiles.IsChecked -eq $true){1}
                    else{0}
                )
                # $AcceptTimeDiff
                $UserParams.AcceptTimeDiff = $(
                    if($GUIParams.ChBx_AcceptTimeDiff.IsChecked -eq $true){1}
                    else{0}
                )
                # $InputSubfolderSearch
                $UserParams.InputSubfolderSearch = $(
                    if($GUIParams.ChBx_InSubSearch.IsChecked -eq $true){1}
                    else{0}
                )
                # $VerifyCopies
                $UserParams.VerifyCopies = $(
                    if($GUIParams.ChBx_VerifyCopies.IsChecked -eq $true){1}
                    else{0}
                )
                # $OverwriteExistingFiles
                $UserParams.OverwriteExistingFiles = $(
                    if($GUIParams.ChBx_OverwriteExistingFiles.IsChecked -eq $true){1}
                    else{0}
                )
                # $EnableLongPaths
                $UserParams.EnableLongPaths = $(
                    if($GUIParams.ChBx_EnableLongPaths.IsChecked -eq $true){1}
                    else{0}
                )
                # $ZipMirror
                $UserParams.ZipMirror = $(
                    if($GUIParams.ChBx_ZipMirror.IsChecked -eq $true){1}
                    else{0}
                )
                # $UnmountInputDrive
                $UserParams.UnmountInputDrive = $(
                    if($GUIParams.ChBx_UnmountInputDrive.IsChecked -eq $true){1}
                    else{0}
                )
                # $PreventStandby (SCRIPT VAR)
                $script:PreventStandby = $(
                    if($GUIParams.ChBx_PreventStandby.IsChecked -eq $true){1}
                    else{0}
                )
                # $RememberInPath
                $UserParams.RememberInPath = $(
                    if($GUIParams.ChBx_RememberIn.IsChecked -eq $true){1}
                    else{0}
                )
                # $RememberOutPath
                $UserParams.RememberOutPath = $(
                    if($GUIParams.ChBx_RememberOut.IsChecked -eq $true){1}
                    else{0}
                )
                # $RememberMirrorPath
                $UserParams.RememberMirrorPath = $(
                    if($GUIParams.ChBx_RememberMirror.IsChecked -eq $true){1}
                    else{0}
                )
                # $RememberSettings
                $UserParams.RememberSettings = $(
                    if($GUIParams.ChBx_RememberSettings.IsChecked -eq $true){1}
                    else{0}
                )

                $Form.Close()
                Start-Everything -UserParams $UserParams
            })
    # DEFINITION: About-Button:
            $GUIParams.Butn_About.Add_Click({
                Start-Process powershell -ArgumentList "Get-Help $($PSCommandPath) -detailed" -NoNewWindow -Wait
            })
    # DEFINITION: Close-Button:
            $GUIParams.Butn_Close.Add_Click({
                $Form.Close()
                Invoke-Close
            })
    }catch{
        Write-ColorOut "Filling GUI failed!" -ForegroundColor Magenta -Indentation 4
        throw 'Filling GUI failed'
    }

    # DEFINITION: Start GUI:
        $Form.ShowDialog() | Out-Null
}

# DEFINITION: Get values from Params, then check the main input- and outputfolder:
# TODO: Array for InputPath
Function Test-UserValues(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Test-UserValues')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting user-values..." -ForegroundColor Cyan

    $invalidChars = "[{0}]" -f [RegEx]::Escape($([IO.Path]::GetInvalidFileNameChars() -join '' -replace '\\',''))
    $separator = '\:\\'

    # DEFINITION: $InputPath
        if($UserParams.InputPath.GetType().Name -ne "Object[]"){
            Write-ColorOut "Invalid choice of -InputPath. ($($UserParams.InputPath.GetType().Name))" -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -InputPath.'
        }
        for($i=0; $i -lt $UserParams.InputPath.Length; $i++){
            $inter = $UserParams.InputPath[$i] -Split $separator
            $inter[1] = $inter[1] -Replace $invalidChars
            $UserParams.InputPath[$i] = $inter -join "$([regex]::Unescape($separator))"
            if($UserParams.InputPath[$i] -match '^.{3,}\\$'){
                $UserParams.InputPath[$i]= $UserParams.InputPath[$i] -Replace '\\$',''
            }

            if($UserParams.InputPath[$i].Length -lt 2 -or (Test-Path -LiteralPath $UserParams.InputPath[$i] -PathType Container -ErrorAction SilentlyContinue) -eq $false){
                Write-ColorOut "Input-path $($UserParams.InputPath[$i]) could not be found." -ForegroundColor Red -Indentation 4
                throw 'Input-path could not be found.'
            }
        }
    # DEFINITION: $OutputPath
        $inter = $UserParams.OutputPath -Split $separator
        $inter[1] = $inter[1] -Replace $invalidChars
        $UserParams.OutputPath = $inter -join "$([regex]::Unescape($separator))"
        if($UserParams.OutputPath -match '^.{3,}\\$'){
            $UserParams.OutputPath = $UserParams.OutputPath -Replace '\\$',''
        }

        if($UserParams.OutputPath -in $UserParams.InputPath){
            Write-ColorOut "Output-path $($UserParams.OutputPath) is the same as input-path." -ForegroundColor Red -Indentation 4
            throw 'Output-path $UserParams.OutputPath is the same as input-path.'
        }
        if($UserParams.OutputPath.Length -lt 2 -or (Test-Path -LiteralPath $UserParams.OutputPath -PathType Container -ErrorAction SilentlyContinue) -eq $false){
            if((Split-Path -Parent -Path $UserParams.OutputPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $UserParams.OutputPath) -PathType Container -ErrorAction SilentlyContinue) -eq $true){
                try{
                    [string]$inter = $UserParams.OutputPath.Substring(0, [math]::Min($UserParams.OutputPath.Length, 250))
                    if($inter -ne $UserParams.OutputPath){
                        Write-ColorOut "OutputPath was longer than 250 characters - shortened it to 250 to allow files to be named." -ForegroundColor Magenta -Indentation 4
                        $UserParams.OutputPath = $inter
                    }
                    New-LongItem -ItemType Directory -Path $UserParams.OutputPath -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
                    Write-ColorOut "Output-path $($UserParams.OutputPath) created." -ForegroundColor Yellow -Indentation 4
                }catch{
                    Write-ColorOut "Could not create output-path $($UserParams.OutputPath)." -ForegroundColor Red -Indentation 4
                    throw 'Could not create output-path $UserParams.OutputPath.'
                }
            }else{
                Write-ColorOut "Output-path $($UserParams.OutputPath) not found." -ForegroundColor Red -Indentation 4
                throw 'Output-path $UserParams.OutputPath not found.'
            }
        }
    # DEFINITION: $MirrorEnable
        if($UserParams.MirrorEnable -notin (0..1)){
            Write-ColorOut "Invalid choice of -MirrorEnable." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -MirrorEnable.'
        }
    # DEFINITION: $MirrorPath
        [array]$inter = $UserParams.MirrorPath -Split $separator
        $inter[1] = $inter[1] -Replace $invalidChars
        $UserParams.MirrorPath = $inter -join "$([regex]::Unescape($separator))"
        if($UserParams.MirrorPath -match '^.{3,}\\$'){
            $UserParams.MirrorPath = $UserParams.MirrorPath -Replace '\\$',''
        }

        if($UserParams.MirrorEnable -eq 1){
            if($UserParams.MirrorPath -in $UserParams.InputPath -or $UserParams.MirrorPath -eq $UserParams.OutputPath){
                Write-ColorOut "Additional output-path $($UserParams.MirrorPath) is the same as input- or output-path." -ForegroundColor Red -Indentation 4
                throw 'Additional output-path $UserParams.MirrorPath is the same as input- or output-path.'
            }
            if($UserParams.MirrorPath.Length -lt 2 -or (Test-Path -LiteralPath $UserParams.MirrorPath -PathType Container -ErrorAction SilentlyContinue) -eq $false){
                if((Split-Path -Parent -Path $UserParams.MirrorPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $UserParams.MirrorPath) -PathType Container -ErrorAction SilentlyContinue) -eq $true){
                    try{
                        [string]$inter = $UserParams.MirrorPath.Substring(0, [math]::Min($UserParams.MirrorPath.Length, 250))
                        if($inter -ne $UserParams.MirrorPath){
                            Write-ColorOut "MirrorPath was longer than 250 characters - shortened it to 250 to allow files to be named." -ForegroundColor Magenta -Indentation 4
                            $UserParams.MirrorPath = $inter
                        }
                        New-LongItem -ItemType Directory -Path $UserParams.MirrorPath -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
                        Write-ColorOut "Mirror-path $($UserParams.MirrorPath) created." -ForegroundColor Yellow -Indentation 4
                    }catch{
                        Write-ColorOut "Could not create mirror-path $($UserParams.MirrorPath)." -ForegroundColor Red -Indentation 4
                        throw 'Could not create mirror-path $UserParams.MirrorPath).'
                    }
                }else{
                    Write-ColorOut "Additional output-path $($UserParams.MirrorPath) not found." -ForegroundColor Red -Indentation 4
                    throw 'Additional output-path $UserParams.MirrorPath not found.'
                }
            }
        }
    # DEFINITION: $FormatPreference
        if((Compare-Object @("all","include","in","exclude","ex") $UserParams.FormatPreference | Where-Object {$_.sideindicator -eq "=>"}).count -ne 0){
            Write-ColorOut "Invalid choice of -FormatPreference." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -FormatPreference.'
        }elseif($UserParams.FormatPreference -eq "all"){
            $UserParams.FormatInExclude = @("*")
        }
    # DEFINITION: $FormatInExclude
        if($UserParams.FormatInExclude.GetType().Name -ne "Object[]"){
            Write-ColorOut "Invalid choice of -FormatInExclude." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -FormatInExclude.'
        }
    # DEFINITION: $OutputSubfolderStyle
        $invalidChars = "[{0}]" -f [RegEx]::Escape($([IO.Path]::GetInvalidFileNameChars() -join ''))
        $UserParams.OutputSubfolderStyle = $UserParams.OutputSubfolderStyle -Replace $invalidChars
        $UserParams.OutputSubfolderStyle = $UserParams.OutputSubfolderStyle.ToLower() -Replace $invalidChars -Replace '^\ +$',"" -Replace '\ +$',""
    # DEFINITION: $OutputFileStyle
        $invalidChars = "[{0}]" -f [RegEx]::Escape($([IO.Path]::GetInvalidFileNameChars() -join ''))
        $UserParams.OutputFileStyle = $UserParams.OutputFileStyle.ToLower() -Replace $invalidChars -Replace '^\ +$',"" -Replace '\ +$',""
        if($UserParams.OutputFileStyle.Length -lt 2 -or $UserParams.OutputFileStyle -match '^\s*$'){
            Write-ColorOut "Invalid choice of -OutputFileStyle." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -OutputFileStyle.'
        }
    # DEFINITION: $UseHistFile
        if($UserParams.UseHistFile -notin (0..1)){
            Write-ColorOut "Invalid choice of -UseHistFile." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -UseHistFile.'
        }
    # DEFINITION: $WriteHistFile
        [array]$inter=@("yes","no","overwrite")
        if($UserParams.WriteHistFile -notin $inter -or $UserParams.WriteHistFile.Length -gt $inter[2].Length){
            Write-ColorOut "Invalid choice of -WriteHistFile." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -WriteHistFile.'
        }
    # DEFINITION: $HistFilePath
        $invalidChars = "[{0}]" -f [RegEx]::Escape($([IO.Path]::GetInvalidFileNameChars() -join '' -replace '\\',''))
        $separator = '\:\\'
        $inter = $UserParams.HistFilePath -Split $separator
        $inter[1] = $inter[1] -Replace $invalidChars
        $UserParams.HistFilePath = $inter -join "$([regex]::Unescape($separator))"

        if(($UserParams.UseHistFile -eq 1 -or $UserParams.WriteHistFile -ne "no") -and (Test-Path -LiteralPath $UserParams.HistFilePath -PathType Leaf -ErrorAction SilentlyContinue) -eq $false){
            if((Split-Path -Parent -Path $UserParams.HistFilePath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $UserParams.HistFilePath) -PathType Container -ErrorAction SilentlyContinue) -eq $true){
                if($UserParams.UseHistFile -eq 1){
                    Write-ColorOut "-HistFilePath does not exist. Therefore, -UseHistFile will be disabled." -ForegroundColor Magenta -Indentation 4
                    $UserParams.UseHistFile = 0
                    Start-Sleep -Seconds 2
                }
            }else{
                Write-ColorOut "-HistFilePath $($UserParams.HistFilePath) could not be found." -ForegroundColor Red -Indentation 4
                throw '-HistFilePath $UserParams.HistFilePath could not be found.'
            }
        }
    # DEFINITION: $HistCompareHashes
        if($UserParams.HistCompareHashes -notin (0..1)){
            Write-ColorOut "Invalid choice of -HistCompareHashes." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -HistCompareHashes.'
        }
    # DEFINITION: $CheckOutputDupli
        if($UserParams.CheckOutputDupli -notin (0..1)){
            Write-ColorOut "Invalid choice of -CheckOutputDupli." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -CheckOutputDupli.'
        }
    # DEFINITION: $AvoidIdenticalFiles
        if($UserParams.AvoidIdenticalFiles -notin (0..1)){
            Write-ColorOut "Invalid choice of -AvoidIdenticalFiles." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -AvoidIdenticalFiles.'
        }
    # DEFINITION: $AcceptTimeDiff
        if($UserParams.AcceptTimeDiff -notin (0..1)){
            Write-ColorOut "Invalid choice of -AcceptTimeDiff." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -AcceptTimeDiff.'
        }
    # DEFINITION: $InputSubfolderSearch
        if($UserParams.InputSubfolderSearch -notin (0..1)){
            Write-ColorOut "Invalid choice of -InputSubfolderSearch ($($UserParams.InputSubfolderSearch))." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -InputSubfolderSearch.'
        }elseif($UserParams.InputSubfolderSearch -eq 1){
            [switch]$UserParams.InputSubfolderSearch = $true
        }else{
            [switch]$UserParams.InputSubfolderSearch = $false
        }
    # DEFINITION: $VerifyCopies
        if($UserParams.VerifyCopies -notin (0..1)){
            Write-ColorOut "Invalid choice of -VerifyCopies." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -VerifyCopies.'
        }
    # DEFINITION: $OverwriteExistingFiles
        if($UserParams.OverwriteExistingFiles -notin (0..1)){
            Write-ColorOut "Invalid choice of -OverwriteExistingFiles." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -OverwriteExistingFiles.'
        }
    # DEFINITION: $EnableLongPaths
        if($UserParams.EnableLongPaths -notin (0..1)){
            Write-ColorOut "Invalid choice of -EnableLongPaths." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -EnableLongPaths.'
        }
    # DEFINITION: $ZipMirror
        if($UserParams.ZipMirror -notin (0..1)){
            Write-ColorOut "Invalid choice of -ZipMirror." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -ZipMirror.'
        }
    # DEFINITION: $UnmountInputDrive
        if($UserParams.UnmountInputDrive -notin (0..1)){
            Write-ColorOut "Invalid choice of -UnmountInputDrive." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -UnmountInputDrive.'
        }
    # DEFINITION: $PreventStandby (SCRIPT VAR)
        if($script:PreventStandby -notin (0..1)){
            Write-ColorOut "Invalid choice of -PreventStandby." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -PreventStandby.'
        }
    # DEFINITION: $RememberInPath
        if($UserParams.RememberInPath -notin (0..1)){
            Write-ColorOut "Invalid choice of -RememberInPath." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -RememberInPath.'
        }
    # DEFINITION: $RememberOutPath
        if($UserParams.RememberOutPath -notin (0..1)){
            Write-ColorOut "Invalid choice of -RememberOutPath." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -RememberOutPath.'
        }
    # DEFINITION: $RememberMirrorPath
        if($UserParams.RememberMirrorPath -notin (0..1)){
            Write-ColorOut "Invalid choice of -RememberMirrorPath." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -RememberMirrorPath.'
        }
    # DEFINITION: $RememberSettings
        if($UserParams.RememberSettings -notin (0..1)){
            Write-ColorOut "Invalid choice of -RememberSettings." -ForegroundColor Red -Indentation 4
            throw 'Invalid choice of -RememberSettings.'
        }

    # DEFINITION: If everything was sucessful, return UserParams:
    return $UserParams
}

# DEFINITION: Show parameters on the console, then exit:
Function Show-Parameters(){
    param(
        [hashtable]$UserParams = $(Write-ColorOut 'UserParams is required by Show-Parameters' -ForegroundColor Magenta)
    )
    Write-ColorOut "Parameters:" -ForegroundColor Green
    Write-ColorOut "-EnableGUI`t`t`t=`t$($UserParams.EnableGUI)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-JSONParamPath`t`t=`t$($UserParams.JSONParamPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-LoadParamPresetName`t=`t$($UserParams.LoadParamPresetName)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-SaveParamPresetName`t=`t$($UserParams.SaveParamPresetName)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberInPath`t`t=`t$($UserParams.RememberInPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberOutPath`t`t=`t$($UserParams.RememberOutPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberMirrorPath`t`t=`t$($UserParams.RememberMirrorPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberSettings`t`t=`t$($UserParams.RememberSettings)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-Debug`t`t`t=`t$($script:InfoPreference)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "These values come from $($UserParams.JSONParamPath):" -ForegroundColor DarkCyan -Indentation 2
    Write-ColorOut "-InputPath`t`t`t=`t$($UserParams.InputPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputPath`t`t`t=`t$($UserParams.OutputPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-MirrorEnable`t`t=`t$($UserParams.MirrorEnable)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-MirrorPath`t`t`t=`t$($UserParams.MirrorPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-FormatPreference`t`t=`t$($UserParams.FormatPreference)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-FormatInExclude`t`t=`t$($UserParams.FormatInExclude)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputSubfolderStyle`t=`t$($UserParams.OutputSubfolderStyle)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputFileStyle`t`t=`t$($UserParams.OutputFileStyle)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-HistFilePath`t`t=`t$($UserParams.HistFilePath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-UseHistFile`t`t=`t$($UserParams.UseHistFile)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-WriteHistFile`t`t=`t$($UserParams.WriteHistFile)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-HistCompareHashes`t`t=`t$($UserParams.HistCompareHashes)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-CheckOutputDupli`t`t=`t$($UserParams.CheckOutputDupli)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-InputSubfolderSearch`t=`t$($UserParams.InputSubfolderSearch)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-AvoidIdenticalFiles`t=`t$($UserParams.AvoidIdenticalFiles)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-AcceptTimeDiff`t=`t$($UserParams.AcceptTimeDiff)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-VerifyCopies`t`t=`t$($UserParams.VerifyCopies)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OverwriteExistingFiles`t=`t$($UserParams.OverwriteExistingFiles)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-EnableLongPaths`t`t=`t$($UserParams.EnableLongPaths)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-ZipMirror`t`t`t=`t$($UserParams.ZipMirror)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-UnmountInputDrive`t`t=`t$($UserParams.UnmountInputDrive)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-PreventStandby`t`t=`t$($script:PreventStandby)" -ForegroundColor Cyan -Indentation 4
}

# DEFINITION: If checked, remember values for future use:
Function Write-JsonParameters(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Show-Parameters')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Remembering parameters as preset `"$($UserParams.SaveParamPresetName)`"..." -ForegroundColor Cyan

    [array]$inter = @(
        [PSCustomObject]@{
            ParamPresetName     = $UserParams.SaveParamPresetName
            ParamPresetValues   = [PSCustomObject]@{
                InputPath               = $UserParams.InputPath
                OutputPath              = $UserParams.OutputPath
                MirrorEnable            = $UserParams.MirrorEnable
                MirrorPath              = $UserParams.MirrorPath
                FormatPreference        = $UserParams.FormatPreference
                FormatInExclude         = $UserParams.FormatInExclude
                OutputSubfolderStyle    = $UserParams.OutputSubfolderStyle
                OutputFileStyle         = $UserParams.OutputFileStyle
                HistFilePath            = $UserParams.HistFilePath.Replace($PSScriptRoot,'$($PSScriptRoot)')
                UseHistFile             = $UserParams.UseHistFile
                WriteHistFile           = $UserParams.WriteHistFile
                HistCompareHashes       = $UserParams.HistCompareHashes
                CheckOutputDupli        = $UserParams.CheckOutputDupli
                AvoidIdenticalFiles     = $UserParams.AvoidIdenticalFiles
                AcceptTimeDiff          = $UserParams.AcceptTimeDiff
                InputSubfolderSearch    = $(if($UserParams.InputSubfolderSearch -eq $true){1}else{0})
                VerifyCopies            = $UserParams.VerifyCopies
                OverwriteExistingFiles  = $UserParams.OverwriteExistingFiles
                EnableLongPaths         = $UserParams.EnableLongPaths
                ZipMirror               = $UserParams.ZipMirror
                UnmountInputDrive       = $UserParams.UnmountInputDrive
                PreventStandby          = $script:PreventStandby
            }
        }
    )

    if((Test-Path -LiteralPath $UserParams.JSONParamPath -PathType Leaf -ErrorAction SilentlyContinue) -eq $true){
        try{
            $jsonparams = @()
            $jsonparams += Get-Content -LiteralPath $UserParams.JSONParamPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            if($script:InfoPreference -gt 1){
                Write-ColorOut "From:" -ForegroundColor Yellow -Indentation 2
                $jsonparams | ConvertTo-Json -ErrorAction Stop | Out-Host
            }
        }catch{
            Write-ColorOut "Getting parameters from $($UserParams.JSONParamPath) failed - aborting!" -ForegroundColor Red
            Start-Sleep -Seconds 5
            throw 'Getting parameters from $UserParams.JSONParamPath failed'
        }
        if($jsonparams.ParamPresetName.GetType().Name -eq "Object[]" -and $inter.ParamPresetName -in $jsonparams.ParamPresetName){
            Write-ColorOut "Preset $($inter.ParamPresetName) will be updated." -ForegroundColor DarkGreen -Indentation 4
            for($i=0; $i -lt $jsonparams.ParamPresetName.Length; $i++){
                if($jsonparams.ParamPresetName[$i] -eq $inter.ParamPresetName){
                    if($UserParams.RememberInPath -eq 1){
                        $jsonparams.ParamPresetValues[$i].InputPath     = $inter.ParamPresetValues.InputPath
                    }
                    if($UserParams.RememberOutPath -eq 1){
                        $jsonparams.ParamPresetValues[$i].OutputPath    = $inter.ParamPresetValues.OutputPath
                    }
                    if($UserParams.RememberMirrorPath -eq 1){
                        $jsonparams.ParamPresetValues[$i].MirrorPath    = $inter.ParamPresetValues.MirrorPath
                    }
                    if($UserParams.RememberSettings -eq 1){
                        $jsonparams.ParamPresetValues[$i].MirrorEnable              = $inter.ParamPresetValues.MirrorEnable
                        $jsonparams.ParamPresetValues[$i].FormatPreference          = $inter.ParamPresetValues.FormatPreference
                        $jsonparams.ParamPresetValues[$i].FormatInExclude           = @($inter.ParamPresetValues.FormatInExclude)
                        $jsonparams.ParamPresetValues[$i].OutputSubfolderStyle      = $inter.ParamPresetValues.OutputSubfolderStyle
                        $jsonparams.ParamPresetValues[$i].OutputFileStyle           = $inter.ParamPresetValues.OutputFileStyle
                        $jsonparams.ParamPresetValues[$i].HistFilePath              = $inter.ParamPresetValues.HistFilePath
                        $jsonparams.ParamPresetValues[$i].UseHistFile               = $inter.ParamPresetValues.UseHistFile
                        $jsonparams.ParamPresetValues[$i].WriteHistFile             = $inter.ParamPresetValues.WriteHistFile
                        $jsonparams.ParamPresetValues[$i].HistCompareHashes         = $inter.ParamPresetValues.HistCompareHashes
                        $jsonparams.ParamPresetValues[$i].CheckOutputDupli          = $inter.ParamPresetValues.CheckOutputDupli
                        $jsonparams.ParamPresetValues[$i].AvoidIdenticalFiles       = $inter.ParamPresetValues.AvoidIdenticalFiles
                        $jsonparams.ParamPresetValues[$i].AcceptTimeDiff            = $inter.ParamPresetValues.AcceptTimeDiff
                        $jsonparams.ParamPresetValues[$i].InputSubfolderSearch      = $inter.ParamPresetValues.InputSubfolderSearch
                        $jsonparams.ParamPresetValues[$i].VerifyCopies              = $inter.ParamPresetValues.VerifyCopies
                        $jsonparams.ParamPresetValues[$i].OverwriteExistingFiles    = $inter.ParamPresetValues.OverwriteExistingFiles
                        $jsonparams.ParamPresetValues[$i].EnableLongPaths           = $inter.ParamPresetValues.EnableLongPaths
                        $jsonparams.ParamPresetValues[$i].ZipMirror                 = $inter.ParamPresetValues.ZipMirror
                        $jsonparams.ParamPresetValues[$i].UnmountInputDrive         = $inter.ParamPresetValues.UnmountInputDrive
                        $jsonparams.ParamPresetValues[$i].PreventStandby            = $inter.ParamPresetValues.PreventStandby
                    }
                }
            }
        }elseif($jsonparams.ParamPresetName.GetType().Name -ne "Object[]" -and $UserParams.SaveParamPresetName -eq $jsonparams.ParamPresetName){
            Write-ColorOut "Preset $($inter.ParamPresetName) will be the only preset." -ForegroundColor Yellow -Indentation 4
            $jsonparams = $inter
        }else{
            Write-ColorOut "Preset $($inter.ParamPresetName) will be added." -ForegroundColor Green -Indentation 4
            $jsonparams += $inter
        }
    }else{
        Write-ColorOut "No preset-file found." -ForegroundColor Magenta -Indentation 4
        $jsonparams = $inter
    }
    $jsonparams | Out-Null
    $jsonparams = $jsonparams | ConvertTo-Json -Depth 5
    $jsonparams | Out-Null

    if($script:InfoPreference -gt 1){
        Write-ColorOut "To:" -ForegroundColor Yellow -Indentation 2
        $jsonparams | Out-Host
    }

    [int]$i = 0
    while($true){
        try{
            Out-File -LiteralPath $UserParams.JSONParamPath -InputObject $jsonparams -Encoding utf8 -ErrorAction Stop
            break
        }catch{
            if($i -lt 5){
                Write-ColorOut "Writing to parameter-file failed! Trying again..." -ForegroundColor Magenta -Indentation 4
                Start-Sleep -Seconds 5
                $i++
                Continue
            }else{
                Write-ColorOut "Writing to parameter-file failed!" -ForegroundColor Magenta -Indentation 4
                throw 'Writing to parameter-file failed'
            }
        }
    }
}

# DEFINITION: Searching for selected formats in Input-Path, getting Path, Name, Time, and calculating Hash:
Function Get-InFiles(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Get-InFiles')
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-CurrentDate)  --  Finding files." -ForegroundColor Cyan

    # pre-defining variables:
    [array]$InFiles = @()
    $script:resultvalues = @{}

    # Search files and get some information about them:
    [array]$allChosenFormats = $(
        if($UserParams.FormatPreference -in @("include","in")){@($UserParams.FormatInExclude)}
        else{@("*")}  # Excluded will be filtered after the search
    )
    [int]$counter = 1
    for($i=0;$i -lt $allChosenFormats.Length; $i++){
        foreach($k in $UserParams.InputPath){
            if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
                Write-Progress -Id 1 -Activity "Find files in $($k)..." -PercentComplete $((($i* 100) / $($allChosenFormats.Length))) -Status "Format #$($i + 1) / $($allChosenFormats.Length)"
                $sw.Reset()
                $sw.Start()
            }

            $InFiles += Get-ChildItem -LiteralPath $k -Filter $allChosenFormats[$i] -Recurse:$UserParams.InputSubfolderSearch -File | ForEach-Object -Process {
                if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
                    Write-Progress -Id 2 -Activity "Looking for files..." -PercentComplete -1 -Status "File #$counter - $($_.FullName.Replace("$($k)",'.'))"
                    $sw.Reset()
                    $sw.Start()
                }
                $counter++
                [PSCustomObject]@{
                    InFullName = $_.FullName
                    InSubfolder = $($(Split-Path -Parent -Path $_.FullName).Replace("$($k)","")) -Replace('^\\','')
                    InPath = (Split-Path -Path $_.FullName -Parent)
                    InName = $_.Name
                    InBaseName = $_.BaseName
                    Extension = $_.Extension
                    Size = $_.Length
                    Date = ([DateTimeOffset]$_.LastWriteTimeUtc).ToUnixTimeSeconds()
                    OutSubfolder = ""
                    OutPath = ""
                    OutName = ""
                    OutBaseName = ""
                    InHash = "ZYX"
                    OutHash = "ZYX"
                    ToCopy = 1
                }
            } -End {
                Write-Progress -Id 2 -Activity "Looking for files..." -Status "Done!" -Completed
            }
        }
    }
    Write-Progress -Id 1 -Activity "Find files in $($k)..." -Status "Done!" -Completed
    $sw.Reset()

    if($UserParams.FormatPreference -in @("exclude","ex")){
        foreach($i in $UserParams.FormatInExclude){
            [array]$InFiles = @($InFiles | Where-Object {$_.InName -notlike $i})
        }
        $InFiles | Out-Null
    }
    $InFiles = $InFiles | Sort-Object -Property InFullName
    $InFiles | Out-Null

    if($script:InfoPreference -gt 1){
        if((Read-Host "    Show all found files? Positive answers: $script:PositiveAnswers") -in $script:PositiveAnswers){
            for($i=0; $i -lt $InFiles.Length; $i++){
                Write-ColorOut "$($InFiles[$i].InFullName.Replace($UserParams.InputPath,"."))" -ForegroundColor Gray -Indentation 4
            }
        }
    }

    Write-ColorOut "Total in-files:`t$($InFiles.Length)" -ForegroundColor Yellow -Indentation 4
    $script:resultvalues.ingoing = $InFiles.Length

    return $InFiles
}

# DEFINITION: Get History-File:
Function Read-JsonHistory(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Read-JsonHistory')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Checking for history-file, importing values..." -ForegroundColor Cyan

    [array]$files_history = @()
    if((Test-Path -LiteralPath $UserParams.HistFilePath -PathType Leaf) -eq $true){
        try{
            $JSONFile = Get-Content -LiteralPath $UserParams.HistFilePath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-JSON -ErrorAction Stop
        }catch{
            Write-ColorOut "Could not load $($UserParams.HistFilePath)." -ForegroundColor Red -Indentation 4
            Start-Sleep -Seconds 5
            throw 'Could not load $UserParams.HistFilePath.'
        }
        $JSONFile | Out-Null
        $files_history += $JSONFile | ForEach-Object {
            [PSCustomObject]@{
                InName = $_.N
                Date = $_.D
                Size = $_.S
                Hash = $_.H
            }
        }
        $files_history | Out-Null

        if($script:InfoPreference -gt 1){
            if((Read-Host "    Show found history-values? Positive answers: $script:PositiveAnswers") -in $script:PositiveAnswers){
                Write-ColorOut "Found values: $($files_history.Length)" -ForegroundColor Yellow -Indentation 4
                $files_history | Format-Table -AutoSize | Out-Host
            }
        }

        if("null" -in $files_history -or $files_history.InName.Length -lt 1 -or ($files_history.Length -gt 1 -and (($files_history.InName.Length -ne $files_history.Date.Length) -or ($files_history.InName.Length -ne $files_history.Size.Length) -or ($files_history.InName.Length -ne $files_history.Hash.Length) -or ($files_history.InName -contains $null) -or ($files_history.Date -contains $null) -or ($files_history.Size -contains $null) -or ($files_history.Hash -contains $null)))){
            Write-ColorOut "Some values in the history-file $($UserParams.HistFilePath) seem wrong - it's safest to delete the whole file." -ForegroundColor Magenta -Indentation 4
            Write-ColorOut "InNames: $($files_history.InName.Length) Dates: $($files_history.Date.Length) Sizes: $($files_history.Size.Length) Hashes: $($files_history.Hash.Length)" -Indentation 4
            if((Read-Host "    Is that okay? Positive answers: $script:PositiveAnswers") -in $script:PositiveAnswers){
                return @()
            }else{
                Write-ColorOut "`r`n`tAborting.`r`n" -ForegroundColor Magenta
                throw 'Aborting.'
            }
        }
        if("ZYX" -in $files_history.Hash -and $UserParams.HistCompareHashes -eq 1){
            Write-ColorOut "Some hash-values in the history-file are missing (because -VerifyCopies wasn't activated when they were added). This could lead to duplicates." -ForegroundColor Magenta -Indentation 4
            Start-Sleep -Seconds 2
        }
    }else{
        Write-ColorOut "History-File $($UserParams.HistFilePath) could not be found. This means it's possible that duplicates get copied." -ForegroundColor Magenta -Indentation 4
        if((Read-Host "    Is that okay? Positive answers: $script:PositiveAnswers") -in $script:PositiveAnswers){
            return @()
        }else{
            Write-ColorOut "`r`n`tAborting.`r`n" -ForegroundColor Magenta
            throw 'Aborting.'
        }
    }

    return $files_history
}

# DEFINITION: dupli-check via history-file:
Function Test-DupliHist(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles = $(throw 'InFiles is required by Test-DupliHist'),
        [ValidateNotNullOrEmpty()]
        [array]$HistFiles = $(throw 'HistFiles is required by Test-DupliHist'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Test-DupliHist')
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-CurrentDate)  --  Checking for duplicates via history-file." -ForegroundColor Cyan

    $InFiles = $InFiles | Sort-Object -Property InName,Date,Size
    $InFiles | Out-Null
    $HistFiles = $HistFiles | Sort-Object -Property InName,Date,Size
    $HistFiles | Out-Null
    for($i=0; $i -lt $InFiles.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750){
            Write-Progress -Activity "Comparing input-files to already copied files (history-file).." -PercentComplete $($i * 100 / $InFiles.Length) -Status "File # $($i + 1) / $($InFiles.Length) - $($InFiles[$i].Name)"
            $sw.Reset()
            $sw.Start()
        }
        [int]$h = 0
        while($h -lt $HistFiles.Length){
            if($InFiles[$i].InName -eq $HistFiles[$h].InName `
            -and $InFiles[$i].Size -eq $HistFiles[$h].Size `
            -and (($UserParams.AcceptTimeDiff -eq 0 -and $InFiles[$i].Date -eq $HistFiles[$h].Date) -or ($UserParams.AcceptTimeDiff -eq 1 -and ([math]::Sqrt([math]::pow(($InFiles[$i].Date - $HistFiles[$h].Date), 2))) -le $script:TimeDiff))){
                if($UserParams.HistCompareHashes -eq 1){
                    if($InFiles[$i].InHash -match '^ZYX.*$') {
                        $InFiles[$i].InHash = (Get-FileHash -LiteralPath $InFiles[$i].InFullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash)
                    }
                    if($InFiles[$i].InHash -eq $HistFiles[$h].Hash) {
                        $InFiles[$i].ToCopy = 0
                        break
                    }else {
                        $h++
                        continue
                    }
                }else{
                    $InFiles[$i].ToCopy = 0
                    break
                }
            }else{
                $h++
            }
        }
    }
    Write-Progress -Activity "Comparing input-files to already copied files (history-file).." -Status "Done!" -Completed

    <# DOES NOT WORK AS INTENDED
        $properties = @("InName","Size")
        for($i=0; $i -lt $InFiles.Length; $i++){
            if($sw.Elapsed.TotalMilliseconds -ge 750){
                Write-Progress -Activity "Comparing input-files to already copied files (history-file).." -PercentComplete $($i * 100 / $InFiles.Length) -Status "File # $($i + 1) / $($InFiles.Length) - $($InFiles[$i].name)"
                $sw.Reset()
                $sw.Start()
            }

            $inter = @(Compare-Object -ReferenceObject $HistFiles -DifferenceObject $InFiles[$i] -Property $properties -ExcludeDifferent -IncludeEqual -PassThru -ErrorAction Stop)
            if($inter.Length -gt 0){
                if(($UserParams.AcceptTimeDiff -eq 1 -and ([math]::Sqrt([math]::pow(($InFiles[$i].Date - $inter.Date), 2))) -le $script:TimeDiff) -or ($UserParams.AcceptTimeDiff -eq 0 -and $InFiles[$i].Date -eq $inter.Date)){
                    if($UserParams.HistCompareHashes -eq 1){
                        $InFiles[$i].InHash = Get-FileHash -LiteralPath $InFiles[$i].InFullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash
                        if($InFiles[$i].InHash -in $inter.InHash){
                            $InFiles[$i].ToCopy = 0
                        }
                    }else{
                        $InFiles[$i].ToCopy = 0
                    }
                }
            }
        }
        Write-Progress -Activity "Comparing input-files to already copied files (history-file).." -Status "Done!" -Completed
    #>

    if($script:InfoPreference -gt 1){
        if((Read-Host "    Show result? Positive answers: $script:PositiveAnswers") -in $script:PositiveAnswers){
            Write-ColorOut "`r`n`tFiles to skip / process:" -ForegroundColor Yellow
            for($i=0; $i -lt $InFiles.Length; $i++){
                if($InFiles[$i].ToCopy -eq 1){
                    Write-ColorOut "Copy $($InFiles[$i].InFullName.Replace($UserParams.InputPath,"."))" -ForegroundColor Gray -Indentation 4
                }else{
                    Write-ColorOut "Omit $($InFiles[$i].InFullName.Replace($UserParams.InputPath,"."))" -ForegroundColor DarkGreen -Indentation 4
                }
            }
        }
    }

    Write-ColorOut "Files to skip:`t$($($InFiles | Where-Object {$_.ToCopy -eq 0}).count)" -ForegroundColor DarkGreen -Indentation 4
    $script:resultvalues.duplihist = $($InFiles | Where-Object {$_.ToCopy -eq 0}).count

    [array]$InFiles = @($InFiles | Where-Object {$_.ToCopy -eq 1})

    $sw.Reset()
    return $InFiles
}

# DEFINITION: dupli-check via output-folder:
Function Test-DupliOut(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Test-DupliOut'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Test-DupliOut')
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-CurrentDate)  --  Checking for duplicates in OutPath." -ForegroundColor Cyan

    # pre-defining variables:
    [array]$files_duplicheck = @()
    [int]$dupliindex_out = 0
    [array]$allChosenFormats = $(
        if($UserParams.FormatPreference -in @("include","in")){@($UserParams.FormatInExclude)}
        else{@("*")}
    )

    [int]$counter = 1
    for($i=0;$i -lt $allChosenFormats.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
            Write-Progress -Id 1 -Activity "Find files in $($UserParams.OutputPath)..." -PercentComplete $(($i / $($allChosenFormats.Length)) * 100) -Status "Format #$($i + 1) / $($allChosenFormats.Length)"
            $sw.Reset()
            $sw.Start()
        }

        $files_duplicheck += @(Get-ChildItem -LiteralPath $UserParams.OutputPath -Filter $allChosenFormats[$i] -Recurse -File | ForEach-Object -Process {
            if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
                Write-Progress -Id 2 -Activity "Looking for files..." -PercentComplete -1 -Status "File #$counter - $($_.FullName.Replace("$($UserParams.OutputPath)",'.'))"
                $sw.Reset()
                $sw.Start()
            }

            [PSCustomObject]@{
                InFullName = $_.FullName
                InName = $_.Name
                Size = $_.Length
                Date = ([DateTimeOffset]$($_.LastWriteTimeUtc)).ToUnixTimeSeconds()
                Hash = "niente"
            }
            $counter++
        } -End {
            Write-Progress -Id 2 -Activity "Looking for files..." -Status "Done!" -Completed
        })
    }
    Write-Progress -Id 1 -Activity "Find files in $($UserParams.OutputPath)..." -Status "Done!" -Completed
    $sw.Reset()

    if($UserParams.FormatPreference -in @("exclude","ex")){
        foreach($i in $UserParams.FormatInExclude){
            [array]$files_duplicheck = @($files_duplicheck | Where-Object {$_.InName -notlike $i})
        }
        $files_duplicheck | Out-Null
    }

    $sw.Start()
    if($files_duplicheck.Length -gt 0){
        $InFiles = $InFiles | Sort-Object -Property InName,Date,Size
        $InFiles | Out-Null
        $files_duplicheck = $files_duplicheck | Sort-Object -Property InName,Date,Size
        $files_duplicheck | Out-Null

        for($i=0; $i -lt $InFiles.Length; $i++){
            if($sw.Elapsed.TotalMilliseconds -ge 750){
                Write-Progress -Activity "Comparing input-files with files in output..." -PercentComplete $($i * 100 / $InFiles.Length) -Status "File # $($i + 1) / $($InFiles.Length) - $($InFiles[$i].Name)"
                $sw.Reset()
                $sw.Start()
            }
            [int]$h = 0
            while($h -lt $files_duplicheck.Length){
                if($InFiles[$i].InName -eq $files_duplicheck[$h].InName `
                -and $InFiles[$i].Size -eq $files_duplicheck[$h].Size `
                -and (($UserParams.AcceptTimeDiff -eq 0 -and $InFiles[$i].Date -eq $files_duplicheck[$h].Date) -or ($UserParams.AcceptTimeDiff -eq 1 -and ([math]::Sqrt([math]::pow(($InFiles[$i].Date - $files_duplicheck[$h].Date), 2))) -le $script:TimeDiff))){
                    if($InFiles[$i].InHash -match '^ZYX.*$') {
                        $InFiles[$i].InHash = (Get-FileHash -LiteralPath $InFiles[$i].InFullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash)
                    }
                    $files_duplicheck[$h].Hash = (Get-FileHash -LiteralPath $files_duplicheck[$h].InFullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash)
                    if($InFiles[$i].InHash -eq $files_duplicheck[$h].Hash) {
                        $InFiles[$i].ToCopy = 0
                        $dupliindex_out++
                        break
                    }else {
                        $h++
                        continue
                    }
                }else{
                    $h++
                }
            }

            if($script:InformationPreference -gt 1){
                if((Read-Host "    Show all files? Positive answers: $script:PositiveAnswers") -in $script:PositiveAnswers){
                    Write-ColorOut "`r`n`tFiles to skip / process:" -ForegroundColor Yellow
                    for($i=0; $i -lt $InFiles.Length; $i++){
                        if($InFiles[$i].ToCopy -eq 1){
                            Write-ColorOut "Copy $($InFiles[$i].FullName.Replace($UserParams.InputPath,"."))" -ForegroundColor Gray -Indentation 4
                        }else{
                            Write-ColorOut "Omit $($InFiles[$i].FullName.Replace($UserParams.InputPath,"."))" -ForegroundColor DarkGreen -Indentation 4
                        }
                    }
                }
            }
            Write-ColorOut "Files to skip (outpath):`t$dupliindex_out" -ForegroundColor DarkGreen -Indentation 4
        }
        Write-Progress -Activity "Comparing input-files with files in output..." -Status "Done!" -Completed

        # To add the already found files to the hist-file:
        [array]$script:dupliout = @($InFiles | Where-Object {$_.ToCopy -eq 0})
        [array]$InFiles = @($InFiles | Where-Object {$_.ToCopy -eq 1})

        $script:resultvalues.dupliout = $dupliindex_out
    }else{
        Write-ColorOut "No files in $($UserParams.OutputPath) - skipping additional verification." -ForegroundColor Magenta -Indentation 4
    }

    $sw.Reset()
    return $InFiles
}

# DEFINITION: Calculate hashes (if not yet done):
Function Get-InFileHash(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles = $(throw 'InFiles is required by Get-InFileHash')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Calculate remaining hashes..." -ForegroundColor Cyan

    if("ZYX" -in $InFiles.InHash){
        $InFiles | Where-Object {$_.InHash -match '^ZYX.*$'} | Start-RSJob -Name "GetHashRest" -FunctionsToLoad Write-ColorOut -ScriptBlock {
            try{
                $_.InHash = (Get-FileHash -LiteralPath $_.InFullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash)
            }catch{
                Write-ColorOut "Failed to get hash of `"$($_.InFullName)`"" -ForegroundColor Red -Indentation 4
                $_.InHash = "ZYXGetHashRestWRONG"
            }
        } | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob -Name "GetHashRest" | Remove-RSJob
    }else{
        Write-ColorOut "No more hashes to get!" -ForegroundColor DarkGreen -Indentation 4
    }

    return $InFiles
}

# DEFINITION: Avoid copying identical files from the input-path:
Function Clear-IdenticalInFiles(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles = $(throw 'InFiles is required by Clear-IdenticalInFiles'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Test-DupliOut')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Avoid identical input-files..." -ForegroundColor Cyan

    [array]$inter = @($InFiles | Sort-Object -Property InName,Date,Size,InHash -Unique)
    $inter | Out-Null
    if($UserParams.AcceptTimeDiff -eq 1){
        for($i=0; $i -lt $inter.Length; $i++){
            for($h=0; $h -lt $inter.Length; $h++){
                if($h -ne $i -and $inter[$i].ToCopy -eq 1 -and $inter[$h].ToCopy -eq 1){
                    if($inter[$i].InName -eq $inter[$h].InName `
                    -and $inter[$i].Size -eq $inter[$h].Size `
                    -and ($UserParams.AcceptTimeDiff -eq 1 -and ([math]::Sqrt([math]::pow(($inter[$i].Date - $inter[$h].Date), 2))) -le $script:TimeDiff) `
                    -and $inter[$i].InHash -eq $inter[$h].InHash){
                        $inter[$i].ToCopy = 0
                    }
                }
            }
        }
        [array]$inter = @($inter | Where-Object {$_.ToCopy -ne 0})
        $inter | Out-Null
    }
    if($inter.Length -ne $InFiles.Length){
        [array]$InFiles = @($inter)
        Write-ColorOut "$(($InFiles.Length - $inter.Length)) identical files were found in the input-path - only copying one of each." -ForegroundColor Magenta -Indentation 4
        Start-Sleep -Seconds 2
    }
    $script:resultvalues.identicalFiles = $($InFiles.Length - $inter.Length)
    $script:resultvalues.copyfiles = $InFiles.Length

    return $InFiles
}

# DEFINITION: Check for free space on the destination volume:
Function Test-DiskSpace(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Test-DiskSpace'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Test-DiskSpace')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Checking if free space is sufficient..." -ForegroundColor Cyan

    [string]$OutPath = Split-Path -Path $UserParams.OutputPath -Qualifier
    [int]$free = ((Get-PSDrive -PSProvider 'FileSystem' | Where-Object {$_.root -match $OutPath} | Select-Object -ExpandProperty Free)[0] / 1MB)
    [int]$needed = $(($InFiles | Measure-Object -Sum -Property Size | Select-Object -ExpandProperty Sum) / 1MB)

    if($needed -lt $free){
        Write-ColorOut "Free: $free MB`tNeeded: $needed MB  --  Okay!" -ForegroundColor Green -Indentation 4
        return $true
    }else{
        Write-ColorOut "Free: $free MB`tNeeded: $needed MB  --  Too big!" -ForegroundColor Red -Indentation 4
        return $false
    }
}

# DEFINITION: Check if filename already exists and if so, then choose new name for copying:
Function Protect-OutFileOverwrite(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Protect-OutFileOverwrite'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Protect-OutFileOverwrite'),
        [int]$Mirror =              $(throw 'Mirror is required by Protect-OutFileOverwrite')
    )
    if($Mirror -eq 1){
        $OutputPath = $UserParams.MirrorPath
    }else{
        $OutputPath = $UserParams.OutputPath
    }
    Write-ColorOut "$(Get-CurrentDate)  --  Prevent overwriting " -ForegroundColor Cyan -NoNewLine
    if($UserParams.OverwriteExistingFiles -eq 0){
        Write-ColorOut "both freshly copied and existing files..." -ForegroundColor Cyan
    }else{
        Write-ColorOut "only freshly copied files..." -ForegroundColor Cyan
    }

    Function Get-ShorterPath(){
        param(
            [ValidateNotNullOrEmpty()]
            [string]$InString =         $(throw 'InString is required by Get-ShorterPath'),
            [ValidateNotNullOrEmpty()]
            [hashtable]$UserParams =    $(throw 'UserParams is required by Get-ShorterPath'),
            [int]$maxpathlength =       $(throw 'maxpathlength is required by Get-ShorterPath')
        )

        [int]$1st = ([math]::Floor($maxpathlength/2) - 1)
        [int]$2nd = ([math]::Floor($maxpathlength/2) - 1)

        $InString = "$($InString.Substring(0, [math]::Min($InString.Length, $1st)))---$($InString.Substring([math]::Max($2nd, ($InString.Length - $2nd)), $2nd))"

        return $InString
    }

    [datetime]$unixOrigin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    $regexCounter = [regex]'%c.%'
    [array]$allpaths = @()
    $sw = [diagnostics.stopwatch]::StartNew()

    for($i=0; $i -lt $InFiles.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750 -or $i -eq 0){
            Write-Progress -Activity "Prevent overwriting existing files..." -PercentComplete $($i / $InFiles.Length * 100) -Status "File # $($i + 1) / $($InFiles.Length) - $($InFiles[$i].name)"
            $sw.Reset()
            $sw.Start()
        }
        if($InFiles[$i].ToCopy -eq 1){
            [int]$maxpathlength = (255 - 7 - $InFiles[$i].Extension.Length)

        # Subfolder renaming style:
        if($InFiles[$i].OutSubfolder -eq "" -and $UserParams.OutputSubfolderStyle.Length -ne 0){
            #no subfolder:
            if($UserParams.OutputSubfolderStyle.Length -eq 0 -or $UserParams.OutputSubfolderStyle -match '^\s*$'){
                $InFiles[$i].OutSubfolder = ""
            # Subfolder per date
            }elseif($UserParams.OutputSubfolderStyle -notmatch '^%n%$'){
                [string]$backconvert = ($unixOrigin.AddSeconds($InFiles[$i].Date)).ToString("yyyy-MM-dd_HH-mm-ss")
                $InFiles[$i].OutSubfolder = "\" + $($UserParams.OutputSubfolderStyle.Replace("%y4%","$($backconvert.Substring(0,4))").Replace("%y2%","$($backconvert.Substring(2,2))").Replace("%mo%","$($backconvert.Substring(5,2))").Replace("%d%","$($backconvert.Substring(8,2))").Replace("%h%","$($backconvert.Substring(11,2))").Replace("%mi%","$($backconvert.Substring(14,2))").Replace("%s%","$($backconvert.Substring(17,2))").Replace("%n%","$($InFiles[$i].InSubFolder)")) -Replace '\ $',''
                $inter = $InFiles[$i].OutSubfolder
                for($k=0; $k -lt $regexCounter.matches($InFiles[$i].OutSubfolder).count; $k++){
                    $match = [regex]::Match($inter, '%c.%')
                    $match = $inter.Substring($match.Index+2,1)
                    $inter = $regexCounter.Replace($inter, "$("{0:D$match}" -f ($i+1))", 1)
                }
                $InFiles[$i].OutSubfolder = $inter
            }else{
                # subfolder per name
                $InFiles[$i].OutSubFolder = "\$($InFiles[$i].InSubFolder)" -Replace '\ $',''
            }
        }

        # File renaming style:
        if($UserParams.OutputFileStyle -notmatch '^%n%$' -or $UserParams.OutputFileStyle.Length -gt 0){
            [string]$backconvert = ($unixOrigin.AddSeconds($InFiles[$i].Date)).ToString("yyyy-MM-dd_HH-mm-ss")
            $InFiles[$i].OutBaseName = $UserParams.OutputFileStyle.Replace("%y4%","$($backconvert.Substring(0,4))").Replace("%y2%","$($backconvert.Substring(2,2))").Replace("%mo%","$($backconvert.Substring(5,2))").Replace("%d%","$($backconvert.Substring(8,2))").Replace("%h%","$($backconvert.Substring(11,2))").Replace("%mi%","$($backconvert.Substring(14,2))").Replace("%s%","$($backconvert.Substring(17,2))").Replace("%n%","$($InFiles[$i].InBaseName)")
            $inter = $InFiles[$i].OutBaseName
            for($k=0; $k -lt $regexCounter.matches($InFiles[$i].OutBaseName).count; $k++){
                $match = [regex]::Match($inter, '%c.%')
                $match = $inter.Substring($match.Index+2,1)
                $inter = $regexCounter.Replace($inter, "$("{0:D$match}" -f ($i+1))", 1)
            }
            $InFiles[$i].OutBaseName = $inter
        }else{
            $InFiles[$i].OutBaseName = $InFiles[$i].InBaseName
        }


            # restrict subfolder path length:
            if($InFiles[$i].OutSubfolder.Length -gt 255){
                $InFiles[$i].OutSubfolder = $(Get-ShorterPath -InString $InFiles[$i].OutSubfolder -UserParams $UserParams -maxpathlength 255)
            }
            $InFiles[$i].OutPath = $("$($OutputPath)$($InFiles[$i].OutSubfolder)").Replace("\\","\").Replace("\\","\")

            # restrict length of file names (found multiple times here):
            if($InFiles[$i].OutBaseName.Length -gt $maxpathlength){
                $InFiles[$i].OutBaseName = $(Get-ShorterPath -InString $InFiles[$i].OutBaseName -UserParams $UserParams -maxpathlength $maxpathlength)
            }

            # check for files with same name from input:
            [int]$j = 1
            [int]$k = 1
            while($true){
                [string]$check = "$($InFiles[$i].OutPath)\$($InFiles[$i].OutBaseName)$($InFiles[$i].Extension)"
                if($check -notin $allpaths){
                    if($UserParams.OverwriteExistingFiles -eq 1 -or (Test-Path -LiteralPath $check -PathType Leaf) -eq $false){
                        $allpaths += $check
                        break
                    }else{
                        if($k -eq 1){
                            $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName)_OutCopy$k"
                        }else{
                            $InFiles[$i].OutBaseName = $InFiles[$i].OutBaseName -replace "_OutCopy$($k - 1)","_OutCopy$k"
                        }
                        if($InFiles[$i].OutBaseName.Length -gt $maxpathlength){
                            $InFiles[$i].OutBaseName = $(Get-ShorterPath -InString $InFiles[$i].OutBaseName -UserParams $UserParams -maxpathlength $maxpathlength)
                        }
                        $k++
                        if($script:InfoPreference -gt 0){
                            Write-ColorOut $InFiles[$i].OutBaseName -ForegroundColor Gray -Indentation 4 #VERBOSE
                        }
                        continue
                    }
                }else{
                    if($j -eq 1){
                        $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName)_InCopy$j"
                    }else{
                        $InFiles[$i].OutBaseName = $InFiles[$i].OutBaseName -replace "_InCopy$($j - 1)","_InCopy$j"
                    }
                    if($InFiles[$i].OutBaseName.Length -gt $maxpathlength){
                        $InFiles[$i].OutBaseName = $(Get-ShorterPath -InString $InFiles[$i].OutBaseName -UserParams $UserParams -maxpathlength $maxpathlength)
                    }
                    $j++
                    if($script:InfoPreference -gt 0){
                        Write-ColorOut $InFiles[$i].OutBaseName -ForegroundColor Gray -Indentation 4 #VERBOSE
                    }
                    continue
                }
            }
            $InFiles[$i].OutName = "$($InFiles[$i].OutBaseName)$($InFiles[$i].Extension)"
            # $InFiles[$i] | Format-List -Property InFullName,OutBaseName,OutName,OutPath | Out-Host #VERBOSE
        }
    }
    Write-Progress -Activity "Prevent overwriting existing files..." -Status "Done!" -Completed

    # Check OutPath for length:
    # TODO: This is a crude implementation. It should be better than this in the future, e.g. change names instead of throwing.
    if($UserParams.EnableLongPaths -eq 0){
        [int]$counter = 0
        foreach($i in $InFiles){
            [string]$pathtest = "$($i.OutPath)\$($i.OutName)"
            if($pathtest.Length -gt 260){
                Write-ColorOut "$pathtest would be over 260 characters long." -ForegroundColor Red -Indentation 4
                $counter++
            }
        }
        if($counter -gt 0){
            Start-Sleep -Seconds 5
        }
    }

    if($script:InfoPreference -gt 1){
        if((Read-Host "    Show all names? Positive answers: $script:PositiveAnswers") -in $script:PositiveAnswers){
            [int]$indent = 0
            foreach($i in $InFiles){
                if($i.ToCopy -eq 1){
                    Write-ColorOut "    $($i.OutPath.Replace($OutputPath,"."))\$($i.OutName)`t`t" -NoNewLine -ForegroundColor Gray
                    if($indent -lt 2){
                        $indent++
                    }else{
                        Write-ColorOut " "
                        $indent = 0
                    }
                }
            }
        }
    }

    return $InFiles
}

# DEFINITION: Copy Files:
# TODO: Array for InputPath
Function Copy-InFiles(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Copy-InFiles'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Copy-InFiles')
    )
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Copy files from $($UserParams.InputPath) to " -NoNewLine -ForegroundColor Cyan
    if($UserParams.OutputSubfolderStyle -eq "none"){
        Write-ColorOut "$($UserParams.OutputPath)..." -ForegroundColor Cyan
    }elseif($UserParams.OutputSubfolderStyle -eq "unchanged"){
        Write-ColorOut "$($UserParams.OutputPath) with original subfolders:" -ForegroundColor Cyan
    }else{
        Write-ColorOut "$($UserParams.OutputPath)\$($UserParams.OutputSubfolderStyle)..." -ForegroundColor Cyan
    }

    $InFiles = $InFiles | Where-Object {$_.ToCopy -eq 1} | Sort-Object -Property InPath,OutPath
    $InFiles | Out-Null

    # setting up robocopy:
    [array]$rc_command = @()
    # CREDIT: https://stackoverflow.com/a/40750265/8013879
    [string]$rc_suffix = "/R:5 /W:15 /MT:$($script:ThreadCount) /ETA /NC /NJH /J /IT /IS /UNICODE"
    [string]$rc_inter_inpath = ""
    [string]$rc_inter_outpath = ""
    [string]$rc_inter_files = ""
    # setting up Copy-LongItem:
    [array]$ps_files = @()

    for($i=0; $i -lt $InFiles.length; $i++){
        # check if files is qualified for robocopy (out-name = in-name):
        if($InFiles[$i].OutBaseName -eq $InFiles[$i].InBaseName){
            if($rc_inter_inpath.Length -eq 0 -or $rc_inter_outpath.Length -eq 0 -or $rc_inter_files.Length -eq 0){
                $rc_inter_inpath = "`"$($InFiles[$i].InPath)`""
                $rc_inter_outpath = "`"$($InFiles[$i].OutPath)`""
                $rc_inter_files = "`"$($InFiles[$i].InName)`" "
            # if in-path and out-path stay the same (between files)...
            }elseif("`"$($InFiles[$i].InPath)`"" -eq $rc_inter_inpath -and "`"$($InFiles[$i].OutPath)`"" -eq $rc_inter_outpath){
                # if command-length is within boundary:
                if($($rc_inter_inpath.Length + $rc_inter_outpath.Length + $rc_inter_files.Length + $InFiles[$i].InName.Length) -lt 8100){
                    $rc_inter_files += "`"$($InFiles[$i].InName)`" "
                }else{
                    $rc_command += "$rc_inter_inpath $rc_inter_outpath $rc_inter_files $rc_suffix"
                    $rc_inter_files = "`"$($InFiles[$i].InName)`" "
                }
            # if in-path and out-path DON'T stay the same (between files):
            }else{
                $rc_command += "$rc_inter_inpath $rc_inter_outpath $rc_inter_files $rc_suffix"
                $rc_inter_inpath = "`"$($InFiles[$i].InPath)`""
                $rc_inter_outpath = "`"$($InFiles[$i].OutPath)`""
                $rc_inter_files = "`"$($InFiles[$i].InName)`" "
            }
        # if NOT qualified for robocopy:
        }else{
            $ps_files += $InFiles[$i]
        }
    }
    $InFiles | Out-Null
    $ps_files | Out-Null

    # if last element is robocopy:
    if($rc_inter_inpath.Length -ne 0 -or $rc_inter_outpath.Length -ne 0 -or $rc_inter_files.Length -ne 0){
        if($rc_inter_inpath -notin $rc_command -or $rc_inter_outpath -notin $rc_command -or $rc_inter_files -notin $rc_command){
            $rc_command += "$rc_inter_inpath $rc_inter_outpath $rc_inter_files $rc_suffix"
        }
    }

    # infos if needed:
    if($script:InfoPreference -gt 1){
        [int]$inter = Read-Host "    Show all commands? `"1`" for yes, `"2`" for writing them as files to your script's path."
        if($inter -gt 0){
            foreach($i in $rc_command){
                Write-ColorOut "robocopy $i`r`n" -ForegroundColor Gray -Indentation 4
                if($inter -eq 2){
                    [System.IO.File]::AppendAllText("$($PSScriptRoot)\robocopy_commands.txt", $i)
                }
            }
            <#
                foreach($i in $xc_command){
                    Write-ColorOut "xcopy $i`r`n" -ForegroundColor Gray -Indentation 4
                    if($inter -eq 2){
                        [System.IO.File]::AppendAllText("$($PSScriptRoot)\xcopy_commands.txt", $i)
                    }
                }
            #>
            foreach($i in $ps_files){
                Write-ColorOut "Copy-LongItem $($i.InFullName) $($i.OutPath)\$($i.OutName)`r`n" -ForegroundColor Gray -Indentation 4
                if($inter -eq 2){
                    [System.IO.File]::AppendAllText("$($PSScriptRoot)\ps_commands.txt", "$($i.InFullName) $($i.OutPath)\$($i.OutName)")
                }
            }
            Invoke-Pause
        }
    }

    # start robocopy:
    for($i=0; $i -lt $rc_command.Length; $i++){
        Start-Process robocopy -ArgumentList $rc_command[$i] -Wait -NoNewWindow
    }

    # Start Copy-LongItem:
    $sw = [diagnostics.stopwatch]::StartNew()
    for($i=0; $i -lt $ps_files.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750 -or $i -eq 0){
            Write-Progress -Activity "Copy files to $($UserParams.OutputPath)\$($Userparams.OutputSubfolderStyle)" -PercentComplete $($i / $ps_files.Length * 100) -Status "File # $($i + 1) / $($ps_files.Length)"
            $sw.Reset()
            $sw.Start()
        }
        try{
            New-LongItem -Path "$($ps_files[$i].OutPath)" -ItemType Directory -ErrorAction Stop -WarningAction SilentlyContinue
            Start-Sleep -Milliseconds 1
            Copy-LongItem -Path "$($ps_files[$i].InFullName)" -Destination "$($ps_files[$i].OutPath)\$($ps_files[$i].OutName)" -Force -ErrorAction Stop
            Write-ColorOut "$($ps_files[$i].InName) $($ps_files[$i].OutName)" -ForegroundColor DarkGray -Indentation 4
        }catch{
            Write-ColorOut "Copying failed for $($ps_files[$i].InName) $($ps_files[$i].OutPath)\$($ps_files[$i].OutName)" -ForegroundColor Magenta -Indentation 4
            Start-Sleep -Seconds 2
        }
    }
    Write-Progress -Activity "Copy files to $($UserParams.OutputPath)\$($Userparams.OutputSubfolderStyle)" -Status "Done!" -Completed

    try{
        Write-VolumeCache -DriveLetter "$($(Split-Path -Path $UserParams.OutputPath -Qualifier).Replace(":",''))" -ErrorAction Stop
    }catch{
        Start-Sleep -Seconds 5
    }
    Start-Sleep -Milliseconds 250
}

# DEFINITION: Starting 7zip:
Function Compress-InFiles(){
    param(
        [string]$7zexe = "$($PSScriptRoot)\7z.exe",
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Compress-InFiles'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Compress-InFiles')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Zipping files..." -ForegroundColor Cyan

    if((Test-Path -LiteralPath "$($PSScriptRoot)\7z.exe" -PathType Leaf) -eq $false){
        if((Test-Path -LiteralPath "C:\Program Files\7-Zip\7z.exe" -PathType Leaf) -eq $true){
            $7zexe = "C:\Program Files\7-Zip\7z.exe"
        }elseif((Test-Path -LiteralPath "C:\Program Files (x86)\7-Zip\7z.exe" -PathType Leaf) -eq $true){
            $7zexe = "C:\Program Files (x86)\7-Zip\7z.exe"
        }else{
            Write-ColorOut "7z.exe could not be found - aborting zipping!" -ForegroundColor Red -Indentation 4
            Pause
            return $false
        }
    }

    [string]$7z_prefix = "a -tzip -mm=Copy -mx0 -ssw -sccUTF-8 -mem=AES256 -bb0"
    [string]$7z_workdir = $(
        if($UserParams.OutputSubfolderStyle -ne "none" -and $UserParams.OutputSubfolderStyle -ne "unchanged"){
            " `"-w$(Split-Path -Qualifier -Path $($UserParams.MirrorPath))\`" `"$($UserParams.MirrorPath)\$(Get-Date -Format "$($UserParams.OutputSubfolderStyle)")_MIRROR.zip`" "
        }else{
            " `"-w$(Split-Path -Qualifier -Path $($UserParams.MirrorPath))\`" `"$($UserParams.MirrorPath)\$($(Get-Date).ToString().Replace(":",'').Replace(",",'').Replace(" ",'').Replace(".",''))_MIRROR.zip`" "
        })
    [array]$7z_command = @()

    [string]$inter_files = ""
    for($k = 0; $k -lt $InFiles.Length; $k++){
        if($($7z_prefix.Length + $7z_workdir.Length + $inter_files.Length) -lt 8100){
            $inter_files += "`"$($InFiles[$k].FullName)`" "
        }else{
            $7z_command += "$7z_prefix $7z_workdir $inter_files"
            $inter_files = "`"$($InFiles[$k].FullName)`" "
        }
    }
    if($inter_files -notin $7z_command){
        $7z_command += "$7z_prefix $7z_workdir $inter_files"
    }

    [int]$errorI = 0
    foreach($cmd in $7z_command){
        try{
            Start-Process -FilePath $7zexe -ArgumentList $cmd -NoNewWindow -Wait -ErrorAction Stop
        }catch{
            $errorI++
        }
    }

    if($errorI -ne 0){
        Write-ColorOut "$errorI errors encountered!" -ForegroundColor Magenta -Indentation 4
        return $false
    }else{
        return $true
    }
}

# DEFINITION: Verify newly copied files
Function Test-CopiedFiles(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Test-CopiedFiles')
        # [ValidateNotNullOrEmpty()]
        # [hashtable]$UserParams =    $(throw 'UserParams is required by Test-CopiedFiles')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Verify newly copied files..." -ForegroundColor Cyan

    $InFiles | Where-Object {$_.ToCopy -eq 1} | Start-RSJob -Name "VerifyHash" -FunctionsToLoad Write-ColorOut -ScriptBlock {
        [string]$inter = "$($_.OutPath)\$($_.OutName)"
        if((Test-Path -LiteralPath $inter -PathType Leaf) -eq $true){
            try{
                $_.OutHash = Get-FileHash -LiteralPath $inter -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash
            }catch{
                Write-ColorOut "Could not calculate Hash of $inter." -ForegroundColor Red -Indentation 4
                $_.OutHash = "ZYXFail"
            }
        }else{
            $_.OutHash = "ZYXMiss"
        }
    } | Wait-RSJob -ShowProgress | Receive-RSJob
    Get-RSJob -Name "VerifyHash" | Remove-RSJob

    for($i=0; $i -lt $InFiles.Length; $i++){
        if($InFiles[$i].ToCopy -eq 1){
            [string]$inter = "$($InFiles[$i].OutPath)\$($InFiles[$i].OutName)"
            if($InFiles[$i].OutHash -eq "ZYXMiss"){
                try{
                    Write-ColorOut "Missing:`t$inter" -ForegroundColor Red -Indentation 4
                    New-LongItem -Path "$($inter -Replace '(\.[^.]*)$',"_broken$($InFiles[$i].Extension)")" -ItemType File -ErrorAction Stop | Out-Null
                }catch{
                    Write-ColorOut "Could not create $($inter -Replace '(\.[^.]*)$',"_broken$($InFiles[$i].Extension)")!" -ForegroundColor Magenta -Indentation 4
                }
            }elseif($InFiles[$i].InHash -ne $InFiles[$i].OutHash){
                Write-ColorOut "Broken:`t$inter" -ForegroundColor Red -Indentation 4
                try{
                    Rename-LongItem -Path $inter -NewName "$($inter -Replace '(\.[^.]*)$',"_broken$($InFiles[$i].Extension)")" -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
                }catch{
                    Write-ColorOut "Renaming $($inter -Replace '(\.[^.]*)$',"_broken$($InFiles[$i].Extension)") failed." -ForegroundColor Magenta -Indentation 4
                }
            }else{
                $InFiles[$i].ToCopy = 0
                if((Test-Path -LiteralPath $($inter -Replace '(\.[^.]*)$',"_broken$($InFiles[$i].Extension)") -PathType Leaf) -eq $true){
                    try{
                        Remove-LongItem -Path $($inter -Replace '(\.[^.]*)$',"_broken$($InFiles[$i].Extension)") -ErrorAction Stop | Out-Null
                    }catch{
                        Write-ColorOut "Removing $($inter -Replace '(\.[^.]*)$',"_broken$($InFiles[$i].Extension)") failed." -ForegroundColor Magenta -Indentation 4
                    }
                }
            }
        }
    }
    $InFiles | Out-Null

    [int]$verified = 0
    [int]$unverified = 0
    [int]$inter=0
    if($script:InfoPreference -gt 1){
        [int]$inter = Read-Host "    Show files? Positive answers: $script:PositiveAnswers"
    }
    for($i=0; $i -lt $InFiles.Length; $i++){
        if($InFiles[$i].ToCopy -eq 1){
            $unverified++
            if($inter -in $script:PositiveAnswers){
                Write-ColorOut "$($InFiles[$i].OutName)`t- $($InFiles[$i].InHash) != $($InFiles[$i].OutHash)" -ForegroundColor Red -Indentation 4
            }
        }else{
            $verified++
            if($inter -in $script:PositiveAnswers){
                Write-ColorOut "$($InFiles[$i].OutName)`t- $($InFiles[$i].InHash) = $($InFiles[$i].OutHash)" -ForegroundColor Green -Indentation 4
            }
        }
    }
    $script:resultvalues.unverified = $unverified
    $script:resultvalues.verified = $verified

    return $InFiles
}

# DEFINITION: Write new files' attributes to history-file:
Function Write-JsonHistory(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Write-JsonHistory'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Write-JsonHistory')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Write attributes of successfully copied files to history-file..." -ForegroundColor Cyan

    [array]$results = @()
    [array]$results = @($InFiles | Where-Object {$_.ToCopy -eq 0} | ForEach-Object {
        [PSCustomObject]@{
            N = $_.InName
            D = $_.Date
            S = $_.Size
            H = $_.InHash
        }
    })

    if($UserParams.WriteHistFile -eq "Yes" -and (Test-Path -LiteralPath $UserParams.HistFilePath -PathType Leaf) -eq $true){
        try{
            $JSON = Get-Content -LiteralPath $UserParams.HistFilePath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
        }catch{
            Write-ColorOut "Could not load $($UserParams.HistFilePath)." -ForegroundColor Red -Indentation 4
            Pause
        }
        $JSON | Out-Null
        $results += $JSON | ForEach-Object {
            [PSCustomObject]@{
                N = $_.N
                D = $_.D
                S = $_.S
                H = $_.H
            }
        }
    }
    if($UserParams.CheckOutputDupli -gt 0){
        $results += $script:dupliout | ForEach-Object {
            [PSCustomObject]@{
                N = $_.InName
                D = $_.Date
                S = $_.Size
                H = $_.Hash
            }
        }
    }

    if($script:InfoPreference -gt 1 -and (Read-Host "    Show files? Positive answers: $script:PositiveAnswers") -in $script:PositiveAnswers){
        $results | Format-Table -AutoSize | Out-Host
    }

    $results = $results | Sort-Object -Property N,D,S,H -Unique | ConvertTo-Json
    $results | Out-Null

    [int]$i = 0
    while($true){
        try{
            [System.IO.File]::WriteAllText($UserParams.HistFilePath, $results)
            break
        }
        catch{
            if($i -lt 5){
                Write-ColorOut "Writing to history-file failed! Trying again..." -ForegroundColor Red -Indentation 4
                Start-Sleep -Seconds 5
                $i++
                Continue
            }else{
                Write-ColorOut "Writing to history-file $($UserParams.HistFilePath) failed!" -ForegroundColor Red -Indentation 4
                return $false
            }
        }
    }

    return $true
}

# DEFINITION: Starts all the things.
Function Start-Everything(){
    param(
        [hashtable]$UserParams = $(throw 'UserParams is required by Start-Everything')
    )
    Write-ColorOut "`r`n$(Get-CurrentDate)  --  Starting everything..." -NoNewLine -ForegroundColor Cyan -BackgroundColor DarkGray
    Write-ColorOut "A                               A" -ForegroundColor DarkGray -BackgroundColor DarkGray

    if($script:InfoPreference -gt 0){
        $script:timer = [diagnostics.stopwatch]::StartNew()
    }

    while($true){
        # DEFINITION: Test User-Values:
        try{
            $UserParams = Test-UserValues -UserParams $UserParams
        }catch{
            Start-Sound -Success 0
            Start-Sleep -Seconds 2
            break
        }
        Invoke-Pause

        # DEFINITION: Show parameters, then close:
        if($UserParams.ShowParams -ne 0){
            Show-Parameters -UserParams $UserParams
            Pause
            Invoke-Close
        }

        # DEFINITION: If enabled, remember parameters:
        if($UserParams.RememberInPath -ne 0 -or $UserParams.RememberOutPath -ne 0 -or $UserParams.RememberMirrorPath -ne 0 -or $UserParams.RememberSettings -ne 0){
            try{
                Write-JsonParameters -UserParams $UserParams
            }catch{
                Invoke-Close
            }
            Invoke-Pause
        }

        # DEFINITION: If enabled, start preventsleep script:
        if($script:PreventStandby -eq 1){
            Invoke-PreventSleep
        }

        # DEFINITION: Search for files:
        try{
            [array]$inputfiles = @(Get-InFiles -UserParams $UserParams)
        }catch{
            Write-ColorOut "Get-InFiles failed" -ForegroundColor Red
            break
        }
        if($inputfiles.Length -lt 1){
            Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
            Start-Sound -Success 1
            Start-Sleep -Seconds 2
            break
        }
        Invoke-Pause

        # DEFINITION: If enabled: Get History-File:
        [array]$histfiles = @()
        if($UserParams.UseHistFile -eq 1){
            try{
                [array]$histfiles = @(Read-JsonHistory -UserParams $UserParams)
                Invoke-Pause
            }catch{
                Write-ColorOut "Read-JsonHistory failed" -ForegroundColor Red
                break
            }
        }
        if($histfiles.Length -le 0){
            Write-ColorOut "No History-files found." -ForegroundColor Gray -Indentation 4
            $UserParams.UseHistFile = 0
            if($UserParams.WriteHistFile -eq "yes"){
                $UserParams.WriteHistFile = "Overwrite"
            }
        }else{
            # DEFINITION: If enabled: Check for duplicates against history-files:
            try{
                [array]$inputfiles = @(Test-DupliHist -InFile $inputfiles -HistFiles $histfiles -UserParams $UserParams)
            }catch{
                Write-ColorOut "Test-DupliHist failed" -ForegroundColor Red
                break
            }
            if($inputfiles.Length -lt 1){
                Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
                Start-Sound -Success 1
                Start-Sleep -Seconds 2
                break
            }
            Invoke-Pause
        }

        # DEFINITION: If enabled: Check for duplicates against output-files:
        if($UserParams.CheckOutputDupli -eq 1){
            try{
                [array]$inputfiles = (Test-DupliOut -InFiles $inputfiles -UserParams $UserParams)
            }catch{
                Write-ColorOut "Test-DupliOut failed" -ForegroundColor Red
                break
            }
            if($inputfiles.Length -lt 1){
                Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
                Start-Sound -Success 1
                Start-Sleep -Seconds 2
                break
            }
            Invoke-Pause
        }

        # DEFINITION: Avoid copying input-files more than once:
        if($UserParams.AvoidIdenticalFiles -eq 1){
            try{
                [array]$inputfiles = (Get-InFileHash -InFiles $inputfiles)
            }catch{
                Write-ColorOut "Get-InFileHash failed" -ForegroundColor Red
                break
            }
            Invoke-Pause
            try{
                [array]$inputfiles = Clear-IdenticalInFiles -InFiles $inputfiles -UserParams $UserParams
            }catch{
                Write-ColorOut "Clear-IdenticalInFiles failed" -ForegroundColor Red
                break
            }
            Invoke-Pause
        }

        Write-ColorOut "Files left after dupli-check(s):`t$($script:resultvalues.ingoing - $script:resultvalues.duplihist - $script:resultvalues.dupliout - $script:resultvalues.identicalFiles) = $($script:resultvalues.copyfiles)" -ForegroundColor Yellow -Indentation 4

        # DEFINITION: Get free space:
        try{
            [bool]$Test = Test-DiskSpace -UserParams $UserParams -InFiles $inputfiles -OutPath $UserParams.OutputPath
        }catch{
            Write-ColorOut "Test-DiskSpace failed" -ForegroundColor Red
            break
        }
        if($Test -eq $false){
            Start-Sound -Success 0
            Start-Sleep -Seconds 2
            break
        }
        Invoke-Pause

        # DEFINITION: Copy stuff and check it:
        $j = 0
        while(1 -in $inputfiles.ToCopy){
            if($j -gt 0){
                Write-ColorOut "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                if((Read-Host " Positive answers: $script:PositiveAnswers") -notin $script:PositiveAnswers){
                    Write-ColorOut "Aborting." -ForegroundColor Cyan
                    Start-Sleep -Seconds 2
                    break
                }
            }
            try{
                [array]$inputfiles = (Protect-OutFileOverwrite -InFiles $inputfiles -UserParams $UserParams -Mirror 0)
            }catch{
                Write-ColorOut "Protect-OutFileOverwrite failed" -ForegroundColor Red
                break
            }
            Invoke-Pause
            try{
                Copy-InFiles -InFiles $inputfiles -UserParams $UserParams
            }catch{
                Write-ColorOut "Copy-InFiles failed" -ForegroundColor Red
                break
            }
            Invoke-Pause

            # DEFINITION: Check copied files:
            if($UserParams.VerifyCopies -eq 1){
                 # Get hashes of remaining files:
                try{
                    [array]$inputfiles = (Get-InFileHash -InFiles $inputfiles)
                }catch{
                    Write-ColorOut "Get-InFileHash failed" -ForegroundColor Red
                    break
                }
                Invoke-Pause
                try{
                    [array]$inputfiles = (Test-CopiedFiles -InFiles $inputfiles)
                }catch{
                    Write-ColorOut "Test-CopiedFiles failed" -ForegroundColor Red
                    break
                }
                Invoke-Pause
                $j++
            }else{
                foreach($instance in $inputfiles.ToCopy){
                    $instance = 0
                }
            }
        }
        # DEFINITION: Unmount input-drive:
        if($UserParams.UnmountInputDrive -eq 1){
            # CREDIT: https://serverfault.com/a/580298
            # TODO: Find a solution that works with all drives.
            # TODO: Array for InputPath
            try{
                $driveEject = New-Object -comObject Shell.Application
                $driveEject.Namespace(17).ParseName($(Split-Path -Qualifier -Path $UserParams.InputPath)).InvokeVerb("Eject")
                Write-ColorOut "Drive $(Split-Path -Qualifier -Path $UserParams.InputPath) successfully ejected!" -ForegroundColor DarkCyan -BackgroundColor Gray
            }
            catch{
                Write-ColorOut "Couldn't eject drive $(Split-Path -Qualifier -Path $UserParams.InputPath)." -ForegroundColor Magenta
            }
        }
        if($UserParams.WriteHistFile -ne "no"){
            try{
                Write-JsonHistory -InFiles $inputfiles -UserParams $UserParams
            }catch{
                Write-ColorOut "Write-JsonHistory failed" -ForegroundColor Red
                break
            }
            Invoke-Pause
        }
        if($UserParams.MirrorEnable -eq 1){
            # DEFINITION: Get free space:
            try{
                [bool]$Test = Test-DiskSpace -InFiles $inputfiles -OutPath $UserParams.MirrorPath
            }catch{
                Write-ColorOut "Test-DiskSpace failed" -ForegroundColor Red
                break
            }
            if($Test -eq $false){
                Start-Sound -Success 0
                Start-Sleep -Seconds 2
                break
            }
            Invoke-Pause
            for($i=0; $i -lt $inputfiles.length; $i++){
                if($inputfiles[$i].tocopy -eq 1){
                    $inputfiles[$i].tocopy = 0
                }else{
                    $inputfiles[$i].tocopy = 1
                }
                $inputfiles[$i].FullName = "$($inputfiles[$i].outpath)\$($inputfiles[$i].outname)"
                $inputfiles[$i].inpath = (Split-Path -Path $inputfiles[$i].FullName -Parent)
                $inputfiles[$i].outname = "$($inputfiles[$i].basename)$($inputfiles[$i].extension)"
            }

            if($UserParams.ZipMirror -eq 1){
                try{
                    Compress-InFiles -InFiles $inputfiles
                }catch{
                    Write-ColorOut "Compress-InFiles failed" -ForegroundColor Red
                    break
                }
                Invoke-Pause
            }else{
                $j = 1
                while(1 -in $inputfiles.tocopy){
                    if($j -gt 1){
                        Write-ColorOut "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                        if((Read-Host "Positive answers: $script:PositiveAnswers") -notin $script:PositiveAnswers){
                            break
                        }
                    }
                    [array]$inputfiles = (Protect-OutFileOverwrite -InFiles $inputfiles -UserParams $UserParams -Mirror 1)
                    Invoke-Pause
                    try{
                        Copy-InFiles -InFiles $inputfiles -UserParams $UserParams
                    }catch{
                        Write-ColorOut "Copy-InFiles failed" -ForegroundColor Red
                        break
                    }
                    Invoke-Pause
                    if($UserParams.VerifyCopies -eq 1){
                        try{
                            [array]$inputfiles = (Test-CopiedFiles -InFiles $inputfiles)
                        }catch{
                            Write-ColorOut "Test-CopiedFiles failed" -ForegroundColor Red
                            break
                        }
                        Invoke-Pause
                        $j++
                    }else{
                        foreach($instance in $inputfiles.tocopy){$instance = 0}
                    }
                }
            }
        }
        break
    }

    Write-ColorOut "$(Get-CurrentDate)  --  Done!" -ForegroundColor Cyan
    Write-ColorOut "`r`nStats:" -ForegroundColor DarkCyan -Indentation 4
    Write-ColorOut "Found:`t$($script:resultvalues.ingoing)`tfiles." -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "Skipped:`t$($script:resultvalues.duplihist)`t(history) +`r`n`t`t$($script:resultvalues.dupliout)`t(out-path) +`r`n`t`t$($script:resultvalues.IdenticalFiles)`t(identical) files." -ForegroundColor DarkGreen -Indentation 4
    Write-ColorOut "Copied:`t$($script:resultvalues.copyfiles)`tfiles." -ForegroundColor Yellow -Indentation 4
    if($UserParams.VerifyCopies -eq 1){
        Write-ColorOut "Verified:`t$($script:resultvalues.verified)`tfiles." -ForegroundColor Green -Indentation 4
        Write-ColorOut "Unverified:`t$($script:resultvalues.unverified)`tfiles." -ForegroundColor DarkRed -Indentation 4
    }
    Write-ColorOut "                                                                               A" -BackgroundColor DarkGray -ForegroundColor DarkGray
    Write-ColorOut "                                                                               A`r`n" -BackgroundColor Gray -ForegroundColor Gray

    if($script:resultvalues.unverified -eq 0){
        Start-Sound -Success 1
    }else{
        Start-Sound -Success 0
    }

    if($script:PreventStandby -gt 1){
        try{
            Stop-Process -Id $script:PreventStandby
        }catch{
            Write-ColorOut "Stop-Process -Id $($script:PreventStandby) failed" -ForegroundColor Red
        }
    }
    if($UserParams.EnableGUI -eq 1){
        try{
            Start-GUI -GUIPath $script:GUIPath -UserParams $UserParams
        }catch{
            Write-ColorOut "Re-starting Start-GUI failed" -ForegroundColor Red
        }
    }
}


# ==================================================================================================
# ==============================================================================
#    Starting everything:
# ==============================================================================
# ==================================================================================================

# (COMMENT THIS BLOCK FOR PESTER)
# DEFINITION: Console banner
    Write-ColorOut "                            flolilo's Media-Copytool                            " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "                          $VersionNumber           " -ForegroundColor DarkMagenta -BackgroundColor DarkGray -NoNewLine
    Write-ColorOut "(PID = $("{0:D8}" -f $pid))`r`n" -ForegroundColor Gray -BackgroundColor DarkGray
    $Host.UI.RawUI.WindowTitle = "CLI: Media-Copytool $VersionNumber"

# DEFINITION: Start-up:
    try{
        [hashtable]$UserParams = Read-JsonParameters -UserParams $UserParams -Renew 0
    }catch{
        Throw 'Could not read Parameters from JSON.'
        Start-Sleep -Seconds 2
    }
    if($UserParams.EnableGUI -eq 1){
        try{
            Start-GUI -GUIPath $GUIPath -UserParams $UserParams
        }catch{
            Write-ColorOut "GUI could not be started!" -ForegroundColor Red
            $UserParams.EnableGUI = 0
            Start-Everything -UserParams $UserParams
        }
    }elseif($UserParams.EnableGUI -eq 0){
        Start-Everything -UserParams $UserParams
    }else{
        Write-ColorOut "Invalid choice of -EnableGUI value (0, 1). Trying GUI..." -ForegroundColor Red
        Start-Sleep -Seconds 2
        $UserParams.EnableGUI = 1
        try{
            Start-GUI -GUIPath $GUIPath -UserParams $UserParams
        }catch{
            Write-ColorOut "GUI could not be started!" -ForegroundColor Red
            $UserParams.EnableGUI = 0
            Start-Everything -UserParams $UserParams
        }
    }
#>
