#requires -version 3

<#
    .SYNOPSIS
        Copy (and verify) user-defined filetypes from A to B (and optionally C).
    .DESCRIPTION
        Uses Windows' Robocopy and Xcopy for file-copy, then uses PowerShell's Get-FileHash (SHA1) for verifying that files were copied without errors.
        Now supports multithreading via Boe Prox's PoshRSJob-cmdlet (https://github.com/proxb/PoshRSJob)
    .NOTES
        Version:        0.8.7 (Beta)
        Author:         flolilo
        Creation Date:  2018-02-17
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
        mc_preventsleep.ps1 if -PreventStandby is 1,
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
    [string]$LoadParamPresetName =  "",
    [string]$SaveParamPresetName =  "",
    [int]$RememberInPath =          0,
    [int]$RememberOutPath =         0,
    [int]$RememberMirrorPath =      0,
    [int]$RememberSettings =        0,
    [int]$Debug =                   0,
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
# DEFINITION: Some relevant variables from the start:
    [int]$ThreadCount = 4
    # Setting up the parameters for mc_parameters.json:
        if($LoadParamPresetName.Length -le 0){
            [string]$LoadParamPresetName = "default"
        }else{
            [string]$LoadParamPresetName = $($LoadParamPresetName.ToLower() -Replace '[^A-Za-z0-9_+-]','')
            [string]$LoadParamPresetName = $LoadParamPresetName.Substring(0, [math]::Min($LoadParamPresetName.Length, 64))
        }
        if($SaveParamPresetName.Length -le 0){
            [string]$SaveParamPresetName = $LoadParamPresetName
        }else{
            [string]$SaveParamPresetName = $($SaveParamPresetName.ToLower() -Replace '[^A-Za-z0-9_+-]','').Substring(0, 64)
        }
    # If you want to see the variables (buttons, checkboxes, ...) the GUI has to offer, set this to 1:
        [int]$getWPF = 0
    # Creating preventsleep.ps1's PID-variable here - for Invoke-Close:
        [int]$preventstandbyid = 999999999

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
        Write-Host "Could not load Module `"PoshRSJob`" - Please install it in an " -ForegroundColor Red -NoNewline
        Write-Host "administrative console " -ForegroundColor Magenta -NoNewline
        Write-Host "via " -ForegroundColor Red -NoNewline
        Write-Host "Install-Module PoshRSJob" -NoNewline
        Write-Host ", or run this script with " -ForegroundColor Red -NoNewline
        Write-Host "-GUI_CLI_Direct CLI" -NoNewline
        Write-Host "." -ForegroundColor Red
        Pause
        Exit
    }
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -TypeName System.Text.UTF8Encoding


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
    param(
        [Parameter(Mandatory=$true)]
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
    }
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
    if($script:PreventStandby -eq 1 -and $script:preventstandbyid -ne 999999999){
        Stop-Process -Id $script:preventstandbyid -ErrorAction SilentlyContinue
    }
    if((Get-RSJob).count -gt 0){
        Get-RSJob | Stop-RSJob
        Start-Sleep -Milliseconds 5
        Get-RSJob | Remove-RSJob
    }
    if($script:Debug -gt 0){
        Pause
    }
    Exit
}

# DEFINITION: For the auditory experience:
Function Start-Sound(){
    <#
        .SYNOPSIS
            Gives auditive feedback for fails and successes
        .DESCRIPTION
            Uses SoundPlayer and Windows's own WAVs to play sounds.
        .NOTES
            Date: 2018-10-25

        .PARAMETER Success
            1 plays Windows's "tada"-sound, 0 plays Windows's "chimes"-sound.
        
        .EXAMPLE
            For success: Start-Sound 1
        .EXAMPLE
            For fail: Start-Sound 0
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$Success
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
        [Parameter(Mandatory=$true)]
        [string]$JSONPath,
        [Parameter(Mandatory=$true)]
        [int]$Renew
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Getting parameter-values..." -ForegroundColor Cyan

    if( $Renew -eq 1 -or
        $script:InputPath.Length -eq 0 -or
        $script:OutputPath.Length -eq 0 -or
        $script:MirrorEnable -eq -1 -or
        ($script:MirrorEnable -eq 1 -and $script:MirrorPath.Length -eq 0) -or
        ($script:PresetFormats.Length -eq 0 -and $script:CustomFormatsEnable.Length -eq -1 -or ($script:CustomFormatsEnable -eq 1 -and $script:CustomFormats.Length -eq 0)) -or
        $script:OutputSubfolderStyle.Length -eq 0 -or
        $script:OutputFileStyle.Length -eq 0 -or
        $script:HistFilePath.Length -eq 0 -or
        $script:UseHistFile -eq -1 -or
        $script:WriteHistFile.Length -eq 0 -or
        $script:HistCompareHashes -eq -1 -or
        $script:InputSubfolderSearch -eq -1 -or
        $script:CheckOutputDupli -eq -1 -or
        $script:VerifyCopies -eq -1 -or
        $script:OverwriteExistingFiles -eq -1 -or
        $script:AvoidIdenticalFiles -eq -1 -or
        $script:ZipMirror -eq -1 -or
        $script:UnmountInputDrive -eq -1 -or
        $script:PreventStandby -eq -1
    ){
        if((Test-Path -LiteralPath $JSONPath -PathType Leaf) -eq $true){
            try{
                $jsonparams = Get-Content -Path $JSONPath -Raw -Encoding UTF8 | ConvertFrom-Json

                if($script:LoadParamPresetName -in $jsonparams.ParamPresetName){
                    $jsonparams = $jsonparams | Where-Object {$_.ParamPresetName -eq $script:LoadParamPresetName}
                    Write-ColorOut "Loaded preset `"$script:LoadParamPresetName`" from mc_parameters.json." -ForegroundColor Yellow -Indentation 4
                }elseif("default" -in $jsonparams.ParamPresetName){
                    $jsonparams = $jsonparams | Where-Object {$_.ParamPresetName -eq "default"}
                    Write-ColorOut "Loaded preset `"$($jsonparams.ParamPresetName)`", as `"$script:LoadParamPresetName`" is not specified in mc_parameters.json." -ForegroundColor Magenta -Indentation 4
                }else{
                    $jsonparams = $jsonparams | Select-Object -Index 0
                    Write-ColorOut "Loaded first preset from mc_parameters.json (`"$($jsonparams.ParamPresetName)`"), as neither `"$script:LoadParamPresetName`" nor `"default`" were found." -ForegroundColor Magenta -Indentation 4
                }
                $jsonparams = $jsonparams.ParamPresetValues

                if($Renew -eq 1){
                    [string]$script:SaveParamPresetName = $script:LoadParamPresetName
                }
                if($script:InputPath.Length -eq 0 -or $Renew -eq 1){
                    [string]$script:InputPath = $jsonparams.InputPath
                }
                if($script:OutputPath.Length -eq 0 -or $Renew -eq 1){
                    [string]$script:OutputPath = $jsonparams.OutputPath
                }
                if($script:MirrorEnable -eq -1 -or $Renew -eq 1){
                    [int]$script:MirrorEnable = $jsonparams.MirrorEnable
                }
                if($script:MirrorPath.Length -eq 0 -or $Renew -eq 1){
                    [string]$script:MirrorPath = $jsonparams.MirrorPath
                }
                if($script:PresetFormats.Length -eq 0 -or $Renew -eq 1){
                    [array]$script:PresetFormats = @($jsonparams.PresetFormats)
                }
                if($script:CustomFormatsEnable -eq -1 -or $Renew -eq 1){
                    [int]$script:CustomFormatsEnable = $jsonparams.CustomFormatsEnable
                }
                if($script:CustomFormats.Length -eq 0 -or $Renew -eq 1){
                    [array]$script:CustomFormats = @($jsonparams.CustomFormats)
                }
                if($script:OutputSubfolderStyle.Length -eq 0 -or $Renew -eq 1){
                    [string]$script:OutputSubfolderStyle = $jsonparams.OutputSubfolderStyle
                }
                if($script:OutputFileStyle.Length -eq 0 -or $Renew -eq 1){
                    [string]$script:OutputFileStyle = $jsonparams.OutputFileStyle
                }
                if($script:HistFilePath.Length -eq 0 -or $Renew -eq 1){
                    [string]$script:HistFilePath = $jsonparams.HistFilePath.Replace('$($PSScriptRoot)',"$PSScriptRoot")
                }
                if($script:UseHistFile -eq -1 -or $Renew -eq 1){
                    [int]$script:UseHistFile = $jsonparams.UseHistFile
                }
                if($script:WriteHistFile.Length -eq 0 -or $Renew -eq 1){
                    [string]$script:WriteHistFile = $jsonparams.WriteHistFile
                }
                if($script:HistCompareHashes -eq -1 -or $Renew -eq 1){
                    [int]$script:HistCompareHashes = $jsonparams.HistCompareHashes
                }
                if($script:InputSubfolderSearch -eq -1 -or $Renew -eq 1){
                    [int]$script:InputSubfolderSearch = $jsonparams.InputSubfolderSearch
                }
                if($script:CheckOutputDupli -eq -1 -or $Renew -eq 1){
                    [int]$script:CheckOutputDupli = $jsonparams.CheckOutputDupli
                }
                if($script:VerifyCopies -eq -1 -or $Renew -eq 1){
                    [int]$script:VerifyCopies = $jsonparams.VerifyCopies
                }
                if($script:OverwriteExistingFiles -eq -1 -or $Renew -eq 1){
                    [int]$script:OverwriteExistingFiles = $jsonparams.OverwriteExistingFiles
                }
                if($script:AvoidIdenticalFiles -eq -1 -or $Renew -eq 1){
                    [int]$script:AvoidIdenticalFiles = $jsonparams.AvoidIdenticalFiles
                }
                if($script:ZipMirror -eq -1 -or $Renew -eq 1){
                    [int]$script:ZipMirror = $jsonparams.ZipMirror
                }
                if($script:UnmountInputDrive -eq -1 -or $Renew -eq 1){
                    [int]$script:UnmountInputDrive = $jsonparams.UnmountInputDrive
                }
                if($script:PreventStandby -eq -1 -or $Renew -eq 1){
                    [int]$script:PreventStandby = $jsonparams.PreventStandby
                }
            }catch{
                if($script:GUI_CLI_Direct -eq "direct"){
                    Write-ColorOut "$JSONPath does not exist - aborting!" -ForegroundColor Red -Indentation 4
                    Write-ColorOut "(You can specify the path with -JSONParamPath. Also, if you use `"-GUI_CLI_Direct direct`", you can circumvent this error by setting all parameters by yourself - or use `"-GUI_CLI_Direct CLI`" or `"-GUI_CLI_Direct GUI`".)" -ForegroundColor Magenta -Indentation 4
                    Start-Sleep -Seconds 5
                    Exit
                }else{
                    Write-ColorOut "$JSONPath does not exist - cannot load presets!" -ForegroundColor Magenta -Indentation 4
                    Write-ColorOut "(It is recommended to use a JSON-file to save your parameters. You can save one when activating one of the `"Save`"-checkboxes in the GUI - or simply download the one from GitHub.)" -ForegroundColor Blue -Indentation 4
                    Start-Sleep -Seconds 5
                }
            }
            Clear-Variable -Name jsonparams
        }else{
            if($script:GUI_CLI_Direct -eq "direct"){
                Write-ColorOut "$JSONPath does not exist - aborting!" -ForegroundColor Red -Indentation 4
                Write-ColorOut "(You can specify the path with -JSONParamPath. Also, if you use `"-GUI_CLI_Direct direct`", you can circumvent this error by setting all parameters by yourself - or use `"-GUI_CLI_Direct CLI`" or `"-GUI_CLI_Direct GUI`".)" -ForegroundColor Magenta -Indentation 4
                Start-Sleep -Seconds 5
                Exit
            }else{
                Write-ColorOut "$JSONPath does not exist - cannot load presets!" -ForegroundColor Magenta -Indentation 4
                Write-ColorOut "(It is recommended to use a JSON-file to save your parameters. You can save one when activating one of the `"Save`"-checkboxes in the GUI - or simply download the one from GitHub.)" -ForegroundColor Blue -Indentation 4
                Start-Sleep -Seconds 5
            }
        }
    }
}

# DEFINITION: Show parameters on the console, then exit:
Function Show-Parameters(){
    Write-ColorOut "flolilo's Media-Copytool's Parameters:`r`n" -ForegroundColor Green
    Write-ColorOut "-GUI_CLI_Direct`t`t=`t$script:GUI_CLI_Direct" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-JSONParamPath`t`t=`t$script:JSONParamPath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-LoadParamPresetName`t=`t$script:LoadParamPresetName" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-SaveParamPresetName`t=`t$script:SaveParamPresetName" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberInPath`t`t=`t$script:RememberInPath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberOutPath`t`t=`t$script:RememberOutPath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberMirrorPath`t`t=`t$script:RememberMirrorPath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-RememberSettings`t`t=`t$script:RememberSettings" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-Debug`t`t`t=`t$script:Debug" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "These values come from $script:JSONParamPath :" -ForegroundColor DarkCyan -Indentation 2
    Write-ColorOut "-InputPath`t`t`t=`t$script:InputPath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputPath`t`t`t=`t$script:OutputPath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-MirrorEnable`t`t=`t$script:MirrorEnable" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-MirrorPath`t`t`t=`t$script:MirrorPath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-PresetFormats`t`t=`t$script:PresetFormats" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-CustomFormatsEnable`t=`t$script:CustomFormatsEnable" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-CustomFormats`t`t=`t$script:CustomFormats" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputSubfolderStyle`t=`t$script:OutputSubfolderStyle" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputFileStyle`t`t=`t$script:OutputFileStyle" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-HistFilePath`t`t=`t$script:HistFilePath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-UseHistFile`t`t=`t$script:UseHistFile" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-WriteHistFile`t`t=`t$script:WriteHistFile" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-HistCompareHashes`t`t=`t$script:HistCompareHashes" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-InputSubfolderSearch`t=`t$script:InputSubfolderSearch" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-CheckOutputDupli`t`t=`t$script:CheckOutputDupli" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-VerifyCopies`t`t=`t$script:VerifyCopies" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OverwriteExistingFiles`t=`t$script:OverwriteExistingFiles" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-AvoidIdenticalFiles`t=`t$script:AvoidIdenticalFiles" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-ZipMirror`t`t`t=`t$script:ZipMirror" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-UnmountInputDrive`t`t=`t$script:UnmountInputDrive" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-PreventStandby`t`t=`t$script:PreventStandby" -ForegroundColor Cyan -Indentation 4
}

# DEFINITION: "Select"-Window for buttons to choose a path.
Function Get-Folder(){
    param(
        [Parameter(Mandatory=$true)]
        [string]$ToInfluence
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
                $script:WPFtextBoxInput.Text = $browse.SelectedPath
            }elseif($ToInfluence -eq "output"){
                $script:WPFtextBoxOutput.Text = $browse.SelectedPath
            }elseif($ToInfluence -eq "mirror"){
                $script:WPFtextBoxMirror.Text = $browse.SelectedPath
            }
        }
    }else{
        [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        $browse = New-Object System.Windows.Forms.OpenFileDialog
        $browse.Multiselect = $false
        $browse.Filter = 'JSON (*.json)|*.json'

        if($browse.ShowDialog() -eq "OK"){
            if($browse.FileName -like "*.json"){
                $script:WPFtextBoxHistFile.Text = $browse.FileName
            }
        }
    }
}

# DEFINITION: Get values from GUI, then check the main input- and outputfolder:
Function Get-UserValues(){
    Write-ColorOut "$(Get-CurrentDate)  --  Getting user-values..." -ForegroundColor Cyan

    # DEFINITION: Get values, test paths:
        if($script:GUI_CLI_Direct -eq "CLI"){
            # $InputPath
            while($true){
                [string]$script:InputPath = Read-Host "    Please specify input-path"
                if($script:InputPath.Length -gt 1 -and (Test-Path -LiteralPath $script:InputPath -PathType Container) -eq $true){
                    break
                }else{
                    Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $OutputPath
            while($true){
                [string]$script:OutputPath = Read-Host "    Please specify output-path"
                if($script:OutputPath -eq $script:InputPath){
                    Write-ColorOut "Input-path is the same as output-path.`r`n" -ForegroundColor Magenta -Indentation 4
                    continue
                }else{
                    if($script:OutputPath.Length -gt 1 -and (Test-Path -LiteralPath $script:OutputPath -PathType Container) -eq $true){
                        break
                    }elseif((Split-Path -Parent -Path $script:OutputPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $script:OutputPath) -PathType Container) -eq $true){
                        try{
                            New-Item -ItemType Directory -Path $script:OutputPath -ErrorAction Stop | Out-Null
                            Write-ColorOut "Directory $script:OutputPath created." -ForegroundColor Yellow -Indentation 4
                            break
                        }catch{
                            Write-ColorOut "Could not reate directory $script:OutputPath - aborting!" -ForegroundColor Magenta -Indentation 4
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
                [int]$script:MirrorEnable = Read-Host "    Copy files to an additional folder? 1 = yes, 0 = no."
                if($script:MirrorEnable -eq 1 -or $script:MirrorEnable -eq 0){
                    break
                }else{
                    Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $MirrorPath
            if($script:MirrorEnable -eq 1){
                while($true){
                    [string]$script:MirrorPath = Read-Host "    Please specify additional output-path"
                    if($script:MirrorPath -eq $script:OutputPath -or $script:MirrorPath -eq $script:InputPath){
                        Write-ColorOut "`r`nAdditional output-path is the same as input- or output-path.`r`n" -ForegroundColor Red -Indentation 4
                        continue
                    }
                    if($script:MirrorPath -gt 1 -and (Test-Path -LiteralPath $script:MirrorPath -PathType Container) -eq $true){
                        break
                    }elseif((Split-Path -Parent -Path $script:MirrorPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $script:MirrorPath) -PathType Container) -eq $true){
                        try{
                            New-Item -ItemType Directory -Path $script:MirrorPath -ErrorAction Stop | Out-Null
                            Write-ColorOut "Directory $script:OutputPath created." -ForegroundColor Yellow -Indentation 4
                            break
                        }catch{
                            Write-ColorOut "Could not reate directory $script:OutputPath - aborting!" -ForegroundColor Magenta -Indentation 4
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
                [array]$script:PresetFormats = (Read-Host "    Which preset file-formats would you like to copy? Options: `"Can`",`"Nik`",`"Son`",`"Jpg`",`"Inter`",`"Mov`",`"Aud`", or leave empty for none. For multiple selection, separate with commata.").Split($separator,$option)
                if($script:PresetFormats.Length -eq 0 -or $script:PresetFormats -in $inter){
                    break
                }else{
                    Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $CustomFormatsEnable - Number
            while($true){
                [int]$script:CustomFormatsEnable = Read-Host "    How many custom file-formats? Range: From 0 for `"none`" to as many as you like."
                if($script:CustomFormatsEnable -in (0..999)){
                    break
                }else{
                    Write-ColorOut "Please choose a positive number!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $CustomFormats
            [array]$script:CustomFormats = @()
            if($script:CustomFormatsEnable -ne 0){
                for($i = 1; $i -le $script:CustomFormatsEnable; $i++){
                    while($true){
                        [string]$inter = Read-Host "    Select custom format no. $i. `"*`" (w/o quotes) = all files, `"*.ext`" = all files with extension .ext, `"file.*`" = all files named file."
                        if($inter.Length -ne 0){
                            $script:CustomFormats += $inter
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
                [string]$script:OutputSubfolderStyle = Read-Host "    Which subfolder-style should be used in the output-path? Options: none, unchanged, yyyy-MM-dd, yyyy_MM_dd, yyyy.MM.dd, yyyyMMdd, yy-MM-dd, yy_MM_dd, yy.MM.dd, yyMMdd."
                if($script:OutputSubfolderStyle -in $inter){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $OutputFileStyle
            while($true){
                [array]$inter = @("unchanged","yyyy-MM-dd_HH-mm-ss","yyyyMMdd_HHmmss","yyyyMMddHHmmss","yy-MM-dd_HH-mm-ss","yyMMdd_HHmmss","yyMMddHHmmss","HH-mm-ss","HH_mm_ss","HHmmss")
                [string]$script:OutputFileStyle = Read-Host "    Which subfolder-style should be used in the output-path? Options: unchanged, yyyy-MM-dd_HH-mm-ss, yyyyMMdd_HHmmss, yyyyMMddHHmmss, yy-MM-dd_HH-mm-ss, yyMMdd_HHmmss, yyMMddHHmmss, HH-mm-ss, HH_mm_ss, HHmmss."
                if($script:OutputFileStyle -cin $inter){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $HistFilePath
            if($script:UseHistFile -eq 1 -or $script:WriteHistFile -ne "no"){
                while($true){
                    [string]$script:HistFilePath = Read-Host "    Please specify path for the history-file"
                    if($script:HistFilePath.Length -gt 1 -and (Test-Path -LiteralPath $script:HistFilePath -PathType Leaf) -eq $true){
                        break
                    }else{
                        Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                        continue
                    }
                }
            }
            # $UseHistFile
            while($true){
                [int]$script:UseHistFile = Read-Host "    Compare input-files with the history-file to prevent duplicates? 1 = yes, 0 = no"
                if($script:UseHistFile -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $WriteHistFile
            while($true){
                [array]$inter = @("yes","no","overwrite")
                [string]$script:WriteHistFile = Read-Host "    Write newly copied files to history-file? Options: yes, no, overwrite."
                if($script:WriteHistFile -in $inter){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $HistCompareHashes
            while($true){
                [int]$script:HistCompareHashes = Read-Host "    Additionally compare all input-files via hashes? 1 = yes, 0 = no."
                if($script:HistCompareHashes -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $InputSubfolderSearch
            while($true){
                [int]$script:InputSubfolderSearch = Read-Host "    Check input-path's subfolders? 1 = yes, 0 = no."
                if($script:InputSubfolderSearch -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $CheckOutputDupli
            while($true){
                [int]$script:CheckOutputDupli = Read-Host "    Additionally check output-path for already copied files? 1 = yes, 0 = no."
                if($script:CheckOutputDupli -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $VerifyCopies
            while($true){
                [int]$script:VerifyCopies = Read-Host "    Enable verifying copied files afterwards for guaranteed successfully copied files? 1 = yes, 0 = no."
                if($script:VerifyCopies -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $OverwriteExistingFiles
            while($true){
                [int]$script:OverwriteExistingFiles = Read-Host "    Overwrite existing files? 1 = yes, 0 = no."
                if($script:OverwriteExistingFiles -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $AvoidIdenticalFiles
            while($true){
                [int]$script:AvoidIdenticalFiles = Read-Host "    Avoid copying identical input-files? 1 = yes, 0 = no."
                if($script:AvoidIdenticalFiles -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $ZipMirror
            if($script:MirrorEnable -eq 1){
                while($true){
                    [int]$script:ZipMirror = Read-Host "    Copying files to additional output-path as 7zip-archive? 1 = yes, 0 = no."
                    if($script:ZipMirror -in (0..1)){
                        break
                    }else{
                        Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                        continue
                    }
                }
            }
            # $UnmountInputDrive
            while($true){
                [int]$script:UnmountInputDrive = Read-Host "    Removing input-drive after copying & verifying (before mirroring)? Only use it for external drives. 1 = yes, 0 = no."
                if($script:UnmountInputDrive -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $PreventStandby
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
                [int]$script:RememberInPath = Read-Host "    Remember the input-path for future uses? 1 = yes, 0 = no."
                if($script:RememberInPath -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $RememberOutPath
            while($true){
                [int]$script:RememberOutPath = Read-Host "    Remember the output-path for future uses? 1 = yes, 0 = no."
                if($script:RememberOutPath -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $RememberMirrorPath
            while($true){
                [int]$script:RememberMirrorPath = Read-Host "    Remember the additional output-path for future uses? 1 = yes, 0 = no."
                if($script:RememberMirrorPath -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $RememberSettings
            while($true){
                [int]$script:RememberSettings = Read-Host "    Remember settings for future uses? 1 = yes, 0 = no."
                if($script:RememberSettings -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta -Indentation 4
                    continue
                }
            }
            # $SaveParamPresetName
            if($script:RememberSettings -eq 1 -or $script:RememberMirrorPath -eq 1 -or $script:RememberOutPath -eq 1 -or $script:RememberInPath -eq 1){
                while($true){
                    [string]$script:SaveParamPresetName = $((Read-Host "    Which preset do you want to save your settings to? (Valid cahracters: A-z,0-9,+,-,_ ; max. 64 cahracters)`t").ToLower() -Replace '[^A-Za-z0-9_+-]','')
                    [string]$script:SaveParamPresetName = $script:SaveParamPresetName.Substring(0, [math]::Min($SaveParamPresetName.Length, 64))
                    if($script:SaveParamPresetName.Length -gt 1){
                        break
                    }else{
                        Write-ColorOut "Invalid selection!" -ForegroundColor Magenta -Indentation 4
                        continue
                    }
                }
            }
            return $true
        }elseif($script:GUI_CLI_Direct -eq "GUI"){
            # $SaveParamPresetName
            $script:SaveParamPresetName = $($script:WPFtextBoxSavePreset.Text.ToLower() -Replace '[^A-Za-z0-9_+-]','')
            $script:SaveParamPresetName = $script:SaveParamPresetName.Substring(0, [math]::Min($script:SaveParamPresetName.Length, 64))
            # $InputPath
            $script:InputPath = $script:WPFtextBoxInput.Text
            # $OutputPath
            $script:OutputPath = $script:WPFtextBoxOutput.Text
            # $MirrorEnable
            $script:MirrorEnable = $(
                if($script:WPFcheckBoxMirror.IsChecked -eq $true){1}
                else{0}
            )
            # $MirrorPath
            $script:MirrorPath = $script:WPFtextBoxMirror.Text
            # $HistFilePath
            $script:HistFilePath = $script:WPFtextBoxHistFile.Text
            # $PresetFormats
            [array]$script:PresetFormats = @()
            if($script:WPFcheckBoxCan.IsChecked -eq $true){$script:PresetFormats += "Can"}
            if($script:WPFcheckBoxNik.IsChecked -eq $true){$script:PresetFormats += "Nik"}
            if($script:WPFcheckBoxSon.IsChecked -eq $true){$script:PresetFormats += "Son"}
            if($script:WPFcheckBoxJpg.IsChecked -eq $true){$script:PresetFormats += "Jpg"}
            if($script:WPFcheckBoxInter.IsChecked -eq $true){$script:PresetFormats += "Inter"}
            if($script:WPFcheckBoxMov.IsChecked -eq $true){$script:PresetFormats += "Mov"}
            if($script:WPFcheckBoxAud.IsChecked -eq $true){$script:PresetFormats += "Aud"}
            # $CustomFormatsEnable
            $script:CustomFormatsEnable = $(
                if($script:WPFcheckBoxCustom.IsChecked -eq $true){1}
                else{0}
            )
            # $CustomFormats
            [array]$script:CustomFormats = @()
            $separator = ","
            $option = [System.StringSplitOptions]::RemoveEmptyEntries
            $script:CustomFormats = $script:WPFtextBoxCustom.Text.Replace(" ",'').Split($separator,$option)
            # $OutputSubfolderStyle
            $script:OutputSubfolderStyle = $(
                if($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 0){"none"}
                elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 1){"unchanged"}
                elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 2){"yyyy-MM-dd"}
                elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 3){"yyyy_MM_dd"}
                elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 4){"yyyy.MM.dd"}
                elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 5){"yyyyMMdd"}
                elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 6){"yy-MM-dd"}
                elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 7){"yy_MM_dd"}
                elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 8){"yy.MM.dd"}
                elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 9){"yyMMdd"}
            )
            # $OutputFileStyle
            $script:OutputFileStyle = $(
                if($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 0){"unchanged"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 1){"yyyy-MM-dd_HH-mm-ss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 2){"yyyyMMdd_HHmmss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 3){"yyyyMMddHHmmss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 4){"yy-MM-dd_HH-mm-ss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 5){"yyMMdd_HHmmss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 6){"yyMMddHHmmss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 7){"HH-mm-ss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 8){"HH_mm_ss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 9){"HHmmss"}
            )
            # $UseHistFile
            $script:UseHistFile = $(
                if($script:WPFcheckBoxUseHistFile.IsChecked -eq $true){1}
                else{0}
            )
            # $WriteHistFile
            $script:WriteHistFile = $(
                if($script:WPFcomboBoxWriteHistFile.SelectedIndex -eq 0){"yes"}
                elseif($script:WPFcomboBoxWriteHistFile.SelectedIndex -eq 1){"overwrite"}
                elseif($script:WPFcomboBoxWriteHistFile.SelectedIndex -eq 2){"no"}
            )
            # $HistCompareHashes
            $script:HistCompareHashes = $(
                if($script:WPFcheckBoxCheckHashHist.IsChecked -eq $true){1}
                else{0}
            )
            # $InputSubfolderSearch
            $script:InputSubfolderSearch = $(
                if($script:WPFcheckBoxInSubSearch.IsChecked -eq $true){1}
                else{0}
            )
            # $CheckOutputDupli
            $script:CheckOutputDupli = $(
                if($script:WPFcheckBoxOutputDupli.IsChecked -eq $true){1}
                else{0}
            )
            # $VerifyCopies
            $script:VerifyCopies = $(
                if($script:WPFcheckBoxVerifyCopies.IsChecked -eq $true){1}
                else{0}
            )
            # $OverwriteExistingFiles
            $script:OverwriteExistingFiles = $(
                if($script:WPFcheckBoxOverwriteExistingFiles.IsChecked -eq $true){1}
                else{0}
            )
            # $AvoidIdenticalFiles
            $script:AvoidIdenticalFiles = $(
                if($script:WPFcheckBoxAvoidIdenticalFiles.IsChecked -eq $true){1}
                else{0}
            )
            # $ZipMirror
            $script:ZipMirror = $(
                if($script:WPFcheckBoxZipMirror.IsChecked -eq $true){1}
                else{0}
            )
            # $UnmountInputDrive
            $script:UnmountInputDrive = $(
                if($script:WPFcheckBoxUnmountInputDrive.IsChecked -eq $true){1}
                else{0}
            )
            # $PreventStandby
            $script:PreventStandby = $(
                if($script:WPFcheckBoxPreventStandby.IsChecked -eq $true){1}
                else{0}
            )
            # $RememberInPath
            $script:RememberInPath = $(
                if($script:WPFcheckBoxRememberIn.IsChecked -eq $true){1}
                else{0}
            )
            # $RememberOutPath
            $script:RememberOutPath = $(
                if($script:WPFcheckBoxRememberOut.IsChecked -eq $true){1}
                else{0}
            )
            # $RememberMirrorPath
            $script:RememberMirrorPath = $(
                if($script:WPFcheckBoxRememberMirror.IsChecked -eq $true){1}
                else{0}
            )
            # $RememberSettings
            $script:RememberSettings = $(
                if($script:WPFcheckBoxRememberSettings.IsChecked -eq $true){1}
                else{0}
            )
        }elseif($script:GUI_CLI_Direct -eq "direct"){
            # $MirrorEnable
            if($script:MirrorEnable -notin (0..1)){
                Write-ColorOut "Invalid choice of -MirrorEnable." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $PresetFormats
            [array]$inter = @("Can","Nik","Son","Jpeg","Jpg","Inter","Mov","Aud")
            if($script:PresetFormats.Length -gt 0 -and $(Compare-Object $inter $script:PresetFormats | Where-Object {$_.sideindicator -eq "=>"}).count -ne 0){
                Write-ColorOut "$script:PresetFormats"
                Write-ColorOut "Invalid choice of -PresetFormats." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $CustomFormatsEnable
            if($script:CustomFormatsEnable -notin (0..1)){
                Write-ColorOut "Invalid choice of -CustomFormatsEnable." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $OutputSubfolderStyle
            [array]$inter = @("none","unchanged","yyyy-mm-dd","yyyy_mm_dd","yyyy.mm.dd","yyyymmdd","yy-mm-dd","yy_mm_dd","yy.mm.dd","yymmdd")
            if($script:OutputSubfolderStyle -inotin $inter){
                Write-ColorOut "Invalid choice of -OutputSubfolderStyle." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $OutputFileStyle
            [array]$inter = @("unchanged","yyyy-MM-dd_HH-mm-ss","yyyyMMdd_HHmmss","yyyyMMddHHmmss","yy-MM-dd_HH-mm-ss","yyMMdd_HHmmss","yyMMddHHmmss","HH-mm-ss","HH_mm_ss","HHmmss")
            if($script:OutputFileStyle -cnotin $inter -or $script:OutputFileStyle.Length -gt $inter[1].Length){
                Write-ColorOut "Invalid choice of -OutputFileStyle." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $HistFilePath
            if(($script:UseHistFile -eq 1 -or $script:WriteHistFile -ne "no") -and (Test-Path -LiteralPath $script:HistFilePath -PathType Leaf) -eq $false){
                Write-ColorOut "Invalid choice of -HistFilePath." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $UseHistFile
            if($script:UseHistFile -notin (0..1)){
                Write-ColorOut "Invalid choice of -UseHistFile." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $WriteHistFile
            [array]$inter=@("yes","no","overwrite")
            if($script:WriteHistFile -notin $inter -or $script:WriteHistFile.Length -gt $inter[2].Length){
                Write-ColorOut "Invalid choice of -WriteHistFile." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $HistCompareHashes
            if($script:HistCompareHashes -notin (0..1)){
                Write-ColorOut "Invalid choice of -HistCompareHashes." -ForegroundColor Red -Indentation 4
                return $false
            }
            # InputSubfolderSearch
            if($script:InputSubfolderSearch -notin (0..1)){
                Write-ColorOut "Invalid choice of -InputSubfolderSearch." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $CheckOutputDupli
            if($script:CheckOutputDupli -notin (0..1)){
                Write-ColorOut "Invalid choice of -CheckOutputDupli." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $VerifyCopies
            if($script:VerifyCopies -notin (0..1)){
                Write-ColorOut "Invalid choice of -VerifyCopies." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $OverwriteExistingFiles
            if($script:OverwriteExistingFiles -notin (0..1)){
                Write-ColorOut "Invalid choice of -OverwriteExistingFiles." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $AvoidIdenticalFiles
            if($script:AvoidIdenticalFiles -notin (0..1)){
                Write-ColorOut "Invalid choice of -AvoidIdenticalFiles." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $ZipMirror
            if($script:ZipMirror -notin (0..1)){
                Write-ColorOut "Invalid choice of -ZipMirror." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $UnmountInputDrive
            if($script:UnmountInputDrive -notin (0..1)){
                Write-ColorOut "Invalid choice of -UnmountInputDrive." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $PreventStandby
            if($script:PreventStandby -notin (0..1)){
                Write-ColorOut "Invalid choice of -PreventStandby." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $RememberInPath
            if($script:RememberInPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberInPath." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $RememberOutPath
            if($script:RememberOutPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberOutPath." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $RememberMirrorPath
            if($script:RememberMirrorPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberMirrorPath." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $RememberSettings
            if($script:RememberSettings -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberSettings." -ForegroundColor Red -Indentation 4
                return $false
            }
        }

    # DEFINITION: Checking paths for GUI and direct:
        if($script:GUI_CLI_Direct -ne "CLI"){
            # $InputPath
            if($script:InputPath.Length -lt 2 -or (Test-Path -LiteralPath $script:InputPath -PathType Container) -eq $false){
                Write-ColorOut "Input-path $script:InputPath could not be found.`r`n" -ForegroundColor Red -Indentation 4
                return $false
            }
            # $OutputPath
            if($script:OutputPath -eq $script:InputPath){
                Write-ColorOut "Output-path is the same as input-path.`r`n" -ForegroundColor Red -Indentation 4
                return $false
            }
            if($script:OutputPath.Length -lt 2 -or (Test-Path -LiteralPath $script:OutputPath -PathType Container) -eq $false){
                if((Split-Path -Parent -Path $script:OutputPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $script:OutputPath) -PathType Container) -eq $true){
                    try{
                        New-Item -ItemType Directory -Path $script:OutputPath -ErrorAction Stop | Out-Null
                        Write-ColorOut "Output-path $script:OutputPath created." -ForegroundColor Yellow -Indentation 4
                    }catch{
                        Write-ColorOut "Could not create output-path $script:OutputPath." -ForegroundColor Red -Indentation 4
                        return $false
                    }
                }else{
                    Write-ColorOut "Output-path not found.`r`n" -ForegroundColor Red -Indentation 4
                    return $false
                }
            }
            # $MirrorPath
            if($script:MirrorEnable -eq 1){
                if($script:MirrorPath -eq $script:InputPath -or $script:MirrorPath -eq $script:OutputPath){
                    Write-ColorOut "Additional output-path is the same as input- or output-path.`r`n" -ForegroundColor Red -Indentation 4
                    return $false
                }
                if($script:MirrorPath.Length -lt 2 -or (Test-Path -LiteralPath $script:MirrorPath -PathType Container) -eq $false){
                    if((Test-Path -LiteralPath $(Split-Path -Qualifier -Path $script:MirrorPath) -PathType Container) -eq $true){
                        try{
                            New-Item -ItemType Directory -Path $script:MirrorPath -ErrorAction Stop | Out-Null
                            Write-ColorOut "Mirror-path $script:MirrorPath created." -ForegroundColor Yellow -Indentation 4
                        }catch{
                            Write-ColorOut "Could not create mirror-path $script:MirrorPath." -ForegroundColor Red -Indentation 4
                            return $false
                        }
                    }else{
                        Write-ColorOut "Additional output-path not found.`r`n" -ForegroundColor Red -Indentation 4
                        return $false
                    }
                }
            }
            # $HistFilePath
            if($script:UseHistFile -eq 1 -or $script:WriteHistFile -ne "no"){
                [string]$inter = Split-Path $script:HistFilePath -Qualifier
                if((Test-Path -LiteralPath $inter -PathType Container) -eq $false){
                    Write-ColorOut "History-file-volume $inter could not be found.`r`n" -ForegroundColor Red -Indentation 4
                    return $false
                }
            }
        }

    # DEFINITION: Sum up formats:
        [array]$script:allChosenFormats = @()
        if("Can" -in $script:PresetFormats){
            $script:allChosenFormats += "*.cr2"
        }
        if("Nik" -in $script:PresetFormats){
            $script:allChosenFormats += "*.nef"
            $script:allChosenFormats += "*.nrw"
        }
        if("Son" -in $script:PresetFormats){
            $script:allChosenFormats += "*.arw"
        }
        if("Jpg" -in $script:PresetFormats -or "Jpeg" -in $script:PresetFormats){
            $script:allChosenFormats += "*.jpg"
            $script:allChosenFormats += "*.jpeg"
        }
        if("Inter" -in $script:PresetFormats){
            $script:allChosenFormats += "*.dng"
            $script:allChosenFormats += "*.tif"
        }
        if("Mov" -in $script:PresetFormats){
            $script:allChosenFormats += "*.mov"
            $script:allChosenFormats += "*.mp4"
        }
        if("Aud" -in $script:PresetFormats){
            $script:allChosenFormats += "*.wav"
            $script:allChosenFormats += "*.mp3"
            $script:allChosenFormats += "*.m4a"
        }
        if($script:CustomFormatsEnable -ne 0 -and $script:CustomFormats.Length -gt 0){
            for($i = 0; $i -lt $script:CustomFormats.Length; $i++){
                $script:allChosenFormats += $script:CustomFormats[$i]
            }
        }
        if($script:allChosenFormats.Length -eq 0){
            if((Read-Host "    No file-format selected. Copy all files? 1 = yes, 0 = no.") -eq 1){
                [array]$script:allChosenFormats = "*"
            }else{
                Write-ColorOut "No file-format specified." -ForegroundColor Red -Indentation 4
                return $false
            }
        }

    # DEFINITION: Build switches:
        [switch]$script:input_recurse = $(
            if($script:InputSubfolderSearch -eq 1){$true}
            else{$false}
        )

    # DEFINITION: Get minutes (mm) to months (MM):
        $script:OutputSubfolderStyle = $script:OutputSubfolderStyle -Replace 'mm','MM'

    # DEFINITION: Check paths for trailing backslash:
        if($script:InputPath.replace($script:InputPath.Substring(0,$script:InputPath.Length-1),"") -eq "\" -and $script:InputPath.Length -gt 3){
            $script:InputPath = $script:InputPath.Substring(0,$script:InputPath.Length-1)
        }
        if($script:OutputPath.replace($script:OutputPath.Substring(0,$script:OutputPath.Length-1),"") -eq "\" -and $script:OutputPath.Length -gt 3){
            $script:OutputPath = $script:OutputPath.Substring(0,$script:OutputPath.Length-1)
        }
        if($script:MirrorPath.replace($script:MirrorPath.Substring(0,$script:MirrorPath.Length-1),"") -eq "\" -and $script:MirrorPath.Length -gt 3){
            $script:MirrorPath = $script:MirrorPath.Substring(0,$script:MirrorPath.Length-1)
        }

    # DEFINITION: If debugging, show stuff:
        if($script:Debug -gt 1){
            Write-ColorOut "InputPath:`t`t`t$script:InputPath" -Indentation 4
            Write-ColorOut "OutputPath:`t`t`t$script:OutputPath" -Indentation 4
            Write-ColorOut "MirrorEnable:`t`t$script:MirrorEnable" -Indentation 4
            Write-ColorOut "MirrorPath:`t`t`t$script:MirrorPath" -Indentation 4
            Write-ColorOut "CustomFormatsEnable:`t$script:CustomFormatsEnable" -Indentation 4
            Write-ColorOut "AllChosenFormats:`t`t$script:allChosenFormats" -Indentation 4
            Write-ColorOut "OutputSubfolderStyle:`t$script:OutputSubfolderStyle" -Indentation 4
            Write-ColorOut "OutputFileStyle:`t`t$script:OutputFileStyle" -Indentation 4
            Write-ColorOut "HistFilePath:`t`t$script:HistFilePath" -Indentation 4
            Write-ColorOut "UseHistFile:`t`t$script:UseHistFile" -Indentation 4
            Write-ColorOut "WriteHistFile:`t`t$script:WriteHistFile" -Indentation 4
            Write-ColorOut "HistCompareHashes:`t`t$script:HistCompareHashes" -Indentation 4
            Write-ColorOut "InputSubfolderSearch:`t$script:InputSubfolderSearch" -Indentation 4
            Write-ColorOut "CheckOutputDupli:`t`t$script:CheckOutputDupli" -Indentation 4
            Write-ColorOut "VerifyCopies:`t`t$script:VerifyCopies" -Indentation 4
            Write-ColorOut "OverwriteExistingFiles:`t$script:OverwriteExistingFiles" -Indentation 4
            Write-ColorOut "ZipMirror:`t`t`t$script:ZipMirror" -Indentation 4
            Write-ColorOut "UnmountInputDrive:`t`t$script:UnmountInputDrive" -Indentation 4
            Write-ColorOut "PreventStandby:`t`t$script:PreventStandby" -Indentation 4
        }

    # If everything was sucessful, return true:
    return $true
}

# DEFINITION: If checked, remember values for future use:
Function Set-Parameters(){
    param(
        [Parameter(Mandatory=$true)]
        [string]$JSONPath
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Remembering parameters as preset `"$script:SaveParamPresetName`"..." -ForegroundColor Cyan

    [array]$inter = @([PSCustomObject]@{
        ParamPresetName = $script:SaveParamPresetName
        ParamPresetValues = [PSCustomObject]@{
            InputPath = $script:InputPath
            OutputPath = $script:OutputPath
            MirrorEnable = $script:MirrorEnable
            MirrorPath = $script:MirrorPath
            PresetFormats = $script:PresetFormats
            CustomFormatsEnable = $script:CustomFormatsEnable
            CustomFormats = $script:CustomFormats
            OutputSubfolderStyle = $script:OutputSubfolderStyle
            OutputFileStyle = $script:OutputFileStyle
            HistFilePath = $script:HistFilePath.Replace($PSScriptRoot,'$($PSScriptRoot)')
            UseHistFile = $script:UseHistFile
            WriteHistFile = $script:WriteHistFile
            HistCompareHashes = $script:HistCompareHashes
            InputSubfolderSearch = $script:InputSubfolderSearch
            CheckOutputDupli = $script:CheckOutputDupli
            VerifyCopies = $script:VerifyCopies
            OverwriteExistingFiles = $script:OverwriteExistingFiles
            AvoidIdenticalFiles = $script:AvoidIdenticalFiles
            ZipMirror = $script:ZipMirror
            UnmountInputDrive = $script:UnmountInputDrive
            PreventStandby = $script:PreventStandby
        }
    })
    if((Test-Path -LiteralPath $JSONPath -PathType Leaf) -eq $true){
        try{
            $jsonparams = Get-Content -Path $JSONPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if($script:Debug -gt 1){
                Write-ColorOut "From:" -ForegroundColor Yellow -Indentation 2
                $jsonparams | ConvertTo-Json | Out-Host
            }
        }catch{
            Write-ColorOut "Getting parameters from $JSONPath failed - aborting!" -ForegroundColor Red
            Start-Sleep -Seconds 5
            Exit
        }
        if($script:SaveParamPresetName -in $jsonparams.ParamPresetName -or $script:SaveParamPresetName -eq $jsonparams.ParamPresetName){
            if($jsonparams.ParamPresetName -is [array]){
                Write-ColorOut "Preset $($inter.ParamPresetName) will be updated." -ForegroundColor DarkGreen -Indentation 4
                for($i=0; $i -lt $jsonparams.ParamPresetName.Length; $i++){
                    if($jsonparams.ParamPresetName[$i] -eq $inter.ParamPresetName){
                        if($script:RememberInPath -eq 1){
                            $jsonparams.ParamPresetValues[$i].InputPath = $inter.ParamPresetValues.InputPath
                        }
                        if($script:RememberOutPath -eq 1){
                            $jsonparams.ParamPresetValues[$i].OutputPath = $inter.ParamPresetValues.OutputPath
                        }
                        if($script:RememberMirrorPath -eq 1){
                            $jsonparams.ParamPresetValues[$i].MirrorPath = $inter.ParamPresetValues.MirrorPath
                        }
                        if($script:RememberSettings -eq 1){
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
            }else{
                Write-ColorOut "Preset $($inter.ParamPresetName) will be the only preset." -ForegroundColor Yellow -Indentation 4
                $jsonparams = $inter
            }
        }else{
            Write-ColorOut "Preset $($inter.ParamPresetName) will be added." -ForegroundColor Green -Indentation 4
            $jsonparams += $inter
        }
    }else{
        $jsonparams = $inter
    }
    $jsonparams | Out-Null
    $jsonparams = $jsonparams | ConvertTo-Json -Depth 5
    $jsonparams | Out-Null

    if($script:Debug -gt 1){
        Write-ColorOut "To:" -ForegroundColor Yellow -Indentation 2
        $jsonparams | Out-Host
    }

    while($true){
        try{
            [System.IO.File]::WriteAllText($script:JSONParamPath, $jsonparams)
            break
        }catch{
            Write-ColorOut "Writing to parameter-file failed! Trying again..." -ForegroundColor Red -Indentation 4
            Pause
            Continue
        }
    }
}

# DEFINITION: Searching for selected formats in Input-Path, getting Path, Name, Time, and calculating Hash:
Function Start-FileSearch(){
    param(
        [Parameter(Mandatory=$true)]
        [string]$InPath
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-CurrentDate)  --  Finding files." -ForegroundColor Cyan

    # pre-defining variables:
    [array]$InFiles = @()
    $script:resultvalues = @{}

    # Search files and get some information about them:
    [int]$counter = 1
    for($i=0;$i -lt $script:allChosenFormats.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
            Write-Progress -Id 1 -Activity "Find files in $InPath..." -PercentComplete $((($i* 100) / $($script:allChosenFormats.Length))) -Status "Format #$($i + 1) / $($script:allChosenFormats.Length)"
            $sw.Reset()
            $sw.Start()
        }

        $InFiles += Get-ChildItem -LiteralPath $InPath -Filter $script:allChosenFormats[$i] -Recurse:$script:input_recurse -File | ForEach-Object -Process {
            if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
                Write-Progress -Id 2 -Activity "Looking for files..." -PercentComplete -1 -Status "File #$counter - $($_.FullName.Replace("$InPath",'.'))"
                $sw.Reset()
                $sw.Start()
            }
            $counter++
            [PSCustomObject]@{
                FullName = $_.FullName
                InPath = (Split-Path -Path $_.FullName -Parent)
                InName = $_.Name
                BaseName = $(if($script:OutputFileStyle -eq "unchanged"){$_.BaseName}else{$_.LastWriteTime.ToString("$script:OutputFileStyle")})
                Extension = $_.Extension
                Size = $_.Length
                Date = $_.LastWriteTime.ToString("yyyy-MM-dd_HH-mm-ss")
                Sub_Date = $(if($script:OutputSubfolderStyle -eq "none"){""}elseif($script:OutputSubfolderStyle -eq "unchanged"){$($(Split-Path -Parent -Path $_.FullName).Replace($script:InputPath,""))}else{"\$($_.LastWriteTime.ToString("$script:OutputSubfolderStyle"))"})
                OutPath = "ZYX"
                OutName = $_.Name
                OutBaseName = $(if($script:OutputFileStyle -eq "unchanged"){$_.BaseName}else{$_.LastWriteTime.ToString("$script:OutputFileStyle")})
                Hash = "ZYX"
                ToCopy = 1
            }
        } -End {
            Write-Progress -Id 2 -Activity "Looking for files..." -Status "Done!" -Completed
        }
    }
    Write-Progress -Id 1 -Activity "Find files in $InPath..." -Status "Done!" -Completed
    $sw.Reset()

    $InFiles = $InFiles | Sort-Object -Property FullName
    $InFiles | Out-Null

    if($script:Debug -gt 1){
        if((Read-Host "    Show all found files? `"1`" for `"yes`"") -eq 1){
            for($i=0; $i -lt $InFiles.Length; $i++){
                Write-ColorOut "$($InFiles[$i].FullName.Replace($InPath,"."))" -ForegroundColor Gray -Indentation 4
            }
        }
    }

    # DEFINITION: If dupli-checks are enabled: Get hashes for all input-files:
    if(($script:UseHistFile -eq 1 -and $script:HistCompareHashes -eq 1) -or $script:CheckOutputDupli -eq 1){
        Write-ColorOut "Running RS-Job for getting hashes (see progress-bar)..." -ForegroundColor DarkGray -Indentation 4
        $InFiles | Start-RSJob -Name "GetHashAll" -FunctionsToLoad Write-ColorOut -ScriptBlock {
            try{
                $_.Hash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash
            }catch{
                Write-ColorOut "Could not get hash of $($_.FullName)" -ForegroundColor Red -Indentation 4
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
        [string]$HistFilePath
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Checking for history-file, importing values..." -ForegroundColor Cyan

    [array]$files_history = @()
    if(Test-Path -LiteralPath $HistFilePath -PathType Leaf){
        try{
            $JSONFile = Get-Content -LiteralPath $HistFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        }catch{
            Write-ColorOut "Could not load $HistFilePath." -ForegroundColor Red -Indentation 4
            Start-Sleep -Seconds 5
            Invoke-Close
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
            if((Read-Host "    Show fonud history-values? `"1`" means `"yes`"") -eq 1){
                Write-ColorOut "Found values: $($files_history.Length)" -ForegroundColor Yellow -Indentation 4
                Write-ColorOut "Name`t`tDate`t`tSize`t`tHash" -Indentation 4
                for($i = 0; $i -lt $files_history.Length; $i++){
                    Write-ColorOut "$($files_history[$i].InName)`t$($files_history[$i].Date)`t$($files_history[$i].Size)`t$($files_history[$i].Hash)" -ForegroundColor Gray -Indentation 4
                }
            }
        }
        if("null" -in $files_history -or $files_history.InName.Length -lt 1 -or ($files_history.Length -gt 1 -and (($files_history.InName.Length -ne $files_history.Date.Length) -or ($files_history.InName.Length -ne $files_history.Size.Length) -or ($files_history.InName.Length -ne $files_history.Hash.Length)))){
            Write-ColorOut "Some values in the history-file $HistFilePath seem wrong - it's safest to delete the whole file." -ForegroundColor Magenta -Indentation 4
            Write-ColorOut "InNames: $($files_history.InName.Length) Dates: $($files_history.Date.Length) Sizes: $($files_history.Size.Length) Hashes: $($files_history.Hash.Length)" -Indentation 4
            if((Read-Host "    Is that okay? Type '1' (without quotes) to confirm or any other number to abort. Confirm by pressing Enter") -eq 1){
                $script:UseHistFile = 0
                $script:WriteHistFile = "Overwrite"
            }else{
                Write-ColorOut "`r`n`tAborting.`r`n" -ForegroundColor Magenta
                Invoke-Close
            }
        }
        if("ZYX" -in $files_history.Hash -and $script:HistCompareHashes -eq 1){
            Write-ColorOut "Some hash-values in the history-file are missing (because -VerifyCopies wasn't activated when they were added). This could lead to duplicates." -ForegroundColor Magenta -Indentation 4
            Start-Sleep -Seconds 2
        }
    }else{
        Write-ColorOut "History-File $HistFilePath could not be found. This means it's possible that duplicates get copied." -ForegroundColor Magenta -Indentation 4
        if((Read-Host "    Is that okay? Type '1' (without quotes) to confirm or any other number to abort. Confirm by pressing Enter") -eq 1){
            $script:UseHistFile = 0
            $script:WriteHistFile = "Overwrite"
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
        [array]$HistFiles
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-CurrentDate)  --  Checking for duplicates via history-file." -ForegroundColor Cyan

    $properties = @("InName","Date","Size")
    if($script:HistCompareHashes -eq 1){
        $properties += "Hash"
    }

    for($i=0; $i -lt $InFiles.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750){
            Write-Progress -Activity "Comparing input-files to already copied files (history-file).." -PercentComplete $($i * 100 / $InFiles.Length) -Status "File # $($i + 1) / $($InFiles.Length) - $($InFiles[$i].name)"
            $sw.Reset()
            $sw.Start()
        }

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
                    Write-ColorOut "Copy $($InFiles[$i].FullName.Replace($InPath,"."))" -ForegroundColor Gray -Indentation 4
                }else{
                    Write-ColorOut "Omit $($InFiles[$i].FullName.Replace($InPath,"."))" -ForegroundColor DarkGreen -Indentation 4
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
        [string]$OutPath
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-CurrentDate)  --  Checking for duplicates in OutPath." -ForegroundColor Cyan

    # pre-defining variables:
    [array]$files_duplicheck = @()

    [int]$dupliindex_out = 0

    [int]$counter = 1
    for($i=0;$i -lt $script:allChosenFormats.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
            Write-Progress -Id 1 -Activity "Find files in $OutPath..." -PercentComplete $(($i / $($script:allChosenFormats.Length)) * 100) -Status "Format #$($i + 1) / $($script:allChosenFormats.Length)"
            $sw.Reset()
            $sw.Start()
        }

        $files_duplicheck += Get-ChildItem -LiteralPath $OutPath -Filter $script:allChosenFormats[$i] -Recurse -File | ForEach-Object -Process {
            if($sw.Elapsed.TotalMilliseconds -ge 750 -or $counter -eq 1){
                Write-Progress -Id 2 -Activity "Looking for files..." -PercentComplete -1 -Status "File #$counter - $($_.FullName.Replace("$OutPath",'.'))"
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
    Write-Progress -Id 1 -Activity "Find files in $OutPath..." -Status "Done!" -Completed
    $sw.Reset()

    $sw.Start()
    if($files_duplicheck.Length -gt 0){
        # DEFINITION: New implementation:
        $properties = @("Date","Size")
        for($i=0; $i -lt $files_duplicheck.Length; $i++){
            if($sw.Elapsed.TotalMilliseconds -ge 750 -or $i -eq 0){
                Write-Progress -Id 1 -Activity "Determine files in output that need to be checked..." -PercentComplete $($i * 100 / $($files_duplicheck.Length)) -Status "File # $($i + 1) / $($files_duplicheck.Length)"
                $sw.Reset()
                $sw.Start()
            }
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

            <# DEFINITION: old code
                for($i = 0; $i -lt $InFiles.Length; $i++){
                    if($sw.Elapsed.TotalMilliseconds -ge 750 -or $i -eq 0){
                        Write-Progress -Activity "Comparing to files in out-path..." -PercentComplete $($i / $($InFiles.Length - $dupliindex_hist.Length) * 100) -Status "File # $($i + 1) / $($InFiles.Length) - $($InFiles[$i].name)"
                        $sw.Reset()
                        $sw.Start()
                    }

                    $j = $files_duplicheck.Length
                    while($true){
                        # calculate hash only if date and size are the same:
                        if($($InFiles[$i].date) -eq $($files_duplicheck[$j].date) -and $($InFiles[$i].size) -eq $($files_duplicheck[$j].size)){
                            try{
                                $files_duplicheck[$j].Hash = (Get-FileHash -LiteralPath $files_duplicheck[$j].FullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash)
                            }catch{
                                Write-ColorOut "Getting hash of $($files_duplicheck[$j].FullName) failed." -ForegroundColor Red -Indentation 4
                                if($j -le 0){
                                    break
                                }
                                $j--
                            }
                            if($InFiles[$i].Hash -eq $files_duplicheck[$j].Hash){
                                $dupliindex_out++
                                $InFiles[$i].ToCopy = 0
                                $files_duplicheck[$j].InName = $InFiles[$i].InName
                                break
                            }else{
                                if($j -le 0){
                                    break
                                }
                                $j--
                            }
                        }else{
                            if($j -le 0){
                                break
                            }
                            $j--
                        }
                    }
                }
                Write-Progress -Activity "Comparing to files in out-path..." -Status "Done!" -Completed
                $sw.Reset()
            #>

            if($script:Debug -gt 1){
                if((Read-Host "    Show all files? `"1`" for `"yes`"") -eq 1){
                    Write-ColorOut "`r`n`tFiles to skip / process:" -ForegroundColor Yellow
                    for($i=0; $i -lt $InFiles.Length; $i++){
                        if($InFiles[$i].ToCopy -eq 1){
                            Write-ColorOut "Copy $($InFiles[$i].FullName.Replace($InPath,"."))" -ForegroundColor Gray -Indentation 4
                        }else{
                            Write-ColorOut "Omit $($InFiles[$i].FullName.Replace($InPath,"."))" -ForegroundColor DarkGreen -Indentation 4
                        }
                    }
                }
            }
            Write-ColorOut "Files to skip (outpath):`t$dupliindex_out" -ForegroundColor DarkGreen -Indentation 4

            [array]$InFiles = @($InFiles | Where-Object {$_.ToCopy -eq 1})
        }else{
            Write-ColorOut "No potential dupli-files in $OutPath - skipping additional verification." -ForegroundColor Gray -Indentation 4
        }

        [array]$script:dupliout = $files_duplicheck
        $script:resultvalues.dupliout = $dupliindex_out
    }else{
        Write-ColorOut "No files in $OutPath - skipping additional verification." -ForegroundColor Magenta -Indentation 4
    }

    $sw.Reset()
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

# DEFINITION: Cleaning away all files that will not get copied. ALSO checks for Identical files:
Function Start-InputGetHash(){
    param(
        [Parameter(Mandatory=$true)]
        [array]$InFiles
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Calculate remaining hashes" -ForegroundColor Cyan -NoNewLine
    if($script:AvoidIdenticalFiles -eq 1){
        Write-ColorOut " (& avoid identical input-files)." -ForegroundColor Cyan
    }else{
        Write-ColorOut " "
    }

    # DEFINITION: Calculate hash (if not yet done):
    if($script:VerifyCopies -eq 1 -and "ZYX" -in $InFiles.Hash){
        $InFiles | Where-Object {$_.Hash -eq "ZYX"} | Start-RSJob -Name "GetHashRest" -FunctionsToLoad Write-ColorOut -ScriptBlock {
            try{
                $_.Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash)
            }catch{
                Write-ColorOut "Failed to get hash of `"$($_.FullName)`"" -ForegroundColor Red -Indentation 4
                $_.Hash = "GetHashRestWRONG"
            }
        } | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob -Name "GetHashRest" | Remove-RSJob
    }

    # DEFINITION: if enabled, avoid copying identical files from the input-path:
    if($script:AvoidIdenticalFiles -eq 1){
        [array]$inter = ($InFiles | Sort-Object -Property InName,Date,Size,Hash -Unique)
        if($inter.Length -ne $InFiles.Length){
            Write-ColorOut "$($InFiles.Length - $inter.Length) identical files were found in the input-path - only copying one of each." -ForegroundColor Magenta
            Start-Sleep -Seconds 3
        }
        $script:resultvalues.identicalFiles = $($InFiles.Length - $inter.Length)
        [array]$InFiles = $inter
    }

    $script:resultvalues.copyfiles = $InFiles.Length
    Write-ColorOut "Files left after dupli-check(s):`t$($script:resultvalues.ingoing - $script:resultvalues.duplihist - $script:resultvalues.dupliout - $script:resultvalues.identicalFiles) = $($script:resultvalues.copyfiles)" -ForegroundColor Yellow -Indentation 4

    return $InFiles
}

# DEFINITION: Check if filename already exists and if so, then choose new name for copying:
Function Start-OverwriteProtection(){
    param(
        [Parameter(Mandatory=$true)]
        [array]$InFiles,
        [Parameter(Mandatory=$true)]
        [string]$OutPath
    )
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Prevent overwriting " -ForegroundColor Cyan -NoNewLine
    if($script:OverwriteExistingFiles -eq 0){
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
        $InFiles[$i].outpath = $("$OutPath$($InFiles[$i].sub_date)").Replace("\\","\").Replace("\\","\")
        $InFiles[$i].outbasename = $InFiles[$i].basename
        $InFiles[$i].outname = "$($InFiles[$i].basename)$($InFiles[$i].extension)"
        # check for files with same name from input:
        [int]$j = 1
        [int]$k = 1
        while($true){
            [string]$check = "$($InFiles[$i].outpath)\$($InFiles[$i].outname)"
            if($check -notin $allpaths){
                if((Test-Path -LiteralPath $check -PathType Leaf) -eq $false -or $script:OverwriteExistingFiles -eq 1){
                    $allpaths += $check
                    break
                }else{
                    if($k -eq 1){
                        $InFiles[$i].outbasename = "$($InFiles[$i].outbasename)_OutCopy$k"
                    }else{
                        $InFiles[$i].outbasename = $InFiles[$i].outbasename -replace "_OutCopy$($k - 1)","_OutCopy$k"
                    }
                    $InFiles[$i].outname = "$($InFiles[$i].outbasename)$($InFiles[$i].extension)"
                    $k++
                    # if($script:Debug -ne 0){Write-ColorOut $InFiles[$i].outbasename}
                    continue
                }
            }else{
                if($j -eq 1){
                    $InFiles[$i].outbasename = "$($InFiles[$i].outbasename)_InCopy$j"
                }else{
                    $InFiles[$i].outbasename = $InFiles[$i].outbasename -replace "_InCopy$($j - 1)","_InCopy$j"
                }
                $InFiles[$i].outname = "$($InFiles[$i].outbasename)$($InFiles[$i].extension)"
                $j++
                # if($script:Debug -ne 0){Write-ColorOut $InFiles[$i].outbasename}
                continue
            }
        }
    }
    Write-Progress -Activity "Prevent overwriting existing files..." -Status "Done!" -Completed

    if($script:Debug -gt 1){
        if((Read-Host "    Show all names? `"1`" for `"yes`"") -eq 1){
            [int]$indent = 0
            for($i=0; $i -lt $InFiles.Length; $i++){
                Write-ColorOut "    $($InFiles[$i].outpath.Replace($OutPath,"."))\$($InFiles[$i].outname)`t`t" -NoNewLine -ForegroundColor Gray
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
        [string]$InPath,
        [Parameter(Mandatory=$true)]
        [string]$OutPath
    )

    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Copy files from $InPath to " -NoNewLine -ForegroundColor Cyan
    if($script:OutputSubfolderStyle -eq "none"){
        Write-ColorOut "$($OutPath)..." -ForegroundColor Cyan
    }elseif($script:OutputSubfolderStyle -eq "unchanged"){
        Write-ColorOut "$($OutPath) with original subfolders:" -ForegroundColor Cyan
    }else{
        Write-ColorOut "$OutPath\$($script:OutputSubfolderStyle)..." -ForegroundColor Cyan
    }

    $InFiles = $InFiles | Sort-Object -Property inpath,outpath

    # setting up robocopy:
    [array]$rc_command = @()
    [string]$rc_suffix = "/R:5 /W:15 /MT:$script:ThreadCount /XO /XC /XN /NJH /NC /J"
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
}

# DEFINITION: Starting 7zip:
Function Start-7zip(){
    param(
        [string]$7zexe = "$($PSScriptRoot)\7z.exe",
        [Parameter(Mandatory=$true)]
        [array]$InFiles
    )
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Zipping files..." -ForegroundColor Cyan

    if((Test-Path -LiteralPath "$($PSScriptRoot)\7z.exe" -PathType Leaf) -eq $false){
        if((Test-Path -LiteralPath "C:\Program Files\7-Zip\7z.exe" -PathType Leaf) -eq $true){
            $7zexe = "C:\Program Files\7-Zip\7z.exe"
        }elseif((Test-Path -LiteralPath "C:\Program Files (x86)\7-Zip\7z.exe" -PathType Leaf) -eq $true){
            $7zexe = "C:\Program Files (x86)\7-Zip\7z.exe"
        }else{
            Write-ColorOut "7z.exe could not be found - aborting zipping!" -ForegroundColor Red -Indentation 4
            Pause
            break
        }
    }

    [string]$7z_prefix = "a -tzip -mm=Copy -mx0 -ssw -sccUTF-8 -mem=AES256 -bb0"
    [string]$7z_workdir = $(if($script:OutputSubfolderStyle -ne "none" -and $script:OutputSubfolderStyle -ne "unchanged"){" `"-w$(Split-Path -Qualifier -Path $script:MirrorPath)\`" `"$script:MirrorPath\$(Get-Date -Format "$script:OutputSubfolderStyle")_MIRROR.zip`" "}else{" `"-w$(Split-Path -Qualifier -Path $script:MirrorPath)\`" `"$script:MirrorPath\$($(Get-Date).ToString().Replace(":",'').Replace(",",'').Replace(" ",'').Replace(".",''))_MIRROR.zip`" "})
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

    foreach($cmd in $7z_command){
        Start-Process -FilePath $7zexe -ArgumentList $cmd -NoNewWindow -Wait
    }
}

# DEFINITION: Verify newly copied files
Function Start-FileVerification(){
    param(
        [Parameter(Mandatory=$true)]
        [array]$InFiles
    )
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Verify newly copied files..." -ForegroundColor Cyan

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
        [string]$HistFilePath
    )
    Write-ColorOut "$(Get-CurrentDate)  --  Write attributes of successfully copied files to history-file..." -ForegroundColor Cyan

    [array]$results = @($InFiles | Where-Object {$_.ToCopy -eq 0} | Select-Object -Property InName,Date,Size,Hash)

    if($script:WriteHistFile -eq "Yes" -and (Test-Path -LiteralPath $HistFilePath -PathType Leaf) -eq $true){
        try{
            $JSON = Get-Content -LiteralPath $HistFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        }catch{
            Write-ColorOut "Could not load $HistFilePath." -ForegroundColor Red -Indentation 4
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
    if($script:CheckOutputDupli -gt 0){
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

    try{
        [System.IO.File]::WriteAllText($HistFilePath, $results)
    }
    catch{
        Write-ColorOut "Writing to history-file failed! Trying again..." -ForegroundColor Red -Indentation 4
        Pause
        Continue
    }
}

# DEFINITION: Starts all the things.
Function Start-Everything(){
    Write-ColorOut "`r`n$(Get-CurrentDate)  --  Starting everything..." -NoNewLine -ForegroundColor Cyan -BackgroundColor DarkGray
    Write-ColorOut "A                               A" -ForegroundColor DarkGray -BackgroundColor DarkGray

    if($script:Debug -gt 0){
        $script:timer = [diagnostics.stopwatch]::StartNew()
    }

    while($true){
        # DEFINITION: Get User-Values:
        if((Get-UserValues) -eq $false -and $script:ShowParams -eq 0){
            Start-Sound 0
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml"
            }
            break
        }
        Invoke-Pause

        # DEFINITION: Show parameters, then close:
        if($script:ShowParams -ne 0){
            Show-Parameters
            Pause
            Invoke-Close
        }

        # DEFINITION: If enabled: remember parameters:
        if($script:RememberInPath -ne 0 -or $script:RememberOutPath -ne 0 -or $script:RememberMirrorPath -ne 0 -or $script:RememberSettings -ne 0){
            Set-Parameters -JSONPath $script:JSONParamPath
            Invoke-Pause
        }

        # DEFINITION: If enabled: start preventsleep.ps1:
        if($script:PreventStandby -eq 1){
            if((Test-Path -Path "$($PSScriptRoot)\mc_preventsleep.ps1" -PathType Leaf) -eq $true){
                $script:preventstandbyid = (Start-Process powershell -ArgumentList "$($PSScriptRoot)\mc_preventsleep.ps1" -WindowStyle Hidden -PassThru).Id
                if($script:Debug -gt 0){
                    Write-ColorOut "preventsleep-ID is $script:preventstandbyid" -ForegroundColor Magenta -BackgroundColor DarkGray
                }
            }else{
                Write-Host "Couldn't find .\mc_preventsleep.ps1, so can't prevent standby." -ForegroundColor Magenta
                Start-Sleep -Seconds 3
            }
        }

        # DEFINITION: Search for files:
        [array]$inputfiles = (Start-FileSearch -InPath $script:InputPath)
        if($inputfiles.Length -lt 1){
            Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
            Start-Sound 1
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml"
            }
            break
        }
        Invoke-Pause

        # DEFINITION: If enabled: Get History-File:
        [array]$histfiles = @()
        if($script:UseHistFile -eq 1){
            [array]$histfiles = @(Get-HistFile -HistFilePath $script:HistFilePath)
            Invoke-Pause
            if($histfiles.Length -gt 0){
                # DEFINITION: If enabled: Check for duplicates against history-files:
                [array]$inputfiles = @(Start-DupliCheckHist -InFile $inputfiles -HistFiles $histfiles)
                if($inputfiles.Length -lt 1){
                    Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
                    Start-Sound 1
                    Start-Sleep -Seconds 2
                    if($script:GUI_CLI_Direct -eq "GUI"){
                        Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml"
                    }
                    break
                }
                Invoke-Pause
            }else{
                Write-ColorOut "No History-files found" -ForegroundColor Gray -Indentation 4
            }
        }

        # DEFINITION: If enabled: Check for duplicates against output-files:
        if($script:CheckOutputDupli -eq 1){
            [array]$inputfiles = (Start-DupliCheckOut -InFiles $inputfiles -OutPath $script:OutputPath)
            if($inputfiles.Length -lt 1){
                Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
                Start-Sound 1
                Start-Sleep -Seconds 2
                if($script:GUI_CLI_Direct -eq "GUI"){
                    Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml"
                }
                break
            }
            Invoke-Pause
        }

        # DEFINITION: Get free space:
        if((Start-SpaceCheck -InFiles $inputfiles -OutPath $script:OutputPath) -eq $false){
            Start-Sound 0
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml"
            }
            break
        }
        Invoke-Pause

        # DEFINITION: Get hashes of all remaining input-files:
        [array]$inputfiles = (Start-InputGetHash -InFiles $inputfiles)
        Invoke-Pause

        # DEFINITION: Copy stuff and check it:
        $j = 0
        while(1 -in $inputfiles.tocopy){
            if($j -gt 0){
                Write-ColorOut "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                if((Read-Host "`"1`" (w/o quotes) for `"yes`", other number for `"no`"") -ne 1){
                    Write-ColorOut "Aborting." -ForegroundColor Cyan
                    Start-Sleep -Seconds 2
                    if($script:GUI_CLI_Direct -eq "GUI"){
                        Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml"
                    }
                    break
                }
            }
            [array]$inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -OutPath $script:OutputPath)
            Invoke-Pause
            Start-FileCopy -InFiles $inputfiles -InPath $script:InputPath -OutPath $script:OutputPath
            Invoke-Pause
            if($script:VerifyCopies -eq 1){
                [array]$inputfiles = (Start-FileVerification -InFiles $inputfiles)
                Invoke-Pause
                $j++
            }else{
                foreach($instance in $inputfiles.tocopy){$instance = 0}
            }
        }
        # DEFINITION: Unmount input-drive:
        if($script:UnmountInputDrive -eq 1){
            # CREDIT: https://serverfault.com/a/580298
            # TODO: Find a solution that works with all drives.
            $driveEject = New-Object -comObject Shell.Application
            try{
                $driveEject.Namespace(17).ParseName($(Split-Path -Qualifier -Path $script:InputPath)).InvokeVerb("Eject")
                Write-ColorOut "Drive $(Split-Path -Qualifier -Path $script:InputPath) successfully ejected!" -ForegroundColor DarkCyan -BackgroundColor Gray
            }
            catch{
                Write-ColorOut "Couldn't eject drive $(Split-Path -Qualifier -Path $script:InputPath)." -ForegroundColor Magenta
            }
        }
        if($script:WriteHistFile -ne "no"){
            Set-HistFile -InFiles $inputfiles -HistFilePath $script:HistFilePath
            Invoke-Pause
        }
        if($script:MirrorEnable -eq 1){
            # DEFINITION: Get free space:
            if((Start-SpaceCheck -InFiles $inputfiles -OutPath $script:MirrorPath) -eq $false){
                Start-Sound 0
                Start-Sleep -Seconds 2
                if($script:GUI_CLI_Direct -eq "GUI"){
                    Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml"
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

            if($script:ZipMirror -eq 1){
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
                    [array]$inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -OutPath $script:MirrorPath)
                    Invoke-Pause
                    Start-FileCopy -InFiles $inputfiles -InPath $script:OutputPath -OutPath $script:MirrorPath
                    Invoke-Pause
                    if($script:VerifyCopies -eq 1){
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
    if($script:VerifyCopies -eq 1){
        Write-ColorOut "Verified:`t$($script:resultvalues.verified)`tfiles." -ForegroundColor Green -Indentation 4
        Write-ColorOut "Unverified:`t$($script:resultvalues.unverified)`tfiles." -ForegroundColor DarkRed -Indentation 4
    }
    Write-ColorOut "                                                                               A" -BackgroundColor DarkGray -ForegroundColor DarkGray
    Write-ColorOut "                                                                               A`r`n" -BackgroundColor Gray -ForegroundColor Gray

    if($script:resultvalues.unverified -eq 0){
        Start-Sound 1
    }else{
        Start-Sound 0
    }
    
    if($script:PreventStandby -eq 1 -and $script:preventstandbyid -ne 999999999){
        Stop-Process -Id $script:preventstandbyid
    }
    if($script:GUI_CLI_Direct -eq "GUI"){
        Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml"
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
            CREDIT:
                code of this section (except from small modifications) by
                https://foxdeploy.com/series/learning-gui-toolmaking-series/
    #> 
    param(
        [Parameter(Mandatory=$true)]
        [string]$GUIPath
    )

    if((Test-Path -LiteralPath $GUIPath -PathType Leaf)){
        $inputXML = Get-Content -LiteralPath $GUIPath -Encoding UTF8
    }else{
        Write-ColorOut "Could not find $GUIPath - GUI can therefore not start." -ForegroundColor Red
        Pause
        Exit
    }

    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    [xml]$xaml = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:Name",'Name'  -replace '^<Win.*', '<Window'
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    try{
        $script:Form = [Windows.Markup.XamlReader]::Load($reader)
    }
    catch{
        Write-ColorOut "Unable to load Windows.Markup.XamlReader. Usually this means that you haven't installed .NET Framework. Please download and install the latest .NET Framework Web-Installer for your OS: " -ForegroundColor Red
        Write-ColorOut "https://duckduckgo.com/?q=net+framework+web+installer&t=h_&ia=web"
        Write-ColorOut "Alternatively, start this script with '-GUI_CLI_Direct CLI' (w/o single-quotes) to run it via CLI (find other parameters via '-ShowParams 1' or '-Get-Help media_copytool.ps1 -detailed'." -ForegroundColor Yellow
        Pause
        Exit
    }
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        Set-Variable -Name "WPF$($_.Name)" -Value $script:Form.FindName($_.Name) -Scope Script
    }

    if($script:getWPF -ne 0){
        Write-ColorOut "Found the following interactable elements:`r`n" -ForegroundColor Cyan
        Get-Variable WPF*
        Pause
        Exit
    }

    # Fill the TextBoxes and buttons with user parameters:
    if((Test-Path -LiteralPath $script:JSONParamPath -PathType Leaf) -eq $true){
        try{
            $jsonparams = Get-Content -Path $script:JSONParamPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if($jsonparams.ParamPresetName -is [array]){
                $jsonparams.ParamPresetName | ForEach-Object {
                    $script:WPFcomboBoxLoadPreset.AddChild($_)
                }
                for($i=0; $i -lt $jsonparams.ParamPresetName.length; $i++){
                    if($jsonparams.ParamPresetName[$i] -eq $script:LoadParamPresetName){
                        $script:WPFcomboBoxLoadPreset.SelectedIndex = $i
                    }
                }
            }else{
                $script:WPFcomboBoxLoadPreset.AddChild($jsonparams.ParamPresetName)
                $script:WPFcomboBoxLoadPreset.SelectedIndex = 0
            }
        }catch{
            Write-ColorOut "Getting preset-names from $script:JSONParamPath failed - aborting!" -ForegroundColor Magenta -Indentation 4
        }
    }else{
        Write-ColorOut "Getting preset-names from $script:JSONParamPath failed - aborting!" -ForegroundColor  Magenta -Indentation 4
    }
    $script:WPFtextBoxSavePreset.Text = $script:SaveParamPresetName
    $script:WPFtextBoxInput.Text = $script:InputPath
    $script:WPFtextBoxOutput.Text = $script:OutputPath
    $script:WPFcheckBoxMirror.IsChecked = $script:MirrorEnable
    $script:WPFtextBoxMirror.Text = $script:MirrorPath
    $script:WPFtextBoxHistFile.Text = $script:HistFilePath
    $script:WPFcheckBoxCan.IsChecked = $(if("Can" -in $script:PresetFormats){$true}else{$false})
    $script:WPFcheckBoxNik.IsChecked = $(if("Nik" -in $script:PresetFormats){$true}else{$false})
    $script:WPFcheckBoxSon.IsChecked = $(if("Son" -in $script:PresetFormats){$true}else{$false})
    $script:WPFcheckBoxJpg.IsChecked = $(if("Jpg" -in $script:PresetFormats -or "Jpeg" -in $script:PresetFormats){$true}else{$false})
    $script:WPFcheckBoxInter.IsChecked = $(if("Inter" -in $script:PresetFormats){$true}else{$false})
    $script:WPFcheckBoxMov.IsChecked = $(if("Mov" -in $script:PresetFormats){$true}else{$false})
    $script:WPFcheckBoxAud.IsChecked = $(if("Aud" -in $script:PresetFormats){$true}else{$false})
    $script:WPFcheckBoxCustom.IsChecked = $script:CustomFormatsEnable
    $script:WPFtextBoxCustom.Text = $script:CustomFormats -join ","
    $script:WPFcomboBoxOutSubStyle.SelectedIndex = $(
        if("none" -eq $script:OutputSubfolderStyle){0}
        elseif("unchanged" -eq $script:OutputSubfolderStyle){1}
        elseif("yyyy-mm-dd" -eq $script:OutputSubfolderStyle){2}
        elseif("yyyy_mm_dd" -eq $script:OutputSubfolderStyle){3}
        elseif("yyyy.mm.dd" -eq $script:OutputSubfolderStyle){4}
        elseif("yyyymmdd" -eq $script:OutputSubfolderStyle){5}
        elseif("yy-mm-dd" -eq $script:OutputSubfolderStyle){6}
        elseif("yy_mm_dd" -eq $script:OutputSubfolderStyle){7}
        elseif("yy.mm.dd" -eq $script:OutputSubfolderStyle){8}
        elseif("yymmdd" -eq $script:OutputSubfolderStyle){9}
    )
    $script:WPFcomboBoxOutFileStyle.SelectedIndex = $(
        if("Unchanged" -eq $script:OutputFileStyle){0}
        elseif("yyyy-MM-dd_HH-mm-ss" -eq $script:OutputFileStyle){1}
        elseif("yyyyMMdd_HHmmss" -eq $script:OutputFileStyle){2}
        elseif("yyyyMMddHHmmss" -eq $script:OutputFileStyle){3}
        elseif("yy-MM-dd_HH-mm-ss" -eq $script:OutputFileStyle){4}
        elseif("yyMMdd_HHmmss" -eq $script:OutputFileStyle){5}
        elseif("yyMMddHHmmss" -eq $script:OutputFileStyle){6}
        elseif("HH-mm-ss" -eq $script:OutputFileStyle){7}
        elseif("HH_mm_ss" -eq $script:OutputFileStyle){8}
        elseif("HHmmss" -eq $script:OutputFileStyle){9}
    )
    $script:WPFcheckBoxUseHistFile.IsChecked = $script:UseHistFile
    $script:WPFcomboBoxWriteHistFile.SelectedIndex = $(
        if("yes" -eq $script:OutputSubfolderStyle){0}
        elseif("Overwrite" -eq $script:WriteHistFile){1}
        elseif("no" -eq $script:WriteHistFile){2}
    )
    $script:WPFcheckBoxCheckHashHist.IsChecked = $script:HistCompareHashes
    $script:WPFcheckBoxInSubSearch.IsChecked = $script:InputSubfolderSearch
    $script:WPFcheckBoxOutputDupli.IsChecked = $script:CheckOutputDupli
    $script:WPFcheckBoxVerifyCopies.IsChecked = $script:VerifyCopies
    $script:WPFcheckBoxOverwriteExistingFiles.IsChecked = $script:OverwriteExistingFiles
    $script:WPFcheckBoxAvoidIdenticalFiles.IsChecked = $script:AvoidIdenticalFiles
    $script:WPFcheckBoxZipMirror.IsChecked = $script:ZipMirror
    $script:WPFcheckBoxUnmountInputDrive.IsChecked = $script:UnmountInputDrive
    $script:WPFcheckBoxPreventStandby.IsChecked = $script:PreventStandby
    $script:WPFcheckBoxRememberIn.IsChecked = $script:RememberInPath
    $script:WPFcheckBoxRememberOut.IsChecked = $script:RememberOutPath
    $script:WPFcheckBoxRememberMirror.IsChecked = $script:RememberMirrorPath
    $script:WPFcheckBoxRememberSettings.IsChecked = $script:RememberSettings

    # DEFINITION: Load-Preset-Button
    $script:WPFbuttonLoadPreset.Add_Click({
        if($jsonparams.ParamPresetName -is [array]){
            for($i=0; $i -lt $jsonparams.ParamPresetName.Length; $i++){
                if($i -eq $script:WPFcomboBoxLoadPreset.SelectedIndex){
                    [string]$script:LoadParamPresetName = $jsonparams.ParamPresetName[$i]
                }
            }
        }else{
            [string]$script:LoadParamPresetName = $jsonparams.ParamPresetName
        }
        $script:Form.Close()
        Get-Parameters -JSONPath $script:JSONParamPath -Renew 1
        Start-Sleep -Milliseconds 2
        Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml"
    })
    # DEFINITION: InPath-Button
    $script:WPFbuttonSearchIn.Add_Click({
        Get-Folder "input"
    })
    # DEFINITION: OutPath-Button
    $script:WPFbuttonSearchOut.Add_Click({
        Get-Folder "output"
    })
    # DEFINITION: MirrorPath-Button
    $script:WPFbuttonSearchMirror.Add_Click({
        Get-Folder "mirror"
    })
    $script:WPFbuttonSearchHistFile.Add_Click({
        Get-Folder "histfile"
    })
    # DEFINITION: Start-Button
    $script:WPFbuttonStart.Add_Click({
        $script:Form.Close()
        Start-Everything
    })
    # DEFINITION: About-Button
    $script:WPFbuttonAbout.Add_Click({
        Start-Process powershell -ArgumentList "Get-Help $($PSCommandPath) -detailed" -NoNewWindow -Wait
    })
    # DEFINITION: Close-Button
    $script:WPFbuttonClose.Add_Click({
        $script:Form.Close()
        Invoke-Close
    })

    # DEFINITION: Start GUI
    $script:Form.ShowDialog() | Out-Null
}

# DEFINITION: Banner:
    Write-ColorOut "`r`n                            flolilo's Media-Copytool                            " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "                           v0.8.7 (Beta) - 2018-02-17           " -ForegroundColor DarkMagenta -BackgroundColor DarkGray -NoNewLine
    Write-ColorOut "(PID = $("{0:D8}" -f $pid))`r`n" -ForegroundColor Gray -BackgroundColor DarkGray

# DEFINITION: Start-up:
    if($GUI_CLI_Direct -eq "GUI"){
        Get-Parameters -JSONPath $JSONParamPath -Renew 0
        Start-GUI -GUIPath "$($PSScriptRoot)/mc_GUI.xaml"
    }elseif($GUI_CLI_Direct -eq "Direct"){
        Get-Parameters -JSONPath $JSONParamPath -Renew 0
        Start-Everything
    }elseif($GUI_CLI_Direct -eq "CLI"){
        Start-Everything
    }else{
        Write-ColorOut "Please choose a valid -GUI_CLI_Direct value (`"GUI`", `"CLI`", or `"Direct`")." -ForegroundColor Red
        Pause
        Exit
    }
