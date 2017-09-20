#requires -version 3
#requires -module PoshRSJob

<#
    .SYNOPSIS
        Copy (and verify) user-defined filetypes from A to B (and optionally C).
    .DESCRIPTION
        Uses Windows' Robocopy and Xcopy for file-copy, then uses PowerShell's Get-FileHash (SHA1) for verifying that files were copied without errors.
        Now supports multithreading via Boe Prox's PoshRSJob-cmdlet (https://github.com/proxb/PoshRSJob)
    .NOTES
        Version:        0.7.8 (Beta)
        Author:         flolilo
        Creation Date:  2017-09-19
        Legal stuff: This program is free software. It comes without any warranty, to the extent permitted by
        applicable law. Most of the script was written by myself (or heavily modified by me when searching for solutions
        on the WWW). However, some parts are copies or modifications of very genuine code - see
        the "CREDIT:"-tags to find them.

    .PARAMETER ShowParams
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
    .PARAMETER ThreadCount
        Thread-count for RSJobs (not ATM), Xcopy-instances and Robocopy's /MT-switch. Recommended: 6, Valid: 2-48.
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
    .PARAMETER Debug
        Gives more verbose so one can see what is happening (and where it goes wrong).
        Valid options:
            0 - no debug (default)
            1 - only stop on end, show information
            2 - pause after every function, option to show files and their status
            3 - ???

    .INPUTS
        media_copytool_filehistory.json if -UseHistFile is 1
        media_copytool_GUI.xaml if -GUI_CLI_direct is "GUI"
        media_copytool_preventsleep.ps1 if -PreventStandby is 1
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
    [int]$ShowParams=0,
    [string]$GUI_CLI_Direct="GUI",
    [string]$InputPath="G:\",
    [string]$OutputPath="D:\",
    [int]$MirrorEnable=0,
    [string]$MirrorPath="E:\",
    [array]$PresetFormats=("Can","Jpg","Mov"),
    [int]$CustomFormatsEnable=0,
    [array]$CustomFormats=("*"),
    [string]$OutputSubfolderStyle="yyyy-MM-dd",
    [string]$OutputFileStyle="unchanged",
    [int]$UseHistFile=1,
    [string]$WriteHistFile="yes",
    [int]$InputSubfolderSearch=1,
    [int]$DupliCompareHashes=0,
    [int]$CheckOutputDupli=0,
    [int]$VerifyCopies=1,
    [int]$AvoidIdenticalFiles=0,
    [int]$ZipMirror=0,
    [int]$UnmountInputDrive=0,
    [int]$PreventStandby=1,
    [int]$ThreadCount=6,
    [int]$RememberInPath=0,
    [int]$RememberOutPath=0,
    [int]$RememberMirrorPath=0,
    [int]$RememberSettings=0,
    [int]$Debug=0
)
# DEFINITION: Get all error-outputs in English:
[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
$OutputEncoding = New-Object -TypeName System.Text.UTF8Encoding

# DEFINITION: Making Write-Host much, much faster:
Function Write-ColorOut(){
    <#
        .SYNOPSIS
            A faster version of Write-Host
        .DESCRIPTION
            Using the [Console]-commands to make everything faster.
        .NOTES
            Date: 2017-09-18
        
        .PARAMETER Object
            String to write out
        .PARAMETER ForegroundColor
            Color of characters. If not specified, uses color that was set before calling. Valid: White (PS-Default), Red, Yellow, Cyan, Green, Gray, Magenta, Blue, Black, DarkRed, DarkYellow, DarkCyan, DarkGreen, DarkGray, DarkMagenta, DarkBlue
        .PARAMETER BackgroundColor
            Color of background. If not specified, uses color that was set before calling. Valid: DarkMagenta (PS-Default), White, Red, Yellow, Cyan, Green, Gray, Magenta, Blue, Black, DarkRed, DarkYellow, DarkCyan, DarkGreen, DarkGray, DarkBlue
        .PARAMETER NoNewLine
            When enabled, no line-break will be created.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Object,

        [ValidateSet("DarkBlue","DarkGreen","DarkCyan","DarkRed","Blue","Green","Cyan","Red","Magenta","Yellow","Black","DarkGray","Gray","DarkYellow","White","DarkMagenta")]
        [string]$ForegroundColor=[Console]::ForegroundColor,

        [ValidateSet("DarkBlue","DarkGreen","DarkCyan","DarkRed","Blue","Green","Cyan","Red","Magenta","Yellow","Black","DarkGray","Gray","DarkYellow","White","DarkMagenta")]
        [string]$BackgroundColor=[Console]::BackgroundColor,

        [switch]$NoNewLine=$false,

        [ValidateRange(0,48)]
        [int]$Indentation=0
    )

    if($ForegroundColor.Length -ge 3){
        $old_fg_color = [Console]::ForegroundColor
        [Console]::ForegroundColor = $ForeGroundColor
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

# DEFINITION: Set default ErrorAction to Stop: CREDIT: https://stackoverflow.com/a/21260623/8013879
if($Debug -eq 0){
    $PSDefaultParameterValues = @{}
    $PSDefaultParameterValues += @{'*:ErrorAction' = 'Stop'}
    $ErrorActionPreference = 'Stop'
}else{
    Write-ColorOut "PID = $($pid)" -ForegroundColor Magenta -BackgroundColor DarkGray
}

# DEFINITION: Show parameters on the console, then exit:
if($ShowParams -ne 0){
    Write-ColorOut "flolilo's Media-Copytool's Parameters:`r`n" -ForegroundColor Green
    Write-ColorOut "-GUI_CLI_Direct`t`t=`t$GUI_CLI_Direct" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-InputPath`t`t`t=`t$InputPath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputPath`t`t`t=`t$OutputPath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-MirrorEnable`t`t=`t$MirrorEnable" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-MirrorPath`t`t`t=`t$MirrorPath" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-PresetFormats`t`t=`t$PresetFormats" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-CustomFormatsEnable`t=`t$CustomFormatsEnable" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-CustomFormats`t`t=`t$CustomFormats" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputSubfolderStyle`t=`t$OutputSubfolderStyle" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-OutputFileStyle`t`t=`t$OutputFileStyle" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-UseHistFile`t`t=`t$UseHistFile" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-WriteHistFile`t`t=`t$WriteHistFile" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-InputSubfolderSearch`t=`t$InputSubfolderSearch" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-CheckOutputDupli`t`t=`t$CheckOutputDupli" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-VerifyCopies`t`t=`t$VerifyCopies" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-AvoidIdenticalFiles`t=`t$AvoidIdenticalFiles" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-ZipMirror`t`t`t=`t$ZipMirror" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-UnmountInputDrive`t`t=`t$UnmountInputDrive" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-PreventStandby`t`t=`t$PreventStandby" -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "-ThreadCount`t`t=`t$ThreadCount`r`n" -ForegroundColor Cyan -Indentation 4
    Pause
    Exit
}

# DEFINITION: Some relevant variables from the start:
# First line of "param" (for remembering/restoring parameters):
[int]$paramline = 157
# If you want to see the variables (buttons, checkboxes, ...) the GUI has to offer, set this to 1:
[int]$getWPF = 0
# Creating it here for Invoke-Close:
[int]$preventstandbyid = 999999999


# ==================================================================================================
# ==============================================================================
#   Defining Functions:
# ==============================================================================
# ==================================================================================================

# DEFINITION: Pause the programme if debug-var is active. Also, enable measuring times per command with -debug 3.
Function Invoke-Pause(){
    param($TotTime=0.0)

    if($script:Debug -gt 0 -and $TotTime -ne 0.0){
        Write-ColorOut "Used time for process:`t$TotTime" -ForegroundColor Magenta
    }
    if($script:Debug -gt 1){
        if($TotTime -ne 0.0){
            $script:timer.Reset()
        }
        Pause
        if($TotTime -ne 0.0){
            $script:timer.Start()
        }
    }
}

# DEFINITION: Exit the program (and close all windows) + option to pause before exiting.
Function Invoke-Close(){
    if($script:PreventStandby -eq 1 -and $script:preventstandbyid -ne 999999999){
        Stop-Process -Id $script:preventstandbyid -ErrorAction SilentlyContinue
    }
    Write-ColorOut "Exiting - This could take some seconds. Please do not close this window!" -ForegroundColor Magenta
    Get-RSJob | Stop-RSJob
    Start-Sleep -Milliseconds 5
    Get-RSJob | Remove-RSJob
    if($script:Debug -gt 0){
        Pause
    }
    Exit
}

# DEFINITION: For the auditory experience:
Function Start-Sound($Success){
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
    try{
        $sound = New-Object System.Media.SoundPlayer -ErrorAction stop
        if($Success -eq 1){
            $sound.SoundLocation = "C:\Windows\Media\tada.wav"
        }else{
            $sound.SoundLocation = "C:\Windows\Media\chimes.wav"
        }
        $sound.Play()
    }catch{
        Write-Host "`a"
    }
}


# DEFINITION: "Select"-Window for buttons to choose a path.
Function Get-Folder($InOutMirror){
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $folderdialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderdialog.rootfolder = "MyComputer"
    if($folderdialog.ShowDialog() -eq "OK"){
        if($InOutMirror -eq "input"){
            $script:WPFtextBoxInput.Text = $folderdialog.SelectedPath
        }
        if($InOutMirror -eq "output"){
            $script:WPFtextBoxOutput.Text = $folderdialog.SelectedPath
        }
        if($InOutMirror -eq "mirror"){
            $script:WPFtextBoxMirror.Text = $folderdialog.SelectedPath
        }
    }
}

# DEFINITION: Get values from GUI, then check the main input- and outputfolder:
Function Get-UserValues(){
    Write-ColorOut "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  --  Getting user-values..." -ForeGroundColor Cyan
    
    # get values, test paths:
    if($script:GUI_CLI_Direct -eq "GUI" -or $script:GUI_CLI_Direct -eq "CLI" -or $script:GUI_CLI_Direct -eq "direct"){
        if($script:GUI_CLI_Direct -eq "CLI"){
            # $InputPath
            while($true){
                [string]$script:InputPath = Read-Host "    Please specify input-path"
                if($script:InputPath.Length -gt 1 -and (Test-Path -LiteralPath $script:InputPath -PathType Container) -eq $true){
                    break
                }else{
                    Write-ColorOut "Invalid selection!" -ForeGroundColor Magenta -Indentation 4
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
                [array]$inter=@("Can","Nik","Son","Jpeg","Jpg","Mov","Aud")
                $separator = ","
                $option = [System.StringSplitOptions]::RemoveEmptyEntries
                [array]$script:PresetFormats = (Read-Host "    Which preset file-formats would you like to copy? Options: `"Can`",`"Nik`",`"Son`",`"Jpg`",`"Mov`",`"Aud`", or leave empty for none. For multiple selection, separate with commata.").Split($separator,$option)
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
            # $DupliCompareHashes
            while($true){
                [int]$script:DupliCompareHashes = Read-Host "    Additionally compare all input-files via hashes? 1 = yes, 0 = no."
                if($script:DupliCompareHashes -in (0..1)){
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
            # $ThreadCount
            while($true){
                [int]$script:ThreadCount = Read-Host "    Number of threads for operations. Range: 2 - 48, suggestion: 6."
                if($script:ThreadCount -in (2..48)){
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
                Write-ColorOut "Invalid choice of -MirrorEnable." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $PresetFormats
            [array]$inter = @("Can","Nik","Son","Jpeg","Jpg","Mov","Aud")
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
            # InputSubfolderSearch
            if($script:InputSubfolderSearch -notin (0..1)){
                Write-ColorOut "Invalid choice of -InputSubfolderSearch." -ForegroundColor Red -Indentation 4
                return $false
            }
            # $DupliCompareHashes
            if($script:DupliCompareHashes -notin (0..1)){
                Write-ColorOut "Invalid choice of -DupliCompareHashes." -ForegroundColor Red -Indentation 4
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
            # $ThreadCount
            if($script:ThreadCount -notin (2..48)){
                Write-ColorOut "Invalid choice of -ThreadCount." -ForegroundColor Red -Indentation 4
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

        # checking paths for GUI and direct:
        if($script:GUI_CLI_Direct -ne "CLI"){
            # $InputPath
            if($script:InputPath.Length -lt 2 -or (Test-Path -LiteralPath $script:InputPath -PathType Container) -eq $false){
                Write-ColorOut "`r`nInput-path $script:InputPath could not be found.`r`n" -ForegroundColor Red -Indentation 4
                return $false
            }
            # $OutputPath
            if($script:OutputPath -eq $script:InputPath){
                Write-ColorOut "`r`nOutput-path is the same as input-path.`r`n" -ForegroundColor Red -Indentation 4
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
                    Write-ColorOut "`r`nOutput-path not found.`r`n" -ForegroundColor Red -Indentation 4
                    return $false
                }
            }
            # $MirrorPath
            if($script:MirrorEnable -eq 1){
                if($script:MirrorPath -eq $script:InputPath -or $script:MirrorPath -eq $script:OutputPath){
                    Write-ColorOut "`r`nAdditional output-path is the same as input- or output-path.`r`n" -ForegroundColor Red -Indentation 4
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
                        Write-ColorOut "`r`nAdditional output-path not found.`r`n" -ForegroundColor Red -Indentation 4
                        return $false
                    }
                }
            }
        }

    }else{
        Write-ColorOut "Invalid choice of -GUI_CLI_Direct." -ForegroundColor Magenta -Indentation 4
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
        if((Read-Host "    No file-format selected. Copy all files? 1 = yes, 0 = no.") -eq 1){
            [array]$script:allChosenFormats = "*"
        }else{
            Write-ColorOut "No file-format specified." -ForegroundColor Red -Indentation 4
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

    if($script:Debug -gt 1){
        Write-ColorOut "InputPath:`t`t$script:InputPath" -Indentation 4
        Write-ColorOut "OutputPath:`t`t$script:OutputPath" -Indentation 4
        Write-ColorOut "MirrorEnable:`t`t$script:MirrorEnable" -Indentation 4
        Write-ColorOut "MirrorPath:`t`t$script:MirrorPath" -Indentation 4
        Write-ColorOut "CustomFormatsEnable:`t$script:CustomFormatsEnable" -Indentation 4
        Write-ColorOut "AllChosenFormats:`t$script:allChosenFormats" -Indentation 4
        Write-ColorOut "OutputSubfolderStyle:`t$script:OutputSubfolderStyle" -Indentation 4
        Write-ColorOut "OutputFileStyle:`t$script:OutputFileStyle" -Indentation 4
        Write-ColorOut "UseHistFile:`t`t$script:UseHistFile" -Indentation 4
        Write-ColorOut "WriteHistFile:`t`t$script:WriteHistFile" -Indentation 4
        Write-ColorOut "InputSubfolderSearch:`t$script:InputSubfolderSearch" -Indentation 4
        Write-ColorOut "DupliCompareHashes:`t$script:DupliCompareHashes" -Indentation 4
        Write-ColorOut "CheckOutputDupli:`t$script:CheckOutputDupli" -Indentation 4
        Write-ColorOut "VerifyCopies:`t`t$script:VerifyCopies" -Indentation 4
        Write-ColorOut "ZipMirror:`t`t$script:ZipMirror" -Indentation 4
        Write-ColorOut "UnmountInputDrive:`t$script:UnmountInputDrive" -Indentation 4
        Write-ColorOut "PreventStandby:`t`t$script:PreventStandby" -Indentation 4
        Write-ColorOut "ThreadCount:`t`t$script:ThreadCount" -Indentation 4
    }

    # if everything was sucessful, return true:
    return $true
}

# DEFINITION: If checked, remember values for future use:
Function Start-Remembering(){
    Write-ColorOut "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  --  Remembering settings..." -ForegroundColor Cyan

    $lines_old = [System.IO.File]::ReadAllLines($PSCommandPath)
    $lines_new = $lines_old
    
    # $InputPath
    if($script:RememberInPath -ne 0){
        Write-ColorOut "From:`t$($lines_new[$($script:paramline + 2)])" -ForegroundColor Gray -Indentation 4
        $lines_new[$($script:paramline + 2)] = '    [string]$InputPath="' + "$script:InputPath" + '",'
        Write-ColorOut "To:`t$($lines_new[$($script:paramline + 2)])" -ForegroundColor Yellow -Indentation 4
    }
    # $OutputPath
    if($script:RememberOutPath -ne 0){
        Write-ColorOut "From:`t$($lines_new[$($script:paramline + 3)])" -ForegroundColor Gray -Indentation 4
        $lines_new[$($script:paramline + 3)] = '    [string]$OutputPath="' + "$script:OutputPath" + '",'
        Write-ColorOut "To:`t$($lines_new[$($script:paramline + 3)])" -ForegroundColor Yellow -Indentation 4
    }
    # $MirrorPath
    if($script:RememberMirrorPath -ne 0){
        Write-ColorOut "From:`t$($lines_new[$($script:paramline + 5)])" -ForegroundColor Gray -Indentation 4
        $lines_new[$($script:paramline + 5)] = '    [string]$MirrorPath="' + "$script:MirrorPath" + '",'
        Write-ColorOut "To:`t$($lines_new[$($script:paramline + 5)])" -ForegroundColor Yellow -Indentation 4
    }

    # Remember settings
    if($script:RememberSettings -ne 0){
        Write-ColorOut "From:" -Indentation 4
        for($i = $($script:paramline + 1); $i -le $($script:paramline + 21); $i++){
            if(-not ($i -eq $($script:paramline + 2) -or $i -eq $($script:paramline + 3) -or $i -eq $($script:paramline + 5))){
                Write-ColorOut "$($lines_new[$i])" -ForegroundColor Gray -Indentation 4
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
        # $OutputFileStyle
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
        # $AvoidIdenticalFiles
        $lines_new[$($script:paramline + 17)] = '    [int]$AvoidIdenticalFiles=' + "$script:AvoidIdenticalFiles" + ','
        # $ZipMirror
        $lines_new[$($script:paramline + 18)] = '    [int]$ZipMirror=' + "$script:ZipMirror" + ','
        # $UnmountInputDrive
        $lines_new[$($script:paramline + 19)] = '    [int]$UnmountInputDrive=' + "$script:UnmountInputDrive" + ','
        # $PreventStandby
        $lines_new[$($script:paramline + 20)] = '    [int]$PreventStandby=' + "$script:PreventStandby" + ','
        # $ThreadCount
        $lines_new[$($script:paramline + 21)] = '    [int]$ThreadCount=' + "$script:ThreadCount" + ','

        Write-ColorOut "To:" -Indentation 4
        for($i = $($script:paramline + 1); $i -le $($script:paramline + 21); $i++){
            if(-not ($i -eq $($script:paramline + 2) -or $i -eq $($script:paramline + 3) -or $i -eq $($script:paramline + 5))){
                Write-ColorOut "$($lines_new[$i])" -ForegroundColor Yellow -Indentation 4
            }
        }
    }

    Invoke-Pause
    [System.IO.File]::WriteAllLines($PSCommandPath, $lines_new)
}

# DEFINITION: Get History-File
Function Get-HistFile(){
    param(
        [string]$HistFilePath="$($PSScriptRoot)\media_copytool_filehistory.json"
    )
    Write-ColorOut "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  --  Checking for history-file, importing values..." -ForegroundColor Cyan

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
        if("ZYX" -in $files_history.Hash -and $script:DupliCompareHashes -eq 1){
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

# DEFINITION: Searching for selected formats in Input-Path, getting Path, Name, Time, and calculating Hash:
Function Start-FileSearch(){
    param(
        [Parameter(Mandatory=$true)]
        [string]$InPath
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  --  Finding files." -ForegroundColor Cyan

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

    if($script:DupliCompareHashes -eq 1 -or $script:CheckOutputDupli -eq 1){
        $InFiles | Start-RSJob -Name "GetHashAll" <#-throttle $script:ThreadCount#> -ScriptBlock {
            try{
                $_.Hash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash
            }catch{
                Write-ColorOut "Could not get Hash of $($_.FullName)" -ForegroundColor Red -Indentation 4
                $_.Hash = "GetHashAllWRONG"
            }
        } -FunctionsToLoad Write-ColorOut | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob -Name "GetHashAll" | Remove-RSJob
    }

    Write-ColorOut "Total in-files:`t$($InFiles.Length)" -ForegroundColor Yellow -Indentation 4
    $script:resultvalues.ingoing = $InFiles.Length

    return $InFiles
}

# DEFINITION: dupli-check via history-file:
# TODO: multithread if possible (Start-MTFileHash?)
Function Start-DupliCheckHist(){
    param(
        [Parameter(Mandatory=$true)]
        [array]$InFiles,
        [Parameter(Mandatory=$true)]
        [array]$HistFiles
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  --  Checking for duplicates via history-file." -ForegroundColor Cyan

    <# DEFINITION: This multithread-code made everything slower.
        $InFiles | Start-RSJob -Name "CheckDupliHist" -ScriptBlock {
            param(
                [Parameter(Mandatory=$true)]
                [array]$histi,
                [Parameter(Mandatory=$true)]
                [ValidateRange(0,1)]
                [int]$dupli,
                [Parameter(Mandatory=$true)]
                [string]$inni
            )
            $j = $histi.Length
            while($true){
                if($_.InName -eq $histi[$j].InName -and $_.Date -eq $histi[$j].Date -and $_.Size -eq $histi[$j].Size -and ($dupli -eq 0 -or ($dupli -eq 1 -and $_.Hash -eq $histi[$j].Hash))){
                    $_.ToCopy = 0
                    break
                }elseif($_.InName -eq $histi[$j].InName -and $_.Date -eq $histi[$j].Date -and $_.Size -eq $histi[$j].Size -and $dupli -eq 1 -and $histi[$j].Hash -eq "ZYX"){
                    Write-ColorOut "Possible duplicate (no hash found): $($i + 1) - $($_.FullName.Replace($inni,'.'))" -ForegroundColor Green -Indentation 4
                    if($j -le 0){
                        break
                    }
                    $j--
                }else{
                    if($j -le 0){
                        break
                    }
                    $j--
                }
            }
        } -ArgumentList $HistFiles, $script:DupliCompareHashes, $script:InputPath -FunctionsToLoad Write-ColorOut | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob -Name "CheckDupliHist" | Remove-RSJob
    #> 
    <# DEFINITION: my own implementation of multithreading:
        # Add a new PSCustomObject to the input-array:
        $InFiles | Add-Member -MemberType NoteProperty -Name SplitPart -Value 0
        $InFiles | Out-Null

        for($i=1; $i -lt $script:ThreadCount; $i++){
            for($j=0; $j -lt $InFiles.Length; $j++){
                if($j -in (0..[math]::Floor(((1 * ($InFiles.Length - 1)) / $script:ThreadCount)))){
                    $InFiles[$j].SplitPart = 0
                }elseif($j -in ([math]::Floor(((($i * ($InFiles.Length - 1)) / $script:ThreadCount) + 1))..[math]::Floor(((($i + 1) * ($InFiles.Length - 1))) / $script:ThreadCount))){
                    $InFiles[$j].SplitPart = $i
                }
            }
        }
        for($i=0; $i -lt $script:ThreadCount; $i++){
            $array = $InFiles | Where-Object {$_.SplitPart -eq $i}
            try{
                Start-job -Name "HistCheck_$i" -ScriptBlock {
                    param(
                        [Parameter(Mandatory=$true)]
                        [array]$InFiles,
                        [Parameter(Mandatory=$true)]
                        [array]$HistFiles,
                        [Parameter(Mandatory=$true)]
                        [ValidateRange(0,1)]
                        [int]$DupliCheck,
                        [Parameter(Mandatory=$true)]
                        [string]$InPath
                    )
                    for($i=0; $i -lt $InFiles.Length; $i++){
                    $j = $histi.Length
                        while($true){
                            if($InFiles[$i].InName -eq $HistFiles[$j].InName -and $InFiles[$i].Date -eq $HistFiles[$j].Date -and $InFiles[$i].Size -eq $HistFiles[$j].Size -and ($DupliCheck -eq 0 -or ($DupliCheck -eq 1 -and $InFiles[$i].Hash -eq $HistFiles[$j].Hash))){
                                $InFiles[$i].ToCopy = 0
                                break
                            }elseif($InFiles[$i].InName -eq $HistFiles[$j].InName -and $DupliCheck -eq 1 -and $HistFiles[$j].Hash -eq "ZYX"  -and $InFiles[$i].Date -eq $HistFiles[$j].Date -and $InFiles[$i].Size -eq $HistFiles[$j].Size){
                                Write-Host "    Possible duplicate (no hash found): $($i + 1) - $($InFiles[$i].FullName.Replace($InPath,'.'))" -ForegroundColor Green
                                if($j -le 0){
                                    break
                                }
                                $j--
                            }else{
                                if($j -le 0){
                                    break
                                }
                                $j--
                            }
                        }
                    }
                } -ArgumentList $array, $HistFiles, $script:DupliCompareHashes, $script:InputPath -ErrorAction Stop

                [array]$InFiles = @()
                for($i=0; $i -lt $script:ThreadCount; $i++){
                    $InFiles += Receive-Job -Wait -Name "HistCheck_$i" -ErrorAction Stop | Select-Object -Property * -ExcludeProperty RunspaceId,SplitPart
                }
            }catch{
                Write-ColorOut "SERIOUS ISSUE." -ForegroundColor Red -Indentation 4
                Invoke-Close
            }
        }
    #>

    # DEFINITION:single-threaded code:
    for($i=0; $i -lt $InFiles.Length; $i++){
        if($sw.Elapsed.TotalMilliseconds -ge 750){
            Write-Progress -Activity "Comparing to already copied files (history-file).." -PercentComplete $(($i / $InFiles.Length) * 100) -Status "File # $($i + 1) / $($InFiles.Length) - $($InFiles[$i].name)"
            $sw.Reset()
            $sw.Start()
        }

        $properties = @("InName","Date","Size")
        if($script:DupliCompareHashes -eq 1){
            $properties += "Hash"
        }
        [int]$duplicount = @(Compare-Object -ReferenceObject $InFiles[$i] -DifferenceObject $HistFiles -Property $properties -ExcludeDifferent -IncludeEqual -ErrorAction Stop).count
        if($duplicount -gt 0){
            $InFiles[$i].ToCopy = 0
        }
    }
    Write-Progress -Activity "Comparing to already copied files (history-file).." -Status "Done!" -Completed
    $sw.Reset()

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

    [array]$inter = $InFiles | Where-Object {$_.ToCopy -eq 1}
    [array]$InFiles = $inter

    return $InFiles
}

# DEFINITION: dupli-check via output-folder:
# TODO: multithread if possible (Start-MTFileHash?)
Function Start-DupliCheckOut(){
    param(
        [Parameter(Mandatory=$true)]
        [array]$InFiles,
        [Parameter(Mandatory=$true)]
        [string]$OutPath
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  --  Checking for duplicates in OutPath." -ForegroundColor Cyan

    # pre-defining variables:
    $files_duplicheck = @()

    [array]$dupliindex_out = @()

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

            $counter++
            [PSCustomObject]@{
                FullName = $_.FullName
                name = $_.Name
                size = $_.Length
                date = $_.LastWriteTime.ToString("yyyy-MM-dd_HH-mm-ss")
                hash ="ZYX"
            }
        } -End {
            Write-Progress -Id 2 -Activity "Looking for files..." -Status "Done!" -Completed
        }
    }
    Write-Progress -Id 1 -Activity "Find files in $OutPath..." -Status "Done!" -Completed
    $sw.Reset()

    $sw.Start()
    if($files_duplicheck.Length -ne 0){
        for($i = 0; $i -lt $InFiles.Length; $i++){
            if($sw.Elapsed.TotalMilliseconds -ge 750 -or $i -eq 0){
                Write-Progress -Activity "Comparing to files in out-path..." -PercentComplete $($i / $($InFiles.Length - $dupliindex_hist.Length) * 100) -Status "File # $($i + 1) / $($InFiles.Length) - $($InFiles[$i].name)"
                $sw.Reset()
                $sw.Start()
            }

            $j = 0
            while($true){
                # calculate hash only if date and size are the same:
                if($($InFiles[$i].date) -eq $($files_duplicheck[$j].date) -and $($InFiles[$i].size) -eq $($files_duplicheck[$j].size)){
                    $files_duplicheck[$j].hash = (Get-FileHash -LiteralPath $files_duplicheck.FullName[$j] -Algorithm SHA1 | Select-Object -ExpandProperty Hash)
                    if($InFiles[$i].hash -eq $files_duplicheck[$j].hash){
                        $dupliindex_out += $i
                        $InFiles[$i].ToCopy = 0
                        break
                    }else{
                        if($j -ge $files_duplicheck.Length){
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
        Write-Progress -Activity "Comparing to files in out-path..." -Status "Done!" -Completed
        $sw.Reset()

        if($script:Debug -gt1){
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

        Write-ColorOut "Files to skip (outpath):`t$($dupliindex_out.Length)" -ForegroundColor DarkGreen -Indentation 4
    
        [array]$inter = $InFiles | Where-Object {$_.tocopy -eq 1}
        [array]$InFiles = $inter
    }else{
        Write-ColorOut "No files in $OutPath - skipping additional verification." -ForegroundColor Magenta -Indentation 4
    }

    $script:resultvalues.dupliout = $dupliindex_out.Length

    return $InFiles
}

# DEFINITION: Cleaning away all files that will not get copied. ALSO checks for Identical files:
Function Start-InputGetHash(){
    param(
        [Parameter(Mandatory=$true)]
        [array]$InFiles
    )
    Write-ColorOut "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  --  Calculate remaining hashes" -ForegroundColor Cyan -NoNewLine
    if($script:AvoidIdenticalFiles -eq 1){
        Write-ColorOut " (& avoid identical input-files)." -ForegroundColor Cyan
    }else{
        Write-ColorOut " "
    }

    # DEFINITION: Calculate hash (if not yet done):
    if($script:VerifyCopies -eq 1 -or $script:AvoidIdenticalFiles -eq 1){
        $InFiles | Where-Object {$_.Hash -eq "ZYX"} | Start-RSJob -Name "GetHashRest" <#-throttle $script:ThreadCount#> -ScriptBlock {
            try{
                $_.Hash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash
            }catch{
                Write-ColorOut "Failed to get Hash of $($_.FullName)!" -ForegroundColor Red -Indentation 4
                $_.Hash = "GetHashRestWRONG"
            }
        } -FunctionsToLoad Write-ColorOut | Wait-RSJob -ShowProgress | Receive-RSJob
        Get-RSJob -Name "GetHashRest" | Remove-RSJob
    }

    # DEFINITION: if enabled, avoid copying identical files from the input-path:
    if($script:AvoidIdenticalFiles -eq 1){
        [array]$inter = ($InFiles | Sort-Object -Property InName,Date,Size,Hash -Unique)
        if($inter.Length -ne $InFiles.Length){
            Write-ColorOut "$($InFiles.Length - $inter.Length) identical files were found in the input-path - only copying one of each." -ForegroundColor Magenta
            Start-Sleep -Seconds 5
        }
        [array]$InFiles = $inter
        $InFiles | Out-Null
        $script:resultvalues.identicalFiles = $($InFiles.Length - $inter.Length)
    }

    $script:resultvalues.copyfiles = $InFiles.Length
    Write-ColorOut "Files left after dupli-check(s):`t$($script:resultvalues.ingoing - $script:resultvalues.duplihist - $script:resultvalues.dupliout) = $($script:resultvalues.copyfiles)" -ForegroundColor Yellow -Indentation 4

    return $InFiles
}

# DEFINITION: Check if filename already exists and if so, then choose new name for copying:
# TODO: multithread if possible (Start-MTFileHash?)
Function Start-OverwriteProtection(){
    param(
        [Parameter(Mandatory=$true)]
        [array]$InFiles,
        [Parameter(Mandatory=$true)]
        [string]$OutPath
    )
    $sw = [diagnostics.stopwatch]::StartNew()
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Prevent overwriting existing files in $OutPath..." -ForegroundColor Cyan

    [array]$allpaths = @()

    for($i=0; $i -lt $InFiles.Length; $i++){
        if($InFiles[$i].tocopy -eq 1){
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
                    # if($script:Debug -ne 0){Write-ColorOut $InFiles[$i].outbasename}
                    continue
                }elseif((Test-Path -LiteralPath $check -PathType Leaf) -eq $true){
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
            }
            
        }
    }
    Write-Progress -Activity "Prevent overwriting existing files..." -Status "Done!" -Completed

    if($script:Debug -gt 1){
        if((Read-Host "    Show all names? `"1`" for `"yes`"") -eq 1){
            [int]$indent=0
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
    [string]$xc_suffix = " /Q /J /-Y"

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
                Write-ColorOut "robocopy $i`r`n" -ForeGroundColor Gray -Indentation 4
                if($inter -eq 2){
                    [System.IO.File]::AppendAllText("$($PSScriptRoot)\robocopy_commands.txt", $i)
                }
            }
            foreach($i in $xc_command){
                Write-ColorOut "xcopy $i`r`n" -ForeGroundColor Gray -Indentation 4
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
            Start-Sleep -Milliseconds 25
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
        Start-Sleep -Milliseconds 50
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

    $InFiles | Where-Object {$_.ToCopy -eq 1} | Start-RSJob -Name "VerifyHash" <#-throttle $script:ThreadCount#> -FunctionsToLoad Write-ColorOut -ScriptBlock {
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
        [string]$HistFilePath="$($PSScriptRoot)\media_copytool_filehistory.json"
    )
    Write-ColorOut "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  --  Write attributes of successfully copied files to history-file..." -ForegroundColor Cyan

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
    Write-ColorOut "`r`n`                                flolilo's Media-Copytool                                " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "                               v0.7.8 (Beta) - 2017-09-19                               `r`n" -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  --  Starting everything..." -ForegroundColor Cyan
    $script:timer = [diagnostics.stopwatch]::StartNew()
    while($true){
        if((Get-UserValues) -eq $false){
            Start-Sound(0)
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                Start-GUI
            }
            break
        }
        Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
        iF($script:RememberInPath -ne 0 -or $script:RememberOutPath -ne 0 -or $script:RememberMirrorPath -ne 0 -or $script:RememberSettings -ne 0){
            $script:timer.start()
            Start-Remembering
            Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
        }
        if($script:PreventStandby -eq 1){
            if((Test-Path -Path "$($PSScriptRoot)\media_copytool_preventsleep.ps1" -PathType Leaf) -eq $true){
                $script:preventstandbyid = (Start-Process powershell -ArgumentList "$($PSScriptRoot)\media_copytool_preventsleep.ps1" -WindowStyle Hidden -PassThru).Id
                if($script:Debug -gt 0){
                    Write-ColorOut "preventsleep-ID is $script:preventstandbyid" -ForegroundColor Magenta -BackgroundColor DarkGray
                }
            }else{
                Write-Host "Couldn't find .\media_copytool_preventsleep.ps1, so can't prevent standby." -ForegroundColor Magenta
                Start-Sleep -Seconds 3
            }
        }
        [array]$histfiles = @()
        if($script:UseHistFile -eq 1){
            $script:timer.start()
            [array]$histfiles = Get-HistFile
            Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
        }
        $script:timer.start()
        [array]$inputfiles = (Start-FileSearch -InPath $script:InputPath)
        Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
        if($inputfiles.Length -lt 1){
            Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
            Start-Sound(1)
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                Start-GUI
            }
            break
        }
        $script:timer.start()
        if($script:UseHistFile -eq 1){
            [array]$inputfiles = (Start-DupliCheckHist -InFile $inputfiles -HistFiles $histfiles)
            Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
            $script:timer.start()
        }
        if($inputfiles.Length -lt 1){
            Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
            Start-Sound(1)
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                Start-GUI
            }
            break
        }
        if($script:CheckOutputDupli -eq 1){
            [array]$inputfiles = (Start-DupliCheckOut -InFiles $inputfiles -OutPath $script:OutputPath)
            Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
            $script:timer.start()
        }
        if($inputfiles.Length -lt 1){
            Write-ColorOut "$($inputfiles.Length) files left to copy - aborting rest of the script." -ForegroundColor Magenta
            Start-Sound(1)
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                Start-GUI
            }
            break
        }
        [array]$inputfiles = (Start-InputGetHash -InFiles $inputfiles)
        Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
        if($inputfiles.Length -lt 1){
            Write-ColorOut "$($inputfiles.count) files left to copy - aborting rest of the script." -ForegroundColor Magenta
            Start-Sound(1)
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                Start-GUI
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
                        Start-GUI
                    }
                    break
                }
            }
            $script:timer.start()
            [array]$inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -OutPath $script:OutputPath)
            Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
            $script:timer.start()
            Start-FileCopy -InFiles $inputfiles -InPath $script:InputPath -OutPath $script:OutputPath
            Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
            if($script:VerifyCopies -eq 1){
                $script:timer.start()
                [array]$inputfiles = (Start-FileVerification -InFiles $inputfiles)
                Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
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
            $script:timer.start()
            Set-HistFile -InFiles $inputfiles
            Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
        }
        if($script:MirrorEnable -eq 1){
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
                $script:timer.start()
                Start-7zip -InFiles $inputfiles
                Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
            }else{
                $j = 1
                while(1 -in $inputfiles.tocopy){
                    if($j -gt 1){
                        Write-ColorOut "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                        if((Read-Host "`"1`" (w/o quotes) for `"yes`", other number for `"no`"") -ne 1){
                            break
                        }
                    }
                    $script:timer.start()
                    [array]$inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -OutPath $script:MirrorPath)
                    Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
                    $script:timer.start()
                    Start-FileCopy -InFiles $inputfiles -InPath $script:OutputPath -OutPath $script:MirrorPath
                    Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
                    if($script:VerifyCopies -eq 1){
                        $script:timer.start()
                        [array]$inputfiles = (Start-FileVerification -InFiles $inputfiles)
                        Invoke-Pause -TotTime $script:timer.elapsed.TotalSeconds
                        $j++
                    }else{
                        foreach($instance in $inputfiles.tocopy){$instance = 0}
                    }
                }
            }
        }
        break
    }

    Write-ColorOut "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  --  Done!" -ForegroundColor Cyan
    Write-ColorOut "`r`nStats:" -ForegroundColor DarkCyan -Indentation 4
    Write-ColorOut "Found:`t`t$($script:resultvalues.ingoing)`tfiles." -ForegroundColor Cyan -Indentation 4
    Write-ColorOut "Skipped:`t$($script:resultvalues.duplihist) (history) + $($script:resultvalues.dupliout) (out-path) + $($script:resultvalues.IdenticalFiles) (identical)`tfiles." -ForegroundColor DarkGreen -Indentation 4
    Write-ColorOut "Copied: `t$($script:resultvalues.copyfiles)`tfiles." -ForegroundColor Yellow -Indentation 4
    if($script:VerifyCopies -eq 1){
        Write-ColorOut "Verified:`t$($script:resultvalues.verified)`tfiles." -ForegroundColor Green -Indentation 4
        Write-ColorOut "Unverified:`t$($script:resultvalues.unverified)`tfiles." -ForegroundColor DarkRed -Indentation 4
    }
    Write-ColorOut "                                                                                " -BackgroundColor Gray
    Write-ColorOut "                                                                                `r`n" -BackgroundColor Gray
    if($script:resultvalues.unverified -eq 0){
        Start-Sound(1)
    }else{
        Start-Sound(0)
    }
    
    if($script:PreventStandby -eq 1){
        Stop-Process -Id $script:preventstandbyid
    }
    if($script:GUI_CLI_Direct -eq "GUI"){
        Start-GUI
    }
}


# ==================================================================================================
# ==============================================================================
#   Programming GUI & starting everything:
# ==============================================================================
# ==================================================================================================

# DEFINITION: Load and Start GUI:
Function Start-GUI(){
    <# CREDIT:
        code of this section (except from small modifications) by
        https://foxdeploy.com/series/learning-gui-toolmaking-series/
    #>
    if((Test-Path -LiteralPath "$($PSScriptRoot)/media_copytool_GUI.xaml" -PathType Leaf)){
        $inputXML = Get-Content -LiteralPath "$($PSScriptRoot)/media_copytool_GUI.xaml" -Encoding UTF8
    }else{
        Write-ColorOut "Could not find $($PSScriptRoot)/media_copytool_GUI.xaml - GUI can therefore not start." -ForegroundColor Red
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
        Write-ColorOut "Alternatively, start this script with '-GUI_CLI_Direct `"CLI`"' (w/o single-quotes) to run it via CLI (find other parameters via '-showparams 1' '-Get-Help media_copytool.ps1 -detailed'." -ForegroundColor Yellow
        Pause
        Exit
    }
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        Set-Variable -Name "WPF$($_.Name)" -Value $script:Form.FindName($_.Name) -Scope Script
    }

    if($getWPF -ne 0){
        Write-ColorOut "Found the following interactable elements:`r`n" -ForegroundColor Cyan
        Get-Variable WPF*
        Pause
        Exit
    }

    # Fill the TextBoxes and buttons with user parameters:
    $script:WPFtextBoxInput.Text = $script:InputPath
    $script:WPFtextBoxOutput.Text = $script:OutputPath
    $script:WPFcheckBoxMirror.IsChecked = $script:MirrorEnable
    $script:WPFtextBoxMirror.Text = $script:MirrorPath
    $script:WPFcheckBoxCan.IsChecked = $(if("Can" -in $script:PresetFormats){$true}else{$false})
    $script:WPFcheckBoxNik.IsChecked = $(if("Nik" -in $script:PresetFormats){$true}else{$false})
    $script:WPFcheckBoxSon.IsChecked = $(if("Son" -in $script:PresetFormats){$true}else{$false})
    $script:WPFcheckBoxJpg.IsChecked = $(if("Jpg" -in $script:PresetFormats -or "Jpeg" -in $script:PresetFormats){$true}else{$false})
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
    $script:WPFcheckBoxInSubSearch.IsChecked = $script:InputSubfolderSearch
    $script:WPFcheckBoxCheckInHash.IsChecked = $script:DupliCompareHashes
    $script:WPFcheckBoxOutputDupli.IsChecked = $script:CheckOutputDupli
    $script:WPFcheckBoxVerifyCopies.IsChecked = $script:VerifyCopies
    $script:WPFcheckBoxAvoidIdenticalFiles.IsChecked = $script:AvoidIdenticalFiles
    $script:WPFcheckBoxZipMirror.IsChecked = $script:ZipMirror
    $script:WPFcheckBoxUnmountInputDrive.IsChecked = $script:UnmountInputDrive
    $script:WPFcheckBoxPreventStandby.IsChecked = $script:PreventStandby
    $script:WPFtextBoxThreadCount.Text = $script:ThreadCount
    $script:WPFcheckBoxRememberIn.IsChecked = $script:RememberInPath
    $script:WPFcheckBoxRememberOut.IsChecked = $script:RememberOutPath
    $script:WPFcheckBoxRememberMirror.IsChecked = $script:RememberMirrorPath
    $script:WPFcheckBoxRememberSettings.IsChecked = $script:RememberSettings

    # DEFINITION: InPath-Button
    $script:WPFbuttonSearchIn.Add_Click({
        Get-Folder("input")
    })
    # DEFINITION: OutPath-Button
    $script:WPFbuttonSearchOut.Add_Click({
        Get-Folder("output")
    })
    # DEFINITION: MirrorPath-Button
    $script:WPFbuttonSearchMirror.Add_Click({
        Get-Folder("mirror")
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

if($GUI_CLI_Direct -eq "GUI"){
    Start-GUI
}else{
    Start-Everything
}
