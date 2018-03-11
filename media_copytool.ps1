#requires -version 3

<#
    .SYNOPSIS
        Copy (and verify) user-defined filetypes from A to B (and optionally C).
    .DESCRIPTION
        Uses Windows' Robocopy and Xcopy for file-copy, then uses PowerShell's Get-FileHash (SHA1) for verifying that files were copied without errors.
        Now supports multithreading via Boe Prox's PoshRSJob-cmdlet (https://github.com/proxb/PoshRSJob)
    .NOTES
        Version:        0.8.12 (Beta)
        Author:         flolilo
        Creation Date:  2018-02-24
        Legal stuff: This program is free software. It comes without any warranty, to the extent permitted by
        applicable law. Most of the script was written by myself (or heavily modified by me when searching for solutions
        on the WWW). However, some parts are copies or modifications of very genuine code - see
        the "CREDIT:"-tags to find them.

    .PARAMETER ShowParams
        Cannot be specified in mc_parameters.json.
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it shows the pre-set parameters, so you can see what would happen if you e.g. try 'media_copytool.ps1 -GUI_CLI_Direct "direct"'
    .PARAMETER GUI_CLI_Direct
        Sets the mode in which the script will guide the user.
        Valid options:
            "GUI" - Graphical User Interface (default)
            "CLI" - interactive console
            "direct" - instant execution with given parameters.
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
            "Can"   - *.CR2
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
        mc_GUI.xaml if -GUI_CLI_direct is "GUI",
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
        media_copytool.ps1 -GUI_CLI_Direct "GUI"
    .EXAMPLE
        Copy Canon's Raw-Files, Movies, JPEGs from G:\ to D:\Backup and prevent the computer from ging to standby:
        media_copytool.ps1 -PresetFormats "Can","Mov","Jpg" .InputPath "G:\" -OutputPath "D:\Backup" -PreventStandby 1 
#>
param(
    [int]$ShowParams =              0,
    [string]$GUI_CLI_Direct =       "GUI",
    [string]$JSONParamPath =        "$($PSScriptRoot)\mc_parameters.json",
    [string]$LoadParamPresetName =  "default",
    [string]$SaveParamPresetName =  "",
    [int]$RememberInPath =          0,
    [int]$RememberOutPath =         0,
    [int]$RememberMirrorPath =      0,
    [int]$RememberSettings =        0,
    [int]$Debug =                   1,
    # From here on, parameters can be set both via parameters and via JSON file(s).
    [string]$InputPath =            "",
    [string]$OutputPath =           "",
    [int]$MirrorEnable =            -1,
    [string]$MirrorPath =           "",
    [array]$PresetFormats =         @(),
    [int]$CustomFormatsEnable =     -1,
    [array]$CustomFormats =         @(),
    [string]$OutputSubfolderStyle = "",
    [string]$OutputFileStyle =      "",
    [string]$HistFilePath =         "",
    [int]$UseHistFile =             -1,
    [string]$WriteHistFile =        "",
    [int]$HistCompareHashes =       -1,
    [int]$InputSubfolderSearch =    -1,
    [int]$CheckOutputDupli =        -1,
    [int]$VerifyCopies =            -1,
    [int]$OverwriteExistingFiles =  -1,
    [int]$AvoidIdenticalFiles =     -1,
    [int]$ZipMirror =               -1,
    [int]$UnmountInputDrive =       -1,
    [int]$PreventStandby =          -1
)
# DEFINITION: Combine all parameters into a hashtable, then delete the parameter variables:
    [hashtable]$UserParams = @{
        ShowParams = $ShowParams
        GUI_CLI_Direct = $GUI_CLI_Direct
        JSONParamPath = $JSONParamPath
        LoadParamPresetName = $LoadParamPresetName
        SaveParamPresetName = $SaveParamPresetName
        RememberInPath = $RememberInPath
        RememberOutPath = $RememberOutPath
        RememberMirrorPath = $RememberMirrorPath
        RememberSettings = $RememberSettings
        # DEFINITION: From here on, parameters can be set both via parameters and via JSON file(s).
        InputPath = $InputPath
        OutputPath = $OutputPath
        MirrorEnable = $MirrorEnable
        MirrorPath = $MirrorPath
        PresetFormats = $PresetFormats
        CustomFormatsEnable = $CustomFormatsEnable
        CustomFormats = $CustomFormats
        OutputSubfolderStyle = $OutputSubfolderStyle
        OutputFileStyle = $OutputFileStyle
        HistFilePath = $HistFilePath
        UseHistFile = $UseHistFile
        WriteHistFile = $WriteHistFile
        HistCompareHashes = $HistCompareHashes
        InputSubfolderSearch = $InputSubfolderSearch
        CheckOutputDupli = $CheckOutputDupli
        VerifyCopies = $VerifyCopies
        OverwriteExistingFiles = $OverwriteExistingFiles
        AvoidIdenticalFiles = $AvoidIdenticalFiles
        ZipMirror = $ZipMirror
        UnmountInputDrive = $UnmountInputDrive
        allChosenFormats = @()
    }
    Remove-Variable -Name ShowParams,GUI_CLI_Direct,JSONParamPath,LoadParamPresetName,SaveParamPresetName,RememberInPath,RememberOutPath,RememberMirrorPath,RememberSettings,InputPath,OutputPath,MirrorEnable,MirrorPath,PresetFormats,CustomFormatsEnable,CustomFormats,OutputSubfolderStyle,OutputFileStyle,HistFilePath,UseHistFile,WriteHistFile,HistCompareHashes,InputSubfolderSearch,CheckOutputDupli,VerifyCopies,OverwriteExistingFiles,AvoidIdenticalFiles,ZipMirror,UnmountInputDrive

# DEFINITION: Vars for getting GUI variables, ThreadCount
    # If you want to see the variables (buttons, checkboxes, ...) the GUI has to offer, set this to 1:
        $GetWPF = 0
    # ThreadCount for xCopy / RoboCopy:
        $ThreadCount = 4
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
# DEFINITION: Set default ErrorAction to Stop: CREDIT: https://stackoverflow.com/a/21260623/8013879
    if($Debug -eq 0){
        $PSDefaultParameterValues = @{}
        $PSDefaultParameterValues += @{'*:ErrorAction' = 'Stop'}
        $ErrorActionPreference = 'Stop'
    }

# DEFINITION: Load PoshRSJob:
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
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -TypeName System.Text.UTF8Encoding
# DEFINITION: Set current date and version number:
    $VersionNumber = "v0.8.12 (Beta) - 2018-02-24"

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
            Date: 2017-10-25
        
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
    <#param(
        [ValidateNotNullOrEmpty()]
        [string]$Object,

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
    }#>
}

# DEFINITION: Pause the programme if debug-var is active. Also, enable measuring times per command with -debug 3.
Function Invoke-Pause(){
    if($script:Debug -gt 0){
        Write-ColorOut "Processing-time:`t$($script:timer.elapsed.TotalSeconds)" -ForegroundColor Magenta
    }
    if($script:Debug -gt 1){
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
    if($script:Debug -gt 0){
        Pause
    }

    $Host.UI.RawUI.WindowTitle = "Windows PowerShell"
    Exit
}

# DEFINITION: For the auditory experience:
Function Start-Sound([int]$Success){
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
            For success: Start-Sound(1)
        .EXAMPLE
            For fail: Start-Sound(0)
    #>
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

# DEFINITION: Start equivalent to PreventSleep.ps1:
Function Invoke-PreventSleep(){
    <#
        .NOTES
            v1.1 - 2018-02-25
    #>
    Write-ColorOut "$(Get-CurrentDate)  --  Starting preventsleep-script..." -ForegroundColor Cyan

$standby = @'
    # DEFINITION: For button-emulation:
    Write-Host "(PID = $("{0:D8}" -f $pid))" -ForegroundColor Gray
    $MyShell = New-Object -ComObject "Wscript.Shell"
    while($true){
        # DEFINITION:/CREDIT: https://superuser.com/a/1023836/703240
        $MyShell.sendkeys("{F15}")
        Start-Sleep -Seconds 90
    }
'@
    $standby = [System.Text.Encoding]::Unicode.GetBytes($standby)
    $standby = [Convert]::ToBase64String($standby)

    try{
        [int]$inter = (Start-Process powershell -ArgumentList "-EncodedCommand $standby" -WindowStyle Hidden -PassThru).Id
        if($script:Debug -gt 0){
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
    return $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

# ==================================================================================================
# ==============================================================================
#    Defining specific functions:
# ==============================================================================
# ==================================================================================================

# DEFINITION: Get parameters from JSON file:
Function Get-Parameters(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Get-Parameters'),
        [ValidateRange(0,1)]
        [int]$Renew = $(throw 'Renew is required by Get-Parameters')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting parameter-values..." -ForegroundColor Cyan

    if($Renew -eq 1 -or
        $UserParams.InputPath.Length -lt 3 -or
        $UserParams.OutputPath.Length -lt 3 -or
        $UserParams.MirrorEnable -eq -1 -or
        ($UserParams.MirrorEnable -eq 1 -and $UserParams.MirrorPath.Length -lt 3) -or
        ($UserParams.PresetFormats.Length -eq 0 -and $UserParams.CustomFormatsEnable.Length -eq -1 -or ($UserParams.CustomFormatsEnable -eq 1 -and $UserParams.CustomFormats.Length -eq 0)) -or
        $UserParams.OutputSubfolderStyle.Length -eq 0 -or
        $UserParams.OutputFileStyle.Length -eq 0 -or
        $UserParams.HistFilePath.Length -lt 6 -or
        $UserParams.UseHistFile -eq -1 -or
        $UserParams.WriteHistFile.Length -eq 0 -or
        $UserParams.HistCompareHashes -eq -1 -or
        $UserParams.InputSubfolderSearch -eq -1 -or
        $UserParams.CheckOutputDupli -eq -1 -or
        $UserParams.VerifyCopies -eq -1 -or
        $UserParams.OverwriteExistingFiles -eq -1 -or
        $UserParams.AvoidIdenticalFiles -eq -1 -or
        $UserParams.ZipMirror -eq -1 -or
        $UserParams.UnmountInputDrive -eq -1 -or
        $script:PreventStandby -eq -1
    ){
        if((Test-Path -LiteralPath $UserParams.JSONParamPath -PathType Leaf -ErrorAction SilentlyContinue) -eq $true){
            try{
                $jsonparams = Get-Content -LiteralPath $UserParams.JSONParamPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                if($jsonparams.Length -eq 0){
                    Write-ColorOut "$($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) is empty!" -ForegroundColor Magenta -Indentation 4
                    return $false
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
                if($UserParams.PresetFormats.Length -eq 0 -or $Renew -eq 1){
                    [array]$UserParams.PresetFormats = @($jsonparams.PresetFormats)
                }
                if($UserParams.CustomFormatsEnable -eq -1 -or $Renew -eq 1){
                    [int]$UserParams.CustomFormatsEnable = $jsonparams.CustomFormatsEnable
                }
                if($UserParams.CustomFormats.Length -eq 0 -or $Renew -eq 1){
                    [array]$UserParams.CustomFormats = @($jsonparams.CustomFormats)
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
                if($UserParams.InputSubfolderSearch -eq -1 -or $Renew -eq 1){
                    [int]$UserParams.InputSubfolderSearch = $jsonparams.InputSubfolderSearch
                }
                if($UserParams.CheckOutputDupli -eq -1 -or $Renew -eq 1){
                    [int]$UserParams.CheckOutputDupli = $jsonparams.CheckOutputDupli
                }
                if($UserParams.VerifyCopies -eq -1 -or $Renew -eq 1){
                    [int]$UserParams.VerifyCopies = $jsonparams.VerifyCopies
                }
                if($UserParams.OverwriteExistingFiles -eq -1 -or $Renew -eq 1){
                    [int]$UserParams.OverwriteExistingFiles = $jsonparams.OverwriteExistingFiles
                }
                if($UserParams.AvoidIdenticalFiles -eq -1 -or $Renew -eq 1){
                    [int]$UserParams.AvoidIdenticalFiles = $jsonparams.AvoidIdenticalFiles
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
                if($UserParams.GUI_CLI_Direct -eq "direct"){
                    Write-ColorOut "$($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) cannot be loaded - aborting!" -ForegroundColor Red -Indentation 4
                    Write-ColorOut "(You can specify the path with -JSONParamPath. Also, if you use `"-GUI_CLI_Direct direct`", you can circumvent this error by setting all parameters by yourself - or use `"-GUI_CLI_Direct CLI`" or `"-GUI_CLI_Direct GUI`".)" -ForegroundColor Magenta -Indentation 4
                    Start-Sleep -Seconds 5
                    return $false
                }else{
                    Write-ColorOut "$($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) - cannot load presets!" -ForegroundColor Magenta -Indentation 4
                    Write-ColorOut "(It is recommended to use a JSON-file to save your parameters. You can save one when activating one of the `"Save`"-checkboxes in the GUI - or simply download the one from GitHub.)" -ForegroundColor Blue -Indentation 4
                    Start-Sleep -Seconds 5
                }
            }
        }else{
            if($UserParams.GUI_CLI_Direct -eq "direct"){
                Write-ColorOut "$($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) does not exist - aborting!" -ForegroundColor Red -Indentation 4
                Write-ColorOut "(You can specify the path with -JSONParamPath. Also, if you use `"-GUI_CLI_Direct direct`", you can circumvent this error by setting all parameters by yourself - or use `"-GUI_CLI_Direct CLI`" or `"-GUI_CLI_Direct GUI`".)" -ForegroundColor Magenta -Indentation 4
                Start-Sleep -Seconds 5
                return $false
            }else{
                Write-ColorOut "$($UserParams.JSONParamPath.Replace("$($PSScriptRoot)",".")) does not exist - cannot load presets!" -ForegroundColor Magenta -Indentation 4
                Write-ColorOut "(It is recommended to use a JSON-file to save your parameters. You can save one when activating one of the `"Save`"-checkboxes in the GUI - or simply download the one from GitHub.)" -ForegroundColor Blue -Indentation 4
                Start-Sleep -Seconds 5
            }
        }
    }

    return $UserParams
}

# DEFINITION: Get values from GUI, then check the main input- and outputfolder:
Function Get-UserValuesGUI(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Get-UserValuesGUI'),
        [ValidateNotNullOrEmpty()]
        [hashtable]$GUIParams = $(throw 'GUIParams is required by Get-UserValuesGUI')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting user-values..." -ForegroundColor Cyan

    # DEFINITION: Get values, test paths:
        # $SaveParamPresetName
        $UserParams.SaveParamPresetName = $($GUIParams.textBoxSavePreset.Text.ToLower() -Replace '[^A-Za-z0-9_+-]','')
        $UserParams.SaveParamPresetName = $UserParams.SaveParamPresetName.Substring(0, [math]::Min($UserParams.SaveParamPresetName.Length, 64))
        # $InputPath
        $UserParams.InputPath = $GUIParams.textBoxInput.Text
        if($UserParams.InputPath.Length -lt 2 -or (Test-Path -LiteralPath $UserParams.InputPath -PathType Container -ErrorAction SilentlyContinue) -eq $false){
            Write-ColorOut "Input-path $($UserParams.InputPath) could not be found.`r`n" -ForegroundColor Red -Indentation 4
            return $false
        }
        # $OutputPath
        $UserParams.OutputPath = $GUIParams.textBoxOutput.Text
        if($UserParams.OutputPath -eq $UserParams.InputPath){
            Write-ColorOut "Output-path $($UserParams.OutputPath) is the same as input-path.`r`n" -ForegroundColor Red -Indentation 4
            return $false
        }
        if($UserParams.OutputPath.Length -lt 2 -or (Test-Path -LiteralPath $UserParams.OutputPath -PathType Container -ErrorAction SilentlyContinue) -eq $false){
            if((Split-Path -Parent -Path $UserParams.OutputPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $UserParams.OutputPath) -PathType Container) -eq $true){
                try{
                    New-Item -ItemType Directory -Path $UserParams.OutputPath -ErrorAction Stop | Out-Null
                    Write-ColorOut "Output-path $($UserParams.OutputPath) created." -ForegroundColor Yellow -Indentation 4
                }catch{
                    Write-ColorOut "Could not create output-path $($UserParams.OutputPath)." -ForegroundColor Red -Indentation 4
                    return $false
                }
            }else{
                Write-ColorOut "Output-path $($UserParams.OutputPath) not found." -ForegroundColor Red -Indentation 4
                return $false
            }
        }
        # $MirrorEnable
        $UserParams.MirrorEnable = $(
            if($GUIParams.checkBoxMirror.IsChecked -eq $true){1}
            else{0}
        )
        # $MirrorPath
        if($UserParams.MirrorEnable -eq 1){
            $UserParams.MirrorPath = $GUIParams.textBoxMirror.Text
            if($UserParams.MirrorPath -eq $UserParams.InputPath -or $UserParams.MirrorPath -eq $UserParams.OutputPath){
                Write-ColorOut "Additional output-path $($UserParams.MirrorPath) is the same as input- or output-path." -ForegroundColor Red -Indentation 4
                return $false
            }
            if($UserParams.MirrorPath.Length -lt 2 -or (Test-Path -LiteralPath $UserParams.MirrorPath -PathType Container -ErrorAction SilentlyContinue) -eq $false){
                if((Test-Path -LiteralPath $(Split-Path -Qualifier -Path $UserParams.MirrorPath) -PathType Container -ErrorAction SilentlyContinue) -eq $true){
                    try{
                        New-Item -ItemType Directory -Path $UserParams.MirrorPath -ErrorAction Stop | Out-Null
                        Write-ColorOut "Mirror-path $($UserParams.MirrorPath) created." -ForegroundColor Yellow -Indentation 4
                    }catch{
                        Write-ColorOut "Could not create mirror-path $($UserParams.MirrorPath)." -ForegroundColor Red -Indentation 4
                        return $false
                    }
                }else{
                    Write-ColorOut "Additional output-path $($UserParams.MirrorPath) not found." -ForegroundColor Red -Indentation 4
                    return $false
                }
            }
        }
        # $PresetFormats
        [array]$UserParams.PresetFormats = @()
        if($GUIParams.checkBoxCan.IsChecked -eq $true){$UserParams.PresetFormats += "Can"}
        if($GUIParams.checkBoxNik.IsChecked -eq $true){$UserParams.PresetFormats += "Nik"}
        if($GUIParams.checkBoxSon.IsChecked -eq $true){$UserParams.PresetFormats += "Son"}
        if($GUIParams.checkBoxJpg.IsChecked -eq $true){$UserParams.PresetFormats += "Jpg"}
        if($GUIParams.checkBoxInter.IsChecked -eq $true){$UserParams.PresetFormats += "Inter"}
        if($GUIParams.checkBoxMov.IsChecked -eq $true){$UserParams.PresetFormats += "Mov"}
        if($GUIParams.checkBoxAud.IsChecked -eq $true){$UserParams.PresetFormats += "Aud"}
        # $CustomFormatsEnable
        $UserParams.CustomFormatsEnable = $(
            if($GUIParams.checkBoxCustom.IsChecked -eq $true){1}
            else{0}
        )
        # $CustomFormats
        [array]$UserParams.CustomFormats = @()
        $separator = ","
        $option = [System.StringSplitOptions]::RemoveEmptyEntries
        $UserParams.CustomFormats = $GUIParams.textBoxCustom.Text.Replace(" ",'').Split($separator,$option)
        # $OutputSubfolderStyle
        $UserParams.OutputSubfolderStyle = $(
            if($GUIParams.comboBoxOutSubStyle.SelectedIndex -eq 0){"none"}
            elseif($GUIParams.comboBoxOutSubStyle.SelectedIndex -eq 1){"unchanged"}
            elseif($GUIParams.comboBoxOutSubStyle.SelectedIndex -eq 2){"yyyy-MM-dd"}
            elseif($GUIParams.comboBoxOutSubStyle.SelectedIndex -eq 3){"yyyy_MM_dd"}
            elseif($GUIParams.comboBoxOutSubStyle.SelectedIndex -eq 4){"yyyy.MM.dd"}
            elseif($GUIParams.comboBoxOutSubStyle.SelectedIndex -eq 5){"yyyyMMdd"}
            elseif($GUIParams.comboBoxOutSubStyle.SelectedIndex -eq 6){"yy-MM-dd"}
            elseif($GUIParams.comboBoxOutSubStyle.SelectedIndex -eq 7){"yy_MM_dd"}
            elseif($GUIParams.comboBoxOutSubStyle.SelectedIndex -eq 8){"yy.MM.dd"}
            elseif($GUIParams.comboBoxOutSubStyle.SelectedIndex -eq 9){"yyMMdd"}
        )
        # $OutputFileStyle
        $UserParams.OutputFileStyle = $(
            if($GUIParams.comboBoxOutFileStyle.SelectedIndex -eq 0){"unchanged"}
            elseif($GUIParams.comboBoxOutFileStyle.SelectedIndex -eq 1){"yyyy-MM-dd_HH-mm-ss"}
            elseif($GUIParams.comboBoxOutFileStyle.SelectedIndex -eq 2){"yyyyMMdd_HHmmss"}
            elseif($GUIParams.comboBoxOutFileStyle.SelectedIndex -eq 3){"yyyyMMddHHmmss"}
            elseif($GUIParams.comboBoxOutFileStyle.SelectedIndex -eq 4){"yy-MM-dd_HH-mm-ss"}
            elseif($GUIParams.comboBoxOutFileStyle.SelectedIndex -eq 5){"yyMMdd_HHmmss"}
            elseif($GUIParams.comboBoxOutFileStyle.SelectedIndex -eq 6){"yyMMddHHmmss"}
            elseif($GUIParams.comboBoxOutFileStyle.SelectedIndex -eq 7){"HH-mm-ss"}
            elseif($GUIParams.comboBoxOutFileStyle.SelectedIndex -eq 8){"HH_mm_ss"}
            elseif($GUIParams.comboBoxOutFileStyle.SelectedIndex -eq 9){"HHmmss"}
        )
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
        if(($UserParams.UseHistFile -eq 1 -or $UserParams.WriteHistFile -ne "no") -and (Test-Path -LiteralPath $UserParams.HistFilePath -PathType Leaf -ErrorAction SilentlyContinue) -eq $false){
            [string]$inter = Split-Path $UserParams.HistFilePath -Qualifier
            if((Test-Path -LiteralPath $inter -PathType Container) -eq $false){
                Write-ColorOut "History-file-volume $inter could not be found." -ForegroundColor Red -Indentation 4
                return $false
            }else{
                if($UserParams.UseHistFile -eq 1){
                    Write-ColorOut "History-file does not exist. Therefore, dupli-check via history will be disabled." -ForegroundColor Magenta -Indentation 4
                    $UserParams.UseHistFile = 0
                    Start-Sleep -Seconds 2
                }
            }
        }
        # $HistCompareHashes
        $UserParams.HistCompareHashes = $(
            if($GUIParams.checkBoxCheckHashHist.IsChecked -eq $true){1}
            else{0}
        )
        # $InputSubfolderSearch
        $UserParams.InputSubfolderSearch = $(
            if($GUIParams.checkBoxInSubSearch.IsChecked -eq $true){1}
            else{0}
        )
        # $CheckOutputDupli
        $UserParams.CheckOutputDupli = $(
            if($GUIParams.checkBoxOutputDupli.IsChecked -eq $true){1}
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
        # $AvoidIdenticalFiles
        $UserParams.AvoidIdenticalFiles = $(
            if($GUIParams.checkBoxAvoidIdenticalFiles.IsChecked -eq $true){1}
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

    # DEFINITION: Sum up formats:
        [array]$UserParams.allChosenFormats = @()
        if("Can" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.cr2"
        }
        if("Nik" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.nef"
            $UserParams.allChosenFormats += "*.nrw"
        }
        if("Son" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.arw"
        }
        if("Jpg" -in $UserParams.PresetFormats -or "Jpeg" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.jpg"
            $UserParams.allChosenFormats += "*.jpeg"
        }
        if("Inter" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.dng"
            $UserParams.allChosenFormats += "*.tif"
        }
        if("Mov" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.mov"
            $UserParams.allChosenFormats += "*.mp4"
        }
        if("Aud" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.wav"
            $UserParams.allChosenFormats += "*.mp3"
            $UserParams.allChosenFormats += "*.m4a"
        }
        if($UserParams.CustomFormatsEnable -ne 0 -and $UserParams.CustomFormats.Length -gt 0){
            for($i = 0; $i -lt $UserParams.CustomFormats.Length; $i++){
                $UserParams.allChosenFormats += $UserParams.CustomFormats[$i]
            }
        }
        if($UserParams.allChosenFormats.Length -eq 0){
            if((Read-Host "    No file-format selected. Copy all files? 1 = yes, 0 = no.") -eq 1){
                [array]$UserParams.allChosenFormats = "*"
            }else{
                Write-ColorOut "No file-format specified." -ForegroundColor Red -Indentation 4
                return $false
            }
        }

    # DEFINITION: Build switches:
        [switch]$script:input_recurse = $(
            if($UserParams.InputSubfolderSearch -eq 1)  {$true}
            else                                        {$false}
        )

    # DEFINITION: Check paths for trailing backslash:
        if($UserParams.InputPath.replace($UserParams.InputPath.Substring(0,$UserParams.InputPath.Length-1),"") -eq "\" -and $UserParams.InputPath.Length -gt 3){
            $UserParams.InputPath = $UserParams.InputPath.Substring(0,$UserParams.InputPath.Length-1)
        }
        if($UserParams.OutputPath.replace($UserParams.OutputPath.Substring(0,$UserParams.OutputPath.Length-1),"") -eq "\" -and $UserParams.OutputPath.Length -gt 3){
            $UserParams.OutputPath = $UserParams.OutputPath.Substring(0,$UserParams.OutputPath.Length-1)
        }
        if($UserParams.MirrorPath.replace($UserParams.MirrorPath.Substring(0,$UserParams.MirrorPath.Length-1),"") -eq "\" -and $UserParams.MirrorPath.Length -gt 3){
            $UserParams.MirrorPath = $UserParams.MirrorPath.Substring(0,$UserParams.MirrorPath.Length-1)
        }

    # If everything was sucessful, return UserParams:
    return $UserParams
}

# DEFINITION: Get values from CLI, then check the main input- and outputfolder:
Function Get-UserValuesCLI(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Get-UserValuesCLI')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting user-values..." -ForegroundColor Cyan

    # DEFINITION: Get values, test paths:
        # $InputPath
        while($true){
            try{
                [string]$UserParams.InputPath = Read-Host "    Please specify input-path"
                if($UserParams.InputPath.Length -gt 1 -and (Test-Path -LiteralPath $UserParams.InputPath -PathType Container -ErrorAction SilentlyContinue) -eq $true){
                    break
                }else{
                    Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }catch{
                continue
            }
        }
        # $OutputPath
        while($true){
            [string]$UserParams.OutputPath = Read-Host "    Please specify output-path"
            if($UserParams.OutputPath -eq $UserParams.InputPath){
                Write-ColorOut "Input-path is the same as output-path.`r`n" -ForegroundColor Magenta -Indentation 4
                continue
            }else{
                if($UserParams.OutputPath.Length -gt 1 -and (Test-Path -LiteralPath $UserParams.OutputPath -PathType Container) -eq $true){
                    break
                }elseif((Split-Path -Parent -Path $UserParams.OutputPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $UserParams.OutputPath) -PathType Container) -eq $true){
                    try{
                        New-Item -ItemType Directory -Path $UserParams.OutputPath -ErrorAction Stop | Out-Null
                        Write-ColorOut "Directory $UserParams.OutputPath created." -ForegroundColor Yellow -Indentation 4
                        break
                    }catch{
                        Write-ColorOut "Could not reate directory $UserParams.OutputPath - aborting!" -ForegroundColor Magenta -Indentation 4
                        return $false
                    }
                }else{
                    Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
        }
        # $MirrorEnable
        while($true){
            [int]$UserParams.MirrorEnable = Read-Host "    Copy files to an additional folder? 1 = yes, 0 = no."
            if($UserParams.MirrorEnable -eq 1 -or $UserParams.MirrorEnable -eq 0){
                break
            }else{
                Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $MirrorPath
        if($UserParams.MirrorEnable -eq 1){
            while($true){
                [string]$UserParams.MirrorPath = Read-Host "    Please specify additional output-path"
                if($UserParams.MirrorPath -eq $UserParams.OutputPath -or $UserParams.MirrorPath -eq $UserParams.InputPath){
                    Write-ColorOut "`r`nAdditional output-path is the same as input- or output-path.`r`n" -ForegroundColor Red -Indentation 4
                    continue
                }
                if($UserParams.MirrorPath -gt 1 -and (Test-Path -LiteralPath $UserParams.MirrorPath -PathType Container) -eq $true){
                    break
                }elseif((Split-Path -Parent -Path $UserParams.MirrorPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $UserParams.MirrorPath) -PathType Container) -eq $true){
                    try{
                        New-Item -ItemType Directory -Path $UserParams.MirrorPath -ErrorAction Stop | Out-Null
                        Write-ColorOut "Directory $($UserParams.OutputPath) created." -ForegroundColor Yellow -Indentation 4
                        break
                    }catch{
                        Write-ColorOut "Could not reate directory $($UserParams.OutputPath) - aborting!" -ForegroundColor Magenta -Indentation 4
                        return $false
                    }
                }else{
                    Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
        }
        # $PresetFormats
        while($true){
            [array]$inter=@("Can","Nik","Son","Jpeg","Jpg","Inter","Mov","Aud")
            $separator = ","
            $option = [System.StringSplitOptions]::RemoveEmptyEntries
            [array]$UserParams.PresetFormats = (Read-Host "    Which preset file-formats would you like to copy? Options: `"Can`",`"Nik`",`"Son`",`"Jpg`",`"Inter`",`"Mov`",`"Aud`", or leave empty for none. For multiple selection, separate with commata.").Split($separator,$option)
            if($UserParams.PresetFormats.Length -eq 0 -or $UserParams.PresetFormats -in $inter){
                break
            }else{
                Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $CustomFormatsEnable - Number
        while($true){
            [int]$UserParams.CustomFormatsEnable = Read-Host "    How many custom file-formats? Range: From 0 for `"none`" to as many as you like."
            if($UserParams.CustomFormatsEnable -in (0..999)){
                break
            }else{
                Write-ColorOut "Please choose a positive number!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $CustomFormats
        [array]$UserParams.CustomFormats = @()
        if($UserParams.CustomFormatsEnable -ne 0){
            for($i = 1; $i -le $UserParams.CustomFormatsEnable; $i++){
                while($true){
                    [string]$inter = Read-Host "    Select custom format no. $i. `"*`" (w/o quotes) = all files, `"*.ext`" = all files with extension .ext, `"file.*`" = all files named file."
                    if($inter.Length -ne 0){
                        $UserParams.CustomFormats += $inter
                        break
                    }else{
                        Write-ColorOut "Invalid input!" -ForegroundColor Magenta -Indentation 4
                        continue
                    }
                }
            }
        }
        # $OutputSubfolderStyle
        while($true){
            [array]$inter = @("none","unchanged","yyyy-MM-dd","yyyy_MM_dd","yyyy.MM.dd","yyyyMMdd","yy-MM-dd","yy_MM_dd","yy.MM.dd","yyMMdd")
            [string]$UserParams.OutputSubfolderStyle = Read-Host "    Which subfolder-style should be used in the output-path? Options: none, unchanged, yyyy-MM-dd, yyyy_MM_dd, yyyy.MM.dd, yyyyMMdd, yy-MM-dd, yy_MM_dd, yy.MM.dd, yyMMdd."
            if($UserParams.OutputSubfolderStyle -in $inter){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $OutputFileStyle
        while($true){
            [array]$inter = @("unchanged","yyyy-MM-dd_HH-mm-ss","yyyyMMdd_HHmmss","yyyyMMddHHmmss","yy-MM-dd_HH-mm-ss","yyMMdd_HHmmss","yyMMddHHmmss","HH-mm-ss","HH_mm_ss","HHmmss")
            [string]$UserParams.OutputFileStyle = Read-Host "    Which subfolder-style should be used in the output-path? Options: unchanged, yyyy-MM-dd_HH-mm-ss, yyyyMMdd_HHmmss, yyyyMMddHHmmss, yy-MM-dd_HH-mm-ss, yyMMdd_HHmmss, yyMMddHHmmss, HH-mm-ss, HH_mm_ss, HHmmss."
            if($UserParams.OutputFileStyle -cin $inter){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $UseHistFile
        while($true){
            [int]$UserParams.UseHistFile = Read-Host "    Compare input-files with the history-file to prevent duplicates? 1 = yes, 0 = no"
            if($UserParams.UseHistFile -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $WriteHistFile
        while($true){
            [array]$inter = @("yes","no","overwrite")
            [string]$UserParams.WriteHistFile = Read-Host "    Write newly copied files to history-file? Options: yes, no, overwrite."
            if($UserParams.WriteHistFile -in $inter){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $HistFilePath
        if($UserParams.UseHistFile -eq 1 -or $UserParams.WriteHistFile -ne "no"){
            while($true){
                [string]$UserParams.HistFilePath = Read-Host "    Please specify path for the history-file"
                if($UserParams.HistFilePath.Length -gt 1 -and (Test-Path -LiteralPath $UserParams.HistFilePath -PathType Leaf) -eq $true){
                    break
                }else{
                    Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
        }
        # $HistCompareHashes
        while($true){
            [int]$UserParams.HistCompareHashes = Read-Host "    Additionally compare all input-files via hashes? 1 = yes, 0 = no."
            if($UserParams.HistCompareHashes -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $InputSubfolderSearch
        while($true){
            [int]$UserParams.InputSubfolderSearch = Read-Host "    Check input-path's subfolders? 1 = yes, 0 = no."
            if($UserParams.InputSubfolderSearch -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $CheckOutputDupli
        while($true){
            [int]$UserParams.CheckOutputDupli = Read-Host "    Additionally check output-path for already copied files? 1 = yes, 0 = no."
            if($UserParams.CheckOutputDupli -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $VerifyCopies
        while($true){
            [int]$UserParams.VerifyCopies = Read-Host "    Enable verifying copied files afterwards for guaranteed successfully copied files? 1 = yes, 0 = no."
            if($UserParams.VerifyCopies -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $OverwriteExistingFiles
        while($true){
            [int]$UserParams.OverwriteExistingFiles = Read-Host "    Overwrite existing files? 1 = yes, 0 = no."
            if($UserParams.OverwriteExistingFiles -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $AvoidIdenticalFiles
        while($true){
            [int]$UserParams.AvoidIdenticalFiles = Read-Host "    Avoid copying identical input-files? 1 = yes, 0 = no."
            if($UserParams.AvoidIdenticalFiles -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $ZipMirror
        if($UserParams.MirrorEnable -eq 1){
            while($true){
                [int]$UserParams.ZipMirror = Read-Host "    Copying files to additional output-path as 7zip-archive? 1 = yes, 0 = no."
                if($UserParams.ZipMirror -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
        }
        # $UnmountInputDrive
        while($true){
            [int]$UserParams.UnmountInputDrive = Read-Host "    Removing input-drive after copying & verifying (before mirroring)? Only use it for external drives. 1 = yes, 0 = no."
            if($UserParams.UnmountInputDrive -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $PreventStandby (SCRIPT VAR)
        while($true){
            [int]$script:PreventStandby = Read-Host "    Auto-prevent standby of computer while script is running? 1 = yes, 0 = no."
            if($script:PreventStandby -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $RememberInPath
        while($true){
            [int]$UserParams.RememberInPath = Read-Host "    Remember the input-path for future uses? 1 = yes, 0 = no."
            if($UserParams.RememberInPath -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $RememberOutPath
        while($true){
            [int]$UserParams.RememberOutPath = Read-Host "    Remember the output-path for future uses? 1 = yes, 0 = no."
            if($UserParams.RememberOutPath -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $RememberMirrorPath
        while($true){
            [int]$UserParams.RememberMirrorPath = Read-Host "    Remember the additional output-path for future uses? 1 = yes, 0 = no."
            if($UserParams.RememberMirrorPath -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $RememberSettings
        while($true){
            [int]$UserParams.RememberSettings = Read-Host "    Remember settings for future uses? 1 = yes, 0 = no."
            if($UserParams.RememberSettings -in (0..1)){
                break
            }else{
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                continue
            }
        }
        # $SaveParamPresetName
        if($UserParams.RememberSettings -eq 1 -or $UserParams.RememberMirrorPath -eq 1 -or $UserParams.RememberOutPath -eq 1 -or $UserParams.RememberInPath -eq 1){
            while($true){
                [string]$UserParams.SaveParamPresetName = $((Read-Host "    Which preset do you want to save your settings to? (Valid cahracters: A-z, 0-9, +, -, _ ; Max. 64 cahracters)`t").ToLower() -Replace '[^A-Za-z0-9_+-]','')
                [string]$UserParams.SaveParamPresetName = $UserParams.SaveParamPresetName.Substring(0, [math]::Min($UserParams.SaveParamPresetName.Length, 64))
                if($UserParams.SaveParamPresetName.Length -gt 1){
                    break
                }else{
                    Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
        }

        return $UserParams
}

# DEFINITION: Get values from Params, then check the main input- and outputfolder:
Function Get-UserValuesDirect(){
    param(
        [ValidateNotNullOrEmpty()]
        [hashtable]$UserParams = $(throw 'UserParams is required by Get-UserValuesDirect')
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting user-values..." -ForegroundColor Cyan

    # DEFINITION: Get values, test paths:
        # DEFINITION: $InputPath
            if($UserParams.InputPath.Length -lt 2 -or (Test-Path -LiteralPath $UserParams.InputPath -PathType Container -ErrorAction SilentlyContinue) -eq $false){
                Write-ColorOut "Input-path $($UserParams.InputPath) could not be found." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $OutputPath
            if($UserParams.OutputPath -eq $UserParams.InputPath){
                Write-ColorOut "Output-path $($UserParams.OutputPath) is the same as input-path." -ForegroundColor Red -Indentation 4
                return $false
            }
            if($UserParams.OutputPath.Length -lt 2 -or (Test-Path -LiteralPath $UserParams.OutputPath -PathType Container -ErrorAction SilentlyContinue) -eq $false){
                if((Split-Path -Parent -Path $UserParams.OutputPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $UserParams.OutputPath) -PathType Container -ErrorAction SilentlyContinue) -eq $true){
                    try{
                        New-Item -ItemType Directory -Path $UserParams.OutputPath -ErrorAction Stop | Out-Null
                        Write-ColorOut "Output-path $($UserParams.OutputPath) created." -ForegroundColor Yellow -Indentation 4
                    }catch{
                        Write-ColorOut "Could not create output-path $($UserParams.OutputPath)." -ForegroundColor Red -Indentation 4
                        return $false
                    }
                }else{
                    Write-ColorOut "Output-path $($UserParams.OutputPath) not found." -ForegroundColor Red -Indentation 4
                    return $false
                }
            }
        # DEFINITION: $MirrorEnable
            if($UserParams.MirrorEnable -notin (0..1)){
                Write-ColorOut "Invalid choice of -MirrorEnable." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $MirrorPath
            if($UserParams.MirrorEnable -eq 1){
                if($UserParams.MirrorPath -eq $UserParams.InputPath -or $UserParams.MirrorPath -eq $UserParams.OutputPath){
                    Write-ColorOut "Additional output-path $($UserParams.MirrorPath) is the same as input- or output-path." -ForegroundColor Red -Indentation 4
                    return $false
                }
                if($UserParams.MirrorPath.Length -lt 2 -or (Test-Path -LiteralPath $UserParams.MirrorPath -PathType Container -ErrorAction SilentlyContinue) -eq $false){
                    if((Split-Path -Parent -Path $UserParams.MirrorPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $UserParams.MirrorPath) -PathType Container -ErrorAction SilentlyContinue) -eq $true){
                        try{
                            New-Item -ItemType Directory -Path $UserParams.MirrorPath -ErrorAction Stop | Out-Null
                            Write-ColorOut "Mirror-path $($UserParams.MirrorPath) created." -ForegroundColor Yellow -Indentation 4
                        }catch{
                            Write-ColorOut "Could not create mirror-path $($UserParams.MirrorPath)." -ForegroundColor Red -Indentation 4
                            return $false
                        }
                    }else{
                        Write-ColorOut "Additional output-path $($UserParams.MirrorPath) not found." -ForegroundColor Red -Indentation 4
                        return $false
                    }
                }
            }
        # DEFINITION: $PresetFormats
            [array]$inter = @("Can","Nik","Son","Jpeg","Jpg","Inter","Mov","Aud")
            if($UserParams.PresetFormats.Length -gt 0 -and $(Compare-Object $inter $UserParams.PresetFormats | Where-Object {$_.sideindicator -eq "=>"}).count -ne 0){
                Write-ColorOut "$UserParams.PresetFormats"
                Write-ColorOut "Invalid choice of -PresetFormats." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $CustomFormatsEnable
            if($UserParams.CustomFormatsEnable -notin (0..1)){
                Write-ColorOut "Invalid choice of -CustomFormatsEnable." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $CustomFormats
            if($UserParams.CustomFormats.GetType().Name -ne "Object[]"){
                Write-ColorOut "Invalid choice of -CustomFormats." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $OutputSubfolderStyle
            [array]$inter = @("none","unchanged","yyyy-mm-dd","yyyy_mm_dd","yyyy.mm.dd","yyyymmdd","yy-mm-dd","yy_mm_dd","yy.mm.dd","yymmdd")
            if($UserParams.OutputSubfolderStyle -inotin $inter){
                Write-ColorOut "Invalid choice of -OutputSubfolderStyle." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $OutputFileStyle
            [array]$inter = @("unchanged","yyyy-MM-dd_HH-mm-ss","yyyyMMdd_HHmmss","yyyyMMddHHmmss","yy-MM-dd_HH-mm-ss","yyMMdd_HHmmss","yyMMddHHmmss","HH-mm-ss","HH_mm_ss","HHmmss")
            if($UserParams.OutputFileStyle -cnotin $inter -or $UserParams.OutputFileStyle.Length -gt $inter[1].Length){
                Write-ColorOut "Invalid choice of -OutputFileStyle." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $UseHistFile
            if($UserParams.UseHistFile -notin (0..1)){
                Write-ColorOut "Invalid choice of -UseHistFile." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $WriteHistFile
            [array]$inter=@("yes","no","overwrite")
            if($UserParams.WriteHistFile -notin $inter -or $UserParams.WriteHistFile.Length -gt $inter[2].Length){
                Write-ColorOut "Invalid choice of -WriteHistFile." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $HistFilePath
            if(($UserParams.UseHistFile -eq 1 -or $UserParams.WriteHistFile -ne "no") -and (Test-Path -LiteralPath $UserParams.HistFilePath -PathType Leaf -ErrorAction SilentlyContinue) -eq $false){
                if((Split-Path -Parent -Path $UserParams.HistFilePath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $UserParams.HistFilePath) -PathType Container -ErrorAction SilentlyContinue) -eq $true){
                    if($UserParams.UseHistFile -eq 1){
                        Write-ColorOut "-HistFilePath does not exist. Therefore, -UseHistFile will be disabled." -ForegroundColor Magenta -Indentation 4
                        $UserParams.UseHistFile = 0
                        Start-Sleep -Seconds 2
                    }
                }else{
                    Write-ColorOut "-HistFilePath $($UserParams.HistFilePath) could not be found." -ForegroundColor Red -Indentation 4
                    return $false
                }
            }
        # DEFINITION: $HistCompareHashes
            if($UserParams.HistCompareHashes -notin (0..1)){
                Write-ColorOut "Invalid choice of -HistCompareHashes." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $InputSubfolderSearch
            if($UserParams.InputSubfolderSearch -notin (0..1)){
                Write-ColorOut "Invalid choice of -InputSubfolderSearch." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $CheckOutputDupli
            if($UserParams.CheckOutputDupli -notin (0..1)){
                Write-ColorOut "Invalid choice of -CheckOutputDupli." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $VerifyCopies
            if($UserParams.VerifyCopies -notin (0..1)){
                Write-ColorOut "Invalid choice of -VerifyCopies." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $OverwriteExistingFiles
            if($UserParams.OverwriteExistingFiles -notin (0..1)){
                Write-ColorOut "Invalid choice of -OverwriteExistingFiles." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $AvoidIdenticalFiles
            if($UserParams.AvoidIdenticalFiles -notin (0..1)){
                Write-ColorOut "Invalid choice of -AvoidIdenticalFiles." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $ZipMirror
            if($UserParams.ZipMirror -notin (0..1)){
                Write-ColorOut "Invalid choice of -ZipMirror." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $UnmountInputDrive
            if($UserParams.UnmountInputDrive -notin (0..1)){
                Write-ColorOut "Invalid choice of -UnmountInputDrive." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $PreventStandby (SCRIPT VAR)
            if($script:PreventStandby -notin (0..1)){
                Write-ColorOut "Invalid choice of -PreventStandby." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $RememberInPath
            if($UserParams.RememberInPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberInPath." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $RememberOutPath
            if($UserParams.RememberOutPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberOutPath." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $RememberMirrorPath
            if($UserParams.RememberMirrorPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberMirrorPath." -ForegroundColor Red -Indentation 4
                return $false
            }
        # DEFINITION: $RememberSettings
            if($UserParams.RememberSettings -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberSettings." -ForegroundColor Red -Indentation 4
                return $false
            }

    # DEFINITION: Sum up formats:
        [array]$UserParams.allChosenFormats = @()
        if("Can" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.cr2"
        }
        if("Nik" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.nef"
            $UserParams.allChosenFormats += "*.nrw"
        }
        if("Son" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.arw"
        }
        if("Jpg" -in $UserParams.PresetFormats -or "Jpeg" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.jpg"
            $UserParams.allChosenFormats += "*.jpeg"
        }
        if("Inter" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.dng"
            $UserParams.allChosenFormats += "*.tif"
        }
        if("Mov" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.mov"
            $UserParams.allChosenFormats += "*.mp4"
        }
        if("Aud" -in $UserParams.PresetFormats){
            $UserParams.allChosenFormats += "*.wav"
            $UserParams.allChosenFormats += "*.mp3"
            $UserParams.allChosenFormats += "*.m4a"
        }
        if($UserParams.CustomFormatsEnable -eq 1 -and $UserParams.CustomFormats.Length -gt 0){
            for($i = 0; $i -lt $UserParams.CustomFormats.Length; $i++){
                $UserParams.allChosenFormats += $UserParams.CustomFormats[$i]
            }
        }
        if($UserParams.allChosenFormats.Length -eq 0){
            if((Read-Host "    No file-format selected. Copy all files? 1 = yes, 0 = no.") -eq 1){
                [array]$UserParams.allChosenFormats = @("*")
            }else{
                Write-ColorOut "No file-format specified." -ForegroundColor Red -Indentation 4
                return $false
            }
        }

    # DEFINITION: Build switches:
        [switch]$script:input_recurse = $(
            if($UserParams.InputSubfolderSearch -eq 1)  {$true}
            else                                        {$false}
        )

    # DEFINITION: Get minutes (mm) to months (MM):
        $UserParams.OutputSubfolderStyle = $UserParams.OutputSubfolderStyle -Replace 'mm','MM'

    # DEFINITION: Check paths for trailing backslash:
        if($UserParams.InputPath.replace($UserParams.InputPath.Substring(0,$UserParams.InputPath.Length-1),"") -eq "\" -and $UserParams.InputPath.Length -gt 3){
            $UserParams.InputPath = $UserParams.InputPath.Substring(0,$UserParams.InputPath.Length-1)
        }
        if($UserParams.OutputPath.replace($UserParams.OutputPath.Substring(0,$UserParams.OutputPath.Length-1),"") -eq "\" -and $UserParams.OutputPath.Length -gt 3){
            $UserParams.OutputPath = $UserParams.OutputPath.Substring(0,$UserParams.OutputPath.Length-1)
        }
        if($UserParams.MirrorPath.replace($UserParams.MirrorPath.Substring(0,$UserParams.MirrorPath.Length-1),"") -eq "\" -and $UserParams.MirrorPath.Length -gt 3){
            $UserParams.MirrorPath = $UserParams.MirrorPath.Substring(0,$UserParams.MirrorPath.Length-1)
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
    Write-ColorOut "flolilo's Media-Copytool's parameters:`r`n" -ForegroundColor Green
    Write-ColorOut "-GUI_CLI_Direct`t`t=`t$($UserParams.GUI_CLI_Direct)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-JSONParamPath`t`t=`t$($UserParams.JSONParamPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-LoadParamPresetName`t=`t$($UserParams.LoadParamPresetName)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-SaveParamPresetName`t=`t$($UserParams.SaveParamPresetName)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberInPath`t`t=`t$($UserParams.RememberInPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberOutPath`t`t=`t$($UserParams.RememberOutPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberMirrorPath`t`t=`t$($UserParams.RememberMirrorPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberSettings`t`t=`t$($UserParams.RememberSettings)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-Debug`t`t`t=`t$($script:Debug)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "These values come from $($UserParams.JSONParamPath):" -ForegroundColor DarkCyan -Indentation 2
    Write-ColorOut "-InputPath`t`t`t=`t$($UserParams.InputPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputPath`t`t`t=`t$($UserParams.OutputPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-MirrorEnable`t`t=`t$($UserParams.MirrorEnable)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-MirrorPath`t`t`t=`t$($UserParams.MirrorPath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-PresetFormats`t`t=`t$($UserParams.PresetFormats)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-CustomFormatsEnable`t=`t$($UserParams.CustomFormatsEnable)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-CustomFormats`t`t=`t$($UserParams.CustomFormats)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputSubfolderStyle`t=`t$($UserParams.OutputSubfolderStyle)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputFileStyle`t`t=`t$($UserParams.OutputFileStyle)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-HistFilePath`t`t=`t$($UserParams.HistFilePath)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-UseHistFile`t`t=`t$($UserParams.UseHistFile)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-WriteHistFile`t`t=`t$($UserParams.WriteHistFile)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-HistCompareHashes`t`t=`t$($UserParams.HistCompareHashes)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-InputSubfolderSearch`t=`t$($UserParams.InputSubfolderSearch)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-CheckOutputDupli`t`t=`t$($UserParams.CheckOutputDupli)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-VerifyCopies`t`t=`t$($UserParams.VerifyCopies)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OverwriteExistingFiles`t=`t$($UserParams.OverwriteExistingFiles)" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-AvoidIdenticalFiles`t=`t$($UserParams.AvoidIdenticalFiles)" -ForegroundColor Cyan -Indentation 4
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

    [array]$inter = @([PSCustomObject]@{
        ParamPresetName = $UserParams.SaveParamPresetName
        ParamPresetValues = [PSCustomObject]@{
            InputPath = $UserParams.InputPath
            OutputPath = $UserParams.OutputPath
            MirrorEnable = $UserParams.MirrorEnable
            MirrorPath = $UserParams.MirrorPath
            PresetFormats = $UserParams.PresetFormats
            CustomFormatsEnable = $UserParams.CustomFormatsEnable
            CustomFormats = $UserParams.CustomFormats
            OutputSubfolderStyle = $UserParams.OutputSubfolderStyle
            OutputFileStyle = $UserParams.OutputFileStyle
            HistFilePath = $UserParams.HistFilePath.Replace($PSScriptRoot,'$($PSScriptRoot)')
            UseHistFile = $UserParams.UseHistFile
            WriteHistFile = $UserParams.WriteHistFile
            HistCompareHashes = $UserParams.HistCompareHashes
            InputSubfolderSearch = $UserParams.InputSubfolderSearch
            CheckOutputDupli = $UserParams.CheckOutputDupli
            VerifyCopies = $UserParams.VerifyCopies
            OverwriteExistingFiles = $UserParams.OverwriteExistingFiles
            AvoidIdenticalFiles = $UserParams.AvoidIdenticalFiles
            ZipMirror = $UserParams.ZipMirror
            UnmountInputDrive = $UserParams.UnmountInputDrive
            PreventStandby = $script:PreventStandby
        }
    })

    if((Test-Path -LiteralPath $UserParams.JSONParamPath -PathType Leaf -ErrorAction SilentlyContinue) -eq $true){
        try{
            $jsonparams = Get-Content -LiteralPath $UserParams.JSONParamPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            if($script:Debug -gt 1){
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
                        $jsonparams.ParamPresetValues[$i].InputPath = $inter.ParamPresetValues.InputPath
                    }
                    if($UserParams.RememberOutPath -eq 1){
                        $jsonparams.ParamPresetValues[$i].OutputPath = $inter.ParamPresetValues.OutputPath
                    }
                    if($UserParams.RememberMirrorPath -eq 1){
                        $jsonparams.ParamPresetValues[$i].MirrorPath = $inter.ParamPresetValues.MirrorPath
                    }
                    if($UserParams.RememberSettings -eq 1){
                        $jsonparams.ParamPresetValues[$i].MirrorEnable = $inter.ParamPresetValues.MirrorEnable
                        $jsonparams.ParamPresetValues[$i].PresetFormats = @($inter.ParamPresetValues.PresetFormats)
                        $jsonparams.ParamPresetValues[$i].CustomFormatsEnable = $inter.ParamPresetValues.CustomFormatsEnable
                        $jsonparams.ParamPresetValues[$i].CustomFormats = @($inter.ParamPresetValues.CustomFormats)
                        $jsonparams.ParamPresetValues[$i].OutputSubfolderStyle = $inter.ParamPresetValues.OutputSubfolderStyle
                        $jsonparams.ParamPresetValues[$i].OutputFileStyle = $inter.ParamPresetValues.OutputFileStyle
                        $jsonparams.ParamPresetValues[$i].HistFilePath = $inter.ParamPresetValues.HistFilePath
                        $jsonparams.ParamPresetValues[$i].UseHistFile = $inter.ParamPresetValues.UseHistFile
                        $jsonparams.ParamPresetValues[$i].WriteHistFile = $inter.ParamPresetValues.WriteHistFile
                        $jsonparams.ParamPresetValues[$i].HistCompareHashes = $inter.ParamPresetValues.HistCompareHashes
                        $jsonparams.ParamPresetValues[$i].InputSubfolderSearch = $inter.ParamPresetValues.InputSubfolderSearch
                        $jsonparams.ParamPresetValues[$i].CheckOutputDupli = $inter.ParamPresetValues.CheckOutputDupli
                        $jsonparams.ParamPresetValues[$i].VerifyCopies = $inter.ParamPresetValues.VerifyCopies
                        $jsonparams.ParamPresetValues[$i].OverwriteExistingFiles = $inter.ParamPresetValues.OverwriteExistingFiles
                        $jsonparams.ParamPresetValues[$i].AvoidIdenticalFiles = $inter.ParamPresetValues.AvoidIdenticalFiles
                        $jsonparams.ParamPresetValues[$i].ZipMirror = $inter.ParamPresetValues.ZipMirror
                        $jsonparams.ParamPresetValues[$i].UnmountInputDrive = $inter.ParamPresetValues.UnmountInputDrive
                        $jsonparams.ParamPresetValues[$i].PreventStandby = $inter.ParamPresetValues.PreventStandby
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

    if($script:Debug -gt 1){
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
        [hashtable]$UserParams = $(throw 'UserParams is required by Show-Parameters')
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-CurrentDate)  --  Finding files." -ForegroundColor Cyan

    # pre-defining variables:
    [array]$InFiles = @()
    $script:resultvalues = @{}

    # Search files and get some information about them:
    [int]$counter = 1
    for($i=0;$i -lt $UserParams.allChosenFormats.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
            Write-Progress -Id 1 -Activity "Find files in $($UserParams.InputPath)..." -PercentComplete $((($i* 100) / $($UserParams.allChosenFormats.Length))) -Status "Format #$($i + 1) / $($UserParams.allChosenFormats.Length)"
            $sw.Reset()
            $sw.Start()
        }

        $InFiles += Get-ChildItem -LiteralPath $UserParams.InputPath -Filter $UserParams.allChosenFormats[$i] -Recurse:$script:input_recurse -File | ForEach-Object -Process {
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
                InBaseName = $(if($UserParams.OutputFileStyle -eq "unchanged"){$_.BaseName}else{$_.LastWriteTime.ToString("$($UserParams.OutputFileStyle)")})
                Extension = $_.Extension
                Size = $_.Length
                Date = $_.LastWriteTime.ToString("yyyy-MM-dd_HH-mm-ss")
                OutSubfolder = $(if($UserParams.OutputSubfolderStyle -eq "none"){""}elseif($UserParams.OutputSubfolderStyle -eq "unchanged"){$($(Split-Path -Parent -Path $_.FullName).Replace($UserParams.InputPath,""))}else{"\$($_.LastWriteTime.ToString("$($UserParams.OutputSubfolderStyle)"))"}) # TODO: should there really be a backslash? # TODO: should it really be empty for unchanged in root folder?
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

    $InFiles = $InFiles | Sort-Object -Property FullName
    $InFiles | Out-Null

    if($script:Debug -gt 1){
        if((Read-Host "    Show all found files? `"1`" for `"yes`"") -eq 1){
            for($i=0; $i -lt $InFiles.Length; $i++){
                Write-ColorOut "$($InFiles[$i].FullName.Replace($UserParams.InputPath,"."))" -ForegroundColor Gray -Indentation 4
            }
        }
    }

    # TODO: (HASH SPEED) get hashes only if needed.
    # DEFINITION: If dupli-checks are enabled: Get hashes for all input-files:
    if(($UserParams.UseHistFile -eq 1 -and $UserParams.HistCompareHashes -eq 1) -or $UserParams.CheckOutputDupli -eq 1){
        Write-ColorOut "Running RS-Job for getting hashes (see progress-bar)..." -ForegroundColor DarkGray -Indentation 4
        $InFiles | Start-RSJob -Name "GetHashAll" -FunctionsToLoad Write-ColorOut -ScriptBlock {
            try{
                $_.Hash = Get-FileHash -LiteralPath $_.InFullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash
            }catch{
                Write-ColorOut "Could not get hash of $($_.InFullName)" -ForegroundColor Red -Indentation 4
                $_.Hash = "GetHashAllWRONG"
            }
        } | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob -Name "GetHashAll" | Remove-RSJob
    }


    Write-ColorOut "Total in-files:`t$($InFiles.Length)" -ForegroundColor Yellow -Indentation 4
    $script:resultvalues.ingoing = $InFiles.Length

    return $InFiles
}

# DEFINITION: Get History-File:
Function Get-HistFile(){
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$UserParams
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Checking for history-file, importing values..." -ForegroundColor Cyan

    [array]$files_history = @()
    if(Test-Path -LiteralPath $UserParams.HistFilePath -PathType Leaf){
        try{
            $JSONFile = Get-Content -LiteralPath $UserParams.HistFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        }catch{
            Write-ColorOut "Could not load $($UserParams.HistFilePath)." -ForegroundColor Red -Indentation 4
            Start-Sleep -Seconds 5
            return $false
        }
        $JSONFile | Out-Null
        $files_history = $JSONFile | ForEach-Object {
            [PSCustomObject]@{
                InName = $_.InName
                Date = $_.Date
                Size = $_.Size
                Hash = $_.Hash
            }
        }
        $files_history
        if($script:Debug -gt 1){
            if((Read-Host "    Show found history-values? `"1`" means `"yes`"") -eq 1){
                Write-ColorOut "Found values: $($files_history.Length)" -ForegroundColor Yellow -Indentation 4
                Write-ColorOut "Name`t`tDate`t`tSize`t`tHash" -Indentation 4
                for($i = 0; $i -lt $files_history.Length; $i++){
                    Write-ColorOut "$($files_history[$i].InName)`t$($files_history[$i].Date)`t$($files_history[$i].Size)`t$($files_history[$i].Hash)" -ForegroundColor Gray -Indentation 4
                }
            }
        }
        if("null" -in $files_history -or $files_history.InName.Length -lt 1 -or ($files_history.Length -gt 1 -and (($files_history.InName.Length -ne $files_history.Date.Length) -or ($files_history.InName.Length -ne $files_history.Size.Length) -or ($files_history.InName.Length -ne $files_history.Hash.Length)))){
            Write-ColorOut "Some values in the history-file $($UserParams.HistFilePath) seem wrong - it's safest to delete the whole file." -ForegroundColor Magenta -Indentation 4
            Write-ColorOut "InNames: $($files_history.InName.Length) Dates: $($files_history.Date.Length) Sizes: $($files_history.Size.Length) Hashes: $($files_history.Hash.Length)" -Indentation 4
            if((Read-Host "    Is that okay? Type '1' (without quotes) to confirm or any other number to abort. Confirm by pressing Enter") -eq 1){
                $UserParams.UseHistFile = 0
                $UserParams.WriteHistFile = "Overwrite"
            }else{
                Write-ColorOut "`r`n`tAborting.`r`n" -ForegroundColor Magenta
                Invoke-Close
            }
        }
        if("ZYX" -in $files_history.Hash -and $UserParams.HistCompareHashes -eq 1){
            Write-ColorOut "Some hash-values in the history-file are missing (because -VerifyCopies wasn't activated when they were added). This could lead to duplicates." -ForegroundColor Magenta -Indentation 4
            Start-Sleep -Seconds 2
        }
    }else{
        Write-ColorOut "History-File $($UserParams.HistFilePath) could not be found. This means it's possible that duplicates get copied." -ForegroundColor Magenta -Indentation 4
        if((Read-Host "    Is that okay? Type '1' (without quotes) to confirm or any other number to abort. Confirm by pressing Enter") -eq 1){
            $UserParams.UseHistFile = 0
            $UserParams.WriteHistFile = "Overwrite"
        }else{
            Write-ColorOut "`r`n`tAborting.`r`n" -ForegroundColor Magenta
            Invoke-Close
        }
    }

    return $files_history
}

# DEFINITION: dupli-check via history-file:
Function Start-DupliCheckHist(){
    param(
        [Parameter(Mandatory=$true)]
        [array]$InFiles,
        [Parameter(Mandatory=$true)]
        [array]$HistFiles,
        [Parameter(Mandatory=$true)]
        [hashtable]$UserParams
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-CurrentDate)  --  Checking for duplicates via history-file." -ForegroundColor Cyan

    $properties = @("InName","Date","Size")
    if($UserParams.HistCompareHashes -eq 1){
        $properties += "Hash"
    }

    for($i=0; $i -lt $InFiles.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750){
            Write-Progress -Activity "Comparing input-files to already copied files (history-file).." -PercentComplete $($i * 100 / $InFiles.Length) -Status "File # $($i + 1) / $($InFiles.Length) - $($InFiles[$i].name)"
            $sw.Reset()
            $sw.Start()
        }

        # TODO: (HASH SPEED) get hashes only if needed.
        if(@(Compare-Object -ReferenceObject $InFiles[$i] -DifferenceObject $HistFiles -Property $properties -ExcludeDifferent -IncludeEqual -ErrorAction Stop).count -gt 0){
            $InFiles[$i].ToCopy = 0
        }
    }
    Write-Progress -Activity "Comparing input-files to already copied files (history-file).." -Status "Done!" -Completed

    if($script:Debug -gt 1){
        if((Read-Host "    Show result? `"1`" for `"yes`"") -eq 1){
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

    Write-ColorOut "Files to skip:`t$($($InFiles | Where-Object {$_.ToCopy -eq 0}).count)" -ForegroundColor DarkGreen -Indentation 4
    $script:resultvalues.duplihist = $($InFiles | Where-Object {$_.ToCopy -eq 0}).count

    [array]$InFiles = @($InFiles | Where-Object {$_.ToCopy -eq 1})

    $sw.Reset()
    return $InFiles
}

# DEFINITION: dupli-check via output-folder:
Function Start-DupliCheckOut(){
    param(
        [Parameter(Mandatory=$true)]
        [array]$InFiles,
        [Parameter(Mandatory=$true)]
        [hashtable]$UserParams
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-CurrentDate)  --  Checking for duplicates in OutPath." -ForegroundColor Cyan

    # pre-defining variables:
    [array]$files_duplicheck = @()
    [int]$dupliindex_out = 0

    [int]$counter = 1
    for($i=0;$i -lt $UserParams.allChosenFormats.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
            Write-Progress -Id 1 -Activity "Find files in $($UserParams.OutputPath)..." -PercentComplete $(($i / $($UserParams.allChosenFormats.Length)) * 100) -Status "Format #$($i + 1) / $($UserParams.allChosenFormats.Length)"
            $sw.Reset()
            $sw.Start()
        }

        $files_duplicheck += Get-ChildItem -LiteralPath $UserParams.OutputPath -Filter $UserParams.allChosenFormats[$i] -Recurse -File | ForEach-Object -Process {
            if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
                Write-Progress -Id 2 -Activity "Looking for files..." -PercentComplete -1 -Status "File #$counter - $($_.FullName.Replace("$($UserParams.OutputPath)",'.'))"
                $sw.Reset()
                $sw.Start()
            }

            [PSCustomObject]@{
                FullName = $_.FullName
                InName = $null
                Size = $_.Length
                Date = $_.LastWriteTime.ToString("yyyy-MM-dd_HH-mm-ss")
                Hash = $null
            }
            $counter++
        } -End {
            Write-Progress -Id 2 -Activity "Looking for files..." -Status "Done!" -Completed
        }
    }
    Write-Progress -Id 1 -Activity "Find files in $($UserParams.OutputPath)..." -Status "Done!" -Completed
    $sw.Reset()

    $sw.Start()
    if($files_duplicheck.Length -gt 0){
        $properties = @("Date","Size")
        for($i=0; $i -lt $files_duplicheck.Length; $i++){
            if($sw.Elapsed.TotalMilliseconds -ge 750 -or $i -eq 0){
                Write-Progress -Id 1 -Activity "Determine files in output that need to be checked..." -PercentComplete $($i * 100 / $($files_duplicheck.Length)) -Status "File # $($i + 1) / $($files_duplicheck.Length)"
                $sw.Reset()
                $sw.Start()
            }
            # TODO: (HASH SPEED) get hashes only if needed.
            if(@(Compare-Object -ReferenceObject $files_duplicheck[$i] -DifferenceObject $InFiles -Property $properties -ExcludeDifferent -IncludeEqual -ErrorAction Stop).count -gt 0){
                $files_duplicheck[$i].Hash = (Get-FileHash -LiteralPath $files_duplicheck[$i].FullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash)
            }
        }
        $files_duplicheck = $files_duplicheck | Where-Object {$_.Hash -ne $null}
        Write-Progress -Id 1 -Activity "Determine files in output that need to be checked..." -Status "Done!" -PercentComplete 100

        if($files_duplicheck.Count -gt 0){
            $properties += "Hash"
            for($i = 0; $i -lt $InFiles.Length; $i++){
                if($sw.Elapsed.TotalMilliseconds -ge 750 -or $i -eq 0){
                    Write-Progress -Id 2 -Activity "Comparing input-files with files in output..." -PercentComplete $($i * 100 / $($InFiles.Length)) -Status "File # $($i + 1) / $($InFiles.Length)"
                    $sw.Reset()
                    $sw.Start()
                }
                if(@(Compare-Object -ReferenceObject $InFiles[$i] -DifferenceObject $files_duplicheck -Property $properties -ExcludeDifferent -IncludeEqual -ErrorAction Stop).count -gt 0){
                    $InFiles[$i].ToCopy = 0
                    $dupliindex_out++
                    # $files_duplicheck[$j].InName = $InFiles[$i].InName
                }
            }
            Write-Progress -Id 2 -Activity "Comparing input-files with files in output..." -Status "Done!" -Completed

            [array]$inter = @($InFiles | Where-Object {$_.ToCopy -eq 0})
            for($i=0; $i -lt $inter.Length; $i++){
                [int]$j = $files_duplicheck.Length
                while($true){
                    # calculate hash only if date and size are the same:
                    if($inter[$i].date -eq $files_duplicheck[$j].date -and $inter[$i].size -eq $files_duplicheck[$j].size -and $inter[$i].Hash -eq $files_duplicheck[$j].Hash){
                            $files_duplicheck[$j].InName = $inter[$i].InName
                            break
                    }else{
                        if($j -le 0){
                            break
                        }
                        $j--
                    }
                }
            }

            if($script:Debug -gt 1){
                if((Read-Host "    Show all files? `"1`" for `"yes`"") -eq 1){
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

            [array]$InFiles = @($InFiles | Where-Object {$_.ToCopy -eq 1})
        }else{
            Write-ColorOut "No potential dupli-files in $($UserParams.OutputPath) - skipping additional verification." -ForegroundColor Gray -Indentation 4
        }

        [array]$script:dupliout = $files_duplicheck
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
        [Parameter(Mandatory=$true)]
        [array]$InFiles
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Calculate remaining hashes..." -ForegroundColor Cyan

    if("ZYX" -in $InFiles.Hash){
        $InFiles | Where-Object {$_.Hash -eq "ZYX"} | Start-RSJob -Name "GetHashRest" -FunctionsToLoad Write-ColorOut -ScriptBlock {
            try{
                $_.Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash)
            }catch{
                Write-ColorOut "Failed to get hash of `"$($_.FullName)`"" -ForegroundColor Red -Indentation 4
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
        [Parameter(Mandatory=$true)]
        [array]$InFiles
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Avoid identical input-files..." -ForegroundColor Cyan -NoNewLine

    [array]$inter = ($InFiles | Sort-Object -Property InName,Date,Size,Hash -Unique)
    if($inter.Length -ne $InFiles.Length){
        Write-ColorOut "$($InFiles.Length - $inter.Length) identical files were found in the input-path - only copying one of each." -ForegroundColor Magenta -Indentation 4
        Start-Sleep -Seconds 3
        [array]$InFiles = ($inter)
    }
    $script:resultvalues.identicalFiles = $($InFiles.Length - $inter.Length)
    $script:resultvalues.copyfiles = $InFiles.Length

    return $InFiles
}

# DEFINITION: Check for free space on the destination volume:
Function Start-SpaceCheck(){
    param(
        [Parameter(Mandatory=$true)]
        [string]$OutPath,
        [Parameter(Mandatory=$true)]
        [array]$InFiles
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Checking if free space is sufficient..." -ForegroundColor Cyan

    [string]$OutPath = Split-Path -Path $OutPath -Qualifier
    [int]$free = ((Get-PSDrive -PSProvider 'FileSystem' | Where-Object {$_.root -match $OutPath} | Select-Object -ExpandProperty Free) / 1MB)
    [int]$needed = $(($InFiles | Measure-Object -Sum -Property Size | Select-Object -ExpandProperty Sum) / 1MB)
    
    if($needed -lt $free){
        Write-ColorOut "Free: $free MB; Needed: $needed MB - Okay!" -ForegroundColor Green -Indentation 4
        return $true
    }else{
        Write-ColorOut "Free: $free MB; Needed: $needed MB - Too big!" -ForegroundColor Red -Indentation 4
        return $false
    }
}

# DEFINITION: Check if filename already exists and if so, then choose new name for copying:
Function Start-OverwriteProtection(){
    param(
        [Parameter(Mandatory=$true)]
        [array]$InFiles,
        [Parameter(Mandatory=$true)]
        [hashtable]$UserParams,
        [Parameter(Mandatory=$true)]
        [int]$Mirror
    )
    if($Mirror -eq 1){
        $UserParams.OutputPath = $UserParams.MirrorPath
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

        # create outpath:
        $InFiles[$i].outpath = $("$($UserParams.OutputPath)$($InFiles[$i].sub_date)").Replace("\\","\").Replace("\\","\")
        $InFiles[$i].OutBaseName = $InFiles[$i].basename
        $InFiles[$i].outname = "$($InFiles[$i].basename)$($InFiles[$i].extension)"
        # check for files with same name from input:
        [int]$j = 1
        [int]$k = 1
        while($true){
            [string]$check = "$($InFiles[$i].outpath)\$($InFiles[$i].outname)"
            if($check -notin $allpaths){
                if((Test-Path -LiteralPath $check -PathType Leaf) -eq $false -or $UserParams.OverwriteExistingFiles -eq 1){
                    $allpaths += $check
                    break
                }else{
                    if($k -eq 1){
                        $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName)_OutCopy$k"
                    }else{
                        $InFiles[$i].OutBaseName = $InFiles[$i].OutBaseName -replace "_OutCopy$($k - 1)","_OutCopy$k"
                    }
                    $InFiles[$i].outname = "$($InFiles[$i].OutBaseName)$($InFiles[$i].extension)"
                    $k++
                    # if($script:Debug -ne 0){Write-ColorOut $InFiles[$i].OutBaseName}
                    continue
                }
            }else{
                if($j -eq 1){
                    $InFiles[$i].OutBaseName = "$($InFiles[$i].OutBaseName)_InCopy$j"
                }else{
                    $InFiles[$i].OutBaseName = $InFiles[$i].OutBaseName -replace "_InCopy$($j - 1)","_InCopy$j"
                }
                $InFiles[$i].outname = "$($InFiles[$i].OutBaseName)$($InFiles[$i].extension)"
                $j++
                # if($script:Debug -ne 0){Write-ColorOut $InFiles[$i].OutBaseName}
                continue
            }
        }
    }
    Write-Progress -Activity "Prevent overwriting existing files..." -Status "Done!" -Completed

    if($script:Debug -gt 1){
        if((Read-Host "    Show all names? `"1`" for `"yes`"") -eq 1){
            [int]$indent = 0
            for($i=0; $i -lt $InFiles.Length; $i++){
                Write-ColorOut "    $($InFiles[$i].outpath.Replace($UserParams.OutputPath,"."))\$($InFiles[$i].outname)`t`t" -NoNewLine -ForegroundColor Gray
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
        [Parameter(Mandatory=$true)]
        [array]$InFiles,
        [Parameter(Mandatory=$true)]
        [hashtable]$UserParams
    )
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Copy files from $($UserParams.InputPath) to " -NoNewLine -ForegroundColor Cyan
    if($UserParams.OutputSubfolderStyle -eq "none"){
        Write-ColorOut "$($UserParams.OutputPath)..." -ForegroundColor Cyan
    }elseif($UserParams.OutputSubfolderStyle -eq "unchanged"){
        Write-ColorOut "$($UserParams.OutputPath) with original subfolders:" -ForegroundColor Cyan
    }else{
        Write-ColorOut "$($UserParams.OutputPath)\$($UserParams.OutputSubfolderStyle)..." -ForegroundColor Cyan
    }

    $InFiles = $InFiles | Sort-Object -Property InPath,OutPath

    # setting up robocopy:
    [array]$rc_command = @()
    [string]$rc_suffix = "/R:5 /W:15 /MT:$($script:ThreadCount) /XO /XC /XN /NC /NJH /J"
    [string]$rc_inter_inpath = ""
    [string]$rc_inter_outpath = ""
    [string]$rc_inter_files = ""
    # setting up xcopy:
    [array]$xc_command = @()
    [string]$xc_suffix = " /Q /J /Y"

    for($i=0; $i -lt $InFiles.length; $i++){
        if($InFiles[$i].tocopy -eq 1){
            # check if files is qualified for robocopy (out-name = in-name):
            if($InFiles[$i].outname -eq $(Split-Path -Leaf -Path $InFiles[$i].FullName)){
                if($rc_inter_inpath.Length -eq 0 -or $rc_inter_outpath.Length -eq 0 -or $rc_inter_files.Length -eq 0){
                    $rc_inter_inpath = "`"$($InFiles[$i].inpath)`""
                    $rc_inter_outpath = "`"$($InFiles[$i].outpath)`""
                    $rc_inter_files = "`"$($InFiles[$i].outname)`" "
                # if in-path and out-path stay the same (between files)...
                }elseif("`"$($InFiles[$i].inpath)`"" -eq $rc_inter_inpath -and "`"$($InFiles[$i].outpath)`"" -eq $rc_inter_outpath){
                    # if command-length is within boundary:
                    if($($rc_inter_inpath.Length + $rc_inter_outpath.Length + $rc_inter_files.Length + $InFiles[$i].outname.Length) -lt 8100){
                        $rc_inter_files += "`"$($InFiles[$i].outname)`" "
                    }else{
                        $rc_command += "$rc_inter_inpath $rc_inter_outpath $rc_inter_files $rc_suffix"
                        $rc_inter_files = "`"$($InFiles[$i].outname)`" "
                    }
                # if in-path and out-path DON'T stay the same (between files):
                }else{
                    $rc_command += "$rc_inter_inpath $rc_inter_outpath $rc_inter_files $rc_suffix"
                    $rc_inter_inpath = "`"$($InFiles[$i].inpath)`""
                    $rc_inter_outpath = "`"$($InFiles[$i].outpath)`""
                    $rc_inter_files = "`"$($InFiles[$i].outname)`" "
                }

            # if NOT qualified for robocopy:
            }else{
                $xc_command += "`"$($InFiles[$i].FullName)`" `"$($InFiles[$i].outpath)\$($InFiles[$i].outname)*`" $xc_suffix"
            }
        }
    }
    # if last element is robocopy:
    if($rc_inter_inpath.Length -ne 0 -or $rc_inter_outpath.Length -ne 0 -or $rc_inter_files.Length -ne 0){
        if($rc_inter_inpath -notin $rc_command -or $rc_inter_outpath -notin $rc_command -or $rc_inter_files -notin $rc_command){
            $rc_command += "$rc_inter_inpath $rc_inter_outpath $rc_inter_files $rc_suffix"
        }
    }

    
    if($script:Debug -gt 1){
        [int]$inter = Read-Host "    Show all commands? `"1`" for yes, `"2`" for writing them as files to your script's path."
        if($inter -gt 0){
            foreach($i in $rc_command){
                Write-ColorOut "robocopy $i`r`n" -ForegroundColor Gray -Indentation 4
                if($inter -eq 2){
                    [System.IO.File]::AppendAllText("$($PSScriptRoot)\robocopy_commands.txt", $i)
                }
            }
            foreach($i in $xc_command){
                Write-ColorOut "xcopy $i`r`n" -ForegroundColor Gray -Indentation 4
                if($inter -eq 2){
                    [System.IO.File]::AppendAllText("$($PSScriptRoot)\xcopy_commands.txt", $i)
                }
            }
            Invoke-Pause
        }
    }

    # start robocopy:
    for($i=0; $i -lt $rc_command.Length; $i++){
        Start-Process robocopy -ArgumentList $rc_command[$i] -Wait -NoNewWindow
    }

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
        Start-Process xcopy -ArgumentList $xc_command[$i] -WindowStyle Hidden
        $counter++
    }
    while($counter -gt 0){
        $counter = @(Get-Process -Name xcopy -ErrorAction SilentlyContinue).count
        Start-Sleep -Milliseconds 25
    }
    Write-Progress -Activity "Starting Xcopy.." -Status "Done!" -Completed

    Start-Sleep -Milliseconds 250

    $sw.Reset()
}

# DEFINITION: Starting 7zip:
Function Start-7zip(){
    param(
        [Parameter(Mandatory=$false)]
        [string]$7zexe = "$($PSScriptRoot)\7z.exe",
        [Parameter(Mandatory=$true)]
        [array]$InFiles,
        [Parameter(Mandatory=$true)]
        [hashtable]$UserParams
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
        [Parameter(Mandatory=$true)]
        [array]$InFiles
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
                    Rename-Item -LiteralPath $inter -NewName "$($inter)_broken" -ErrorAction Stop
                }catch{
                    Write-ColorOut "Renaming $inter failed." -ForegroundColor Magenta -Indentation 4
                }
            }else{
                $_.ToCopy = 0
                if((Test-Path -LiteralPath "$($inter)_broken" -PathType Leaf) -eq $true){
                    try{
                        Remove-Item -LiteralPath "$($inter)_broken" -ErrorAction Stop
                    }catch{
                        Write-ColorOut "Removing $($inter)_broken failed." -ForegroundColor Magenta -Indentation 4
                    }
                }
            }
        }else{
            Write-ColorOut "Missing:`t$inter" -ForegroundColor Red -Indentation 4
            try{
                New-Item -ItemType File -Path "$($inter)_broken" -ErrorAction Stop | Out-Null
            }catch{
                Write-ColorOut "Creating $($inter)_broken failed." -ForegroundColor Magenta -Indentation 4
            }
        }
    } | Wait-RSJob -ShowProgress | Receive-RSJob
    Get-RSJob -Name "VerifyHash" | Remove-RSJob

    [int]$verified = 0
    [int]$unverified = 0
    [int]$inter=0
    if($script:Debug -gt 1){
        [int]$inter = Read-Host "    Show files? `"1`" for `"yes`""
    }
    for($i=0; $i -lt $InFiles.Length; $i++){
        if($InFiles[$i].tocopy -eq 1){
            $unverified++
            if($inter -eq 1){
                Write-ColorOut $InFiles[$i].outname -ForegroundColor Red -Indentation 4
            }
        }else{
            $verified++
            if($inter -eq 1){
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
        [Parameter(Mandatory=$true)]
        [array]$InFiles,
        [Parameter(Mandatory=$true)]
        [hashtable]$UserParams
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Write attributes of successfully copied files to history-file..." -ForegroundColor Cyan

    [array]$results = @($InFiles | Where-Object {$_.ToCopy -eq 0} | Select-Object -Property InName,Date,Size,Hash)

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
                InName = $_.InName
                Date = $_.Date
                Size = $_.Size
                Hash = $_.Hash
            }
        }
    }
    if($UserParams.CheckOutputDupli -gt 0){
        $results += $script:dupliout | ForEach-Object {
            [PSCustomObject]@{
                InName = $_.InName
                Date = $_.Date
                Size = $_.Size
                Hash = $_.Hash
            }
        }
    }
    $results = $results | Sort-Object -Property InName,Date,Size,Hash -Unique | ConvertTo-Json
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
        [Parameter(Mandatory=$true)]
        [hashtable]$UserParams,
        [Parameter(Mandatory=$false)]
        [hashtable]$GUIParams
    )
    Write-ColorOut "`r`n$(Get-CurrentDate)  --  Starting everything..." -NoNewLine -ForegroundColor Cyan -BackgroundColor DarkGray
    Write-ColorOut "A                               A" -ForegroundColor DarkGray -BackgroundColor DarkGray

    if($script:Debug -gt 0){
        $script:timer = [diagnostics.stopwatch]::StartNew()
    }

    while($true){
        # DEFINITION: Get User-Values:
        $inter = $UserParams.GUI_CLI_Direct
        $UserParams = $(
            if($UserParams.GUI_CLI_Direct -eq "GUI"){Get-UserValuesGUI -UserParams $UserParams -GUIParams $GUIParams}
            elseif($UserParams.GUI_CLI_Direct -eq "CLI"){Get-UserValuesCLI -UserParams $UserParams}
            elseif($UserParams.GUI_CLI_Direct -eq "Direct"){Get-UserValuesDirect -UserParams $UserParams}
        )
        if($UserParams -eq $false){
            Start-Sound(0)
            Start-Sleep -Seconds 2
            if($inter -eq "GUI"){
                Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams
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
            Start-Sound(1)
            Start-Sleep -Seconds 2
            if($UserParams.GUI_CLI_Direct -eq "GUI"){
                Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams
            }
            break
        }
        Invoke-Pause

        # DEFINITION: If enabled: Get History-File:
        [array]$histfiles = @()
        if($UserParams.UseHistFile -eq 1){
            [array]$histfiles = @(Get-HistFile -UserParams $UserParams)
            Invoke-Pause
            if($histfiles.Length -gt 0){
                # DEFINITION: If enabled: Check for duplicates against history-files:
                [array]$inputfiles = @(Start-DupliCheckHist -InFile $inputfiles -HistFiles $histfiles -UserParams $UserParams)
                if($inputfiles.Length -lt 1){
                    Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
                    Start-Sound(1)
                    Start-Sleep -Seconds 2
                    if($UserParams.GUI_CLI_Direct -eq "GUI"){
                        Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams
                    }
                    break
                }
                Invoke-Pause
            }else{
                Write-ColorOut "No History-files found." -ForegroundColor Gray -Indentation 4
            }
        }

        # DEFINITION: If enabled: Check for duplicates against output-files:
        if($UserParams.CheckOutputDupli -eq 1){
            [array]$inputfiles = (Start-DupliCheckOut -InFiles $inputfiles -UserParams $UserParams)
            if($inputfiles.Length -lt 1){
                Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
                Start-Sound(1)
                Start-Sleep -Seconds 2
                if($UserParams.GUI_CLI_Direct -eq "GUI"){
                    Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams
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
            Start-Sound(0)
            Start-Sleep -Seconds 2
            if($UserParams.GUI_CLI_Direct -eq "GUI"){
                Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams
            }
            break
        }
        Invoke-Pause

        # DEFINITION: Copy stuff and check it:
        $j = 0
        while(1 -in $inputfiles.tocopy){
            if($j -gt 0){
                Write-ColorOut "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                if((Read-Host "`"1`" (w/o quotes) for `"yes`", other number for `"no`"") -ne 1){
                    Write-ColorOut "Aborting." -ForegroundColor Cyan
                    Start-Sleep -Seconds 2
                    if($UserParams.GUI_CLI_Direct -eq "GUI"){
                        Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml" -UserParams $UserParams
                    }
                    break
                }
            }
            [array]$inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -UserParams $UserParams -Mirror 0)
            Invoke-Pause
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
                Start-Sound(0)
                Start-Sleep -Seconds 2
                if($UserParams.GUI_CLI_Direct -eq "GUI"){
                    Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams
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
                        if((Read-Host "`"1`" (w/o quotes) for `"yes`", other number for `"no`"") -ne 1){
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
        Start-Sound(1)
    }else{
        Start-Sound(0)
    }
    
    if($script:PreventStandby -gt 1){
        Stop-Process -Id $script:PreventStandby
    }
    if($UserParams.GUI_CLI_Direct -eq "GUI"){
        Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams
    }
}


# ==================================================================================================
# ==============================================================================
#    Programming GUI & starting everything:
# ==============================================================================
# ==================================================================================================

# DEFINITION: Load and Start GUI:
Function Start-GUI(){
    <#
        .NOTES
            CREDIT: code of this section (except from small modifications) by
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
    Function Get-Folder(){
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
                return $false
            }
        }else{
            Write-ColorOut "Could not find $GUIPath - GUI can therefore not start." -ForegroundColor Red
            Pause
            return $false
        }

        try{
            [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
            [xml]$xaml = $inputXML -replace "<MCVersion>","$script:VersionNumber" -replace 'mc:Ignorable="d"','' -replace "x:Name",'Name' -replace '^<Win.*', '<Window'
            $reader = (New-Object System.Xml.XmlNodeReader $xaml)
            $script:Form = [Windows.Markup.XamlReader]::Load($reader)
        }
        catch{
            Write-ColorOut "Unable to load Windows.Markup.XamlReader. Usually this means that you haven't installed .NET Framework. Please download and install the latest .NET Framework Web-Installer for your OS: " -ForegroundColor Red
            Write-ColorOut "https://duckduckgo.com/?q=net+framework+web+installer&t=h_&ia=web"
            Write-ColorOut "Alternatively, this script will now start in CLI-mode, asking you for variables inside the terminal." -ForegroundColor Yellow
            Pause
            return $false
        }

        [hashtable]$GUIParams = @{}
        $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
            $GUIParams.Add($($_.Name), $script:Form.FindName($_.Name))
        }

        if($script:getWPF -ne 0){
            Write-ColorOut "Found the following interactable elements:`r`n" -ForegroundColor Cyan
            $GUIParams | Format-Table -AutoSize
            Pause
            Invoke-Close
        }
    }

    # DEFINITION: Fill the TextBoxes and buttons with user parameters:
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
            return $false
        }
    }else{
        Write-ColorOut "$($UserParams.JSONParamPath) does not exist - aborting!" -ForegroundColor  Magenta -Indentation 4
        return $false
    }
    $GUIParams.textBoxSavePreset.Text =     $UserParams.SaveParamPresetName
    $GUIParams.textBoxInput.Text =          $UserParams.InputPath
    $GUIParams.textBoxOutput.Text =         $UserParams.OutputPath
    $GUIParams.checkBoxMirror.IsChecked =   $UserParams.MirrorEnable
    $GUIParams.textBoxMirror.Text =         $UserParams.MirrorPath
    $GUIParams.textBoxHistFile.Text =       $UserParams.HistFilePath
    $GUIParams.checkBoxCan.IsChecked = $(if("Can" -in $UserParams.PresetFormats){$true}else{$false})
    $GUIParams.checkBoxNik.IsChecked = $(if("Nik" -in $UserParams.PresetFormats){$true}else{$false})
    $GUIParams.checkBoxSon.IsChecked = $(if("Son" -in $UserParams.PresetFormats){$true}else{$false})
    $GUIParams.checkBoxJpg.IsChecked = $(if("Jpg" -in $UserParams.PresetFormats -or "Jpeg" -in $UserParams.PresetFormats){$true}else{$false})
    $GUIParams.checkBoxInter.IsChecked =    $(if("Inter" -in $UserParams.PresetFormats){$true}else{$false})
    $GUIParams.checkBoxMov.IsChecked =      $(if("Mov" -in $UserParams.PresetFormats){$true}else{$false})
    $GUIParams.checkBoxAud.IsChecked =      $(if("Aud" -in $UserParams.PresetFormats){$true}else{$false})
    $GUIParams.checkBoxCustom.IsChecked =   $UserParams.CustomFormatsEnable
    $GUIParams.textBoxCustom.Text =         $UserParams.CustomFormats -join ","
    $GUIParams.comboBoxOutSubStyle.SelectedIndex = $(
        if("none"           -eq $UserParams.OutputSubfolderStyle){0}
        elseif("unchanged"  -eq $UserParams.OutputSubfolderStyle){1}
        elseif("yyyy-mm-dd" -eq $UserParams.OutputSubfolderStyle){2}
        elseif("yyyy_mm_dd" -eq $UserParams.OutputSubfolderStyle){3}
        elseif("yyyy.mm.dd" -eq $UserParams.OutputSubfolderStyle){4}
        elseif("yyyymmdd"   -eq $UserParams.OutputSubfolderStyle){5}
        elseif("yy-mm-dd"   -eq $UserParams.OutputSubfolderStyle){6}
        elseif("yy_mm_dd"   -eq $UserParams.OutputSubfolderStyle){7}
        elseif("yy.mm.dd"   -eq $UserParams.OutputSubfolderStyle){8}
        elseif("yymmdd"     -eq $UserParams.OutputSubfolderStyle){9}
        else{0}
    )
    $GUIParams.comboBoxOutFileStyle.SelectedIndex = $(
        if("Unchanged"                  -eq $UserParams.OutputFileStyle){0}
        elseif("yyyy-MM-dd_HH-mm-ss"    -eq $UserParams.OutputFileStyle){1}
        elseif("yyyyMMdd_HHmmss"        -eq $UserParams.OutputFileStyle){2}
        elseif("yyyyMMddHHmmss"         -eq $UserParams.OutputFileStyle){3}
        elseif("yy-MM-dd_HH-mm-ss"      -eq $UserParams.OutputFileStyle){4}
        elseif("yyMMdd_HHmmss"  -eq $UserParams.OutputFileStyle){5}
        elseif("yyMMddHHmmss"   -eq $UserParams.OutputFileStyle){6}
        elseif("HH-mm-ss"       -eq $UserParams.OutputFileStyle){7}
        elseif("HH_mm_ss"       -eq $UserParams.OutputFileStyle){8}
        elseif("HHmmss"         -eq $UserParams.OutputFileStyle){9}
        else{0}
    )
    $GUIParams.checkBoxUseHistFile.IsChecked = $UserParams.UseHistFile
    $GUIParams.comboBoxWriteHistFile.SelectedIndex = $(
        if("yes"            -eq $UserParams.WriteHistFile){0}
        elseif("Overwrite"  -eq $UserParams.WriteHistFile){1}
        elseif("no"         -eq $UserParams.WriteHistFile){2}
        else{0}
    )
    $GUIParams.checkBoxCheckHashHist.IsChecked =    $UserParams.HistCompareHashes
    $GUIParams.checkBoxInSubSearch.IsChecked =      $UserParams.InputSubfolderSearch
    $GUIParams.checkBoxOutputDupli.IsChecked =      $UserParams.CheckOutputDupli
    $GUIParams.checkBoxVerifyCopies.IsChecked =     $UserParams.VerifyCopies
    $GUIParams.checkBoxOverwriteExistingFiles.IsChecked =   $UserParams.OverwriteExistingFiles
    $GUIParams.checkBoxAvoidIdenticalFiles.IsChecked =      $UserParams.AvoidIdenticalFiles
    $GUIParams.checkBoxZipMirror.IsChecked =                $UserParams.ZipMirror
    $GUIParams.checkBoxUnmountInputDrive.IsChecked =        $UserParams.UnmountInputDrive
    $GUIParams.checkBoxPreventStandby.IsChecked =   $script:PreventStandby
    $GUIParams.checkBoxRememberIn.IsChecked =       $UserParams.RememberInPath
    $GUIParams.checkBoxRememberOut.IsChecked =      $UserParams.RememberOutPath
    $GUIParams.checkBoxRememberMirror.IsChecked =   $UserParams.RememberMirrorPath
    $GUIParams.checkBoxRememberSettings.IsChecked = $UserParams.RememberSettings

    # DEFINITION: Load-Preset-Button
    $GUIParams.buttonLoadPreset.Add_Click({
        if($jsonparams.ParamPresetName -is [array]){
            for($i=0; $i -lt $jsonparams.ParamPresetName.Length; $i++){
                if($i -eq $GUIParams.comboBoxLoadPreset.SelectedIndex){
                    [string]$UserParams.LoadParamPresetName = $jsonparams.ParamPresetName[$i]
                }
            }
        }else{
            [string]$UserParams.LoadParamPresetName = $jsonparams.ParamPresetName
        }
        $script:Form.Close()
        Get-Parameters -UserParams $UserParams -Renew 1
        Start-Sleep -Milliseconds 2
        Start-GUI -GUIPath $GUIPath -UserParams $UserParams
    })
    # DEFINITION: InPath-Button
    $GUIParams.buttonSearchIn.Add_Click({
        Get-Folder -ToInfluence "input" -GUIParams $GUIParams
    })
    # DEFINITION: OutPath-Button
    $GUIParams.buttonSearchOut.Add_Click({
        Get-Folder -ToInfluence "output" -GUIParams $GUIParams
    })
    # DEFINITION: MirrorPath-Button
    $GUIParams.buttonSearchMirror.Add_Click({
        Get-Folder -ToInfluence "mirror" -GUIParams $GUIParams
    })
    # DEFINITION: HistoryPath-Button
    $GUIParams.buttonSearchHistFile.Add_Click({
        Get-Folder -ToInfluence "histfile" -GUIParams $GUIParams
    })
    # DEFINITION: Start-Button
    $GUIParams.buttonStart.Add_Click({
        $script:Form.Close()
        Start-Everything -UserParams $UserParams -GUIParams $GUIParams
    })
    # DEFINITION: About-Button
    $GUIParams.buttonAbout.Add_Click({
        Start-Process powershell -ArgumentList "Get-Help $($PSCommandPath) -detailed" -NoNewWindow -Wait
    })
    # DEFINITION: Close-Button
    $GUIParams.buttonClose.Add_Click({
        $script:Form.Close()
        Invoke-Close
    })

    return $script:Form

    # DEFINITION: Start GUI
    # $script:Form.ShowDialog() | Out-Null
}

# DEFINITION: Banner:
    Write-ColorOut "                            flolilo's Media-Copytool                            " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "                          $VersionNumber           " -ForegroundColor DarkMagenta -BackgroundColor DarkGray -NoNewLine
    Write-ColorOut "(PID = $("{0:D8}" -f $pid))`r`n" -ForegroundColor Gray -BackgroundColor DarkGray
    $Host.UI.RawUI.WindowTitle = "CLI: Media-Copytool $VersionNumber"

<# DEFINITION: Start-up:
    while($true){
        if($UserParams.GUI_CLI_Direct -eq "GUI"){
            [hashtable]$UserParams = Get-Parameters -UserParams $UserParams -Renew 0
            if((Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams) -eq $false){
                $UserParams.GUI_CLI_Direct = "CLI"
                Continue
            }
            Break
        }elseif($UserParams.GUI_CLI_Direct -eq "Direct"){
            Get-Parameters -JSONParamPath $UserParams.JSONParamPath -Renew 0
            Start-Everything -UserParams $UserParams
            Break
        }elseif($UserParams.GUI_CLI_Direct -eq "CLI"){
            Start-Everything -UserParams $UserParams
            Break
        }else{
            Write-ColorOut "Invalid choice of -GUI_CLI_Direct value (`"GUI`", `"CLI`", or `"Direct`"). Trying GUI..." -ForegroundColor Red
            Start-Sleep -Seconds 2
            $UserParams.GUI_CLI_Direct = "GUI"
            Continue
        }
    }
#>