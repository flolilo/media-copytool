#requires -version 3

<#
    .SYNOPSIS
        Copy (and verify) user-defined filetypes from A to B (and optionally C).
    .DESCRIPTION
        Uses Windows' Robocopy and Xcopy for file-copy, then uses PowerShell's Get-FileHash (SHA1) for verifying that files were copied without errors.
        Now supports multithreading via Boe Prox's PoshRSJob-cmdlet (https://github.com/proxb/PoshRSJob)
    .NOTES
        Version:        1.0.0 (ALPHA)
        Author:         flolilo
        Creation Date:  XXXX-XX-XX
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
    .PARAMETER Debug
    Cannot be specified in mc_parameters.json.
        Gives more verbose so one can see what is happening (and where it goes wrong).
        Valid options:
            0 - no debug (default)
            1 - only stop on end, show information
            2 - pause after every function, option to show files and their status
            3 - ???
    .PARAMETER InputPath
        Path from which files will be copied.
    .PARAMETER OutputPath
        Path to copy the files to.
    .PARAMETER MirrorEnable
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it enables copying to a second output-path that is specified with -MirrorPath.
    .PARAMETER MirrorPath
        Second path to which files will  be copied. Only used if -MirrorEnable is set to 1
    .PARAMETER PresetFormats
        Preset formats for some common file-types.
        Valid options:
            "Can"   - *.CR2 + *.CR3
            "Nik"   - *.NRW + *.NEF
            "Son"   - *.ARW
            "Jpg"   - *.JPG + *.JPEG
            "Inter" - *.DNG + *.TIF
            "Mov"   - *.MP4 + *.MOV
            "Aud"   - *.WAV + *.MP3 + *.M4A
        For multiple choices, separate them with commata, e.g. '-PresetFormats "Can","Nik"'.
    .PARAMETER CustomFormatsEnable
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it enables the use of custom formats specified with -CustomFormats.
    .PARAMETER CustomFormats
        User-defined, custom search-terms. Asterisks * are wildcards.
        Examples:
            "*" will look for all files inside -InputPath
            "media*" will look for all files inside -InputPath that start with "media", regardless their extension. E.g. media_copytool.ps1, media123.ini,...
        Specify your terms inside quotes and separate multiple entries with commata.
    .PARAMETER OutputSubfolderStyle
        Creation-style of subfolders for files in -OutputPath. The date will be taken from the file's last edit time.
        Valid options:
            "none"          -   No subfolders in -OutputPath.
            "unchanged"     -   Take the original subfolder-structure and copy it (like Robocopy's /MIR)
            "yyyy-MM-dd"    -   E.g. 2017-01-31
            "yyyy_MM_dd"    -   E.g. 2017_01_31
            "yyyy.MM.dd"    -   E.g. 2017.01.31
            "yyyyMMdd"      -   E.g. 20170131
            "yy-MM-dd"      -   E.g. 17-01-31
            "yy_MM_dd"      -   E.g. 17_01_31
            "yy.MM.dd"      -   E.g. 17.01.31
            "yyMMdd"        -   E.g. 170131
    .PARAMETER OutputFileStyle
        Renaming-style for input-files. The date and time will be taken from the file's last edit time.
        Valid options:
            "unchanged"         -   Original file-name will be used.
            "yyyy-MM-dd_HH-mm-ss"  -   E.g. 2017-01-31_13-59-58.ext
            "yyyyMMdd_HHmmss"     -   E.g. 20170131_135958.ext
            "yyyyMMddHHmmss"      -   E.g. 20170131135958.ext
            "yy-MM-dd_HH-mm-ss"    -   E.g. 17-01-31_13-59-58.ext
            "yyMMdd_HHmmss"       -   E.g. 170131_135958.ext
            "yyMMddHHmmss"        -   E.g. 170131135958.ext
            "HH-mm-ss"          -   E.g. 13-59-58.ext
            "HH_mm_ss"          -   E.g. 13_59_58.ext
            "HHmmss"            -   E.g. 135958.ext
    .PARAMETER HistFilePath
        Path to the JSON-file that represents the history-file.
    .PARAMETER UseHistFile
        Valid range: 0 (deactivate), 1 (activate)
        The history-file is a fast way to rule out the creation of duplicates by comparing the files from -InputPath against the values stored earlier.
        If enabled, it will use the history-file to prevent duplicates.
    .PARAMETER WriteHistFile
        The history-file is a fast way to rule out the creation of duplicates by comparing the files from -InputPath against the values stored earlier.
        Valid options:
            "No"        -   New values will NOT be added to the history-file, the old values will remain.
            "Yes"       -   Old + new values will be added to the history-file, with old values still saved.
            "Overwrite" -   Old values will be deleted, new values will be written. Best to use after the card got formatted, as it will make the history-file smaller and therefore faster.
    .PARAMETER HistCompareHashes
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it additionally checks for duplicates in the history-file via hash-calculation of all input-files (slow!)
    .PARAMETER InputSubfolderSearch
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it enables file-search in subfolders of the input-path.
    .PARAMETER CheckOutputDupli
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it checks for already copied files in the output-path (and its subfolders).
    .PARAMETER OverwriteExistingFiles
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, existing files will be overwritten. If disabled, new files will get a unique name.
    .PARAMETER EnableLongPaths
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, file names will not be restricted to Windows' usual 260 character limit. USE ONLY WITH WIN 10 WITH LONG PATHS ENABLED!
    .PARAMETER VerifyCopies
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, copied files will be checked for their integrity via SHA1-hashes. Disabling will increase speed, but there is no absolute guarantee that your files are copied correctly.
    .PARAMETER AvoidIdenticalFiles
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, identical files from the input-path will only get copied once.
    .PARAMETER ZipMirror
        Valid range: 0 (deactivate), 1 (activate)
        Only enabled if -EnableMirror is enabled, too. Creates a zip-archive for archiving. Name will be <actual time>_Mirror.zip
    .PARAMETER UnmountInputDrive
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, safely removes the input-drive after finishing copying & verifying. Only use with external drives!
    .PARAMETER PreventStandby
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
        media_copytool.ps1 -PresetFormats "Can","Mov","Jpg" .InputPath "G:\" -OutputPath "D:\Backup" -PreventStandby 1
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
    [string]$InputPath =            "",
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
    [int]$InputSubfolderSearch =    -1,
    [int]$CheckOutputDupli =        -1,
    [int]$AcceptTimeDiff =          -1,
    [int]$VerifyCopies =            -1,
    [int]$OverwriteExistingFiles =  -1,
    [int]$EnableLongPaths =         -1,
    [int]$AvoidIdenticalFiles =     -1,
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
        InputSubfolderSearch =      $InputSubfolderSearch
        CheckOutputDupli =          $CheckOutputDupli
        AcceptTimeDiff =            $AcceptTimeDiff
        VerifyCopies =              $VerifyCopies
        OverwriteExistingFiles =    $OverwriteExistingFiles
        EnableLongPaths =           $EnableLongPaths
        AvoidIdenticalFiles =       $AvoidIdenticalFiles
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
            Write-Host "powershellgallery.com/packages/PSAlphaFS " -NoNewline
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
    $VersionNumber = "v1.0.0 (ALPHA) - XXXX-XX-XX"

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
    <#
        if($script:UserParams.InfoPreference -gt 0){
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
    #>
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
        [int]$Success = $(throw '-Success is needed by Start-Sound!')
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

# DEFINITION: Pause the programme if debug-var is active. Also, enable measuring times per command with -debug 3.
Function Invoke-Pause(){
    if($UserParams.InfoPreference -gt 0){
        Write-ColorOut "Processing-time:`t$($script:timer.elapsed.TotalSeconds)" -ForegroundColor Magenta
    }
    if($UserParams.InfoPreference -gt 1){
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
    if($UserParams.InfoPreference -gt 0){
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
        $MyShell.sendkeys("{F15}")
        Start-Sleep -Seconds 90
    }
'@
    $standby = [System.Text.Encoding]::Unicode.GetBytes($standby)
    $standby = [Convert]::ToBase64String($standby)

    try{
        [int]$inter = (Start-Process powershell -ArgumentList "-EncodedCommand $standby" -WindowStyle Hidden -PassThru).Id
        if($UserParams.InfoPreference -gt 0){
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
Function Get-ParametersFromJSON(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Get-ParametersFromJSON'),
        [ValidateRange(0,1)]
        [int]$Renew = $(throw 'Renew is required by Get-ParametersFromJSON')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting parameter-values..." -ForegroundColor Cyan

    if((Test-Path -LiteralPath $UserParams.JSONParamPath -PathType Leaf -ErrorAction SilentlyContinue) -eq $true){
        try{
            $jsonparams = Get-Content -LiteralPath $UserParams.JSONParamPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            if($jsonparams.Length -eq 0){
                Write-ColorOut "$($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) is empty!" -ForegroundColor Magenta -Indentation 4
                throw
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
                [string]$UserParams.InputPath = $jsonparams.InputPath
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
                [array]$UserParams.FormatInExclude = $jsonparams.FormatInExclude
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
            throw
        }
    }else{
        Write-ColorOut "$($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) does not exist - aborting!" -ForegroundColor Red -Indentation 4
        Write-ColorOut "(You can specify the path with -JSONParamPath (w/o GUI) - or use `"-EnableGUI 1`".)" -ForegroundColor Magenta -Indentation 4
        Start-Sleep -Seconds 5
        throw
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
        [hashtable]$UserParams = $(throw 'UserParams is required by Start-GUI'),
        [ValidateRange(0,1)]
        [int]$GetXAML = $(throw 'GetXAML is required by Start-GUI')
    )
    # DEFINITION: "Select"-Window for buttons to choose a path.
    Function Get-GUIFolder(){
        param(
            [Parameter(Mandatory=$true)]
            [string]$ToInfluence,
            [Parameter(Mandatory=$true)]
            [hashtable]$GUIParams
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
                    $GUIParams.textBoxInput.Text = $browse.SelectedPath
                }elseif($ToInfluence -eq "output"){
                    $GUIParams.textBoxOutput.Text = $browse.SelectedPath
                }elseif($ToInfluence -eq "mirror"){
                    $GUIParams.textBoxMirror.Text = $browse.SelectedPath
                }
            }
        }else{
            [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
            $browse = New-Object System.Windows.Forms.OpenFileDialog
            $browse.Multiselect = $false
            $browse.Filter = 'JSON (*.json)|*.json'

            if($browse.ShowDialog() -eq "OK"){
                if($browse.FileName -like "*.json"){
                    $GUIParams.textBoxHistFile.Text = $browse.FileName
                }
            }
        }

        return $GUIParams
    }

    # DEFINITION: Load GUI layout from XAML-File
    if($GetXAML -eq 1){
        if((Test-Path -LiteralPath $GUIPath -PathType Leaf) -eq $true){
            try{
                $inputXML = Get-Content -LiteralPath $GUIPath -Encoding UTF8 -ErrorAction Stop
            }catch{
                Write-ColorOut "Could not load $GUIPath - GUI can therefore not start." -ForegroundColor Red
                Pause
                throw
            }
        }else{
            Write-ColorOut "Could not find $GUIPath - GUI can therefore not start." -ForegroundColor Red
            Pause
            throw
        }

        try{
            [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
            [xml]$xaml = $inputXML -replace '\(\(MC_VERSION\)\)',"$script:VersionNumber" -replace 'mc:Ignorable="d"','' -replace "x:Name",'Name' -replace '^<Win.*', '<Window'
            $reader = (New-Object System.Xml.XmlNodeReader $xaml)
            $script:Form = [Windows.Markup.XamlReader]::Load($reader)
        }
        catch{
            Write-ColorOut "Unable to load Windows.Markup.XamlReader. Usually this means that you haven't installed .NET Framework. Please download and install the latest .NET Framework Web-Installer for your OS: " -ForegroundColor Red
            Write-ColorOut "https://duckduckgo.com/?q=net+framework+web+installer&t=h_&ia=web"
            Write-ColorOut "Alternatively, this script will now start in CLI-mode, which requires you to enter all variables via parameter flags (e.g. `"-Inputpath C:\InputPath`")." -ForegroundColor Yellow
            Pause
            throw
        }

        [hashtable]$GUIParams = @{}
        $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
            # Do not add TextBlocks, as those will not be altered and only mess around:
            if(($script:Form.FindName($_.Name)).ToString() -ne "System.Windows.Controls.TextBlock"){
                $GUIParams.Add($($_.Name), $script:Form.FindName($_.Name))
            }
        }

        if($script:getWPF -ne 0){
            Write-ColorOut "Found these interactable elements:" -ForegroundColor Cyan
            $GUIParams | Format-Table -AutoSize | Out-Host
            Pause
            Invoke-Close
        }
    }

    # DEFINITION: Fill first page of GUI:
        # DEFINITION: Get presets from JSON:
            if((Test-Path -LiteralPath $UserParams.JSONParamPath -PathType Leaf) -eq $true){
                try{
                    $jsonparams = Get-Content -Path $UserParams.JSONParamPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                    if($jsonparams.ParamPresetName -is [array]){
                        $jsonparams.ParamPresetName | ForEach-Object {
                            $GUIParams.comboBoxLoadPreset.AddChild($_)
                        }
                        for($i=0; $i -lt $jsonparams.ParamPresetName.length; $i++){
                            if($jsonparams.ParamPresetName[$i] -eq $UserParams.LoadParamPresetName){
                                $GUIParams.comboBoxLoadPreset.SelectedIndex = $i
                            }
                        }
                    }else{
                        $GUIParams.comboBoxLoadPreset.AddChild($jsonparams.ParamPresetName)
                        $GUIParams.comboBoxLoadPreset.SelectedIndex = 0
                    }
                }catch{
                    Write-ColorOut "Getting preset-names from $($UserParams.JSONParamPath) failed - aborting!" -ForegroundColor Magenta -Indentation 4
                    throw
                }
            }else{
                Write-ColorOut "$($UserParams.JSONParamPath) does not exist - aborting!" -ForegroundColor  Magenta -Indentation 4
                throw
            }
            $GUIParams.TextBoxSavePreset.Text =             $UserParams.SaveParamPresetName
        # DEFINITION: In-, out-, mirrorpath:
            $GUIParams.TextBoxInput.Text =                  $UserParams.InputPath
            $GUIParams.CheckBoxRememberIn.IsChecked =       $UserParams.RememberInPath
            $GUIParams.TextBoxOutput.Text =                 $UserParams.OutputPath
            $GUIParams.CheckBoxRememberOut.IsChecked =      $UserParams.RememberOutPath
            $GUIParams.CheckBoxMirror.IsChecked =           $UserParams.MirrorEnable
            $GUIParams.TextBoxMirror.Text =                 $UserParams.MirrorPath
            $GUIParams.CheckBoxRememberMirror.IsChecked =   $UserParams.RememberMirrorPath
        # DEFINITION: History-file-path:
            $GUIParams.TextBoxHistFile.Text =               $UserParams.HistFilePath
    # DEFINITION: Second page of GUI:
        # DEFINITION: Formats:
            if($UserParams.FormatPreference -in @("include","in")){
                $GUIParams.RadioButtonInclude.IsChecked =   $true
                $GUIParams.TextBoxInclude.Text =            $UserParams.FormatInExclude -join "|"
                $GUIParams.TextBoxExclude.Text =            ""
            }elseif($UserParams.FormatPreference -in @("exclude","ex")){
                $GUIParams.RadioButtonExclude.IsChecked =   $true
                $GUIParams.TextBoxExclude.Text =            $UserParams.FormatInExclude -join "|"
                $GUIParams.TextBoxInclude.Text =            ""
            }else{
                $GUIParams.RadioButtonAll.IsChecked =   $true
                $GUIParams.TextBoxInclude.Text =        ""
                $GUIParams.TextBoxExclude.Text =        ""
            }
        # DEFINITION: Duplicates:
            $GUIParams.CheckBoxUseHistFile.IsChecked = $UserParams.UseHistFile
            $GUIParams.ComboBoxWriteHistFile.SelectedIndex = $(
                if("yes"            -eq $UserParams.WriteHistFile){0}
                elseif("Overwrite"  -eq $UserParams.WriteHistFile){1}
                elseif("no"         -eq $UserParams.WriteHistFile){2}
                else{0}
            )
            $GUIParams.CheckBoxCheckHashHist.IsChecked =        $UserParams.HistCompareHashes
            $GUIParams.CheckBoxOutputDupli.IsChecked =          $UserParams.CheckOutputDupli
            $GUIParams.CheckBoxAvoidIdenticalFiles.IsChecked =  $UserParams.AvoidIdenticalFiles
            $GUIParams.CheckBoxAcceptTimeDiff.IsChecked =       $UserParams.AcceptTimeDiff
        # DEFINITION: (Re)naming:
            $GUIParams.TextBoxOutSubStyle.Text =    $UserParams.OutputSubfolderStyle
            $GUIParams.TextBoxOutFileStyle.Text =   $UserParams.OutputFileStyle
        # DEFINITION: Other options:
            $GUIParams.CheckBoxInSubSearch.IsChecked =              $UserParams.InputSubfolderSearch
            $GUIParams.CheckBoxVerifyCopies.IsChecked =             $UserParams.VerifyCopies
            $GUIParams.CheckBoxOverwriteExistingFiles.IsChecked =   $UserParams.OverwriteExistingFiles
            $GUIParams.CheckBoxEnableLongPaths.IsChecked =          $UserParams.EnableLongPaths
            $GUIParams.CheckBoxZipMirror.IsChecked =                $UserParams.ZipMirror
            $GUIParams.CheckBoxUnmountInputDrive.IsChecked =        $UserParams.UnmountInputDrive
            $GUIParams.CheckBoxPreventStandby.IsChecked =           $script:PreventStandby
            $GUIParams.CheckBoxRememberSettings.IsChecked =         $UserParams.RememberSettings

    # DEFINITION: Load-Preset-Button:
        $GUIParams.ButtonLoadPreset.Add_Click({
            if($jsonparams.ParamPresetName -is [array]){
                for($i=0; $i -lt $jsonparams.ParamPresetName.Length; $i++){
                    if($i -eq $GUIParams.ComboBoxLoadPreset.SelectedIndex){
                        [string]$UserParams.LoadParamPresetName = $jsonparams.ParamPresetName[$i]
                    }
                }
            }else{
                [string]$UserParams.LoadParamPresetName = $jsonparams.ParamPresetName
            }
            $script:Form.Close()
            Get-ParametersFromJSON -UserParams $UserParams -Renew 1
            Start-Sleep -Milliseconds 2
            Start-GUI -GUIPath $GUIPath -UserParams $UserParams -GetXAML 0
        })
    # DEFINITION: InPath-Button:
        $GUIParams.ButtonSearchIn.Add_Click({
            Get-GUIFolder -ToInfluence "input" -GUIParams $GUIParams
        })
    # DEFINITION: OutPath-Button:
        $GUIParams.ButtonSearchOut.Add_Click({
            Get-GUIFolder -ToInfluence "output" -GUIParams $GUIParams
        })
    # DEFINITION: MirrorPath-Button:
        $GUIParams.ButtonSearchMirror.Add_Click({
            Get-GUIFolder -ToInfluence "mirror" -GUIParams $GUIParams
        })
    # DEFINITION: HistoryPath-Button:
        $GUIParams.ButtonSearchHistFile.Add_Click({
            Get-GUIFolder -ToInfluence "histfile" -GUIParams $GUIParams
        })
    # DEFINITION: Start-Button:
        $GUIParams.ButtonStart.Add_Click({
            # $SaveParamPresetName
            $UserParams.SaveParamPresetName = $($GUIParams.textBoxSavePreset.Text.ToLower() -Replace '[^A-Za-z0-9_+-]','')
            $UserParams.SaveParamPresetName = $UserParams.SaveParamPresetName.Substring(0, [math]::Min($UserParams.SaveParamPresetName.Length, 64))
            # $InputPath
            $UserParams.InputPath = $GUIParams.textBoxInput.Text
            # $OutputPath
            $UserParams.OutputPath = $GUIParams.textBoxOutput.Text
            # $MirrorEnable
            $UserParams.MirrorEnable = $(
                if($GUIParams.checkBoxMirror.IsChecked -eq $true){1}
                else{0}
            )
            # $MirrorPath
            if($GUIParams.checkBoxMirror.IsChecked -eq $true){
                $UserParams.MirrorPath = $GUIParams.textBoxMirror.Text
            }
            # $FormatPreference
            $UserParams.FormatPreference = $(
                if($GUIParams.RadioButtonAll.IsChecked -eq          $true){"all"}
                elseif($GUIParams.RadioButtonInclude.IsChecked -eq  $true){"in"}
                elseif($GUIParams.RadioButtonExclude.IsChecked -eq  $true){"ex"}
            )
            # $FormatInExclude
            [array]$UserParams.FormatInExclude = @()
            $separator = "|"
            $option = [System.StringSplitOptions]::RemoveEmptyEntries
            $UserParams.FormatInExclude = $(
                if($GUIParams.RadioButtonAll.IsChecked -eq          $true){@("*")}
                elseif($GUIParams.RadioButtonInclude.IsChecked -eq  $true){
                    $GUIParams.TextBoxInclude.Text.Replace(" ",'').Split($separator,$option)
                }
                elseif($GUIParams.RadioButtonExclude.IsChecked -eq  $true){
                    $GUIParams.TextBoxExclude.Text.Replace(" ",'').Split($separator,$option)
                }
            )
            # $OutputSubfolderStyle
            $UserParams.OutputSubfolderStyle = $GUIParams.TextBoxOutSubStyle.Text
            # $OutputFileStyle
            $UserParams.OutputFileStyle = $GUIParams.TextBoxOutFileStyle.Text
            # $UseHistFile
            $UserParams.UseHistFile = $(
                if($GUIParams.checkBoxUseHistFile.IsChecked -eq $true){1}
                else{0}
            )
            # $WriteHistFile
            $UserParams.WriteHistFile = $(
                if($GUIParams.comboBoxWriteHistFile.SelectedIndex -eq 0){"yes"}
                elseif($GUIParams.comboBoxWriteHistFile.SelectedIndex -eq 1){"overwrite"}
                elseif($GUIParams.comboBoxWriteHistFile.SelectedIndex -eq 2){"no"}
            )
            # $HistFilePath
            $UserParams.HistFilePath = $GUIParams.textBoxHistFile.Text
            # $HistCompareHashes
            $UserParams.HistCompareHashes = $(
                if($GUIParams.checkBoxCheckHashHist.IsChecked -eq $true){1}
                else{0}
            )
            # $CheckOutputDupli
            $UserParams.CheckOutputDupli = $(
                if($GUIParams.checkBoxOutputDupli.IsChecked -eq $true){1}
                else{0}
            )
            # $AvoidIdenticalFiles
            $UserParams.AvoidIdenticalFiles = $(
                if($GUIParams.checkBoxAvoidIdenticalFiles.IsChecked -eq $true){1}
                else{0}
            )
            # $AcceptTimeDiff
            $UserParams.AcceptTimeDiff = $(
                if($GUIParams.CheckBoxAcceptTimeDiff.IsChecked -eq $true){1}
                else{0}
            )
            # $InputSubfolderSearch
            $UserParams.InputSubfolderSearch = $(
                if($GUIParams.checkBoxInSubSearch.IsChecked -eq $true){1}
                else{0}
            )
            # $VerifyCopies
            $UserParams.VerifyCopies = $(
                if($GUIParams.checkBoxVerifyCopies.IsChecked -eq $true){1}
                else{0}
            )
            # $OverwriteExistingFiles
            $UserParams.OverwriteExistingFiles = $(
                if($GUIParams.checkBoxOverwriteExistingFiles.IsChecked -eq $true){1}
                else{0}
            )
            # $EnableLongPaths
            $UserParams.EnableLongPaths = $(
                if($GUIParams.checkBoxEnableLongPaths.IsChecked -eq $true){1}
                else{0}
            )
            # $ZipMirror
            $UserParams.ZipMirror = $(
                if($GUIParams.checkBoxZipMirror.IsChecked -eq $true){1}
                else{0}
            )
            # $UnmountInputDrive
            $UserParams.UnmountInputDrive = $(
                if($GUIParams.checkBoxUnmountInputDrive.IsChecked -eq $true){1}
                else{0}
            )
            # $PreventStandby (SCRIPT VAR)
            $script:PreventStandby = $(
                if($GUIParams.checkBoxPreventStandby.IsChecked -eq $true){1}
                else{0}
            )
            # $RememberInPath
            $UserParams.RememberInPath = $(
                if($GUIParams.checkBoxRememberIn.IsChecked -eq $true){1}
                else{0}
            )
            # $RememberOutPath
            $UserParams.RememberOutPath = $(
                if($GUIParams.checkBoxRememberOut.IsChecked -eq $true){1}
                else{0}
            )
            # $RememberMirrorPath
            $UserParams.RememberMirrorPath = $(
                if($GUIParams.checkBoxRememberMirror.IsChecked -eq $true){1}
                else{0}
            )
            # $RememberSettings
            $UserParams.RememberSettings = $(
                if($GUIParams.checkBoxRememberSettings.IsChecked -eq $true){1}
                else{0}
            )

            $script:Form.Close()
            Start-Everything -UserParams $UserParams
        })
    # DEFINITION: About-Button:
        $GUIParams.ButtonAbout.Add_Click({
            Start-Process powershell -ArgumentList "Get-Help $($PSCommandPath) -detailed" -NoNewWindow -Wait
        })
    # DEFINITION: Close-Button:
        $GUIParams.ButtonClose.Add_Click({
            $script:Form.Close()
            Invoke-Close
        })

    # DEFINITION: Start GUI:
        $script:Form.ShowDialog() | Out-Null

    return $script:Form
}

# DEFINITION: Get values from Params, then check the main input- and outputfolder:
Function Test-UserValues(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Test-UserValues')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting user-values (directly)..." -ForegroundColor Cyan

    # DEFINITION: Get values, test paths:
        # DEFINITION: $InputPath
            $invalidChars = "[{0}]" -f [RegEx]::Escape($([IO.Path]::GetInvalidFileNameChars() -join '' -replace '\\',''))
            $separator = '\:\\'
            $inter = $UserParams.InputPath -Split $separator
            $inter[1] = $inter[1] -Replace $invalidChars
            $UserParams.InputPath = $inter -join "$([regex]::Unescape($separator))"
            if($UserParams.InputPath -match '^.{3,}\\$'){
                $UserParams.InputPath = $UserParams.InputPath -Replace '\\$',''
            }

            if($UserParams.InputPath.Length -lt 2 -or (Test-Path -LiteralPath $UserParams.InputPath -PathType Container -ErrorAction SilentlyContinue) -eq $false){
                Write-ColorOut "Input-path $($UserParams.InputPath) could not be found." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $OutputPath
            $invalidChars = "[{0}]" -f [RegEx]::Escape($([IO.Path]::GetInvalidFileNameChars() -join '' -replace '\\',''))
            $separator = '\:\\'
            $inter = $UserParams.OutputPath -Split $separator
            $inter[1] = $inter[1] -Replace $invalidChars
            $UserParams.OutputPath = $inter -join "$([regex]::Unescape($separator))"
            if($UserParams.OutputPath -match '^.{3,}\\$'){
                $UserParams.OutputPath = $UserParams.OutputPath -Replace '\\$',''
            }

            if($UserParams.OutputPath -eq $UserParams.InputPath){
                Write-ColorOut "Output-path $($UserParams.OutputPath) is the same as input-path." -ForegroundColor Red -Indentation 4
                throw
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
                        throw
                    }
                }else{
                    Write-ColorOut "Output-path $($UserParams.OutputPath) not found." -ForegroundColor Red -Indentation 4
                    throw
                }
            }
        # DEFINITION: $MirrorEnable
            if($UserParams.MirrorEnable -notin (0..1)){
                Write-ColorOut "Invalid choice of -MirrorEnable." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $MirrorPath
            $invalidChars = "[{0}]" -f [RegEx]::Escape($([IO.Path]::GetInvalidFileNameChars() -join '' -replace '\\',''))
            $separator = '\:\\'
            [array]$inter = $UserParams.MirrorPath -Split $separator
            $inter[1] = $inter[1] -Replace $invalidChars
            $UserParams.MirrorPath = $inter -join "$([regex]::Unescape($separator))"
            if($UserParams.MirrorPath -match '^.{3,}\\$'){
                $UserParams.MirrorPath = $UserParams.MirrorPath -Replace '\\$',''
            }

            if($UserParams.MirrorEnable -eq 1){
                if($UserParams.MirrorPath -eq $UserParams.InputPath -or $UserParams.MirrorPath -eq $UserParams.OutputPath){
                    Write-ColorOut "Additional output-path $($UserParams.MirrorPath) is the same as input- or output-path." -ForegroundColor Red -Indentation 4
                    throw
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
                            throw
                        }
                    }else{
                        Write-ColorOut "Additional output-path $($UserParams.MirrorPath) not found." -ForegroundColor Red -Indentation 4
                        throw
                    }
                }
            }
        # DEFINITION: $FormatPreference
            [array]$inter = @("all","include","in","exclude","ex")
            if($(Compare-Object $inter $UserParams.FormatPreference | Where-Object {$_.sideindicator -eq "=>"}).count -ne 0){
                Write-ColorOut "Invalid choice of -FormatPreference." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $FormatInExclude
            if($UserParams.FormatInExclude.GetType().Name -ne "Object[]"){
                Write-ColorOut "Invalid choice of -FormatInExclude." -ForegroundColor Red -Indentation 4
                throw
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
                throw
            }
        # DEFINITION: $UseHistFile
            if($UserParams.UseHistFile -notin (0..1)){
                Write-ColorOut "Invalid choice of -UseHistFile." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $WriteHistFile
            [array]$inter=@("yes","no","overwrite")
            if($UserParams.WriteHistFile -notin $inter -or $UserParams.WriteHistFile.Length -gt $inter[2].Length){
                Write-ColorOut "Invalid choice of -WriteHistFile." -ForegroundColor Red -Indentation 4
                throw
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
                    throw
                }
            }
        # DEFINITION: $HistCompareHashes
            if($UserParams.HistCompareHashes -notin (0..1)){
                Write-ColorOut "Invalid choice of -HistCompareHashes." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $CheckOutputDupli
            if($UserParams.CheckOutputDupli -notin (0..1)){
                Write-ColorOut "Invalid choice of -CheckOutputDupli." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $AvoidIdenticalFiles
            if($UserParams.AvoidIdenticalFiles -notin (0..1)){
                Write-ColorOut "Invalid choice of -AvoidIdenticalFiles." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $AcceptTimeDiff
            if($UserParams.AcceptTimeDiff -notin (0..1)){
                Write-ColorOut "Invalid choice of -AcceptTimeDiff." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $InputSubfolderSearch
            if($UserParams.InputSubfolderSearch -notin (0..1)){
                Write-ColorOut "Invalid choice of -InputSubfolderSearch." -ForegroundColor Red -Indentation 4
                throw
            }elseif($UserParams.InputSubfolderSearch -eq 1){
                [switch]$inter = $true
            }else{
                [switch]$inter = $false
            }
            $UserParams.InputSubfolderSearch = $inter
        # DEFINITION: $VerifyCopies
            if($UserParams.VerifyCopies -notin (0..1)){
                Write-ColorOut "Invalid choice of -VerifyCopies." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $OverwriteExistingFiles
            if($UserParams.OverwriteExistingFiles -notin (0..1)){
                Write-ColorOut "Invalid choice of -OverwriteExistingFiles." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $EnableLongPaths
            if($UserParams.EnableLongPaths -notin (0..1)){
                Write-ColorOut "Invalid choice of -EnableLongPaths." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $ZipMirror
            if($UserParams.ZipMirror -notin (0..1)){
                Write-ColorOut "Invalid choice of -ZipMirror." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $UnmountInputDrive
            if($UserParams.UnmountInputDrive -notin (0..1)){
                Write-ColorOut "Invalid choice of -UnmountInputDrive." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $PreventStandby (SCRIPT VAR)
            if($script:PreventStandby -notin (0..1)){
                Write-ColorOut "Invalid choice of -PreventStandby." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $RememberInPath
            if($UserParams.RememberInPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberInPath." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $RememberOutPath
            if($UserParams.RememberOutPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberOutPath." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $RememberMirrorPath
            if($UserParams.RememberMirrorPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberMirrorPath." -ForegroundColor Red -Indentation 4
                throw
            }
        # DEFINITION: $RememberSettings
            if($UserParams.RememberSettings -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberSettings." -ForegroundColor Red -Indentation 4
                throw
            }

    # DEFINITION: If everything was sucessful, return UserParams:
    return $UserParams
}

# DEFINITION: Show parameters on the console, then exit:
Function Show-Parameters(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Show-Parameters')
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
    Write-ColorOut "-Debug`t`t`t=`t$($UserParams.InfoPreference)" -ForegroundColor Cyan -Indentation 4
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
Function Set-Parameters(){
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
            if($UserParams.InfoPreference -gt 1){
                Write-ColorOut "From:" -ForegroundColor Yellow -Indentation 2
                $jsonparams | ConvertTo-Json -ErrorAction Stop | Out-Host
            }
        }catch{
            Write-ColorOut "Getting parameters from $($UserParams.JSONParamPath) failed - aborting!" -ForegroundColor Red
            Start-Sleep -Seconds 5
            return $false
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

    if($UserParams.InfoPreference -gt 1){
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
                return $false
            }
        }
    }

    return $true
}

# DEFINITION: Searching for selected formats in Input-Path, getting Path, Name, Time, and calculating Hash:
Function Start-FileSearch(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Start-FileSearch')
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
        if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
            Write-Progress -Id 1 -Activity "Find files in $($UserParams.InputPath)..." -PercentComplete $((($i* 100) / $($allChosenFormats.Length))) -Status "Format #$($i + 1) / $($allChosenFormats.Length)"
            $sw.Reset()
            $sw.Start()
        }

        $InFiles += Get-ChildItem -LiteralPath $UserParams.InputPath -Filter $allChosenFormats[$i] -Recurse:$UserParams.InputSubfolderSearch -File | ForEach-Object -Process {
            if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
                Write-Progress -Id 2 -Activity "Looking for files..." -PercentComplete -1 -Status "File #$counter - $($_.FullName.Replace("$($UserParams.InputPath)",'.'))"
                $sw.Reset()
                $sw.Start()
            }
            $counter++
            [PSCustomObject]@{
                InFullName = $_.FullName
                InPath = (Split-Path -Path $_.FullName -Parent)
                InName = $_.Name
                InBaseName = $_.BaseName
                Extension = $_.Extension
                Size = $_.Length
                Date = ([DateTimeOffset]$_.LastWriteTimeUtc).ToUnixTimeSeconds()
                OutSubfolder = $($(Split-Path -Parent -Path $_.FullName).Replace("$($UserParams.InputPath)","")) -Replace('^\\','')
                OutPath = "ZYX"
                OutName = "ZYX"
                OutBaseName = "ZYX"
                Hash = "ZYX"
                ToCopy = 1
            }
        } -End {
            Write-Progress -Id 2 -Activity "Looking for files..." -Status "Done!" -Completed
        }
    }
    Write-Progress -Id 1 -Activity "Find files in $($UserParams.InputPath)..." -Status "Done!" -Completed
    $sw.Reset()

    if($UserParams.FormatPreference -in @("exclude","ex")){
        foreach($i in $UserParams.FormatInExclude){
            [array]$InFiles = @($InFiles | Where-Object {$_.InName -notlike $i})
        }
        $InFiles | Out-Null
    }
    $InFiles = $InFiles | Sort-Object -Property InFullName
    $InFiles | Out-Null

    # Subfolder renaming style:
        #no subfolder:
    if($UserParams.OutputSubfolderStyle.Length -eq 0 -or $UserParams.OutputSubfolderStyle -match '^\s*$'){
        foreach($i in $InFiles){
            $i.OutSubfolder = ""
        }
        # Subfolder per date
    }elseif($UserParams.OutputSubfolderStyle -notmatch '^%n%$'){
        [datetime]$unixOrigin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        for($i=0; $i -lt $InFiles.Length; $i++){
            [string]$backconvert = ($unixOrigin.AddSeconds($InFiles[$i].Date)).ToString("yyyy-MM-dd_HH-mm-ss")
            $InFiles[$i].OutSubfolder = "\" + $($UserParams.OutputSubfolderStyle.Replace("%y4%","$($backconvert.Substring(0,4))").Replace("%y2%","$($backconvert.Substring(2,2))").Replace("%mo%","$($backconvert.Substring(5,2))").Replace("%d%","$($backconvert.Substring(8,2))").Replace("%h%","$($backconvert.Substring(11,2))").Replace("%mi%","$($backconvert.Substring(14,2))").Replace("%s%","$($backconvert.Substring(17,2))").Replace("%n%","$($InFiles[$i].OutSubFolder)")) -Replace '\ $',''
        }
    }else{
        # subfolder per name
        foreach($i in $InFiles){
            $i.OutSubFolder = "\$($i.OutSubFolder)" -Replace '\ $',''
        }
    }
    # File renaming style:
    if($UserParams.OutputFileStyle -notmatch '^%n%$'){
        [datetime]$unixOrigin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $regexCounter = [regex]'%c.%'
        for($i=0; $i -lt $InFiles.Length; $i++){
            [string]$backconvert = ($unixOrigin.AddSeconds($InFiles[$i].Date)).ToString("yyyy-MM-dd_HH-mm-ss")
            $InFiles[$i].InBaseName = $UserParams.OutputFileStyle.Replace("%y4%","$($backconvert.Substring(0,4))").Replace("%y2%","$($backconvert.Substring(2,2))").Replace("%mo%","$($backconvert.Substring(5,2))").Replace("%d%","$($backconvert.Substring(8,2))").Replace("%h%","$($backconvert.Substring(11,2))").Replace("%mi%","$($backconvert.Substring(14,2))").Replace("%s%","$($backconvert.Substring(17,2))").Replace("%n%","$($InFiles[$i].InBaseName)")
            $inter = $InFiles[$i].InBaseName
            for($k=0; $k -lt $regexCounter.matches($InFiles[$i].InBaseName).count; $k++){
                $match = [regex]::Match($inter, '%c.%')
                $match = $inter.Substring($match.Index+2,1)
                $inter = $regexCounter.Replace($inter, "$("{0:D$match}" -f ($i+1))", 1)
            }
            $InFiles[$i].InBaseName = $inter
        }
    }

    if($UserParams.InfoPreference -gt 1){
        if((Read-Host "    Show all found files? Positive answers: $PositiveAnswers") -in $PositiveAnswers){
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
Function Get-HistFile(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Get-HistFile')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Checking for history-file, importing values..." -ForegroundColor Cyan

    [array]$files_history = @()
    if((Test-Path -LiteralPath $UserParams.HistFilePath -PathType Leaf) -eq $true){
        try{
            $JSONFile = Get-Content -LiteralPath $UserParams.HistFilePath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-JSON -ErrorAction Stop
        }catch{
            Write-ColorOut "Could not load $($UserParams.HistFilePath)." -ForegroundColor Red -Indentation 4
            Start-Sleep -Seconds 5
            throw
        }
        $JSONFile | Out-Null
        $files_history = $JSONFile | ForEach-Object {
            [PSCustomObject]@{
                InName = $_.N
                Date = $_.D
                Size = $_.S
                Hash = $_.H
            }
        }
        $files_history | Out-Null

        if($UserParams.InfoPreference -gt 1){
            if((Read-Host "    Show found history-values? Positive answers: $PositiveAnswers") -in $PositiveAnswers){
                Write-ColorOut "Found values: $($files_history.Length)" -ForegroundColor Yellow -Indentation 4
                Write-ColorOut "Name`t`tDate`t`tSize`t`tHash" -Indentation 4
                for($i = 0; $i -lt $files_history.Length; $i++){
                    Write-ColorOut "$($files_history[$i].InName)`t$($files_history[$i].Date)`t$($files_history[$i].Size)`t$($files_history[$i].Hash)" -ForegroundColor Gray -Indentation 4
                }
            }
        }

        if("null" -in $files_history -or $files_history.InName.Length -lt 1 -or ($files_history.Length -gt 1 -and (($files_history.InName.Length -ne $files_history.Date.Length) -or ($files_history.InName.Length -ne $files_history.Size.Length) -or ($files_history.InName.Length -ne $files_history.Hash.Length) -or ($files_history.InName -contains $null) -or ($files_history.Date -contains $null) -or ($files_history.Size -contains $null) -or ($files_history.Hash -contains $null)))){
            Write-ColorOut "Some values in the history-file $($UserParams.HistFilePath) seem wrong - it's safest to delete the whole file." -ForegroundColor Magenta -Indentation 4
            Write-ColorOut "InNames: $($files_history.InName.Length) Dates: $($files_history.Date.Length) Sizes: $($files_history.Size.Length) Hashes: $($files_history.Hash.Length)" -Indentation 4
            if((Read-Host "    Is that okay? Positive answers: $PositiveAnswers") -in $PositiveAnswers){
                return @()
            }else{
                Write-ColorOut "`r`n`tAborting.`r`n" -ForegroundColor Magenta
                throw
            }
        }
        if("ZYX" -in $files_history.Hash -and $UserParams.HistCompareHashes -eq 1){
            Write-ColorOut "Some hash-values in the history-file are missing (because -VerifyCopies wasn't activated when they were added). This could lead to duplicates." -ForegroundColor Magenta -Indentation 4
            Start-Sleep -Seconds 2
        }
    }else{
        Write-ColorOut "History-File $($UserParams.HistFilePath) could not be found. This means it's possible that duplicates get copied." -ForegroundColor Magenta -Indentation 4
        if((Read-Host "    Is that okay? Positive answers: $PositiveAnswers") -in $PositiveAnswers){
            return @()
        }else{
            Write-ColorOut "`r`n`tAborting.`r`n" -ForegroundColor Magenta
            throw
        }
    }

    return $files_history
}

# DEFINITION: dupli-check via history-file:
Function Start-DupliCheckHist(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles = $(throw 'InFiles is required by Start-DupliCheckHist'),
        [ValidateNotNullOrEmpty()]
        [array]$HistFiles = $(throw 'HistFiles is required by Start-DupliCheckHist'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Start-DupliCheckHist')
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
                    if($InFiles[$i].Hash -match '^ZYX$') {
                        $InFiles[$i].Hash = Get-FileHash -LiteralPath $InFiles[$i].InFullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash
                    }
                    if($InFiles[$i].Hash -eq $HistFiles[$h].Hash) {
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
                        $InFiles[$i].Hash = Get-FileHash -LiteralPath $InFiles[$i].InFullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash
                        if($InFiles[$i].Hash -in $inter.Hash){
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

    if($UserParams.InfoPreference -gt 1){
        if((Read-Host "    Show result? Positive answers: $PositiveAnswers") -in $PositiveAnswers){
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
Function Start-DupliCheckOut(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Start-DupliCheckOut'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Start-DupliCheckOut')
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
                    if($InFiles[$i].Hash -match '^ZYX$') {
                        $InFiles[$i].Hash = Get-FileHash -LiteralPath $InFiles[$i].InFullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash
                    }
                    $files_duplicheck[$h].Hash = Get-FileHash -LiteralPath $files_duplicheck[$h].InFullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash
                    if($InFiles[$i].Hash -eq $files_duplicheck[$h].Hash) {
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
                if((Read-Host "    Show all files? Positive answers: $PositiveAnswers") -in $PositiveAnswers){
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
Function Start-InputGetHash(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles = $(throw 'InFiles is required by Start-InputGetHash')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Calculate remaining hashes..." -ForegroundColor Cyan

    if("ZYX" -in $InFiles.Hash){
        $InFiles | Where-Object {$_.Hash -match '^ZYX$'} | Start-RSJob -Name "GetHashRest" -FunctionsToLoad Write-ColorOut -ScriptBlock {
            try{
                $_.Hash = (Get-FileHash -LiteralPath $_.InFullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash)
            }catch{
                Write-ColorOut "Failed to get hash of `"$($_.InFullName)`"" -ForegroundColor Red -Indentation 4
                $_.Hash = "GetHashRestWRONG"
            }
        } | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob -Name "GetHashRest" | Remove-RSJob
    }else{
        Write-ColorOut "No more hashes to get!" -ForegroundColor DarkGreen -Indentation 4
    }

    return $InFiles
}

# DEFINITION: Avoid copying identical files from the input-path:
Function Start-PreventingDoubleCopies(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles = $(throw 'InFiles is required by Start-PreventingDoubleCopies')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Avoid identical input-files..." -ForegroundColor Cyan

    [array]$inter = ($InFiles | Sort-Object -Property InName,Date,Size,Hash -Unique)
    if($inter.Length -ne $InFiles.Length){
        [array]$InFiles = ($inter)
        Write-ColorOut "$($InFiles.Length - $inter.Length) identical files were found in the input-path - only copying one of each." -ForegroundColor Magenta -Indentation 4
        Start-Sleep -Seconds 3
    }
    $script:resultvalues.identicalFiles = $($InFiles.Length - $inter.Length)
    $script:resultvalues.copyfiles = $InFiles.Length

    return $InFiles
}

# DEFINITION: Check for free space on the destination volume:
Function Start-SpaceCheck(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Start-SpaceCheck'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Start-SpaceCheck')
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
Function Start-OverwriteProtection(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Start-OverwriteProtection'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Start-OverwriteProtection'),
        [int]$Mirror =              $(throw 'Mirror is required by Start-OverwriteProtection')
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

    [array]$allpaths = @()

    $sw = [diagnostics.stopwatch]::StartNew()
    for($i=0; $i -lt $InFiles.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750 -or $i -eq 0){
            Write-Progress -Activity "Prevent overwriting existing files..." -PercentComplete $($i / $InFiles.Length * 100) -Status "File # $($i + 1) / $($InFiles.Length) - $($InFiles[$i].name)"
            $sw.Reset()
            $sw.Start()
        }

        [int]$maxpathlength = (255 - $InFiles[$i].Extension.Length)

        # restrict subfolder path length:
        if($InFiles[$i].OutSubfolder.Length -gt 255){
            $InFiles[$i].OutSubfolder = "$($InFiles[$i].OutSubfolder.Substring(0, [math]::Min($InFiles[$i].OutSubfolder.Length, 119)))---$($InFiles[$i].OutSubfolder.Substring([math]::Max(123, ($InFiles[$i].OutSubfolder.Length - 123)), 123))"
        }
        # create outpath:
        $InFiles[$i].OutPath = $("$($OutputPath)$($InFiles[$i].OutSubfolder)").Replace("\\","\").Replace("\\","\")
        $InFiles[$i].OutBaseName = $InFiles[$i].InBaseName
        # restrict length of file names (found multiple times here):
        if($InFiles[$i].OutBaseName.Length -gt $maxpathlength){
            $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName.Substring(0, [math]::Min($InFiles[$i].OutBaseName.Length, 119)))---$($InFiles[$i].OutBaseName.Substring([math]::Max(123, ($InFiles[$i].OutBaseName.Length - 123)), 123))"
        }
        # check for files with same name from input:
        [int]$j = 1
        [int]$k = 1
        while($true){
            [string]$check = "$($InFiles[$i].OutPath)\$($InFiles[$i].OutBaseName)$($InFiles[$i].Extension)"
            if($check -notin $allpaths){
                if((Test-Path -LiteralPath $check -PathType Leaf) -eq $false -or $UserParams.OverwriteExistingFiles -eq 1){
                    $allpaths += $check
                    break
                }else{
                    if($k -eq 1){
                        $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName)_OutCopy$k"
                        if($InFiles[$i].OutBaseName.Length -gt $maxpathlength){
                            $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName.Substring(0, [math]::Min($InFiles[$i].OutBaseName.Length, ([math]::Floor($maxpathlength / 2)))))---$($InFiles[$i].OutBaseName.Substring([math]::Max(([math]::Floor($maxpathlength / 2)), ($InFiles[$i].OutBaseName.Length - ([math]::Floor($maxpathlength / 2)))), ([math]::Floor($maxpathlength / 2))))"
                        }
                    }else{
                        $InFiles[$i].OutBaseName = $InFiles[$i].OutBaseName -replace "_OutCopy$($k - 1)","_OutCopy$k"
                        if($InFiles[$i].OutBaseName.Length -gt $maxpathlength){
                            $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName.Substring(0, [math]::Min($InFiles[$i].OutBaseName.Length, 119)))---$($InFiles[$i].OutBaseName.Substring([math]::Max(123, ($InFiles[$i].OutBaseName.Length - 123)), 123))"
                        }
                    }
                    $k++
                    if($UserParams.InfoPreference -gt 0){$InFiles[$i].OutBaseName | Out-Host} #VERBOSE
                    continue
                }
            }else{
                if($j -eq 1){
                    $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName)_InCopy$j"
                    if($InFiles[$i].OutBaseName.Length -gt 245){
                        $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName.Substring(0, [math]::Min($InFiles[$i].OutBaseName.Length, 119)))---$($InFiles[$i].OutBaseName.Substring([math]::Max(123, ($InFiles[$i].OutBaseName.Length - 123)), 123))"
                    }
                }else{
                    $InFiles[$i].OutBaseName = $InFiles[$i].OutBaseName -replace "_InCopy$($j - 1)","_InCopy$j"
                    if($InFiles[$i].OutBaseName.Length -gt 245){
                        $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName.Substring(0, [math]::Min($InFiles[$i].OutBaseName.Length, 119)))---$($InFiles[$i].OutBaseName.Substring([math]::Max(123, ($InFiles[$i].OutBaseName.Length - 123)), 123))"
                    }
                }
                $j++
                if($UserParams.InfoPreference -gt 0){$InFiles[$i].OutBaseName | Out-Host} #VERBOSE
                continue
            }
        }
        $InFiles[$i].OutName = "$($InFiles[$i].OutBaseName)$($InFiles[$i].Extension)"
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

    if($UserParams.InfoPreference -gt 1){
        if((Read-Host "    Show all names? Positive answers: $PositiveAnswers") -in $PositiveAnswers){
            [int]$indent = 0
            for($i=0; $i -lt $InFiles.Length; $i++){
                Write-ColorOut "    $($InFiles[$i].OutPath.Replace($OutputPath,"."))\$($InFiles[$i].OutName)`t`t" -NoNewLine -ForegroundColor Gray
                if($indent -lt 2){
                    $indent++
                }else{
                    Write-ColorOut " "
                    $indent = 0
                }
            }
        }
    }

    return $InFiles
}

# DEFINITION: Copy Files:
Function Start-FileCopy(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Start-FileCopy'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Start-FileCopy')
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
    [string]$rc_suffix = "/R:5 /W:15 /MT:$($script:ThreadCount) /XO /XC /XN /NC /NJH /J"
    [string]$rc_inter_inpath = ""
    [string]$rc_inter_outpath = ""
    [string]$rc_inter_files = ""
    # setting up xcopy:
    # [array]$xc_command = @()
    # [string]$xc_suffix = " /Q /J /Y"
    [array]$ps_files = @()

    for($i=0; $i -lt $InFiles.length; $i++){
        # check if files is qualified for robocopy (out-name = in-name):
        if($InFiles[$i].OutBaseName -eq $InFiles[$i].InBaseName){
            if($rc_inter_inpath.Length -eq 0 -or $rc_inter_outpath.Length -eq 0 -or $rc_inter_files.Length -eq 0){
                $rc_inter_inpath = "`"$($InFiles[$i].InPath)`""
                $rc_inter_outpath = "`"$($InFiles[$i].OutPath)`""
                $rc_inter_files = "`"$($InFiles[$i].OutName)`" "
            # if in-path and out-path stay the same (between files)...
            }elseif("`"$($InFiles[$i].InPath)`"" -eq $rc_inter_inpath -and "`"$($InFiles[$i].OutPath)`"" -eq $rc_inter_outpath){
                # if command-length is within boundary:
                if($($rc_inter_inpath.Length + $rc_inter_outpath.Length + $rc_inter_files.Length + $InFiles[$i].OutName.Length) -lt 8100){
                    $rc_inter_files += "`"$($InFiles[$i].OutName)`" "
                }else{
                    $rc_command += "$rc_inter_inpath $rc_inter_outpath $rc_inter_files $rc_suffix"
                    $rc_inter_files = "`"$($InFiles[$i].OutName)`" "
                }
            # if in-path and out-path DON'T stay the same (between files):
            }else{
                $rc_command += "$rc_inter_inpath $rc_inter_outpath $rc_inter_files $rc_suffix"
                $rc_inter_inpath = "`"$($InFiles[$i].InPath)`""
                $rc_inter_outpath = "`"$($InFiles[$i].OutPath)`""
                $rc_inter_files = "`"$($InFiles[$i].OutName)`" "
            }
        # if NOT qualified for robocopy:
        }else{
            # $xc_command += "`"$($InFiles[$i].InFullName)`" `"$($InFiles[$i].OutPath)\$($InFiles[$i].OutName)*`" $xc_suffix"
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
    if($UserParams.InfoPreference -gt 1){
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

    $sw = [diagnostics.stopwatch]::StartNew()
    for($i=0; $i -lt $ps_files.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750 -or $i -eq 0){
            Write-Progress -Activity "Starting Copying.." -PercentComplete $($i / $ps_files.Length * 100) -Status "File # $($i + 1) / $($ps_files.Length)"
            $sw.Reset()
            $sw.Start()
        }
        try{
            New-LongItem -Path "$($ps_files[$i].OutPath)" -ItemType Directory -ErrorAction Stop -WarningAction SilentlyContinue
            Start-Sleep -Milliseconds 1
            Copy-LongItem -Path "$($ps_files[$i].InFullName)" -Destination "$($ps_files[$i].OutPath)\$($ps_files[$i].OutName)" -Force -ErrorAction Stop
        }catch{
            Write-ColorOut "Copying failed for $($ps_files[$i].InFullName) $($ps_files[$i].OutPath)\$($ps_files[$i].OutName)" -ForegroundColor Magenta -Indentation 4
            Start-Sleep -Seconds 2
        }
    }
    Write-Progress -Activity "Starting Copying.." -Status "Done!" -Completed

    Write-VolumeCache -DriveLetter "$($(Split-Path -Path $UserParams.OutputPath -Qualifier).Replace(":",''))"
    Start-Sleep -Milliseconds 250

    <#
        # start xcopy:
        $sw = [diagnostics.stopwatch]::StartNew()
        [int]$counter=0
        for($i=0; $i -lt $xc_command.Length; $i++){
            while($counter -ge $script:ThreadCount){
                $counter = @(Get-Process -Name xcopy -ErrorAction SilentlyContinue).count
                Start-Sleep -Milliseconds 10
            }
            if($sw.Elapsed.TotalMilliseconds -ge 750 -or $i -eq 0){
                Write-Progress -Activity "Starting Xcopy.." -PercentComplete $($i / $xc_command.Length * 100) -Status "File # $($i + 1) / $($xc_command.Length)"
                $sw.Reset()
                $sw.Start()
            }
            $xc_command[$i] | Out-Host
            Start-Process xcopy -ArgumentList $xc_command[$i] -NoNewWindow # -WindowStyle Hidden
            $counter++
        }
        while($counter -gt 0){
            $counter = @(Get-Process -Name xcopy -ErrorAction SilentlyContinue).count
            Start-Sleep -Milliseconds 25
        }
        Write-Progress -Activity "Starting Xcopy.." -Status "Done!" -Completed
    #>
}

# DEFINITION: Starting 7zip:
Function Start-7zip(){
    param(
        [string]$7zexe = "$($PSScriptRoot)\7z.exe",
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Start-7zip'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Start-7zip')
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
Function Start-FileVerification(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Start-FileVerification')
        # [ValidateNotNullOrEmpty()]
        # [hashtable]$UserParams =    $(throw 'UserParams is required by Start-FileVerification')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Verify newly copied files..." -ForegroundColor Cyan

    $InFiles | Where-Object {$_.ToCopy -eq 1} | Start-RSJob -Name "VerifyHash" -FunctionsToLoad Write-ColorOut -ScriptBlock {
        [string]$inter = "$($_.OutPath)\$($_.OutName)"
        if((Test-Path -LiteralPath $inter -PathType Leaf) -eq $true){
            try{
                $hash = Get-FileHash -LiteralPath $inter -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash
            }catch{
                Write-ColorOut "Could not calculate Hash of $($_.FullName)" -ForegroundColor Red -Indentation 4
                $hash = "VerifyHashWRONG"
            }
            if($_.Hash -ne $hash){
                Write-ColorOut "Broken:`t$inter" -ForegroundColor Red -Indentation 4
                try{
                    Rename-LongItem -Path $inter -NewName "$($inter)_broken" -ErrorAction Stop
                }catch{
                    Write-ColorOut "Renaming $inter failed." -ForegroundColor Magenta -Indentation 4
                }
            }else{
                $_.ToCopy = 0
                if((Test-Path -LiteralPath "$($inter)_broken" -PathType Leaf) -eq $true){
                    try{
                        Remove-LongItem -Path "$($inter)_broken" -ErrorAction Stop
                    }catch{
                        Write-ColorOut "Removing $($inter)_broken failed." -ForegroundColor Magenta -Indentation 4
                    }
                }
            }
        }else{
            Write-ColorOut "Missing:`t$inter" -ForegroundColor Red -Indentation 4
            try{
                New-LongItem -ItemType File -Path "$($inter)_broken" -ErrorAction Stop | Out-Null
            }catch{
                Write-ColorOut "Creating $($inter)_broken failed." -ForegroundColor Magenta -Indentation 4
            }
        }
    } | Wait-RSJob -ShowProgress | Receive-RSJob
    Get-RSJob -Name "VerifyHash" | Remove-RSJob

    [int]$verified = 0
    [int]$unverified = 0
    [int]$inter=0
    if($UserParams.InfoPreference -gt 1){
        [int]$inter = Read-Host "    Show files? Positive answers: $PositiveAnswers"
    }
    for($i=0; $i -lt $InFiles.Length; $i++){
        if($InFiles[$i].tocopy -eq 1){
            $unverified++
            if($inter -in $PositiveAnswers){
                Write-ColorOut $InFiles[$i].outname -ForegroundColor Red -Indentation 4
            }
        }else{
            $verified++
            if($inter -in $PositiveAnswers){
                Write-ColorOut $InFiles[$i].outname -ForegroundColor Green -Indentation 4
            }
        }
    }
    $script:resultvalues.unverified = $unverified
    $script:resultvalues.verified = $verified

    return $InFiles
}

# DEFINITION: Write new file-attributes to history-file:
Function Set-HistFile(){
    param(
        [ValidateNotNullOrEmpty()]
        [array]$InFiles =           $(throw 'InFiles is required by Set-HistFile'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams =    $(throw 'UserParams is required by Set-HistFile')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Write attributes of successfully copied files to history-file..." -ForegroundColor Cyan

    [array]$results = @()
    [array]$results = @($InFiles | Where-Object {$_.ToCopy -eq 0} | ForEach-Object {
        [PSCustomObject]@{
            N = $_.InName
            D = $_.Date
            S = $_.Size
            H = $_.Hash
        }
    })

    if($UserParams.WriteHistFile -eq "Yes" -and (Test-Path -LiteralPath $UserParams.HistFilePath -PathType Leaf) -eq $true){
        try{
            $JSON = Get-Content -LiteralPath $UserParams.HistFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        }catch{
            Write-ColorOut "Could not load $($UserParams.HistFilePath)." -ForegroundColor Red -Indentation 4
            Pause
        }
        $JSON | Out-Null
        $results += $JSON | ForEach-Object {
            [PSCustomObject]@{
                N = $_.InName
                D = $_.Date
                S = $_.Size
                H = $_.Hash
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

    if($UserParams.InfoPreference -gt 0){
        $script:timer = [diagnostics.stopwatch]::StartNew()
    }

    while($true){
        # DEFINITION: Get User-Values:
        try{
            $UserParams = Test-UserValues -UserParams $UserParams
        }catch{
            Start-Sound -Success 0
            Start-Sleep -Seconds 2
            if($UserParams.EnableGUI -eq 1){
                Start-GUI -GUIPath $GUIPath -UserParams $UserParams -GetXAML 0
            }
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
            if((Set-Parameters -UserParams $UserParams) -eq $false){
                Invoke-Close
            }
            Invoke-Pause
        }

        # DEFINITION: If enabled, start preventsleep script:
        if($script:PreventStandby -eq 1){
            Invoke-PreventSleep
        }

        # DEFINITION: Search for files:
        [array]$inputfiles = @(Start-FileSearch -UserParams $UserParams)
        if($inputfiles.Length -lt 1){
            Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
            Start-Sound -Success 1
            Start-Sleep -Seconds 2
            if($UserParams.EnableGUI -eq 1){
                Start-GUI -GUIPath $GUIPath -UserParams $UserParams
            }
            break
        }
        Invoke-Pause

        # DEFINITION: If enabled: Get History-File:
        [array]$histfiles = @()
        if($UserParams.UseHistFile -eq 1){
            try{
                [array]$histfiles = @(Get-HistFile -UserParams $UserParams)
                Invoke-Pause
            }catch{
                break
            }
        }elseif($histfiles.Length -le 0){
            Write-ColorOut "No History-files found." -ForegroundColor Gray -Indentation 4
            $UserParams.UseHistFile = 0
            if($UserParams.WriteHistFile -eq "yes"){
                $UserParams.WriteHistFile = "Overwrite"
            }
        }else{
            # DEFINITION: If enabled: Check for duplicates against history-files:
            [array]$inputfiles = @(Start-DupliCheckHist -InFile $inputfiles -HistFiles $histfiles -UserParams $UserParams)
            if($inputfiles.Length -lt 1){
                Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
                Start-Sound -Success 1
                Start-Sleep -Seconds 2
                if($UserParams.EnableGUI -eq 1){
                    Start-GUI -GUIPath $GUIPath -UserParams $UserParams
                }
                break
            }
            Invoke-Pause
        }

        # DEFINITION: If enabled: Check for duplicates against output-files:
        if($UserParams.CheckOutputDupli -eq 1){
            [array]$inputfiles = (Start-DupliCheckOut -InFiles $inputfiles -UserParams $UserParams)
            if($inputfiles.Length -lt 1){
                Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
                Start-Sound -Success 1
                Start-Sleep -Seconds 2
                if($UserParams.EnableGUI -eq 1){
                    Start-GUI -GUIPath $GUIPath -UserParams $UserParams
                }
                break
            }
            Invoke-Pause
        }

        # DEFINITION: Avoid copying input-files more than once:
        if($UserParams.AvoidIdenticalFiles -eq 1){
            [array]$inputfiles = (Start-InputGetHash -InFiles $inputfiles)
            Invoke-Pause
            [array]$inputfiles = Start-PreventingDoubleCopies -InFiles $inputfiles
            Invoke-Pause
        }

        Write-ColorOut "Files left after dupli-check(s):`t$($script:resultvalues.ingoing - $script:resultvalues.duplihist - $script:resultvalues.dupliout - $script:resultvalues.identicalFiles) = $($script:resultvalues.copyfiles)" -ForegroundColor Yellow -Indentation 4

        # DEFINITION: Get free space:
        if((Start-SpaceCheck -InFiles $inputfiles -OutPath $UserParams.OutputPath) -eq $false){
            Start-Sound -Success 0
            Start-Sleep -Seconds 2
            if($UserParams.EnableGUI -eq 1){
                Start-GUI -GUIPath $GUIPath -UserParams $UserParams
            }
            break
        }
        Invoke-Pause

        # DEFINITION: Copy stuff and check it:
        $j = 0
        while(1 -in $inputfiles.tocopy){
            if($j -gt 0){
                Write-ColorOut "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                if((Read-Host " Positive answers: $PositiveAnswers") -notin $PositiveAnswers){
                    Write-ColorOut "Aborting." -ForegroundColor Cyan
                    Start-Sleep -Seconds 2
                    if($UserParams.EnableGUI -eq 1){
                        Start-GUI -GUIPath $GUIPath -UserParams $UserParams
                    }
                    break
                }
            }
            [array]$inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -UserParams $UserParams -Mirror 0)
            Invoke-Pause
            # TODO: try-catch
            Start-FileCopy -InFiles $inputfiles -UserParams $UserParams
            Invoke-Pause
            if($UserParams.VerifyCopies -eq 1){
                # DEFINITION: Get hashes of all remaining input-files:
                [array]$inputfiles = (Start-InputGetHash -InFiles $inputfiles)
                Invoke-Pause
                [array]$inputfiles = (Start-FileVerification -InFiles $inputfiles)
                Invoke-Pause
                $j++
            }else{
                foreach($instance in $inputfiles.tocopy){
                    $instance = 0
                }
            }
        }
        # DEFINITION: Unmount input-drive:
        if($UserParams.UnmountInputDrive -eq 1){
            # CREDIT: https://serverfault.com/a/580298
            # TODO: Find a solution that works with all drives.
            $driveEject = New-Object -comObject Shell.Application
            try{
                $driveEject.Namespace(17).ParseName($(Split-Path -Qualifier -Path $UserParams.InputPath)).InvokeVerb("Eject")
                Write-ColorOut "Drive $(Split-Path -Qualifier -Path $UserParams.InputPath) successfully ejected!" -ForegroundColor DarkCyan -BackgroundColor Gray
            }
            catch{
                Write-ColorOut "Couldn't eject drive $(Split-Path -Qualifier -Path $UserParams.InputPath)." -ForegroundColor Magenta
            }
        }
        if($UserParams.WriteHistFile -ne "no"){
            Set-HistFile -InFiles $inputfiles -UserParams $UserParams
            Invoke-Pause
        }
        if($UserParams.MirrorEnable -eq 1){
            # DEFINITION: Get free space:
            if((Start-SpaceCheck -InFiles $inputfiles -OutPath $UserParams.MirrorPath) -eq $false){
                Start-Sound -Success 0
                Start-Sleep -Seconds 2
                if($UserParams.EnableGUI -eq 1){
                    Start-GUI -GUIPath $GUIPath -UserParams $UserParams
                }
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
                Start-7zip -InFiles $inputfiles
                Invoke-Pause
            }else{
                $j = 1
                while(1 -in $inputfiles.tocopy){
                    if($j -gt 1){
                        Write-ColorOut "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                        if((Read-Host "Positive answers: $PositiveAnswers") -notin $PositiveAnswers){
                            break
                        }
                    }
                    [array]$inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -UserParams $UserParams -Mirror 1)
                    Invoke-Pause
                    Start-FileCopy -InFiles $inputfiles -UserParams $UserParams
                    Invoke-Pause
                    if($UserParams.VerifyCopies -eq 1){
                        [array]$inputfiles = (Start-FileVerification -InFiles $inputfiles)
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
        Stop-Process -Id $script:PreventStandby
    }
    if($UserParams.EnableGUI -eq 1){
        Start-GUI -GUIPath $GUIPath -UserParams $UserParams
    }
}


# ==================================================================================================
# ==============================================================================
#    Starting everything:
# ==============================================================================
# ==================================================================================================

<# DEFINITION: Console banner:
    Write-ColorOut "                            flolilo's Media-Copytool                            " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "                          $VersionNumber           " -ForegroundColor DarkMagenta -BackgroundColor DarkGray -NoNewLine
    Write-ColorOut "(PID = $("{0:D8}" -f $pid))`r`n" -ForegroundColor Gray -BackgroundColor DarkGray
    $Host.UI.RawUI.WindowTitle = "CLI: Media-Copytool $VersionNumber"

# DEFINITION: Start-up:
    while($true){
        try{
            [hashtable]$UserParams = Get-ParametersFromJSON -UserParams $UserParams -Renew 0
        }catch{
            break
        }
        if($UserParams.EnableGUI -eq 1){
            try{
                Start-GUI -GUIPath $GUIPath -UserParams $UserParams -GetXAML 1
                Break
            }catch{
                $UserParams.EnableGUI = 0
                Continue
            }
        }elseif($UserParams.EnableGUI -eq 0){
            Start-Everything -UserParams $UserParams
            Break
        }else{
            Write-ColorOut "Invalid choice of -EnableGUI value (0, 1). Trying GUI..." -ForegroundColor Red
            Start-Sleep -Seconds 2
            $UserParams.EnableGUI = 1
            Continue
        }
    }
#>
