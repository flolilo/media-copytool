#requires -version 3

<#
    .SYNOPSIS
        Copy (and verify) user-defined filetypes from A to B (and optionally C).

    .DESCRIPTION
        Uses Windows' Robocopy and Xcopy for file-copy, then uses PowerShell's Get-FileHash (SHA1) for verifying that files were copied without errors.
        Now supports multithreading via Boe Prox's PoshRSJob-cmdlet (https://github.com/proxb/PoshRSJob)

    .NOTES
        Version:        0.6.8 (Beta)
        Author:         flolilo
        Creation Date:  31.8.2017
        Legal stuff: This program is free software. It comes without any warranty, to the extent permitted by
        applicable law. Most of the script was written by myself (or heavily modified by me when searching for solutions
        on the WWW). However, some parts are copies or modifications of very genuine code - see
        the "CREDIT:"-tags to find them.

    .PARAMETER showparams
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it shows the pre-set parameters, so you can see what would happen if you e.g. try 'media_copytool.ps1 -GUI_CLI_Direct "direct"'
    .PARAMETER GUI_CLI_Direct
        Sets the mode in which the script will guide the user.
        Valid options:
            "GUI" - Graphical User Interface (default)
            "CLI" - interactive console
            "direct" - instant execution with given parameters.
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
            "Can" - *.CR2
            "Nik" - *.NRW + *.NEF
            "Son" - *.ARW
            "Jpg" - *.JPG + *.JPEG
            "Mov" - *.MP4 + *.MOV
            "Aud" - *.WAV + *.MP3 + *.M4A
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
        TODO: To be implemented.
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
    .PARAMETER InputSubfolderSearch
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it enables file-search in subfolders of the input-path.
    .PARAMETER DupliCompareHashes
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it additionally checks for duplicates in the history-file via hash-calculation of all input-files (slow!)
    .PARAMETER CheckOutputDupli
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it checks for already copied files in the output-path (and its subfolders).
    .PARAMETER VerifyCopies
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, copied files will be checked for their integrity via SHA1-hashes. Disabling will increase speed, but there is no absolute guarantee that your files are copied correctly.
    .PARAMETER 7zipMirror
        TODO: To be implemented.
        Valid range: 0 (deactivate), 1 (activate)
        Only enabled if -EnableMirror is enabled, too. Creates a 7z-archive for archiving.
    .PARAMETER UnmountInputDrive
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, safely removes the input-drive after finishing copying & verifying. Only use with external drives!
    .PARAMETER PreventStandby
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, automatic standby or shutdown is prevented as long as media-copytool is running.
    .PARAMETER ThreadCount
        Thread-count for RSJobs.
        You can experiment around with this: too high thread counts tend to be much slower than relatively low ones.
    .PARAMETER RememberInPath
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it remembers the value of -InputPath for future script-executions.
    .PARAMETER RememberOutPath
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it remembers the value of -OutputPath for future script-executions.
    .PARAMETER RememberMirrorPath
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it remembers the value of -MirrorPath for future script-executions.
    .PARAMETER RememberSettings
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it remembers all parameters (excl. '-Remember*', '-showparams', and '-*Path') for future script-executions.
    .PARAMETER debug
        Gives more verbose so one can see what is happening (and where it goes wrong).
        Valid options:
            0 - no debug (default)
            1 - only stop on end
            2 - pause after every function
            3 - additional speedtest (ATM not implemented)

    .INPUTS
        "media_copytool_filehistory.json" if -UseHistFile is 1
        "media_copytool_GUI.xaml" if -GUI_CLI_direct "GUI"
        File(s) must be located in the script's directory and must not be renamed.

    .OUTPUTS
        "media_copytool_filehistory.json" if -WriteHistFile is "Yes" or "Overwrite".
        File(s) will be saved into the script's directory.
    
    .EXAMPLE
        See the preset/saved parameters of this script:
        media_copytool.ps1 -showparams 1
    .EXAMPLE
        Start Media-Copytool with the Graphical user interface:
        media_copytool.ps1 -GUI_CLI_Direct "GUI"
    .EXAMPLE
        Copy Canon's Raw-Files, Movies, JPEGs from G:\ to D:\Backup and prevent the computer from ging to standby:
        media_copytool.ps1 -PresetFormats "Can","Mov","Jpg" .InputPath "G:\" -OutputPath "D:\Backup" -PreventStandby 1 
#>
param(
    [int]$showparams=0,
    [string]$GUI_CLI_Direct="GUI",
    [string]$InputPath="G:\",
    [string]$OutputPath="D:\",
    [int]$MirrorEnable=0,
    [string]$MirrorPath="E:\",
    [array]$PresetFormats=("Can","Jpg","Mov"),
    [int]$CustomFormatsEnable=0,
    [array]$CustomFormats=("*"),
    [string]$OutputSubfolderStyle="yyyy-MM-dd",
    # TODO: [string]$OutputFileStyle="unchanged",
    [int]$UseHistFile=1,
    [string]$WriteHistFile="yes",
    [int]$InputSubfolderSearch=1,
    [int]$DupliCompareHashes=0,
    [int]$CheckOutputDupli=0,
    [int]$VerifyCopies=1,
    # TODO: [int]$7zipMirror=0,
    [int]$UnmountInputDrive=1,
    [int]$PreventStandby=1,
    [int]$ThreadCount=2,
    [int]$RememberInPath=0,
    [int]$RememberOutPath=0,
    [int]$RememberMirrorPath=0,
    [int]$RememberSettings=0,
    [int]$debug=0
)
# First line of "param" (for remembering/restoring parameters):
[int]$paramline = 158

#DEFINITION: Hopefully avoiding errors by wrong encoding now:
$OutputEncoding = New-Object -typename System.Text.UTF8Encoding

# DEFINITION: Making Write-Host much, much faster:
Function Write-ColorOut(){
    <#
        .SYNOPSIS
            A faster version of Write-Host
        
        .DESCRIPTION
            Using the [Console]-commands to make everything faster.

        .NOTES
            Date: 2018-08-22
        
        .PARAMETER Object
            String to write out
        
        .PARAMETER ForegroundColor
            Color of characters. If not specified, uses color that was set before calling. Valid: White (PS-Default), Red, Yellow, Cyan, Green, Gray, Magenta, Blue, Black, DarkRed, DarkYellow, DarkCyan, DarkGreen, DarkGray, DarkMagenta, DarkBlue
        
        .PARAMETER BackgroundColor
            Color of background. If not specified, uses color that was set before calling. Valid: DarkMagenta (PS-Default), White, Red, Yellow, Cyan, Green, Gray, Magenta, Blue, Black, DarkRed, DarkYellow, DarkCyan, DarkGreen, DarkGray, DarkBlue
        
        .PARAMETER NoNewLine
            When enabled, no line-break will be created.
        
        .EXAMPLE
            Write-ColorOut "Hello World!" -ForegroundColor Green -NoNewLine
    #>
    param(
        [string]$Object,
        [ValidateSet("DarkBlue","DarkGreen","DarkCyan","DarkRed","Blue","Green","Cyan","Red","Magenta","Yellow","Black","Darkgray","Gray","DarkYellow","White","DarkMagenta")][string]$ForegroundColor=[Console]::ForegroundColor,
        [ValidateSet("DarkBlue","DarkGreen","DarkCyan","DarkRed","Blue","Green","Cyan","Red","Magenta","Yellow","Black","Darkgray","Gray","DarkYellow","White","DarkMagenta")][string]$BackgroundColor=[Console]::BackgroundColor,
        [switch]$NoNewLine=$false
    )
    $old_fg_color = [Console]::ForegroundColor
    $old_bg_color = [Console]::BackgroundColor
    
    if($ForeGroundColor -ne $old_fg_color){[Console]::ForegroundColor = $ForeGroundColor}
    if($BackgroundColor -ne $old_bg_color){[Console]::BackgroundColor = $BackgroundColor}

    if($NoNewLine -eq $false){
        [Console]::WriteLine($Object)
    }else{
        [Console]::Write($Object)
    }
    
    if($ForeGroundColor -ne $old_fg_color){[Console]::ForegroundColor = $old_fg_color}
    if($BackgroundColor -ne $old_bg_color){[Console]::BackgroundColor = $old_bg_color}
}

# Checking if PoshRSJob is installed:
if (-not (Get-Module -ListAvailable -Name PoshRSJob)){
    Write-ColorOut "Module RSJob (https://github.com/proxb/PoshRSJob) is required, but it seemingly isn't installed - please start PowerShell as administrator and run`t" -ForegroundColor Red
    Write-ColorOut "Install-Module -Name PoshRSJob " -ForegroundColor DarkYellow
    Write-ColorOut "or use the fork of media-copytool without RSJob." -ForegroundColor Red
    Pause
    Exit
}

# Get all error-outputs in English:
[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'

# CREDIT: Set default ErrorAction to Stop: https://stackoverflow.com/a/21260623/8013879
if($debug -eq 0){
    $PSDefaultParameterValues = @{}
    $PSDefaultParameterValues += @{'*:ErrorAction' = 'Stop'}
    $ErrorActionPreference = 'Stop'
}

if($showparams -ne 0){
    Write-ColorOut "Flo's Media-Copytool Parameters:`r`n" -ForegroundColor Green
    Write-ColorOut "-GUI_CLI_Direct`t`t=`t$GUI_CLI_Direct" -ForegroundColor Cyan
    Write-ColorOut "-InputPath`t`t=`t$InputPath" -ForegroundColor Cyan
    Write-ColorOut "-OutputPath`t`t=`t$OutputPath" -ForegroundColor Cyan
    Write-ColorOut "-MirrorEnable`t`t=`t$MirrorEnable" -ForegroundColor Cyan
    Write-ColorOut "-MirrorPath`t`t=`t$MirrorPath" -ForegroundColor Cyan
    Write-ColorOut "-PresetFormats`t`t=`t$PresetFormats" -ForegroundColor Cyan
    Write-ColorOut "-CustomFormatsEnable`t=`t$CustomFormatsEnable" -ForegroundColor Cyan
    Write-ColorOut "-CustomFormats`t`t=`t$CustomFormats" -ForegroundColor Cyan
    Write-ColorOut "-OutputSubfolderStyle`t=`t$OutputSubfolderStyle" -ForegroundColor Cyan
    # TODO: Write-ColorOut "-OutputFileStyle`t=`t$OutputFileStyle" -ForegroundColor Cyan
    Write-ColorOut "-UseHistFile`t`t=`t$UseHistFile" -ForegroundColor Cyan
    Write-ColorOut "-WriteHistFile`t`t=`t$WriteHistFile" -ForegroundColor Cyan
    Write-ColorOut "-InputSubfolderSearch`t=`t$InputSubfolderSearch" -ForegroundColor Cyan
    Write-ColorOut "-CheckOutputDupli`t=`t$CheckOutputDupli" -ForegroundColor Cyan
    Write-ColorOut "-VerifyCopies`t=`t$VerifyCopies" -ForegroundColor Cyan
    # TODO: Write-ColorOut "-7zipMirror`t`t=`t$7zipMirror" -ForegroundColor Cyan
    Write-ColorOut "-UnmountInputDrive`t=`t$UnmountInputDrive" -ForegroundColor Cyan
    Write-ColorOut "-PreventStandby`t`t=`t$PreventStandby" -ForegroundColor Cyan
    Write-ColorOut "-ThreadCount`t`t=`t$ThreadCount`r`n" -ForegroundColor Cyan
    Pause
    Exit
}

# If you want to see the variables (buttons, checkboxes, ...) the GUI has to offer, set this to 1:
[int]$getWPF = 0

# ==================================================================================================
# ==============================================================================
#   Defining Functions:
# ==============================================================================
# ==================================================================================================

# DEFINITION: "Select"-Window for buttons to choose a path.
Function Get-Folder($InOutMirror){
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")
    $folderdialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderdialog.rootfolder = "MyComputer"
    if($folderdialog.ShowDialog() -eq "OK"){
        if($InOutMirror -eq "input"){$script:WPFtextBoxInput.Text = $folderdialog.SelectedPath}
        if($InOutMirror -eq "output"){$script:WPFtextBoxOutput.Text = $folderdialog.SelectedPath}
        if($InOutMirror -eq "mirror"){$script:WPFtextBoxMirror.Text = $folderdialog.SelectedPath}
    }
}

# DEFINITION: Get values from GUI, then check the main input- and outputfolder:
Function Get-UserValues(){
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  -" -NoNewLine
    Write-ColorOut "-  Getting user-values..." -ForeGroundColor Cyan
    
    # get values, test paths:
    if($script:GUI_CLI_Direct -eq "GUI" -or $script:GUI_CLI_Direct -eq "CLI" -or $script:GUI_CLI_Direct -eq "direct"){
        if($script:GUI_CLI_Direct -eq "CLI"){
            # $InputPath
            while($true){
                [string]$script:InputPath = Read-Host "Please specify input-path"
                if($script:InputPath.Length -gt 1 -and (Test-Path -LiteralPath $script:InputPath -PathType Container) -eq $true){
                    break
                }else{
                    Write-ColorOut "Invalid selection!" -ForeGroundColor Magenta
                    continue
                }
            }
            # $OutputPath
            while($true){
                [string]$script:OutputPath = Read-Host "Please specify output-path"
                if($script:OutputPath -eq $script:InputPath){
                    Write-ColorOut "`r`nInput-path is the same as output-path.`r`n" -ForegroundColor Magenta
                    continue
                }else{
                    if($script:OutputPath.Length -gt 1 -and (Test-Path -LiteralPath $script:OutputPath -PathType Container) -eq $true){
                        break
                    }elseif((Split-Path -Parent -Path $script:OutputPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $script:OutputPath) -PathType Container) -eq $true){
                        [int]$request = Read-Host "Output-path not found, but it's pointing to a valid drive letter. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                        if($request -eq 1){
                            New-Item -ItemType Directory -Path $script:OutputPath | Out-Null
                            break
                        }elseif($request -eq 0){
                            Write-ColorOut "`r`nOutput-path not found.`r`n" -ForegroundColor Magenta
                            continue
                        }
                    }else{
                        Write-ColorOut "Invalid selection!" -ForegroundColor Magenta
                        continue
                    }
                }
            }
            # $MirrorEnable
            while($true){
                [int]$script:MirrorEnable = Read-Host "Copy files to an additional folder? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:MirrorEnable -eq 1 -or $script:MirrorEnable -eq 0){
                    break
                }else{
                    Write-ColorOut "Invalid selection!" -ForegroundColor Magenta
                    continue
                }
            }
            # $MirrorPath
            if($script:MirrorEnable -eq 1){
                while($true){
                    [string]$script:MirrorPath = Read-Host "Please specify additional output-path"
                    if($script:MirrorPath -eq $script:OutputPath -or $script:MirrorPath -eq $script:InputPath){
                        Write-ColorOut "`r`nAdditional output-path is the same as input- or output-path.`r`n" -ForegroundColor Red
                        continue
                    }
                    if($script:MirrorPath -gt 1 -and (Test-Path -LiteralPath $script:MirrorPath -PathType Container) -eq $true){
                        break
                    }elseif((Split-Path -Parent -Path $script:MirrorPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $script:MirrorPath) -PathType Container) -eq $true){
                        [int]$request = Read-Host "Additional output-path not found, but it's pointing to a valid drive letter. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                        if($request -eq 1){
                            New-Item -ItemType Directory -Path $script:MirrorPath | Out-Null
                            break
                        }elseif($request -eq 0){
                            Write-ColorOut "`r`nAdditional output-path not found.`r`n" -ForegroundColor Magenta
                            continue
                        }
                    }else{
                        Write-ColorOut "Invalid selection!" -ForegroundColor Magenta
                        continue
                    }
                }
            }
            # $PresetFormats
            while($true){
                [array]$inter=@("Can","Nik","Son","Jpeg","Jpg","Mov","Aud")
                $separator = ","
                $option = [System.StringSplitOptions]::RemoveEmptyEntries
                [array]$script:PresetFormats = (Read-Host "Which preset file-formats would you like to copy? Options: `"Can`",`"Nik`",`"Son`",`"Jpg`",`"Mov`",`"Aud`", or leave empty for none. For multiple selection, separate with commata.").Split($separator,$option)
                if($script:PresetFormats.Length -eq 0 -or $script:PresetFormats -in $inter){
                    break
                }else{
                    Write-ColorOut "Invalid selection!" -ForegroundColor Magenta
                    continue
                }
            }
            # $CustomFormatsEnable - Number
            while($true){
                [int]$script:CustomFormatsEnable = Read-Host "How many custom file-formats? Range: From `"0`" (w/o quotes) for `"none`" to as many as you like."
                if($script:CustomFormatsEnable -in (0..999)){
                    break
                }else{
                    Write-ColorOut "Please choose a positive number!" -ForegroundColor Magenta
                    continue
                }
            }
            # $CustomFormats
            [array]$script:CustomFormats = @()
            if($script:CustomFormatsEnable -ne 0){
                for($i = 1; $i -le $script:CustomFormatsEnable; $i++){
                    while($true){
                        [string]$inter = Read-Host "Select custom format no. $i. `"*`" (w/o quotes) means `"all files`", `"*.ext`" means `"all files with extension .ext`", `"file.*`" means `"all files named file`"."
                        if($inter.Length -ne 0){
                            $script:CustomFormats += $inter
                            break
                        }else{
                            Write-ColorOut "Invalid input!" -ForegroundColor Magenta
                            continue
                        }
                    }
                }
            }
            # $OutputSubfolderStyle
            while($true){
                [array]$inter = @("none","unchanged","yyyy-MM-dd","yyyy_MM_dd","yyyy.MM.dd","yyyyMMdd","yy-MM-dd","yy_MM_dd","yy.MM.dd","yyMMdd")
                [string]$script:OutputSubfolderStyle = Read-Host "Which subfolder-style should be used in the output-path? Options: `"none`",`"unchanged`",`"yyyy-MM-dd`",`"yyyy_MM_dd`",`"yyyy.MM.dd`",`"yyyyMMdd`",`"yy-MM-dd`",`"yy_MM_dd`",`"yy.MM.dd`",`"yyMMdd`" (all w/o quotes)."
                if($script:OutputSubfolderStyle -in $inter){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            <# TODO: $OutputFileStyle
            while($true){
                [array]$inter = @("unchanged","yyyy-MM-dd_HH-mm-ss","yyyyMMdd_HHmmss","yyyyMMddHHmmss","yy-MM-dd_HH-mm-ss","yyMMdd_HHmmss","yyMMddHHmmss","HH-mm-ss","HH_mm_ss","HHmmss")
                [string]$script:OutputFileStyle = Read-Host "Which subfolder-style should be used in the output-path? Options: `"unchanged`",`"yyyy-MM-dd_HH-mm-ss`",`"yyyyMMdd_HHmmss`",`"yyyyMMddHHmmss`",`"yy-MM-dd_HH-mmss`",`"yyMMdd_HHmmss`",`"yyMMddHHmmss`",`"HH-mm-ss`",`"HH_mm_ss`",`"HHmmss`" (all w/o quotes). Be aware that this time, you must match the case!"
                if($script:OutputFileStyle -cin $inter){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            } #>
            # $UseHistFile
            while($true){
                [int]$script:UseHistFile = Read-Host "Compare input-files with the history-file to prevent duplicates? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:UseHistFile -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $WriteHistFile
            while($true){
                [array]$inter = @("yes","no","overwrite")
                [string]$script:WriteHistFile = Read-Host "Write newly copied files to history-file? Options: `"yes`",`"no`",`"overwrite`". (all w/o quotes)"
                if($script:WriteHistFile -in $inter){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $InputSubfolderSearch
            while($true){
                [int]$script:InputSubfolderSearch = Read-Host "Check input-path's subfolders? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:InputSubfolderSearch -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $DupliCompareHashes
            while($true){
                [int]$script:DupliCompareHashes = Read-Host "Additionally compare all input-files via hashes (slow)? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:DupliCompareHashes -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $CheckOutputDupli
            while($true){
                [int]$script:CheckOutputDupli = Read-Host "Additionally check output-path for already copied files? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:CheckOutputDupli -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $VerifyCopies
            while($true){
                [int]$script:VerifyCopies = Read-Host "Enable verifying copied files afterwards for guaranteed successfully copied files? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:VerifyCopies -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            <# TODO: $7zipMirror
            if($script:MirrorEnable -eq 1){
                while($true){
                    [int]$script:7zipMirror = Read-Host "Copying files to additional output-path as 7zip-archive? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                    if($script:7zipMirror -in (0..1)){
                        break
                    }else{
                        Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                        continue
                    }
                }
            } #>
            # $UnmountInputDrive
            while($true){
                [int]$script:UnmountInputDrive = Read-Host "Removing input-drive after copying & verifying (before mirroring)? Only use it for external drives. `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:UnmountInputDrive -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $PreventStandby
            while($true){
                [int]$script:PreventStandby = Read-Host "Auto-prevent standby of computer while script is running? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:PreventStandby -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $ThreadCount
            while($true){
                [int]$script:ThreadCount = Read-Host "Number of threads for multithreaded operations. Suggestion: Number in between 2 and 4."
                if($script:ThreadCount -in (1..24)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $RememberInPath
            while($true){
                [int]$script:RememberInPath = Read-Host "Remember the input-path for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:RememberInPath -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $RememberOutPath
            while($true){
                [int]$script:RememberOutPath = Read-Host "Remember the output-path for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:RememberOutPath -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $RememberMirrorPath
            while($true){
                [int]$script:RememberMirrorPath = Read-Host "Remember the additional output-path for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:RememberMirrorPath -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            # $RememberSettings
            while($true){
                [int]$script:RememberSettings = Read-Host "Remember settings for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($script:RememberSettings -in (0..1)){
                    break
                }else{
                    Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                    continue
                }
            }
            return $true
        }elseif($script:GUI_CLI_Direct -eq "GUI"){
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
            # $PresetFormats
            [array]$script:PresetFormats = @()
            if($script:WPFcheckBoxCan.IsChecked -eq $true){$script:PresetFormats += "Can"}
            if($script:WPFcheckBoxNik.IsChecked -eq $true){$script:PresetFormats += "Nik"}
            if($script:WPFcheckBoxSon.IsChecked -eq $true){$script:PresetFormats += "Son"}
            if($script:WPFcheckBoxJpg.IsChecked -eq $true){$script:PresetFormats += "Jpg"}
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
            <# TODO: $OutputFileStyle
            $script:OutputFileStyle = $(
                if($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 0){"unchanged"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 1){"yyyy-MM-dd_HH-mm-ss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 2){"yyyyMMdd_HHmmss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 3){"yyyyMMddHHmmss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 4){"yy-MM-dd_HH-mmss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 5){"yyMMdd_HHmmss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 6){"yyMMddHHmmss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 7){"HH-mm-ss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 8){"HH_mm_ss"}
                elseif($script:WPFcomboBoxOutFileStyle.SelectedIndex -eq 9){"HHmmss"}
            ) #>
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
            # $InputSubfolderSearch
            $script:InputSubfolderSearch = $(
                if($script:WPFcheckBoxInSubSearch.IsChecked -eq $true){1}
                else{0}
            )
            # $DupliCompareHashes
            $script:DupliCompareHashes = $(
                if($script:WPFcheckBoxCheckInHash.IsChecked -eq $true){1}
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
            <# TODO: $7zipMirror
            $script:7zipMirror = $(
                if($script:WPFcheckBox7zipMirror.IsChecked -eq $true){1}
                else{0}
            ) #>
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
            # $ThreadCount
            $script:ThreadCount = $script:WPFtextBoxThreadCount.Text
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
                Write-ColorOut "Invalid choice of -MirrorEnable." -ForegroundColor Red
                return $false
            }
            # $PresetFormats
            [array]$inter=@("Can","Nik","Son","Jpeg","Jpg","Mov","Aud")
            if($script:PresetFormats.Length -gt 0 -and $script:PresetFormats -notin $inter){
                Write-ColorOut "Invalid choice of -PresetFormats." -ForegroundColor Red
                return $false
            }
            # $CustomFormatsEnable
            if($script:CustomFormatsEnable -notin (0..1)){
                Write-ColorOut "Invalid choice of -CustomFormatsEnable." -ForegroundColor Red
                return $false
            }
            # $OutputSubfolderStyle
            [array]$inter=@("none","unchanged","yyyy-mm-dd","yyyy_mm_dd","yyyy.mm.dd","yyyymmdd","yy-mm-dd","yy_mm_dd","yy.mm.dd","yymmdd")
            if($script:OutputSubfolderStyle -notin $inter -or $script:OutputSubfolderStyle.Length -gt $inter[1].Length){
                Write-ColorOut "Invalid choice of -OutputSubfolderStyle." -ForegroundColor Red
                return $false
            }
            <# TODO: $OutputFileStyle
            [array]$inter = @("unchanged","yyyy-MM-dd_HH-mmss","yyyyMMdd_HHmmss","yyyyMMddHHmmss","yy-MM-dd_HH-mmss","yyMMdd_HHmmss","yyMMddHHmmss","HH-mm-ss","HH_mm_ss","HHmmss")
            if($script:OutputFileStyle -cnotin $inter -or $script:OutputFileStyle.Length -gt $inter[1].Length){
                Write-ColorOut "Invalid choice of -OutputFileStyle." -ForegroundColor Red
                return $false
            } #>
            # $UseHistFile
            if($script:UseHistFile -notin (0..1)){
                Write-ColorOut "Invalid choice of -UseHistFile." -ForegroundColor Red
                return $false
            }
            # $WriteHistFile
            [array]$inter=@("yes","no","overwrite")
            if($script:WriteHistFile -notin $inter -or $script:WriteHistFile.Length -gt $inter[2].Length){
                Write-ColorOut "Invalid choice of -WriteHistFile." -ForegroundColor Red
                return $false
            }
            # InputSubfolderSearch
            if($script:InputSubfolderSearch -notin (0..1)){
                Write-ColorOut "Invalid choice of -InputSubfolderSearch." -ForegroundColor Red
                return $false
            }
            # $DupliCompareHashes
            if($script:DupliCompareHashes -notin (0..1)){
                Write-ColorOut "Invalid choice of -DupliCompareHashes." -ForegroundColor Red
                return $false
            }
            # $CheckOutputDupli
            if($script:CheckOutputDupli -notin (0..1)){
                Write-ColorOut "Invalid choice of -CheckOutputDupli." -ForegroundColor Red
                return $false
            }
            # $VerifyCopies
            if($script:VerifyCopies -notin (0..1)){
                Write-ColorOut "Invalid choice of -VerifyCopies." -ForegroundColor Red
                return $false
            }
            <# TODO: $7zipMirror
            if($script:7zipMirror -notin (0..1)){
                Write-ColorOut "Invalid choice of -7zipMirror." -ForegroundColor Red
                return $false
            } #>
            # $UnmountInputDrive
            if($script:UnmountInputDrive -notin (0..1)){
                Write-ColorOut "Invalid choice of -UnmountInputDrive." -ForegroundColor Red
                return $false
            }
            # $PreventStandby
            if($script:PreventStandby -notin (0..1)){
                Write-ColorOut "Invalid choice of -PreventStandby." -ForegroundColor Red
                return $false
            }
            # $ThreadCount
            if($script:ThreadCount -notin (0..999)){
                Write-ColorOut "Invalid choice of -ThreadCount." -ForegroundColor Red
                return $false
            }
            # $RememberInPath
            if($script:RememberInPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberInPath." -ForegroundColor Red
                return $false
            }
            # $RememberOutPath
            if($script:RememberOutPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberOutPath." -ForegroundColor Red
                return $false
            }
            # $RememberMirrorPath
            if($script:RememberMirrorPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberMirrorPath." -ForegroundColor Red
                return $false
            }
            # $RememberSettings
            if($script:RememberSettings -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberSettings." -ForegroundColor Red
                return $false
            }
        }

        # checking paths for GUI and direct:
        if($script:GUI_CLI_Direct -ne "CLI"){
            # $InputPath
            if($script:InputPath -lt 2 -or (Test-Path -LiteralPath $script:InputPath -PathType Container) -eq $false){
                Write-ColorOut "`r`nInput-path $script:InputPath could not be found.`r`n" -ForegroundColor Red
                return $false
            }
            # $OutputPath
            if($script:OutputPath -eq $script:InputPath){
                Write-ColorOut "`r`nOutput-path is the same as input-path.`r`n" -ForegroundColor Red
                return $false
            }
            if($script:OutputPath.Length -lt 2 -or (Test-Path -LiteralPath $script:OutputPath -PathType Container) -eq $false){
                if((Split-Path -Parent -Path $script:OutputPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Qualifier -Path $script:OutputPath) -PathType Container) -eq $true){
                    while($true){
                        [int]$request = Read-Host "Output-path not found, but it's pointing to a valid drive letter. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                        if($request -eq 1){
                            New-Item -ItemType Directory -Path $script:OutputPath | Out-Null
                            break
                        }elseif($request -eq 0){
                            Write-ColorOut"`r`nOutput-path not found.`r`n" -ForegroundColor Red
                            return $false
                            break
                        }else{continue}
                    }
                }else{
                    Write-ColorOut "`r`nOutput-path not found.`r`n" -ForegroundColor Red
                    return $false
                }
            }
            # $MirrorPath
            if($script:MirrorEnable -eq 1){
                if($script:MirrorPath -eq $script:InputPath -or $script:MirrorPath -eq $script:OutputPath){
                    Write-ColorOut "`r`nAdditional output-path is the same as input- or output-path.`r`n" -ForegroundColor Red
                    return $false
                }
                if($script:MirrorPath -lt 2 -or (Test-Path -LiteralPath $script:MirrorPath -PathType Container) -eq $false){
                    if((Split-Path -Parent -Path $script:MirrorPath).Length -gt 1 -and (Test-Path -Qualifier $(Split-Path -Parent -Path $script:MirrorPath) -PathType Container) -eq $true){
                        while($true){
                            [int]$request = Read-Host "Additional output-path not found, but it's pointing to a valid drive letter. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                            if($request -eq 1){
                                New-Item -ItemType Directory -Path $script:MirrorPath | Out-Null
                                break
                            }elseif($request -eq 0){
                                Write-ColorOut "`r`nAdditional output-path not found.`r`n" -ForegroundColor Red
                                return $false
                                break
                            }else{continue}
                        }
                    }else{
                        Write-ColorOut "`r`nAdditional output-path not found.`r`n" -ForegroundColor Red
                        return $false
                    }
                }
            }
        }

    }else{
        Write-ColorOut "Invalid choice of -GUI_CLI_Direct." -ForegroundColor Magenta
        return $false
    }

    # sum up formats:
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
        if((Read-Host "No file-format selected. Copy all files? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`"") -eq 1){
            [array]$script:allChosenFormats = "*"
        }else{
            Write-ColorOut "No file-format specified." -ForegroundColor Red
            return $false
        }
    }

    # build switches
    [switch]$script:input_recurse = $(
        if($script:InputSubfolderSearch -eq 1){$true}
        else{$false}
    )

    # get minutes (mm) to months (MM):
    $script:OutputSubfolderStyle = $script:OutputSubfolderStyle -Replace 'mm','MM'

    # check paths for trailing backslash:
    if($script:InputPath.replace($script:InputPath.Substring(0,$script:InputPath.Length-1),"") -eq "\" -and $script:InputPath.Length -gt 3){
        $script:InputPath = $script:InputPath.Substring(0,$script:InputPath.Length-1)
    }
    if($script:OutputPath.replace($script:OutputPath.Substring(0,$script:OutputPath.Length-1),"") -eq "\" -and $script:OutputPath.Length -gt 3){
        $script:OutputPath = $script:OutputPath.Substring(0,$script:OutputPath.Length-1)
    }
    if($script:MirrorPath.replace($script:MirrorPath.Substring(0,$script:MirrorPath.Length-1),"") -eq "\" -and $script:MirrorPath.Length -gt 3){
        $script:MirrorPath = $script:MirrorPath.Substring(0,$script:MirrorPath.Length-1)
    }

    if($script:debug -ne 0){
        Write-ColorOut "InputPath:`t`t$script:InputPath"
        Write-ColorOut "OutputPath:`t`t$script:OutputPath"
        Write-ColorOut "MirrorEnable:`t`t$script:MirrorEnable"
        Write-ColorOut "MirrorPath:`t`t$script:MirrorPath"
        Write-ColorOut "CustomFormatsEnable:`t$script:CustomFormatsEnable"
        Write-ColorOut "allChosenFormats:`t$script:allChosenFormats"
        Write-ColorOut "OutputSubfolderStyle:`t$script:OutputSubfolderStyle"
        # TODO: Write-ColorOut "OutputFileStyle:`t$script:OutputFileStyle"
        Write-ColorOut "UseHistFile:`t`t$script:UseHistFile"
        Write-ColorOut "WriteHistFile:`t`t$script:WriteHistFile"
        Write-ColorOut "InputSubfolderSearch:`t$script:InputSubfolderSearch"
        Write-ColorOut "DupliCompareHashes:`t$script:DupliCompareHashes"
        Write-ColorOut "CheckOutputDupli:`t$script:CheckOutputDupli"
        Write-ColorOut "VerifyCopies:`t`t$script:VerifyCopies"
        # TODO: Write-ColorOut "7zipMirror:`t`t$script:7zipMirror"
        Write-ColorOut "UnmountInputDrive:`t`t$script:UnmountInputDrive"
        Write-ColorOut "PreventStandby:`t`t$script:PreventStandby"
        Write-ColorOut "ThreadCount:`t`t$script:ThreadCount"
    }

    # if everything was sucessful, return true:
    return $true
}

# DEFINITION: If checked, remember values for future use:
Function Start-Remembering(){
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  -" -NoNewLine
    Write-ColorOut "-  Remembering settings..." -ForegroundColor Cyan

    $lines_old = [System.IO.File]::ReadAllLines($PSCommandPath)
    $lines_new = $lines_old
    
    # $InputPath
    if($script:RememberInPath -ne 0){
        Write-ColorOut "From:`t$($lines_new[$($script:paramline + 2)])" -ForegroundColor Gray
        $lines_new[$($script:paramline + 2)] = '    [string]$InputPath="' + "$script:InputPath" + '",'
        Write-ColorOut "To:`t$($lines_new[$($script:paramline + 2)])" -ForegroundColor Yellow
    }
    # $OutputPath
    if($script:RememberOutPath -ne 0){
        Write-ColorOut "From:`t$($lines_new[$($script:paramline + 3)])" -ForegroundColor Gray
        $lines_new[$($script:paramline + 3)] = '    [string]$OutputPath="' + "$script:OutputPath" + '",'
        Write-ColorOut "To:`t$($lines_new[$($script:paramline + 3)])" -ForegroundColor Yellow
    }
    # $MirrorPath
    if($script:RememberMirrorPath -ne 0){
        Write-ColorOut "From:`t$($lines_new[$($script:paramline + 5)])" -ForegroundColor Gray
        $lines_new[$($script:paramline + 5)] = '    [string]$MirrorPath="' + "$script:MirrorPath" + '",'
        Write-ColorOut "To:`t$($lines_new[$($script:paramline + 5)])" -ForegroundColor Yellow
    }

    # Remember settings
    if($script:RememberSettings -ne 0){
        Write-ColorOut "From:"
        for($i = $($script:paramline + 1); $i -le $($script:paramline + 20); $i++){
            if(-not ($i -eq $($script:paramline + 2) -or $i -eq $($script:paramline + 3) -or $i -eq $($script:paramline + 5))){
                Write-ColorOut $lines_new[$i] -ForegroundColor Gray
            }
        }

        # $GUI_CLI_Direct
        $lines_new[$($script:paramline + 1)] = '    [string]$GUI_CLI_Direct="' + "$script:GUI_CLI_Direct" + '",'
        # $MirrorEnable
        $lines_new[$($script:paramline + 4)] = '    [int]$MirrorEnable=' + "$script:MirrorEnable" + ','
        # $PresetFormats
        [string]$inter = '"' + ($script:PresetFormats -join '","') + '"'
        $lines_new[$($script:paramline + 6)] = '    [array]$PresetFormats=(' + "$inter" + '),'
        # $CustomFormatsEnable
        $lines_new[$($script:paramline + 7)] = '    [int]$CustomFormatsEnable=' + "$script:CustomFormatsEnable" + ','
        # $CustomFormats
        [string]$inter = '"' + ($script:CustomFormats -join '","') + '"'
        $lines_new[$($script:paramline + 8)] = '    [array]$CustomFormats=(' + "$inter" + '),'
        # $OutputSubfolderStyle
        $lines_new[$($script:paramline + 9)] = '    [string]$OutputSubfolderStyle="' + "$script:OutputSubfolderStyle" + '",'
        <# TODO: $OutputFileStyle
        $lines_new[$($script:paramline + 10)] = '    [string]$OutputFileStyle="' + "$script:OutputFileStyle" + '",' #>
        # $UseHistFile
        $lines_new[$($script:paramline + 11)] = '    [int]$UseHistFile=' + "$script:UseHistFile" + ','
        # $WriteHistFile
        $lines_new[$($script:paramline + 12)] = '    [string]$WriteHistFile="' + "$script:WriteHistFile" + '",'
        # $InputSubfolderSearch
        $lines_new[$($script:paramline + 13)] = '    [int]$InputSubfolderSearch=' + "$script:InputSubfolderSearch" + ','
        # $DupliCompareHashes
        $lines_new[$($script:paramline + 14)] = '    [int]$DupliCompareHashes=' + "$script:DupliCompareHashes" + ','
        # $CheckOutputDupli
        $lines_new[$($script:paramline + 15)] = '    [int]$CheckOutputDupli=' + "$script:CheckOutputDupli" + ','
        # $VerifyCopies
        $lines_new[$($script:paramline + 16)] = '    [int]$VerifyCopies=' + "$script:VerifyCopies" + ','
        <# TODO: $7zipMirror
        $lines_new[$($script:paramline + 17)] = '    [int]$7zipMirror=' + "$script:7zipMirror" + ',' #>
        # $UnmountInputDrive
        $lines_new[$($script:paramline + 18)] = '    [int]$UnmountInputDrive=' + "$script:UnmountInputDrive" + ','
        # $PreventStandby
        $lines_new[$($script:paramline + 19)] = '    [int]$PreventStandby=' + "$script:PreventStandby" + ','
        # $ThreadCount
        $lines_new[$($script:paramline + 20)] = '    [int]$ThreadCount=' + "$script:ThreadCount" + ','

        Write-ColorOut "To:"
        for($i = $($script:paramline + 1); $i -le $($script:paramline + 20); $i++){
            if(-not ($i -eq $($script:paramline + 2) -or $i -eq $($script:paramline + 3) -or $i -eq $($script:paramline + 5))){
                Write-ColorOut $lines_new[$i] -ForegroundColor Yellow
            }
        }
    }

    Invoke-Pause
    [System.IO.File]::WriteAllLines($PSCommandPath, $lines_new)
}

# DEFINITION: Get History-File
Function Get-HistFile(){
    param([string]$HistFilePath="$($PSScriptRoot)\media_copytool_filehistory.json")
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  -" -NoNewLine
    Write-ColorOut "-  Checking for history-file, importing values..." -ForegroundColor Cyan

    [array]$files_history = @()
    if(Test-Path -LiteralPath $HistFilePath -PathType Leaf){
        $JSONFile = Get-Content -LiteralPath $HistFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $JSONFile | Out-Null
        $files_history = $JSONFile | ForEach-Object {
            [PSCustomObject]@{
                name = $_.inname
                date = $_.date
                size = $_.size
                hash = $_.hash
            }
        }
        $files_history
        if($script:debug -ne 0){
            Write-ColorOut "Found values: $($files_history.Length)" -ForegroundColor Yellow
            Write-ColorOut "Name`tDate`tSize`tHash"
            for($i = 0; $i -lt $files_history.Length; $i++){
                Write-ColorOut "$($files_history[$i].name)`t$($files_history[$i].date)`t$($files_history[$i].size)`t$($files_history[$i].hash)" -ForegroundColor Gray
            }
        }
        if("null" -in $files_history -or $files_history.name.Length -ne $files_history.date.Length -or $files_history.name.Length -ne $files_history.size.Length -or $files_history.name.Length -ne $files_history.hash.Length -or $files_history.name.Length -eq 0){
            Write-ColorOut "Some values in the history-file $HistFilePath seem wrong - it's safest to delete the whole file." -ForegroundColor Magenta
            if((Read-Host "Is that okay? Type '1' (without quotes) to confirm or any other number to abort. Confirm by pressing Enter") -eq 1){
                $script:UseHistFile = 0
                $script:WriteHistFile = "Overwrite"
            }else{
                Write-ColorOut "`r`nAborting.`r`n" -ForegroundColor Magenta
                Invoke-Close
            }
        }
    }else{
        Write-ColorOut "History-File $HistFilePath could not be found. This means it's possible that duplicates get copied." -ForegroundColor Magenta
        if((Read-Host "Is that okay? Type '1' (without quotes) to confirm or any other number to abort. Confirm by pressing Enter") -eq 1){
            $script:UseHistFile = 0
            $script:WriteHistFile = "Overwrite"
        }else{
            Write-ColorOut "`r`nAborting.`r`n" -ForegroundColor Magenta
            Invoke-Close
        }
    }

    return $files_history
}

# DEFINITION: Searching for selected formats in Input-Path, getting Path, Name, Time, and calculating Hash:
Function Start-FileSearchAndCheck(){
    param(
        [string]$InPath,
        [string]$OutPath,
        [array]$HistFiles
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  -" -NoNewLine
    Write-ColorOut "-  Finding files & checking for duplicates." -ForegroundColor Cyan

    # pre-defining variables:
    $files_in = @()
    $script:files_duplicheck = @()
    $script:resultvalues = @{}

    # Search files and get some information about them:
    [int]$counter = 1
    [string]$inter = $(if($script:DupliCompareHashes -ne 0 -or $script:CheckOutputDupli -ne 0){"incl."}else{"excl."})

    for($i=0;$i -lt $script:allChosenFormats.Length; $i++){
       $files_in += Get-ChildItem -LiteralPath $InPath -Filter $script:allChosenFormats[$i] -Recurse:$script:input_recurse -File | ForEach-Object {
            if($sw.Elapsed.TotalMilliseconds -ge 500 -or $counter -eq 1){
                Write-Progress -Activity "Find files in $InPath ($inter additional hash-calc.)..." -PercentComplete -1 -Status "File #$counter - $($_.FullName.Replace("$InPath",'.'))"
                $sw.Reset()
                $sw.Start()
            }
            
            $counter++
            [PSCustomObject]@{
                fullpath = $_.FullName
                inpath = (Split-Path $_.FullName -Parent)
                inname = $_.Name
                basename = $_.BaseName
                extension = $_.Extension
                size = $_.Length
                date = $_.LastWriteTime.ToString("yyyy-MM-dd_HH-mm-ss")
                sub_date = $(if($script:OutputSubfolderStyle -eq "none"){""}elseif($script:OutputSubfolderStyle -eq "unchanged"){$($(Split-Path -Parent $_.FullName).Replace($script:InputPath,""))}else{"\$($_.LastWriteTime.ToString("$script:OutputSubfolderStyle"))"})
                outpath = "ZYX"
                outname = $_.Name
                outbasename = $_.BaseName
                hash = "ZYX"
                tocopy = 1
            }
        }
    }

    if($script:DupliCompareHashes -ne 0 -or $script:CheckOutputDupli -ne 0){
        $files_in | Start-RSJob -Name "GetHash" -throttle $script:ThreadCount -ScriptBlock {
            $_.hash = Get-FileHash -LiteralPath $_.fullpath -Algorithm SHA1 | Select-Object -ExpandProperty Hash
        } | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob -Name "GetHash" | Remove-RSJob
    }

    $sw.Reset()

    Write-ColorOut "`r`n`r`nTotal in-files:`t$($files_in.fullpath.Length)`r`n" -ForegroundColor Yellow
    $script:resultvalues.ingoing = $files_in.fullpath.Length
    Invoke-Pause

    # dupli-check via history-file:
    [array]$dupliindex_hist = @()
    if($script:UseHistFile -eq 1){
        # Comparing Files between History-File and Input-Folder via history-file:
        for($i = 0; $i -lt $files_in.fullpath.Length; $i++){
            if($sw.Elapsed.TotalMilliseconds -ge 500 -or $i -eq 0){
                Write-Progress -Activity "Comparing to already copied files (history-file).." -PercentComplete $($i / $files_in.fullpath.Length * 100) -Status "File # $($i + 1) / $($files_in.fullpath.Length) - $($files_in[$i].name)"
                $sw.Reset()
                $sw.Start()
            }
            
            $j = $HistFiles.name.Length
            while($true){
                # check resemblance between in_files and hist_files:
                if($files_in[$i].inname -eq $HistFiles[$j].name -and $files_in[$i].date -eq $HistFiles[$j].date -and $files_in[$i].size -eq $HistFiles[$j].size -and ($script:DupliCompareHashes -eq 0 -or ($script:DupliCompareHashes -eq 1 -and $files_in[$i].hash -eq $HistFiles[$j].Hash))){
                    Write-ColorOut "Existing: $($i + 1) - $($files_in[$i].inname.Replace("$InPath",'.'))" -ForegroundColor DarkGreen
                    $dupliindex_hist += $i
                    $files_in[$i].tocopy = 0
                    break
                }else{
                    if($j -le 0){
                        break
                    }
                    $j--
                    continue
                }
            }
        }
        $sw.Reset()
        if($script:debug -ne 0){
            Write-ColorOut "`r`n`r`nFiles to skip / process (after history-check):" -ForegroundColor Yellow
            for($i = 0; $i -lt $files_in.fullpath.Length; $i++){
                [string]$inter = ($($files_in.fullpath[$i]).Replace($InPath,'.'))
                if($i -notin $dupliindex_hist){
                    Write-ColorOut "Copy:`t$inter" -ForegroundColor Gray
                }else{
                    Write-ColorOut "Existing:`t$inter" -ForegroundColor DarkGreen
                }
            }
        }
    }else{
        Write-ColorOut "`r`nNo history-file -> no files to skip." -ForegroundColor Yellow
    }

    Write-ColorOut "`r`n`r`nTotal in-files:`t$($files_in.name.Length)" -ForegroundColor Gray
    Write-ColorOut "Files to skip:`t$($dupliindex_hist.Length)" -ForegroundColor DarkGreen
    Write-ColorOut "Files left after history-check:`t$($files_in.name.Length - $dupliindex_hist.Length)" -ForegroundColor Yellow
    $script:resultvalues.duplihist = $dupliindex_hist.Length
    Invoke-Pause

    # dupli-check via output-folder:
    [array]$dupliindex_out = @()
    if($script:CheckOutputDupli -ne 0){
        Write-ColorOut "`r`nAdditional comparison to already existing files in the output-path..." -ForegroundColor Yellow
        [int]$counter = 1
        for($i=0;$i -lt $script:allChosenFormats.Length; $i++){
            $script:files_duplicheck += Get-ChildItem -LiteralPath $OutPath -Filter $script:allChosenFormats[$i] -Recurse -File | ForEach-Object {
                if($sw.Elapsed.TotalMilliseconds -ge 500 -or $counter -eq 1){
                    Write-Progress -Activity "Find files in $OutPath..." -PercentComplete -1 -Status "File # $counter - $($_.FullName.Replace("$OutPath",'.'))"
                    $sw.Reset()
                    $sw.Start()
                }

                $counter++
                [PSCustomObject]@{
                    fullpath = $_.FullName
                    name = $_.Name
                    size = $_.Length
                    date = $_.LastWriteTime.ToString("yyyy-MM-dd_HH-mm-ss")
                    hash ="ZYX"
                }
            }
        }
        $sw.Reset()
        if($script:files_duplicheck.fullpath.Length -ne 0){
            for($i = 0; $i -lt $files_in.fullpath.Length; $i++){
                if($files_in[$i].tocopy -eq 1){
                    if($sw.Elapsed.TotalMilliseconds -ge 500 -or $i -eq 0){
                        Write-Progress -Activity "Comparing to files in out-path..." -PercentComplete $($i / $($files_in.name.Length - $dupliindex_hist.Length) * 100) -Status "File # $($i + 1) / $($files_in.fullpath.Length) - $($files_in[$i].name)"
                        $sw.Reset()
                        $sw.Start()
                    }

                    $j = 0
                    while($true){
                        # calculate hash only if date and size are the same:
                        if($($files_in[$i].date) -eq $($script:files_duplicheck[$j].date) -and $($files_in[$i].size) -eq $($script:files_duplicheck[$j].size)){
                            $script:files_duplicheck[$j].hash = (Get-FileHash -LiteralPath $script:files_duplicheck.fullpath[$j] -Algorithm SHA1 | Select-Object -ExpandProperty Hash)
                            if($files_in[$i].hash -eq $script:files_duplicheck[$j].hash){
                                $dupliindex_out += $i
                                Write-ColorOut "Existing: $($i + 1) - $($files_in[$i].inname.Replace("$InPath",'.'))" -ForegroundColor DarkGreen
                                $files_in[$i].tocopy = 0
                                break
                            }else{
                                if($j -ge $script:files_duplicheck.fullpath.Length){
                                    break
                                }
                                $j++
                                continue
                            }
                        }else{
                            if($j -ge $duplifile_all_name.Length){
                                break
                            }
                            $j++
                            continue
                        }
                    }
                }
            }

            if($script:debug -ne 0){
                Write-ColorOut "`r`n`r`nFiles to skip / process (after out-path-check):" -ForegroundColor Yellow
                for($i = 0; $i -lt $script:files_duplicheck.fullpath.Length; $i++){
                    [string]$inter = ($($script:files_duplicheck.fullpath[$i]).Replace($InPath,'.'))
                    if($i -notin $dupliindex_out){
                        Write-ColorOut "Copy:`t$inter" -ForegroundColor Gray
                    }else{
                        Write-ColorOut "Existing:`t$inter" -ForegroundColor DarkGreen
                    }
                }
            }
        }else{
            Write-ColorOut "No files in $OutPath - skipping additional verification." -ForegroundColor Magenta
        }
    }
    Write-ColorOut "`r`n`r`nTotal in-files:`t$($files_in.name.Length)" -ForegroundColor Gray
    Write-ColorOut "Files to skip:`t$($dupliindex_hist.Length + $dupliindex_out.Length)" -ForegroundColor DarkGreen
    Write-ColorOut "Files left after history-check and/or output-check:`t$($files_in.name.Length - $dupliindex_hist.Length - $dupliindex_out.Length)" -ForegroundColor Yellow
    $script:resultvalues.dupliout = $dupliindex_out.Length
    Invoke-Pause

    # calculate hash (if not yet done), get index of files,...
    if($script:VerifyCopies -eq 1 -and $script:DupliCompareHashes -eq 0 -and $script:CheckOutputDupli -eq 0){
        $files_in | Where-Object {$_.tocopy -eq 1} | Start-RSJob -Name "GetHash" -throttle $script:ThreadCount -ScriptBlock {
            $_.hash = Get-FileHash -LiteralPath $_.fullpath -Algorithm SHA1 | Select-Object -ExpandProperty Hash
        } | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob -Name "GetHash" | Remove-RSJob
    }

    $script:resultvalues.copyfiles = $files_in.fullpath.Length
    return $files_in
}

# DEFINITION: Check if filename already exists and if so, then choose new name for copying:
Function Start-OverwriteProtection(){
    param(
        [array]$InFiles,
        [string]$OutPath
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")  -" -NoNewLine
    Write-ColorOut "-  Prevent overwriting existing files in $OutPath..." -ForegroundColor Cyan

    [array]$allpaths = @()

    for($i=0; $i -lt $InFiles.fullpath.Length; $i++){
        if($InFiles.tocopy -eq 1){
            if($sw.Elapsed.TotalMilliseconds -ge 500 -or $i -eq 0){
                Write-Progress -Activity "Calculating hashes for files to copy..." -PercentComplete $($i / $InFiles.Length * 100) -Status "File # $($i + 1) / $($InFiles.fullpath.Length) - $($InFiles[$i].name)"
                $sw.Reset()
                $sw.Start()
            }

            # create outpath:
            $InFiles[$i].outpath = "$OutPath$($InFiles[$i].sub_date)"
            $InFiles[$i].outpath = $InFiles[$i].outpath.Replace("\\","\").Replace("\\","\")
            $InFiles[$i].outbasename = $InFiles[$i].basename
            # check for files with same name from input:
            [int]$j = 1
            [int]$k = 1
            while($true){
                [string]$check = "$($InFiles[$i].outpath)\$($InFiles[$i].outname)"
                if($check -notin $allpaths -and (Test-Path -LiteralPath $check -PathType Leaf) -eq $false){
                    $allpaths += $check
                    break
                }elseif($check -in $allpaths){
                    if($j -eq 1){
                        $InFiles[$i].outbasename = "$($InFiles[$i].outbasename)_InCopy$j"
                    }else{
                        $InFiles[$i].outbasename = $InFiles[$i].outbasename -replace "_InCopy$($j - 1)","_InCopy$j"
                    }
                    $InFiles[$i].outname = "$($InFiles[$i].outbasename)$($InFiles[$i].extension)"
                    $j++
                    # if($script:debug -ne 0){Write-ColorOut $InFiles[$i].outbasename}
                    continue
                }elseif((Test-Path -LiteralPath $check -PathType Leaf) -eq $true){
                    if($k -eq 1){
                        $InFiles[$i].outbasename = "$($InFiles[$i].outbasename)_OutCopy$k"
                    }else{
                        $InFiles[$i].outbasename = $InFiles[$i].outbasename -replace "_OutCopy$($k - 1)","_OutCopy$k"
                    }
                    $InFiles[$i].outname = "$($InFiles[$i].outbasename)$($InFiles[$i].extension)"
                    $k++
                    # if($script:debug -ne 0){Write-ColorOut $InFiles[$i].outbasename}
                    continue
                }
            }
            if($script:debug -ne 0){
                Write-ColorOut "$($InFiles[$i].outpath)\$($InFiles[$i].outname)"
            }
        }
    }

    return $InFiles
}

# DEFINITION: Copy Files
Function Start-FileCopy(){
    param(
        [array]$InFiles,
        [string]$InPath="->In<-",
        [string]$OutPath="->Out<-"
    )

    if($script:OutputSubfolderStyle -eq "none"){
        Write-ColorOut "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")  -" -NoNewLine
        Write-ColorOut "-  Copy files from $InPath to $($OutPath)..." -ForegroundColor Cyan
    }elseif($script:OutputSubfolderStyle -eq "unchanged"){
        Write-ColorOut "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")  -" -NoNewLine
        Write-ColorOut "-  Copy files from $InPath to $($OutPath) with original subfolders:" -ForegroundColor Cyan
    }else{
        Write-ColorOut "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")  -" -NoNewLine
        Write-ColorOut "-  Copy files from $InPath to $OutPath\$($script:OutputSubfolderStyle)..." -ForegroundColor Cyan
    }

    $InFiles = $InFiles | Sort-Object -Property inpath,outpath

    # setting up robocopy:
    [array]$rc_command = @()
    [string]$rc_suffix = " /R:5 /W:15 /MT:4 /XO /XC /XN /NJH /NC /J"
    [string]$rc_inter_inpath = ""
    [string]$rc_inter_outpath = ""
    [string]$rc_inter_files = ""
    # setting up xcopy:
    [array]$xc_command = @()
    [string]$xc_suffix = " /Q /J /-Y"

    for($i=0; $i -lt $InFiles.fullpath.length; $i++){
        if($InFiles.tocopy -eq 1){
            # check if qualified for robocopy (out-name = in-name):
            if($InFiles[$i].fullpath.contains($InFiles[$i].outname)){
                if($rc_inter_inpath.Length -eq 0 -or $rc_inter_outpath.Length -eq 0 -or $rc_inter_files.Length -eq 0){
                    $rc_inter_inpath = "`"$($InFiles[$i].inpath)`""
                    $rc_inter_outpath = "`"$($InFiles[$i].outpath)`""
                    $rc_inter_files = "`"$($InFiles[$i].outname)`" "
                }
                # if in-path and out-path stay the same:
                if("`"$($InFiles[$i].inpath)`"" -eq $rc_inter_inpath -and "`"$($InFiles[$i].outpath)`"" -eq $rc_inter_outpath){
                    # if command-length is within boundary:
                    if($($rc_inter_inpath.Length + $rc_inter_outpath.Length + $rc_inter_files.Length + $InFiles[$i].outname.Length) -lt 8100){
                        $rc_inter_files += "`"$($InFiles[$i].outname)`" "
                    }else{
                        $rc_command += "`"$rc_inter_inpath`" `"$rc_inter_outpath`" $rc_inter_files $rc_suffix"
                        $rc_inter_files = "`"$($InFiles[$i].outname)`" "
                    }
                # if in-path and out-path DON'T stay the same:
                }else{
                    $rc_command += "$rc_inter_inpath $rc_inter_outpath $rc_inter_files $rc_suffix"
                    $rc_inter_inpath = "`"$($InFiles[$i].inpath)`""
                    $rc_inter_outpath = "`"$($InFiles[$i].outpath)`""
                    $rc_inter_files = "`"$($InFiles[$i].outname)`" "
                }
            # if NOT qualified for robocopy:
            }else{
                $xc_command += "`"$($InFiles[$i].fullpath)`" `"$($InFiles[$i].outpath)\$($InFiles[$i].outname)*`" $xc_suffix"
            }
        }
    }
    # if last element is robocopy:
    if($rc_inter_inpath.Length -ne 0 -or $rc_inter_outpath.Length -ne 0 -or $rc_inter_files.Length -ne 0){
        if($rc_inter_inpath -notin $rc_command -or $rc_inter_outpath -notin $rc_command -or $rc_inter_files -notin $rc_command){
            $rc_command += "$rc_inter_inpath $rc_inter_outpath $rc_inter_files $rc_suffix"
        }
    }

    
    if($script:debug -ne 0){
        Write-ColorOut "`r`nROBOCOPY:" -ForeGroundColor Yellow
        foreach($i in $rc_command){Write-ColorOut "`'$i`'" -ForeGroundColor Gray}
        Write-ColorOut "`r`nXCOPY:" -ForeGroundColor Yellow
        foreach($i in $xc_command){Write-ColorOut "`'$i`'" -ForeGroundColor Gray}
        Invoke-Pause
    }

    # start robocopy:
    for($i=0; $i -lt $rc_command.Length; $i++){
        Start-Process robocopy -ArgumentList $rc_command[$i] -Wait -NoNewWindow
    }

    # start xcopy:
    $xc_command | Start-RSJob -Name "Xcopy" -throttle $script:ThreadCount -ScriptBlock {
        Start-Process xcopy -ArgumentList $_ -WindowStyle Hidden -Wait
    } | Wait-RSJob -ShowProgress | Out-Null
    Get-RSJob -Name "Xcopy" | Remove-RSJob

    Start-Sleep -Milliseconds 250
}

# DEFINITION: Verify newly copied files
Function Start-FileVerification(){
    param(
        [array]$InFiles
    )

    Write-ColorOut "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")  -" -NoNewLine
    Write-ColorOut "-  Verify newly copied files..." -ForegroundColor Cyan

    $InFiles | Where-Object {$_.tocopy -eq 1} | Start-RSJob -Name "GetHash" -throttle $script:ThreadCount -FunctionsToLoad Write-ColorOut -ScriptBlock {
        [string]$inter = "$($_.outpath)\$($_.outname)"
        if((Test-Path -LiteralPath $inter -PathType Leaf) -eq $true){
            if($_.hash -ne $(Get-FileHash -LiteralPath $inter -Algorithm SHA1 | Select-Object -ExpandProperty Hash)){
                Write-ColorOut "Broken:`t$inter" -ForegroundColor Red
                Rename-Item -LiteralPath $inter -NewName "$($inter)_broken"
            }else{
                $_.tocopy = 0
                if((Test-Path -LiteralPath "$($inter)_broken" -PathType Leaf) -eq $true){
                    Remove-Item -LiteralPath "$($inter)_broken"
                }
            }
        }else{
            Write-ColorOut "Missing:`t$inter" -ForegroundColor Red
            New-Item -Path "$($inter)_broken" | Out-Null
        }
    } | Wait-RSJob -ShowProgress | Receive-RSJob
    Get-RSJob -Name "GetHash" | Remove-RSJob

    [int]$verified = 0
    [int]$unverified = 0
    for($i=0; $i -lt $InFiles.tocopy.Length; $i++){
        if($InFiles[$i].tocopy -eq 1){
            $unverified++
        }else{
            $verified++
        }
    }
    $script:resultvalues.unverified = $unverified
    $script:resultvalues.verified = $verified

    return $InFiles
}

# DEFINITION: Write new file-attributes to history-file:
Function Set-HistFile(){
    param(
        [array]$InFiles,
        [string]$HistFilePath="$PSScriptRoot\media_copytool_filehistory.json"
    )

    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  -" -NoNewLine
    Write-ColorOut "-  Write attributes of successfully copied files to history-file..." -ForegroundColor Cyan

    $results = ($InFiles | Where-Object {$_.tocopy -eq 0 -and $_.hash -ne "ZYX"} | Select-Object -Property inname,date,size,hash)

    if($script:WriteHistFile -eq "Yes" -and (Test-Path -LiteralPath $HistFilePath -PathType Leaf) -eq $true){
        $JSON = Get-Content -LiteralPath $HistFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $JSON | Out-Null
        $results += $JSON | ForEach-Object {
            [PSCustomObject]@{
                inname = $_.inname
                date = $_.date
                size = $_.size
                hash = $_.hash
            }
        }
    }

    $results = $results | Sort-Object -Property inname,date,size,hash -Unique | ConvertTo-Json

    try{
        [System.IO.File]::WriteAllText($HistFilePath, $results)
    }
    catch{
        Write-ColorOut "Writing to history-file failed! Trying again..." -ForegroundColor Red
        Pause
        Continue
    }
}

# DEFINITION: Pause the programme if debug-var is active. Also, enable measuring times per command with -debug 3.
Function Invoke-Pause(){
    param($tottime=0.0)

    if($script:debug -eq 3 -and $tottime -ne 0.0){
        Write-ColorOut "Used time for process:`t$tottime`r`n" -ForegroundColor Magenta
    }
    if($script:debug -ge 2){
        if($tottime -ne 0.0){
            $script:timer.Stop()
        }
        Pause
        if($tottime -ne 0.0){
            $script:timer.Start()
        }
    }
}

# DEFINITION: Exit the program (and close all windows) + option to pause before exiting.
Function Invoke-Close(){
    if($script:GUI_CLI_Direct -eq "GUI"){
        $script:Form.Close()
    }
    Write-ColorOut "Exiting - This could take some seconds. Please do not close window!" -ForegroundColor Magenta
    Get-RSJob | Stop-RSJob
    Start-Sleep -Milliseconds 5
    Get-RSJob | Remove-RSJob
    if($script:debug -ne 0){
        Pause
    }
    Exit
}

# DEFINITION: For the auditory experience:
Function Start-Sound($success){
    <#
        .SYNOPSIS
            Gives auditive feedback for fails and successes
        
        .DESCRIPTION
            Uses SoundPlayer and Windows's own WAVs to play sounds.

        .NOTES
            Date: 2018-08-22

        .PARAMETER success
            If 1 it plays Windows's "tada"-sound, if 0 it plays Windows's "chimes"-sound.
        
        .EXAMPLE
            For success: Start-Sound(1)
    #>
    $sound = New-Object System.Media.SoundPlayer -ErrorAction SilentlyContinue
    if($success -eq 1){
        $sound.SoundLocation = "C:\Windows\Media\tada.wav"
    }else{
        $sound.SoundLocation = "C:\Windows\Media\chimes.wav"
    }
    $sound.Play()
}

# DEFINITION: Starts all the things.
Function Start-Everything(){
    Write-ColorOut "`r`n`r`n            Welcome to flolilo's Media-Copytool!            " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "                 v0.6.8 (Beta) - 31.8.2017                  `r`n" -ForegroundColor DarkCyan -BackgroundColor Gray

    $script:timer = [diagnostics.stopwatch]::StartNew()
    while($true){
        if((Get-UserValues) -eq $false){
            Start-Sound(0)
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                $script:Form.WindowState ='Normal'
            }
            break
        }
        Invoke-Pause -tottime $timer.elapsed.TotalSeconds
        $timer.reset()
        iF($script:RememberInPath -ne 0 -or $script:RememberOutPath -ne 0 -or $script:RememberMirrorPath -ne 0 -or $script:RememberSettings -ne 0){
            $timer.start()
            Start-Remembering
            Invoke-Pause -tottime $timer.elapsed.TotalSeconds
            $timer.reset()
        }
        if($script:PreventStandby -eq 1){
            Start-RSJob -Name "PreventStandby" -Throttle 1 -ScriptBlock {
                while($true){
                    $MyShell = New-Object -com "Wscript.Shell"
                    $MyShell.sendkeys("{F15}")
                    Start-Sleep -Seconds 300
                }
            } | Out-Null
        }
        [array]$histfiles = @()
        if($script:UseHistFile -eq 1 -and $script:VerifyCopies -eq 1){
            $timer.start()
            $histfiles = Get-HistFile
            Invoke-Pause -tottime $timer.elapsed.TotalSeconds
            $timer.reset()
        }
        $timer.start()
        $inputfiles = (Start-FileSearchAndCheck -InPath $script:InputPath -OutPath $script:OutputPath -HistFiles $histfiles)
        Invoke-Pause -tottime $timer.elapsed.TotalSeconds
        $timer.reset()
        if(1 -notin $inputfiles.tocopy){
            Write-ColorOut "0 files left to copy - aborting rest of the script." -ForegroundColor Magenta
            Start-Sound(1)
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                $script:Form.WindowState ='Normal'
            }
            break
        }
        $j = 0
        while(1 -in $inputfiles.tocopy){
            if($j -gt 0){
                Write-ColorOut "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                if((Read-Host "`"1`" (w/o quotes) for `"yes`", other number for `"no`"") -ne 1){
                    Write-ColorOut "Aborting." -ForegroundColor Cyan
                    Start-Sleep -Seconds 2
                    if($script:GUI_CLI_Direct -eq "GUI"){
                        $script:Form.WindowState ='Normal'
                    }
                    break
                }
            }
            $timer.start()
            $inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -OutPath $script:OutputPath)
            Invoke-Pause -tottime $timer.elapsed.TotalSeconds
            $timer.reset()
            $timer.start()
            Start-FileCopy -InFiles $inputfiles -InPath $script:InputPath -OutPath $script:OutputPath
            Invoke-Pause -tottime $timer.elapsed.TotalSeconds
            $timer.reset()
            if($script:VerifyCopies -eq 1){
                $timer.start()
                $inputfiles = (Start-FileVerification -InFiles $inputfiles)
                Invoke-Pause -tottime $timer.elapsed.TotalSeconds
                $timer.reset()
                $j++
            }else{
                foreach($instance in $inputfiles.tocopy){$instance = 0}
            }
        }
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
            $timer.start()
            Set-HistFile -InFiles $inputfiles
            Invoke-Pause -tottime $timer.elapsed.TotalSeconds
            $timer.reset()
        }
        if($script:MirrorEnable -eq 1){
            for($i=0; $i -lt $inputfiles.fullpath.length; $i++){
                if($inputfiles[$i].tocopy -eq 1){
                    $inputfiles[$i].tocopy = 0
                }else{
                    $inputfiles[$i].tocopy = 1
                }
                $inputfiles[$i].fullpath = "$($inputfiles[$i].outpath)\$($inputfiles[$i].outname)"
                $inputfiles[$i].inpath = (Split-Path -Path $inputfiles[$i].fullpath -Parent)
                $inputfiles[$i].outname = "$($inputfiles[$i].basename)$($inputfiles[$i].extension)"
            }
            $j = 1
            while(1 -in $inputfiles.tocopy){
                if($j -gt 1){
                    Write-ColorOut "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                    if((Read-Host "`"1`" (w/o quotes) for `"yes`", other number for `"no`"") -ne 1){
                        break
                    }
                }
                <# TODO: if($script:7zipMirror -eq 1){
                    [string]$inter = ""
                    for($k = 0; $k -lt $inputfiles.Length; $k++){
                        $inter += "`"$($inputfiles[$k].fullpath)`" "
                    }
                    Start-Process -FilePath "$($PSScriptRoot)\7z.exe" -ArgumentList "a -tzip -mm=Copy -mx0 -sccUTF-8 -mem=AES256 -bb0 `"-w$(Split-Path -Qualifier -Path $script:MirrorPath)\`" `"$script:MirrorPath\Mirror_$(Get-Date -Format "$script:OutputSubfolderStyle").zip`" $inter" -NoNewWindow -Wait
                # TODO: }else{ #>
                    $timer.start()
                    $inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -OutPath $script:MirrorPath)
                    Invoke-Pause -tottime $timer.elapsed.TotalSeconds
                    $timer.reset()
                    $timer.start()
                    Start-FileCopy -InFiles $inputfiles -InPath $script:OutputPath -OutPath $script:MirrorPath
                    Invoke-Pause -tottime $timer.elapsed.TotalSeconds
                    $timer.reset()
                    if($script:VerifyCopies -eq 1){
                        $timer.start()
                        $inputfiles = (Start-FileVerification -InFiles $inputfiles)
                        Invoke-Pause -tottime $timer.elapsed.TotalSeconds
                        $timer.reset()
                        $j++
                    }else{
                        foreach($instance in $inputfiles.tocopy){$instance = 0}
                    }
                # TODO: }
            }
        }
        break
    }

    Write-ColorOut "`r`nStats:" -ForegroundColor DarkCyan
    Write-ColorOut "Found:`t`t$($script:resultvalues.ingoing)`tfiles." -ForegroundColor Cyan
    Write-ColorOut "Skipped:`t$($script:resultvalues.duplihist) (history) + $($script:resultvalues.dupliout) (out-path)`tfiles." -ForegroundColor DarkGreen
    Write-ColorOut "Copied: `t$($script:resultvalues.copyfiles)`tfiles." -ForegroundColor Yellow
    if($script:VerifyCopies -eq 1){
        Write-ColorOut "Verified:`t$($script:resultvalues.verified)`tfiles." -ForegroundColor Green
        Write-ColorOut "Unverified:`t$($script:resultvalues.unverified)`tfiles." -ForegroundColor DarkRed
    }
    Write-ColorOut " 
    "
    if($script:resultvalues.unverified -eq 0){
        Start-Sound(1)
    }else{
        Start-Sound(0)
    }
    
    if($script:PreventStandby -eq 1){
        Get-RSJob -Name "PreventStandby" | Stop-RSJob
        Start-Sleep -Milliseconds 5
        Get-RSJob -Name "PreventStandby" | Remove-RSJob
    }
    if($script:GUI_CLI_Direct -eq "GUI"){
        $script:Form.WindowState ='Normal'
    }
}

# ==================================================================================================
# ==============================================================================
#   Programming GUI & starting everything:
# ==============================================================================
# ==================================================================================================

if($GUI_CLI_Direct -eq "GUI"){
    # DEFINITION: Setting up GUI:
    <# CREDIT:
        code of this section (except from content of inputXML and small modifications) by
        https://foxdeploy.com/series/learning-gui-toolmaking-series/
    #>
    if((Test-Path -LiteralPath "$($PSScriptRoot)/media_copytool_GUI.xaml" -PathType Leaf)){
        $inputXML = Get-Content -Path "$($PSScriptRoot)/media_copytool_GUI.xaml" -Encoding UTF8
    }else{
        Write-ColorOut "Could not find $($PSScriptRoot)/media_copytool_GUI.xaml - GUI can therefore not start." -ForegroundColor Red
        Pause
        Exit
    }

    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    [xml]$xaml = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:Name",'Name'  -replace '^<Win.*', '<Window'
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    try{$Form=[Windows.Markup.XamlReader]::Load($reader)}
    catch{
        Write-ColorOut "Unable to load Windows.Markup.XamlReader. Usually this means that you haven't installed .NET Framework. Please download and install the latest .NET Framework Web-Installer for your OS: " -ForegroundColor Red
        Write-ColorOut "https://duckduckgo.com/?q=net+framework+web+installer&t=h_&ia=web"
        Write-ColorOut "Alternatively, start this script with '-GUI_CLI_Direct `"CLI`"' (w/o single-quotes) to run it via CLI (find other parameters via '-showparams 1' '-Get-Help media_copytool.ps1 -detailed'." -ForegroundColor Yellow
        Pause
        Exit
    }
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}

    if($getWPF -ne 0){
        Write-ColorOut "Found the following interactable elements:`r`n" -ForegroundColor Cyan
        Get-Variable WPF*
        Pause
        Exit
    }

    # Fill the TextBoxes and buttons with user parameters:
    $WPFtextBoxInput.Text = $InputPath
    $WPFtextBoxOutput.Text = $OutputPath
    $WPFcheckBoxMirror.IsChecked = $MirrorEnable
    $WPFtextBoxMirror.Text = $MirrorPath
    $WPFcheckBoxCan.IsChecked = $(if("Can" -in $PresetFormats){$true}else{$false})
    $WPFcheckBoxNik.IsChecked = $(if("Nik" -in $PresetFormats){$true}else{$false})
    $WPFcheckBoxSon.IsChecked = $(if("Son" -in $PresetFormats){$true}else{$false})
    $WPFcheckBoxJpg.IsChecked = $(if("Jpg" -in $PresetFormats -or "Jpeg" -in $PresetFormats){$true}else{$false})
    $WPFcheckBoxMov.IsChecked = $(if("Mov" -in $PresetFormats){$true}else{$false})
    $WPFcheckBoxAud.IsChecked = $(if("Aud" -in $PresetFormats){$true}else{$false})
    $WPFcheckBoxCustom.IsChecked = $CustomFormatsEnable
    $WPFtextBoxCustom.Text = $CustomFormats -join ","
    $WPFcomboBoxOutSubStyle.SelectedIndex = $(
        if("none" -eq $OutputSubfolderStyle){0}
        elseif("unchanged" -eq $OutputSubfolderStyle){1}
        elseif("yyyy-mm-dd" -eq $OutputSubfolderStyle){2}
        elseif("yyyy_mm_dd" -eq $OutputSubfolderStyle){3}
        elseif("yyyy.mm.dd" -eq $OutputSubfolderStyle){4}
        elseif("yyyymmdd" -eq $OutputSubfolderStyle){5}
        elseif("yy-mm-dd" -eq $OutputSubfolderStyle){6}
        elseif("yy_mm_dd" -eq $OutputSubfolderStyle){7}
        elseif("yy.mm.dd" -eq $OutputSubfolderStyle){8}
        elseif("yymmdd" -eq $OutputSubfolderStyle){9}
    )
    <# TODO:
    $WPFcomboBoxOutFileStyle.SelectedIndex = $(
        if("Unchanged" -eq $OutFileStyle){0}
        elseif("yyyy-MM-dd_HH-mm-ss" -eq $OutFileStyle){1}
        elseif("yyyyMMdd_HHmmss" -eq $OutFileStyle){2}
        elseif("yyyyMMddHHmmss" -eq $OutFileStyle){3}
        elseif("yy-MM-dd_HH-mmss" -eq $OutFileStyle){4}
        elseif("yyMMdd_HHmmss" -eq $OutFileStyle){5}
        elseif("yyMMddHHmmss" -eq $OutFileStyle){6}
        elseif("HH-mm-ss" -eq $OutFileStyle){7}
        elseif("HH_mm_ss" -eq $OutFileStyle){8}
        elseif("HHmmss" -eq $OutFileStyle){9}
    ) #>
    $WPFcheckBoxUseHistFile.IsChecked = $UseHistFile
    $WPFcomboBoxWriteHistFile.SelectedIndex = $(
        if("yes" -eq $OutputSubfolderStyle){0}
        elseif("Overwrite" -eq $WriteHistFile){1}
        elseif("no" -eq $WriteHistFile){2}
    )
    $WPFcheckBoxInSubSearch.IsChecked = $InputSubfolderSearch
    $WPFcheckBoxCheckInHash.IsChecked = $DupliCompareHashes
    $WPFcheckBoxOutputDupli.IsChecked = $CheckOutputDupli
    $WPFcheckBoxVerifyCopies.IsChecked = $VerifyCopies
    # TODO: $WPFcheckBox7zipMirror.IsChecked = $7zipMirror
    $WPFcheckBoxUnmountInputDrive.IsChecked = $UnmountInputDrive
    $WPFcheckBoxPreventStandby.IsChecked = $PreventStandby
    $WPFtextBoxThreadCount.Text = $ThreadCount
    $WPFcheckBoxRememberIn.IsChecked = $RememberInPath
    $WPFcheckBoxRememberOut.IsChecked = $RememberOutPath
    $WPFcheckBoxRememberMirror.IsChecked = $RememberMirrorPath
    $WPFcheckBoxRememberSettings.IsChecked = $RememberSettings

    # DEFINITION: InPath-Button
    $WPFbuttonSearchIn.Add_Click({
        Get-Folder("input")
    })
    # DEFINITION: OutPath-Button
    $WPFbuttonSearchOut.Add_Click({
        Get-Folder("output")
    })
    # DEFINITION: MirrorPath-Button
    $WPFbuttonSearchMirror.Add_Click({
        Get-Folder("mirror")
    })
    # DEFINITION: Start-Button
    $WPFbuttonStart.Add_Click({
        $Form.WindowState = 'Minimized'
        Start-Everything
        $Form.WindowState ='Normal'
    })
    # DEFINITION: About-Button
    $WPFbuttonAbout.Add_Click({
        Start-Process powershell -ArgumentList "Get-Help $PSCommandPath -detailed" -NoNewWindow -Wait
    })
    # DEFINITION: Close-Button
    $WPFbuttonClose.Add_Click({
        Invoke-Close
    })

    # DEFINITION: Start GUI
    $Form.ShowDialog() | Out-Null

}else{
    Start-Everything
}
