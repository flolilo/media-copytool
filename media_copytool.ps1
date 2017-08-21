#requires -version 3

<#
    .SYNOPSIS
        Copy (and verify) user-defined filetypes from A to B (and optionally C).

    .DESCRIPTION
        Uses Windows' Robocopy and Xcopy for file-copy, then uses PowerShell's Get-FileHash (SHA1) for verifying that files were copied without errors.
        Now supports multithreading via Boe Prox's PoshRSJob-cmdlet (https://github.com/proxb/PoshRSJob)

    .NOTES
        Version:        0.6.3 (Beta)
        Author:         flolilo
        Creation Date:  21.8.2017
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
        Creation-style of subfolders for files in -OutputPath. The date will be taken from the files' last edit time.
        Valid options:
            "none"          -   No subfolders in -OutputPath.
            "yyyy-mm-dd"    -   E.g. 2017-01-31
            "yyyy_mm_dd"    -   E.g. 2017_01_31
            "yy-mm-dd"      -   E.g. 17-01-31
            "yy_mm_dd"      -   E.g. 17_01_31
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
        If enabled, it additionally checks for duplicates via hash-calculation of all input-files (slow!)
    .PARAMETER CheckOutputDupli
        Valid range: 0 (deactivate), 1 (activate)
        If enabled, it checks for already copied files in the output-path (and its subfolders).
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
    [string]$GUI_CLI_Direct="direct",
    [string]$InputPath="D:\Temp\in [ ] pfad",
    [string]$OutputPath="D:\Temp\out [ ] pfad",
    [int]$MirrorEnable=1,
    [string]$MirrorPath="D:\Temp\mirr [ ] pfad",
    [array]$PresetFormats=("Can","Jpg","Mov"),
    [int]$CustomFormatsEnable=1,
    [array]$CustomFormats=("*"),
    [string]$OutputSubfolderStyle="yy-MM-dd",
    [int]$UseHistFile=1,
    [string]$WriteHistFile="yes",
    [int]$InputSubfolderSearch=1,
    [int]$DupliCompareHashes=0,
    [int]$CheckOutputDupli=0,
    [int]$PreventStandby=1,
    [int]$ThreadCount=2,
    [int]$RememberInPath=0,
    [int]$RememberOutPath=0,
    [int]$RememberMirrorPath=0,
    [int]$RememberSettings=0,
    [int]$debug=0
)
# First line of "param" (for remembering/restoring parameters):
[int]$paramline = 128

#DEFINITION: Hopefully avoiding errors by wrong encoding now:
$OutputEncoding = New-Object -typename System.Text.UTF8Encoding

# DEFINITION: Enabling fast, colorful Write-Outs. Unfortunately, no -NoNewLine...
Function Write-ColorOut(){
    param(
        [string]$Object,
        [string]$ForegroundColor=[Console]::ForegroundColor,
        [string]$BackgroundColor=[Console]::BackgroundColor
    )
    $old_fg_color = [Console]::ForegroundColor
    $old_bg_color = [Console]::BackgroundColor

    if($ForeGroundColor -ne $old_fg_color){[Console]::ForegroundColor = $ForeGroundColor}
    if($BackgroundColor -ne $old_bg_color){[Console]::BackgroundColor = $BackgroundColor}
    [Console]::WriteLine($Object)
    if($ForeGroundColor -ne $old_fg_color){[Console]::ForegroundColor = $old_fg_color}
    if($BackgroundColor -ne $old_bg_color){[Console]::BackgroundColor = $old_bg_color}
}

# Checking if PoshRSJob is installed:
if (-not (Get-Module -ListAvailable -Name PoshRSJob)){
    Write-ColorOut "Module RSJob (https://github.com/proxb/PoshRSJob) is required, but it seemingly isn't installed - please start PowerShell as administrator and run`t" -ForegroundColor Red
    Write-ColorOut "Install-Module -Name PoshRSJob" -ForegroundColor DarkYellow
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
    Write-ColorOut "-UseHistFile`t`t=`t$UseHistFile" -ForegroundColor Cyan
    Write-ColorOut "-WriteHistFile`t`t=`t$WriteHistFile" -ForegroundColor Cyan
    Write-ColorOut "-InputSubfolderSearch`t=`t$InputSubfolderSearch" -ForegroundColor Cyan
    Write-ColorOut "-CheckOutputDupli`t=`t$CheckOutputDupli" -ForegroundColor Cyan
    Write-ColorOut "-PreventStandby`t`t=`t$PreventStandby" -ForegroundColor Cyan
    Write-ColorOut "-ThreadCount`t`t=`t$ThreadCount`r`n" -ForegroundColor Cyan
    Pause
    Exit
}

# If you want to see the variables (buttons, checkboxes, ...) the GUI has to offer, set this to 1:
[int]$getWPF = 0

# ==================================================================================================
# ==============================================================================
# Defining Functions:
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
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Getting user-values..." -ForeGroundColor Cyan
    
    # get values, test paths:
    if($script:GUI_CLI_Direct -eq "CLI"){
        # input-path
        while($true){
            [string]$script:InputPath = Read-Host "Please specify input-path"
            if($script:InputPath.Length -lt 2 -or (Test-Path -LiteralPath $script:InputPath -PathType Container) -eq $false){
                Write-ColorOut "Invalid selection!" -ForeGroundColor Magenta
                continue
            }else{
                break
            }
        }
        # output-path
        while($true){
            [string]$script:OutputPath = Read-Host "Please specify output-path"
            if($script:OutputPath -eq $script:InputPath){
                Write-ColorOut "`r`nInput-path is the same as output-path.`r`n" -ForegroundColor Magenta
                continue
            }
            if($script:OutputPath.Length -gt 1 -and (Test-Path -LiteralPath $script:OutputPath -PathType Container) -eq $true){
                break
            }elseif((Split-Path -Parent -Path $script:OutputPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Parent -Path $script:OutputPath) -PathType Container) -eq $true){
                # TODO: (Get-Item .\your\path\to\file.ext).PSDrive.Name instead of split-path TODO:
                # CREDIT: https://stackoverflow.com/a/28967236/8013879
                [int]$request = Read-Host "Output-path not found, but parent directory of it was found. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
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
        # mirror yes/no
        while($true){
            [int]$script:MirrorEnable = Read-Host "Copy files to an additional folder? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if(!($script:MirrorEnable -eq 1 -or $script:MirrorEnable -eq 0)){
                continue
            }else{
                break
            }
        }
        # mirror-path
        if($script:MirrorEnable -eq 1){
            while($true){
                [string]$script:MirrorPath = Read-Host "Please specify additional output-path"
                if($script:MirrorPath -eq $script:OutputPath -or $script:MirrorPath -eq $script:InputPath){
                    Write-ColorOut "`r`nAdditional output-path is the same as input- or output-path.`r`n" -ForegroundColor Red
                    continue
                }
                if($script:MirrorPath -gt 1 -and (Test-Path -LiteralPath $script:MirrorPath -PathType Container) -eq $true){
                    break
                }elseif((Split-Path -Parent -Path $script:MirrorPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Parent -Path $script:MirrorPath) -PathType Container) -eq $true){
                    [int]$request = Read-Host "Additional output-path not found, but parent directory of it was found. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
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
        # preset-formats
        while($true){
            $separator = ","
            $option = [System.StringSplitOptions]::RemoveEmptyEntries
            [array]$script:PresetFormats = (Read-Host "Which preset file-formats would you like to copy? Options: `"Can`",`"Nik`",`"Son`",`"Jpg`",`"Mov`",`"Aud`", or leave empty for none. For multiple selection, separate with commata.").Split($separator,$option)
            if(!($script:PresetFormats.Length -ne 0 -and ("Can" -notin $script:PresetFormats -and "Nik" -notin $script:PresetFormats -and "Son" -notin $script:PresetFormats -and "Jpeg" -notin $script:PresetFormats -and "Jpg" -notin $script:PresetFormats -and "Mov" -notin $script:PresetFormats -and "Aud" -notin $script:PresetFormats))){
                Write-ColorOut "Invalid selection!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # custom format counter
        while($true){
            [int]$script:CustomFormatsEnable = Read-Host "How many custom file-formats? Range: From `"0`" (w/o quotes) for `"none`" to as many as you like."
            if($script:CustomFormatsEnable -in (0..999)){
                break
            }else{
                Write-ColorOut "Please choose a positive number!" -ForegroundColor Magenta
                continue
            }
        }
        # custom formats
        [array]$script:CustomFormats = @()
        if($script:CustomFormatsEnable -ne 0){
            for($i = 1; $i -le $script:CustomFormatsEnable; $i++){
                while($true){
                    [string]$inter = Read-Host "Select custom format no. $i. `"*`" (w/o quotes) means `"all files`", `"*.ext`" means `"all files with extension .ext`", `"file.*`" means `"all files named file`"."
                    if($inter.Length -ne 0 -and $inter -notmatch '[$|[]*]'){
                        $script:CustomFormats += $inter
                        break
                    }else{
                        Write-ColorOut "Invalid input! (Brackets [ ] are not allowed due to issues with PowerShell.)" -ForegroundColor Magenta
                        continue
                    }
                }
            }
        }
        # subfolder-style
        while($true){
            [string]$script:OutputSubfolderStyle = Read-Host "Which subfolder-style should be used in the output-path? Options: `"none`",`"yyyy-mm-dd`",`"yyyy_mm_dd`",`"yy-mm-dd`",`"yy_mm_dd`" (all w/o quotes)."
            if($script:OutputSubfolderStyle.Length -eq 0 -or ("none" -notin $script:OutputSubfolderStyle -and "yyyy-mm-dd" -notin $script:OutputSubfolderStyle -and "yyyy_mm_dd" -notin $script:OutputSubfolderStyle -and "yy-mm-dd" -notin $script:OutputSubfolderStyle -and "yy_mm_dd" -notin $script:OutputSubfolderStyle)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # use history-file
        while($true){
            [int]$script:UseHistFile = Read-Host "How to treat history-file? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:UseHistFile -notin (0..1)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # write history-file
        while($true){
            [string]$script:WriteHistFile = Read-Host "Write newly copied files to history-file? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:WriteHistFile.Length -eq 0 -or ("yes" -notin $script:WriteHistFile -and "no" -notin $script:WriteHistFile -and "overwrite" -notin $script:WriteHistFile)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # search subfolders in input-path 
        while($true){
            [int]$script:InputSubfolderSearch = Read-Host "Check input-path's subfolders? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:InputSubfolderSearch -notin (0..1)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # additionally check input-hashes for dupli-verification
        while($true){
            [int]$script:DupliCompareHashes = Read-Host "Additionally compare all input-files via hashes (slow)? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:DupliCompareHashes -notin (0..1)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # check duplis in output-path
        while($true){
            [int]$script:CheckOutputDupli = Read-Host "Additionally check output-path for already copied files? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:CheckOutputDupli -notin (0..1)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # prevent standby
        while($true){
            [int]$script:PreventStandby = Read-Host "Auto-prevent standby of computer while script is running? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:PreventStandby -notin (0..1)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # $ThreadCount
        while($true){
            [int]$script:ThreadCount = Read-Host "Number of threads for multithreaded operations. Suggestion: Number in between 2 and 4."
            if($script:ThreadCount -notin (0..999)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # remember input
        while($true){
            [int]$script:RememberInPath = Read-Host "Remember the input-path for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:RememberInPath -notin (0..1)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # remember output
        while($true){
            [int]$script:RememberOutPath = Read-Host "Remember the output-path for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:RememberOutPath -notin (0..1)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # remember mirror
        while($true){
            [int]$script:RememberMirrorPath = Read-Host "Remember the additional output-path for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:RememberMirrorPath -notin (0..1)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # remember settings
        while($true){
            [int]$script:RememberSettings = Read-Host "Remember settings for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:RememberSettings -notin (0..1)){
                Write-ColorOut "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        return $true
    }elseif($script:GUI_CLI_Direct -eq "GUI" -or $script:GUI_CLI_Direct -eq "direct"){
        if($script:GUI_CLI_Direct -eq "GUI"){
            # input-path
            $script:InputPath = $script:WPFtextBoxInput.Text
            # output-path
            $script:OutputPath = $script:WPFtextBoxOutput.Text
            # mirror yes/no
            $script:MirrorEnable = $(if($script:WPFcheckBoxMirror.IsChecked -eq $true){1}else{0})
            # mirror-path
            $script:MirrorPath = $script:WPFtextBoxMirror.Text
            # preset-formats
            [array]$script:PresetFormats = @()
            if($script:WPFcheckBoxCan.IsChecked -eq $true){$script:PresetFormats += "Can"}
            if($script:WPFcheckBoxNik.IsChecked -eq $true){$script:PresetFormats += "Nik"}
            if($script:WPFcheckBoxSon.IsChecked -eq $true){$script:PresetFormats += "Son"}
            if($script:WPFcheckBoxJpg.IsChecked -eq $true){$script:PresetFormats += "Jpg"}
            if($script:WPFcheckBoxMov.IsChecked -eq $true){$script:PresetFormats += "Mov"}
            if($script:WPFcheckBoxAud.IsChecked -eq $true){$script:PresetFormats += "Aud"}
            # custom formats yes/no
            $script:CustomFormatsEnable = $(if($script:WPFcheckBoxCustom.IsChecked -eq $true){1}else{0})
            # custom formats
            [array]$script:CustomFormats = @()
            $separator = ","
            $option = [System.StringSplitOptions]::RemoveEmptyEntries
            $script:CustomFormats = $script:WPFtextBoxCustom.Text.Replace(" ",'').Split($separator,$option)
            # subfolder-style
            $script:OutputSubfolderStyle = $(if($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 0){"none"}elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 1){"yyyy-mm-dd"}elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 2){"yyyy_mm_dd"}elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 3){"yy-mm-dd"}elseif($script:WPFcomboBoxOutSubStyle.SelectedIndex -eq 4){"yy_mm_dd"})
            # use history-file
            $script:UseHistFile = $(if($script:WPFcheckBoxUseHistFile.IsChecked -eq $true){1}else{0})
            # write history-file
            $script:WriteHistFile = $(if($script:WPFradioButtonWriteHistFileYes.IsChecked -eq $true){"yes"}elseif($script:WPFradioButtonWriteHistFileNo.IsChecked -eq $true){"no"}elseif($script:WPFradioButtonWriteHistFileOverwrite.IsChecked -eq $true){"Overwrite"})
            # search subfolders in input-path
            $script:InputSubfolderSearch = $(if($script:WPFcheckBoxInSubSearch.IsChecked -eq $true){1}else{0})
            # check all hashes
            $script:DupliCompareHashes = $(if($script:WPFcheckBoxCheckInHash.IsChecked -eq $true){1}else{0})
            # check duplis in output-path
            $script:CheckOutputDupli = $(if($script:WPFcheckBoxOutputDupli.IsChecked -eq $true){1}else{0})
            # prevent standby
            $script:PreventStandby = $(if($script:WPFcheckBoxPreventStandby.IsChecked -eq $true){1}else{0})
            # $ThreadCount
            $script:ThreadCount = $script:WPFtextBoxThreadCount.Text
            # remember input
            $script:RememberInPath = $(if($script:WPFcheckBoxRememberIn.IsChecked -eq $true){1}else{0})
            # remember output
            $script:RememberOutPath = $(if($script:WPFcheckBoxRememberOut.IsChecked -eq $true){1}else{0})
            # remember mirror
            $script:RememberMirrorPath = $(if($script:WPFcheckBoxRememberMirror.IsChecked -eq $true){1}else{0})
            # remember settings
            $script:RememberSettings = $(if($script:WPFcheckBoxRememberSettings.IsChecked -eq $true){1}else{0})
        }
        if($script:GUI_CLI_Direct -eq "direct"){
            if($script:MirrorEnable -notin (0..1)){
                Write-ColorOut "Invalid choice of -MirrorEnable." -ForegroundColor Red
                return $false
            }
            if($script:PresetFormats.Length -gt 0 -and ("Can" -notin $script:PresetFormats -and "Nik" -notin $script:PresetFormats -and "Son" -notin $script:PresetFormats -and "Jpeg" -notin $script:PresetFormats -and "Jpg" -notin $script:PresetFormats -and "Mov" -notin $script:PresetFormats -and "Aud" -notin $script:PresetFormats)){
                Write-ColorOut "Invalid choice of -PresetFormats." -ForegroundColor Red
                return $false
            }
            if($script:CustomFormatsEnable -notin (0..1)){
                Write-ColorOut "Invalid choice of -CustomFormatsEnable." -ForegroundColor Red
                return $false
            }
            if("none" -notin $script:OutputSubfolderStyle -and "yyyy-mm-dd" -notin $script:OutputSubfolderStyle -and "yy-mm-dd" -notin $script:OutputSubfolderStyle -and "yyyy_mm_dd" -notin $script:OutputSubfolderStyle -and "yy_mm_dd" -notin $script:OutputSubfolderStyle){
                Write-ColorOut "Invalid choice of -OutputSubfolderStyle." -ForegroundColor Red
                return $false
            }
            if($script:UseHistFile -notin (0..1)){
                Write-ColorOut "Invalid choice of -UseHistFile." -ForegroundColor Red
                return $false
            }
            if("yes" -notin $script:WriteHistFile -and "no" -notin $script:WriteHistFile -and "Overwrite" -notin $script:WriteHistFile){
                Write-ColorOut "Invalid choice of -WriteHistFile." -ForegroundColor Red
                return $false
            }
            if($script:InputSubfolderSearch -notin (0..1)){
                Write-ColorOut "Invalid choice of -InputSubfolderSearch." -ForegroundColor Red
                return $false
            }
            if($script:DupliCompareHashes -notin (0..1)){
                Write-ColorOut "Invalid choice of -DupliCompareHashes." -ForegroundColor Red
                return $false
            }
            if($script:CheckOutputDupli -notin (0..1)){
                Write-ColorOut "Invalid choice of -CheckOutputDupli." -ForegroundColor Red
                return $false
            }
            if($script:PreventStandby -notin (0..1)){
                Write-ColorOut "Invalid choice of -PreventStandby." -ForegroundColor Red
                return $false
            }
            if($script:ThreadCount -notin (0..999)){
                Write-ColorOut "Invalid choice of -ThreadCount." -ForegroundColor Red
                return $false
            }
            if($script:RememberInPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberInPath." -ForegroundColor Red
                return $false
            }
            if($script:RememberOutPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberOutPath." -ForegroundColor Red
                return $false
            }
            if($script:RememberMirrorPath -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberMirrorPath." -ForegroundColor Red
                return $false
            }
            if($script:RememberSettings -notin (0..1)){
                Write-ColorOut "Invalid choice of -RememberSettings." -ForegroundColor Red
                return $false
            }
        }

        if($script:InputPath -lt 2 -or (Test-Path -LiteralPath $script:InputPath -PathType Container) -eq $false){
            Write-ColorOut "`r`nInput-path $script:InputPath could not be found.`r`n" -ForegroundColor Red
            return $false
        }
        # output-path
        if($script:OutputPath -eq $script:InputPath){
            Write-ColorOut "`r`nOutput-path is the same as input-path.`r`n" -ForegroundColor Red
            return $false
        }
        if($script:OutputPath.Length -lt 2 -or (Test-Path -LiteralPath $script:OutputPath -PathType Container) -eq $false){
            if((Split-Path -Parent -Path $script:OutputPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Parent -Path $script:OutputPath) -PathType Container) -eq $true){
                while($true){
                    [int]$request = Read-Host "Output-path not found, but parent directory of it was found. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
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
        # mirror-path
        if($script:MirrorEnable -eq 1){
            if($script:MirrorPath -eq $script:InputPath -or $script:MirrorPath -eq $script:OutputPath){
                Write-ColorOut "`r`nAdditional output-path is the same as input- or output-path.`r`n" -ForegroundColor Red
                return $false
            }
            if($script:MirrorPath -lt 2 -or (Test-Path -LiteralPath $script:MirrorPath -PathType Container) -eq $false){
                if((Split-Path -Parent -Path $script:MirrorPath).Length -gt 1 -and (Test-Path -LiteralPath $(Split-Path -Parent -Path $script:MirrorPath) -PathType Container) -eq $true){
                    while($true){
                        [int]$request = Read-Host "Additional output-path not found, but parent directory of it was found. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
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
        if($script:CustomFormats -match '[$|[]*]'){
            Write-ColorOut "Custom formats must not include brackets [ ] due to issues with PowerShell." -ForegroundColor Magenta
            return $false
        }
    }else{
        Write-ColorOut "Invalid choice of -GUI_CLI_Direct." -ForegroundColor Magenta
        return $false
    }

    # sum up formats:
    [array]$script:allChosenFormats = @()
    if("Can" -in $script:PresetFormats){$script:allChosenFormats += "*.cr2"}
    if("Nik" -in $script:PresetFormats){$script:allChosenFormats += "*.nef"; $script:allChosenFormats += "*.nrw"}
    if("Son" -in $script:PresetFormats){$script:allChosenFormats += "*.arw"}
    if("Jpg" -in $script:PresetFormats -or "Jpeg" -in $script:PresetFormats){$script:allChosenFormats += "*.jpg"; $script:allChosenFormats += "*.jpeg"}
    if("Mov" -in $script:PresetFormats){$script:allChosenFormats += "*.mov"; $script:allChosenFormats += "*.mp4"}
    if("Aud" -in $script:PresetFormats){$script:allChosenFormats += "*.wav"; $script:allChosenFormats += "*.mp3"; $script:allChosenFormats += "*.m4a"}
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
    if($script:InputSubfolderSearch -eq 1){[switch]$script:input_recurse = $true}else{[switch]$script:input_recurse = $false}

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
        Write-ColorOut "UseHistFile:`t`t$script:UseHistFile"
        Write-ColorOut "WriteHistFile:`t`t$script:WriteHistFile"
        Write-ColorOut "InputSubfolderSearch:`t$script:InputSubfolderSearch"
        Write-ColorOut "DupliCompareHashes:`t$script:DupliCompareHashes"
        Write-ColorOut "CheckOutputDupli:`t$script:CheckOutputDupli"
        Write-ColorOut "PreventStandby:`t`t$script:PreventStandby"
        Write-ColorOut "ThreadCount:`t`t$script:ThreadCount"
    }

    # if everything was sucessful, return true:
    return $true
}

# DEFINITION: If checked, remember values for future use:
Function Start-Remembering(){
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Remembering settings..." -ForegroundColor Cyan

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
        for($i = $($script:paramline + 1); $i -le $($script:paramline + 16); $i++){
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
        # $UseHistFile
        $lines_new[$($script:paramline + 10)] = '    [int]$UseHistFile=' + "$script:UseHistFile" + ','
        # $WriteHistFile
        $lines_new[$($script:paramline + 11)] = '    [string]$WriteHistFile="' + "$script:WriteHistFile" + '",'
        # $InputSubfolderSearch
        $lines_new[$($script:paramline + 12)] = '    [int]$InputSubfolderSearch=' + "$script:InputSubfolderSearch" + ','
        # $DupliCompareHashes
        $lines_new[$($script:paramline + 13)] = '    [int]$DupliCompareHashes=' + "$script:DupliCompareHashes" + ','
        # $CheckOutputDupli
        $lines_new[$($script:paramline + 14)] = '    [int]$CheckOutputDupli=' + "$script:CheckOutputDupli" + ','
        # $PreventStandby
        $lines_new[$($script:paramline + 15)] = '    [int]$PreventStandby=' + "$script:PreventStandby" + ','
        # $ThreadCount
        $lines_new[$($script:paramline + 16)] = '    [int]$ThreadCount=' + "$script:ThreadCount" + ','

        Write-ColorOut "To:"
        for($i = $($script:paramline + 1); $i -le $($script:paramline + 16); $i++){
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
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Checking for history-file, importing values..." -ForegroundColor Cyan

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
    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Finding files & checking for duplicates." -ForegroundColor Cyan

    # pre-defining variables:
    $files_in = @()
    $script:files_duplicheck = @()
    $script:resultvalues = @{}

    # Search files and get some information about them:
    [int]$counter = 1
    $inter = $(if($script:DupliCompareHashes -ne 0 -or $script:CheckOutputDupli -ne 0){"incl."}else{"excl."})

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
                sub_date = $(if($script:OutputSubfolderStyle -eq "none"){""}else{"\$($_.LastWriteTime.ToString("$script:OutputSubfolderStyle"))"})
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
                $inter = ($($files_in.fullpath[$i]).Replace($InPath,'.'))
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
                    $inter = ($($script:files_duplicheck.fullpath[$i]).Replace($InPath,'.'))
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
    if($script:DupliCompareHashes -eq 0 -and $script:CheckOutputDupli -eq 0){
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
    Write-ColorOut "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Prevent overwriting existing files in $OutPath..." -ForegroundColor Cyan

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
            $InFiles[$i].outpath = $InFiles[$i].outpath.Replace("\\","\")
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
        Write-ColorOut "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Copy files from $InPath to $($OutPath)..." -ForegroundColor Cyan
    }else{
        Write-ColorOut "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Copy files from $InPath to $OutPath\$($script:OutputSubfolderStyle)..." -ForegroundColor Cyan
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

    Write-ColorOut "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Verify newly copied files..." -ForegroundColor Cyan

    $InFiles | Where-Object {$_.tocopy -eq 1} | Start-RSJob -Name "GetHash" -throttle $script:ThreadCount -FunctionsToLoad Write-ColorOut -ScriptBlock {
        $inter = "$($_.outpath)\$($_.outname)"
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
    
    if(1 -notin $InFiles.tocopy){
        Write-ColorOut "`r`n`r`nAll files successfully verified!`r`n" -ForegroundColor Green
    }

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

    Write-ColorOut "$(Get-Date -Format "dd.MM.yy HH:mm:ss")  --  Write attributes of successfully copied files to history-file..." -ForegroundColor Cyan

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
    if($script:GUI_CLI_Direct -eq "GUI"){$script:Form.Close()}
    Get-RSJob -Name "GetHash" | Stop-RSJob
    Start-Sleep -Milliseconds 5
    Get-RSJob -Name "GetHash" | Remove-RSJob
    Get-RSJob -Name "Xcopy" | Stop-RSJob
    Start-Sleep -Milliseconds 5
    Get-RSJob -Name "Xcopy" | Remove-RSJob
    Get-RSJob -Name "PreventStandby" | Stop-RSJob
    Start-Sleep -Milliseconds 5
    Get-RSJob -Name "PreventStandby" | Remove-RSJob
    if($script:debug -ne 0){Pause}
    Exit
}

# DEFINITION: For the auditory experience:
Function Start-Sound($success){
    $sound = new-Object System.Media.SoundPlayer -ErrorAction SilentlyContinue
    if($success -eq 1){
        $sound.SoundLocation = "c:\WINDOWS\Media\tada.wav"
    }else{
        $sound.SoundLocation = "c:\WINDOWS\Media\chimes.wav"
    }
    $sound.Play()
}

# DEFINITION: Starts all the things.
Function Start-Everything(){
    Write-ColorOut "`r`n`r`n    Welcome to Flo's Media-Copytool! // Willkommen bei Flos Media-Copytool!    " -ForegroundColor DarkCyan -BackgroundColor Gray
    Write-ColorOut "                           v0.6.1 (Beta) - 19.8.2017                           `r`n" -ForegroundColor DarkCyan -BackgroundColor Gray

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
        if($script:UseHistFile -eq 1){
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
        $j = 1
        while(1 -in $inputfiles.tocopy){
            if($j -gt 1){
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
            $timer.start()
            $inputfiles = (Start-FileVerification -InFiles $inputfiles)
            Invoke-Pause -tottime $timer.elapsed.TotalSeconds
            $timer.reset()
            $j++
        }
        if($script:WriteHistFile -ne "no"){
            $timer.start()
            Set-HistFile -InFiles $inputfiles
            Invoke-Pause -tottime $timer.elapsed.TotalSeconds
            $timer.reset()
        }
        if($script:MirrorEnable -ne 0){
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
                $timer.start()
                $inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -OutPath $script:MirrorPath)
                Invoke-Pause -tottime $timer.elapsed.TotalSeconds
                $timer.reset()
                $timer.start()
                Start-FileCopy -InFiles $inputfiles -InPath $script:OutputPath -OutPath $script:MirrorPath
                Invoke-Pause -tottime $timer.elapsed.TotalSeconds
                $timer.reset()
                $timer.start()
                $inputfiles = (Start-FileVerification -InFiles $inputfiles)
                Invoke-Pause -tottime $timer.elapsed.TotalSeconds
                $timer.reset()
                
                $j++
            }
        }
        break
    }

    # $script:resultvalues.unverified
    Write-ColorOut "`r`nStats:" -ForegroundColor DarkCyan
    Write-ColorOut "Found:`t`t$($script:resultvalues.ingoing)`tfiles." -ForegroundColor Cyan
    Write-ColorOut "Skipped:`t$($script:resultvalues.duplihist) (history) + $($script:resultvalues.dupliout) (out-path)`tfiles." -ForegroundColor DarkGreen
    Write-ColorOut "Copied: `t$($script:resultvalues.copyfiles)`tfiles." -ForegroundColor Yellow
    Write-ColorOut "Verified:`t$($script:resultvalues.verified)`tfiles." -ForegroundColor Green
    Write-ColorOut "Unverified:`t$($script:resultvalues.unverified)`tfiles.`r`n" -ForegroundColor DarkRed
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
# Programming GUI & starting everything:
# ==============================================================================
# ==================================================================================================

if($GUI_CLI_Direct -eq "GUI"){
    # DEFINITION: Setting up GUI:
    <# CREDIT:
        code of this section (except from content of inputXML and small modifications) by
        https://foxdeploy.com/series/learning-gui-toolmaking-series/
    #>
$inputXML = @"
<Window x:Class="MediaCopytool.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        mc:Ignorable="d"
        Title="Flo's Media-Copytool v0.6.2 Beta" Height="276" Width="800" ResizeMode="CanMinimize">
    <Grid Background="#FFB3B6B5">
        <TextBlock x:Name="textBlockInput" Text="Input-path:" HorizontalAlignment="Left" Margin="20,23,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="70" TextAlignment="Right"/>
        <TextBox x:Name="textBoxInput" Text="Input-path, e.g. D:\input_path" ToolTip="Brackets [ ] lead to errors!" HorizontalAlignment="Left" Height="22" Margin="100,20,0,0" VerticalAlignment="Top" Width="500" VerticalScrollBarVisibility="Disabled" VerticalContentAlignment="Center"/>
        <Button x:Name="buttonSearchIn" Content="Select Path..." HorizontalAlignment="Right" Margin="0,20,100,0" VerticalAlignment="Top" Width="80" Height="22"/>
        <CheckBox x:Name="checkBoxRememberIn" Content="Remember" ToolTip="Remember the Input-Path." HorizontalAlignment="Right" Margin="0,21,15,0" VerticalAlignment="Top" Width="80" Foreground="#FFC90000" Padding="4,-2,0,0" VerticalContentAlignment="Center" Height="22"/>
        <TextBlock x:Name="textBlockOutput" Text="Output-path:" HorizontalAlignment="Left" Margin="20,55,0,0" TextWrapping="Wrap" VerticalAlignment="Top" TextAlignment="Right" Width="70"/>
        <TextBox x:Name="textBoxOutput" Text="Output-path, e.g. D:\output_path" ToolTip="Brackets [ ] lead to errors!" HorizontalAlignment="Left" Height="22" Margin="100,52,0,0" VerticalAlignment="Top" Width="500" VerticalScrollBarVisibility="Disabled" VerticalContentAlignment="Center"/>
        <Button x:Name="buttonSearchOut" Content="Select Path..." HorizontalAlignment="Right" Margin="0,52,100,0" VerticalAlignment="Top" Width="80" Height="22"/>
        <CheckBox x:Name="checkBoxRememberOut" Content="Remember" ToolTip="Remember the Output-Path." HorizontalAlignment="Right" Margin="0,53,15,0" VerticalAlignment="Top" Width="80" Foreground="#FFC90000" VerticalContentAlignment="Center" Padding="4,-2,0,0" Height="22"/>
        <CheckBox x:Name="checkBoxMirror" Content=":Mirror" ToolTip="Check if you want to Mirror the copied files to a second path." HorizontalAlignment="Left" Margin="20,85,0,0" VerticalAlignment="Top" Width="70" FlowDirection="RightToLeft" Padding="4,-2,0,0" Height="22" BorderThickness="1" VerticalContentAlignment="Center" UseLayoutRounding="False"/>
        <TextBox x:Name="textBoxMirror" Text="Mirror-path, e.g. D:\mirror_path" HorizontalAlignment="Left" Height="22" Margin="100,84,0,0" VerticalAlignment="Top" Width="500" VerticalScrollBarVisibility="Disabled" VerticalContentAlignment="Center"/>
        <Button x:Name="buttonSearchMirror" Content="Select Path..." HorizontalAlignment="Right" Margin="0,84,100,0" VerticalAlignment="Top" Width="80" Height="22"/>
        <CheckBox x:Name="checkBoxRememberMirror" Content="Remember" ToolTip="Remember the Output-Path." HorizontalAlignment="Right" Margin="0,85,15,0" VerticalAlignment="Top" Width="80" Foreground="#FFC90000" VerticalContentAlignment="Center" Padding="4,-2,0,0" Height="22"/>
        <Rectangle Fill="#FFB3B6B5" HorizontalAlignment="Left" Height="2" Stroke="#FF878787" VerticalAlignment="Top" Width="794" Panel.ZIndex="-1" Margin="0,115,0,0"/>
        <ComboBox x:Name="comboBoxPresetFormats" HorizontalAlignment="Left" Margin="50,126,0,0" VerticalAlignment="Top" Width="210" SelectedIndex="0" VerticalContentAlignment="Center">
            <ComboBoxItem Content="- - - Preset formats to copy - - -"/>
            <CheckBox x:Name="checkBoxCan" Content="Canon   - CR2" FontFamily="Consolas"/>
            <CheckBox x:Name="checkBoxNik" Content="Nikon   - NEF + NRW" FontFamily="Consolas"/>
            <CheckBox x:Name="checkBoxSon" Content="Sony    - ARW" FontFamily="Consolas"/>
            <CheckBox x:Name="checkBoxJpg" Content="JPEG    - JPG + JPEG" FontFamily="Consolas"/>
            <CheckBox x:Name="checkBoxMov" Content="Movies  - MOV + MP4" FontFamily="Consolas"/>
            <CheckBox x:Name="checkBoxAud" Content="Audio   - WAV + MP3 + M4A" FontFamily="Consolas"/>
        </ComboBox>
        <CheckBox x:Name="checkBoxCustom" Content="Custom:" ToolTip="Enable to copy customised file-formats." HorizontalAlignment="Left" Margin="50,159,0,0" VerticalAlignment="Top" VerticalContentAlignment="Center" Height="22" Padding="4,-2,0,0"/>
        <TextBox x:Name="textBoxCustom" Text="custom-formats" FontFamily="Consolas" ToolTip="*.ext1,*.ext2,*.ext3 - Brackets [ ] lead to errors!"  HorizontalAlignment="Left" Height="22" Margin="120,158,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="140" VerticalContentAlignment="Center" VerticalScrollBarVisibility="Disabled"/>
        <TextBlock x:Name="textBlockOutSubStyle" Text="Subfolder-Style:" HorizontalAlignment="Center" Margin="0,129,140,0" VerticalAlignment="Top" Width="90" TextAlignment="Right"/>
        <ComboBox x:Name="comboBoxOutSubStyle" ToolTip="Choose your favorite subfolder-style." HorizontalAlignment="Center" Margin="100,126,0,0" VerticalAlignment="Top" Width="120" SelectedIndex="1" Height="23" VerticalContentAlignment="Center" FontFamily="Consolas">
            <ComboBoxItem Content="No subfolders"/>
            <ComboBoxItem Content="yyyy-mm-dd" FontFamily="Consolas" ToolTip="e.g.: 2017-12-31"/>
            <ComboBoxItem Content="yyyy_mm_dd" FontFamily="Consolas" ToolTip="e.g.: 2017_12_31" Width="120"/>
            <ComboBoxItem Content="yy-mm-dd" FontFamily="Consolas" ToolTip="e.g.: 17-12-31"/>
            <ComboBoxItem Content="yy_mm_dd" FontFamily="Consolas" ToolTip="e.g.: 17_12_31"/>
        </ComboBox>
        <ComboBox x:Name="comboBoxHistFile" HorizontalAlignment="Center" Margin="282,158,287,0" VerticalAlignment="Top" Width="225" SelectedIndex="0" Height="22" VerticalContentAlignment="Center">
            <ComboBoxItem Content="- - - Histoy-file options - - -"/>
            <CheckBox x:Name="checkBoxUseHistFile" Content="Use hist-file to prevent duplis" ToolTip="Default. Fast way to prevent already copied files from being copied again." Foreground="#FF00A22C"/>
            <ComboBoxItem Content="- - - Writing the history-file - - -"/>
            <RadioButton x:Name="radioButtonWriteHistFileYes" Content="Write old + new files to history-file" ToolTip="Default. Adds new values to the old ones." GroupName="WriteHistFile"/>
            <RadioButton x:Name="radioButtonWriteHistFileNo" Content="Don't add new files" ToolTip="Does not touch the history-file." GroupName="WriteHistFile"/>
            <RadioButton x:Name="radioButtonWriteHistFileOverwrite" Content="Delete old files, write new ones" ToolTip="Deletes the old values and only writes the new one to the history-file." GroupName="WriteHistFile"/>
        </ComboBox>
        <ComboBox x:Name="comboBoxOptions" HorizontalAlignment="Right" Margin="0,126,50,0" VerticalAlignment="Top" Width="200" SelectedIndex="0" VerticalContentAlignment="Center" BorderThickness="1,1,1,1">
            <ComboBoxItem Content="Select some options"/>
            <CheckBox x:Name="checkBoxInSubSearch" Content="Include subfolders in in-path" ToolTip="Default. E.g. not only searching files in E:\DCIM, but also in E:\DCIM\abc"/>
            <CheckBox x:Name="checkBoxCheckInHash" Content="Check hashes of in-files (slow)" ToolTip="For history-check: If unchecked, dupli-check is done via name, size, date. If checked, hash is added. Dupli-Check in out-path disables this function."/>
            <CheckBox x:Name="checkBoxOutputDupli" Content="Check for duplis in out-path" ToolTip="Ideal if you have used LR or other import-tools since the last card-formatting."/>
            <!-- <CheckBox x:Name="checkBoxPreventDupli" Content="Prevent duplicates from in-path" ToolTip="Prevent duplicates from the input-path (e.g. same file in two folders)."/> -->
            <CheckBox x:Name="checkBoxPreventStandby" Content="Prevent standby" ToolTip="Prevents system from hibernating by simulating the keystroke of F13." Foreground="#FF0080FF"/>
            <ComboBoxItem Content="Thread Count:"/>
            <DockPanel VerticalAlignment="Center" Margin="1" ToolTip="Number of threads for operations. High numbers tend to slow everything down; recommended: 2-4.">
                <Slider x:Name="sliderThreadCount" Minimum="1" Maximum="24" TickPlacement="TopLeft" Width="150" SmallChange="1" Value="1" IsSnapToTickEnabled="True"/>
                <TextBox x:Name="textBoxThreadCount" Text="{Binding ElementName=sliderThreadCount, Path=Value, UpdateSourceTrigger=PropertyChanged}" DockPanel.Dock="Right" TextAlignment="Right" Width="30" Margin="5,0,0,0" />
            </DockPanel>
        </ComboBox>
        <CheckBox x:Name="checkBoxRememberSettings" Content=":Remember settings" ToolTip="Remember all parameters (excl. Remember-Params)" HorizontalAlignment="Right" Margin="0,158,50,0" VerticalAlignment="Top" Foreground="#FFC90000" VerticalContentAlignment="Center" HorizontalContentAlignment="Center" Padding="4,-2,0,0" Height="22" FlowDirection="RightToLeft"/>
        <Button x:Name="buttonStart" Content="START" HorizontalAlignment="Center" Margin="0,0,0,20" VerticalAlignment="Bottom" Width="100" IsDefault="True" FontWeight="Bold"/>
        <Button x:Name="buttonClose" Content="EXIT" HorizontalAlignment="Right" Margin="0,0,40,20" VerticalAlignment="Bottom" Width="100"/>
        <Button x:Name="buttonAbout" Content="About / Help" HorizontalAlignment="Left" Margin="40,0,0,20" VerticalAlignment="Bottom" Width="90"/>
    </Grid>
</Window>
"@

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
    $WPFcomboBoxOutSubStyle.SelectedIndex = $(if("none" -eq $OutputSubfolderStyle){0}elseif("yyyy-mm-dd" -eq $OutputSubfolderStyle){1}elseif("yyyy_mm_dd" -eq $OutputSubfolderStyle){2}elseif("yy-mm-dd" -eq $OutputSubfolderStyle){3}elseif("yy_mm_dd" -eq $OutputSubfolderStyle){4})
    $WPFcheckBoxUseHistFile.IsChecked = $UseHistFile
    $WPFradioButtonWriteHistFileYes.IsChecked = $(if($WriteHistFile -eq "yes"){1}else{0})
    $WPFradioButtonWriteHistFileNo.IsChecked = $(if($WriteHistFile -eq "no"){1}else{0})
    $WPFradioButtonWriteHistFileOverwrite.IsChecked = $(if($WriteHistFile -eq "Overwrite"){1}else{0})
    $WPFcheckBoxInSubSearch.IsChecked = $InputSubfolderSearch
    $WPFcheckBoxCheckInHash.IsChecked = $DupliCompareHashes
    $WPFcheckBoxOutputDupli.IsChecked = $CheckOutputDupli
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
