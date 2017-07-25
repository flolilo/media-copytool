#requires -version 3

<#
    .SYNOPSIS
        Copy (and verify) user-defined filetypes from A to B (and optionally C).

    .DESCRIPTION
        Uses Windows' Robocopy and Xcopy for file-copy, then uses PowerShell's Get-FileHash (SHA1) for verifying that files were copied without errors.

    .NOTES
        Version:        0.5 Alpha
        Author:         Florian Dolzer
        Creation Date:  25.7.2017
        Legal stuff: This program is free software. It comes without any warranty, to the extent permitted by
        applicable law. Most of the script was written by myself (or heavily modified by me when searching for solutions
        on the WWW). However, some parts are copies or modifications of very genuine code - see
        the "CREDIT"-tags to find them.

    .PARAMETER showparams
        Integer. Value of 1 shows the pre-set parameters.
    .PARAMETER GUI_CLI_Direct
        String. Sets the mode in which the script will guide the user.
        "GUI" - Graphical User Interface
        "CLI" - interactive console
        "direct" - instant execution with given parameters.
    .PARAMETER InputPath
        String. Path from which files should be copied.
    .PARAMETER OutputPath
        String. Path to which files should be copied.
    .PARAMETER MirrorEnable
        Integer. Value of 1 enables copy to second path.
    .PARAMETER MirrorPath
        String. Second path to which files should be copied.
    .PARAMETER PresetFormats
        Array. Preset formats for some manufacturers and file-types.
        Valid options:
        "Can" (Canon, .CR2),
        "Nik" (Nikon, .NRW, .NEF)
        "Son" (Sony, .ARW)
        "Jpeg" (.JPG, .JPEG)
        "Mov" (Movies, .MP4, .MOV)
        "Aud" (Audio, .WAV, .MP3, .M4A)
        For multiple choices, separate with commata.
    .PARAMETER CustomFormatsEnable
        Integer. Value of 1 enables input of custom formats
    .PARAMETER CustomFormats
        Array. User-defined, custom formats. Asterisks * are wildcards.
        Specify in quotes and separate multiple entries with commata.
    .PARAMETER OutputSubfolderStyle
        String. Sets the creation of subfolders in the output-path(s) with the last edit time of each file.
        Valid options:
        "none"
        "yyyy-mm-dd"
        "yyyy_mm_dd"
        "yy-mm-dd"
        "yy_mm_dd"
    .PARAMETER HistoryFile
        String. Sets the usage of the history-file for checking for duplicates before copying.
        Valid options:
        "use"
        "delete"
        "ignore"
    .PARAMETER WriteHist
        Integer. Value of 1 adds newly copied files to history-file.
    .PARAMETER InputSubfolderSearch
        Integer. Value of 1 enables file-search in subfolders of the input-path.
    .PARAMETER DupliCompareHashes
        Integer. Value of 1 additionally checks for duplicates via hash-calculation of all input-files (slow!)
    .PARAMETER CheckOutputDupli
        Integer. Value of 1 checks for already copied files in the output-path (and its subfolders).
    .PARAMETER PreventStandby
        Integer. Value of 1 runs additional script to prevent automatic standby or shutdown as long as media-copytool is running.
    .PARAMETER RememberInPath
        Integer. Value of 1 remembers the input-path for future script-executions.
    .PARAMETER RememberOutPath
        Integer. Value of 1 remembers the output-path for future script-executions.
    .PARAMETER RememberMirrorPath
        Integer. Value of 1 remembers the mirror-path for future script-executions.
    .PARAMETER RememberSettings
        Integer. Value of 1 remembers all settings (excl. remember-parameters, help, and paths) for future script-executions.
    .PARAMETER debug
        Integer. Does what it says: gives more verbose so one can see what is happening (and where it goes wrong).
        Valid options:
        0 - no debug (default)
        1 - only stop on end
        2 - pause after every function
        3 - additional speedtest

    .INPUTS
        None.

    .OUTPUTS
        "media_copytool_progress.txt" & "media_copytool_filehistory.csv", both in the script's directory.
    
    .EXAMPLE
        Start Media-Copytool with the Graphical user interface:
        media_copytool.ps1 -GUI_CLI_Direct "GUI"
#>
param(
    [int]$showparams=0,
    [string]$GUI_CLI_Direct="GUI",
    [string]$InputPath="D:\Temp\powershell\in-pfad",
    [string]$OutputPath="D:\Temp\powershell\out ( ) pfad",
    [int]$MirrorEnable=0,
    [string]$MirrorPath="D:\Temp\powershell\mirr ( ) pfad",
    [array]$PresetFormats=("Can","Jpg"),
    [int]$CustomFormatsEnable=0,
    [array]$CustomFormats=("*.xml","*.xmp"),
    [string]$OutputSubfolderStyle="yyyy-MM-dd",
    [string]$HistoryFile="use",
    [int]$WriteHist=1,
    [int]$InputSubfolderSearch=1,
    [int]$DupliCompareHashes=0,
    [int]$CheckOutputDupli=0,
    [int]$PreventStandby=1,
    [int]$RememberInPath=0,
    [int]$RememberOutPath=0,
    [int]$RememberMirrorPath=0,
    [int]$RememberSettings=0,
    [int]$debug=0
)
# First line of "param" (for remembering/restoring parameters):
[int]$paramline = 99

# Get all error-outputs in English:
[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'

# Usual ErrorAction: Stop: https://stackoverflow.com/a/21260623/8013879
# Set standard ErrorAction to 'Stop':
$PSDefaultParameterValues = @{}
$PSDefaultParameterValues += @{'*:ErrorAction' = 'Stop'}
$ErrorActionPreference = 'Stop'


if($showparams -ne 0){
    Write-Host "Flo's Media-Copytool Parameters:`r`n" -ForegroundColor Green
    Write-Host "-GUI_CLI_Direct`t`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $GUI_CLI_Direct -ForegroundColor Yellow
    Write-Host "-InputPath`t`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $InputPath -ForegroundColor Yellow
    Write-Host "-OutputPath`t`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $OutputPath -ForegroundColor Yellow
    Write-Host "-MirrorEnable`t`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $MirrorEnable -ForegroundColor Yellow
    Write-Host "-MirrorPath`t`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $MirrorPath -ForegroundColor Yellow
    Write-Host "-PresetFormats`t`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $PresetFormats -ForegroundColor Yellow
    Write-Host "-CustomFormatsEnable`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $CustomFormatsEnable -ForegroundColor Yellow
    Write-Host "-CustomFormats`t`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $CustomFormats -ForegroundColor Yellow
    Write-Host "-OutputSubfolderStyle`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $OutputSubfolderStyle -ForegroundColor Yellow
    Write-Host "-HistoryFile`t`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $HistoryFile -ForegroundColor Yellow
    Write-Host "-WriteHist`t`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $WriteHist -ForegroundColor Yellow
    Write-Host "-InputSubfolderSearch`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $InputSubfolderSearch -ForegroundColor Yellow
    Write-Host "-CheckOutputDupli`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host $CheckOutputDupli -ForegroundColor Yellow
    Write-Host "-PreventStandby`t`t=`t" -NoNewline -ForegroundColor Cyan
    Write-Host "$PreventStandby`r`n" -ForegroundColor Yellow
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
    Write-Host "$(Get-Date -Format "dd.MM.yy HH:mm:ss")" -NoNewline
    Write-Host "`t- Getting user-values..." -ForegroundColor Cyan
    
    # get values, test paths:
    if($script:GUI_CLI_Direct -eq "CLI"){
        # input-path
        while($true){
            $script:InputPath = (Read-Host "Please specify input-path")
            if($script:InputPath.Length -lt 2 -or (Test-Path -Path $script:InputPath -PathType Container) -eq $false -or $script:InputPath -match '[$|[]*]'){
                Write-Host "Invalid selection! Please note that brackets [ ] are not supported in filenames due to issues w/ PowerShell." -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # output-path
        while($true){
            $script:OutputPath = (Read-Host "Please specify output-path")
            if($script:OutputPath -eq $script:InputPath){
                Write-Host "`r`nInput-path is the same as output-path.`r`n" -ForegroundColor Magenta
                continue
            }
            if($script:OutputPath -match '[$|[]*]'){
                Write-Host "Invalid selection! Please note that brackets [ ] are not supported in filenames due to issues w/ PowerShell." -ForegroundColor Magenta
                continue
            }
            if($script:OutputPath.Length -gt 1 -and (Test-Path -Path $script:OutputPath -PathType Container) -eq $true){
                break
            }elseif((Split-Path -Parent -Path $script:OutputPath).Length -gt 1 -and (Test-Path -Path $(Split-Path -Parent -Path $script:OutputPath) -PathType Container) -eq $true){
                [int]$request = Read-Host "Output-path not found, but parent directory of it was found. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                if($request -eq 1){
                    New-Item -ItemType Directory -Path $script:OutputPath | Out-Null
                    break
                }elseif($request -eq 0){
                    Write-Host "`r`nOutput-path not found.`r`n" -ForegroundColor Magenta
                    continue
                }
            }else{
                Write-Host "Invalid selection!" -ForegroundColor Magenta
                continue
            }
        }
        # mirror yes/no
        while($true){
            $script:MirrorEnable = Read-Host "Copy files to an additional folder? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if(!($script:MirrorEnable -eq 1 -or $script:MirrorEnable -eq 0)){
                continue
            }else{
                break
            }
        }
        # mirror-path
        if($script:MirrorEnable -eq 1){
            while($true){
                $script:MirrorPath = (Read-Host "Please specify additional output-path")
                if($script:MirrorPath -eq $script:OutputPath -or $script:MirrorPath -eq $script:InputPath){
                    Write-Host "`r`nAdditional output-path is the same as input- or output-path.`r`n" -ForegroundColor Red
                    continue
                }
                if($script:MirrorPath -match '[$|[]*]'){
                    Write-Host "Invalid selection! Please note that brackets [ ] are not supported in filenames due to issues w/ PowerShell." -ForegroundColor Magenta
                    continue
                }
                if($script:MirrorPath -gt 1 -and (Test-Path -Path $script:MirrorPath -PathType Container) -eq $true){
                    break
                }elseif((Split-Path -Parent -Path $script:MirrorPath).Length -gt 1 -and (Test-Path -Path $(Split-Path -Parent -Path $script:MirrorPath) -PathType Container) -eq $true){
                    [int]$request = Read-Host "Additional output-path not found, but parent directory of it was found. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                    if($request -eq 1){
                        New-Item -ItemType Directory -Path $script:MirrorPath | Out-Null
                        break
                    }elseif($request -eq 0){
                        Write-Host "`r`nAdditional output-path not found.`r`n" -ForegroundColor Magenta
                        continue
                    }
                }else{
                    Write-Host "Invalid selection!" -ForegroundColor Magenta
                    continue
                }
            }
        }
        # preset-formats
        while($true){
            $separator = ","
            $option = [System.StringSplitOptions]::RemoveEmptyEntries
            $script:PresetFormats = (Read-Host "Which preset file-formats would you like to copy? Options: `"Can`",`"Nik`",`"Son`",`"Jpg`",`"Mov`",`"Aud`", or leave empty for none. For multiple selection, separate with commata.").Split($separator,$option)
            if(!($script:PresetFormats.Length -ne 0 -and $script:PresetFormats -notin ("Can","Nik","Son","Jpeg","Jpg","Mov","Aud"))){
                Write-Host "Invalid selection!" -ForegroundColor Magenta
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
                Write-Host "Please choose a positive number!" -ForegroundColor Magenta
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
                        Write-Host "Invalid input! (Brackets [ ] are not allowed due to issues with PowerShell.)" -ForegroundColor Magenta
                        continue
                    }
                }
            }
        }
        # subfolder-style
        while($true){
            $script:OutputSubfolderStyle = Read-Host "Which subfolder-style should be used in the output-path? Options: `"none`",`"yyyy-mm-dd`",`"yyyy_mm_dd`",`"yy-mm-dd`",`"yy_mm_dd`" (all w/o quotes)."
            if($script:OutputSubfolderStyle.Length -eq 0 -or $script:OutputSubfolderStyle -notin ("none","yyyy-mm-dd","yyyy_mm_dd","yy-mm-dd","yy_mm_dd")){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # history-file
        while($true){
            $script:HistoryFile = Read-Host "How to treat history-file? Options: `"Use`",`"Delete`",`"Ignore`" (all w/o quotes)."
            if($script:HistoryFile.Length -eq 0 -or $script:HistoryFile -notin ("Use","Delete","Ignore")){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # search subfolders in input-path 
        while($true){
            $script:InputSubfolderSearch = Read-Host "Check input-path's subfolders? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:InputSubfolderSearch -notin (0..1)){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # additionally check input-hashes for dupli-verification
        while($true){
            $script:DupliCompareHashes = Read-Host "Additionally compare all input-files via hashes (slow)? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:DupliCompareHashes -notin (0..1)){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # check duplis in output-path
        while($true){
            $script:CheckOutputDupli = Read-Host "Additionally check output-path for already copied files? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:CheckOutputDupli -notin (0..1)){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # write to history-file
        while($true){
            $script:WriteHist = Read-Host "Write newly copied files to history-file? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:WriteHist -notin (0..1)){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # prevent standby
        while($true){
            $script:PreventStandby = Read-Host "Auto-prevent standby of computer while script is running? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:PreventStandby -notin (0..1)){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # remember input
        while($true){
            $script:RememberInPath = Read-Host "Remember the input-path for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:RememberInPath -notin (0..1)){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # remember output
        while($true){
            $script:RememberOutPath = Read-Host "Remember the output-path for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:RememberOutPath -notin (0..1)){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # remember mirror
        while($true){
            $script:RememberMirrorPath = Read-Host "Remember the additional output-path for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:RememberMirrorPath -notin (0..1)){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
                continue
            }else{
                break
            }
        }
        # remember settings
        while($true){
            $script:RememberSettings = Read-Host "Remember settings for future uses? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
            if($script:RememberSettings -notin (0..1)){
                Write-Host "Invalid choice!" -ForegroundColor Magenta
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
            # history-file
            $script:HistoryFile = $(if($script:WPFcomboBoxHistFile.SelectedIndex -eq 0){"use"}elseif($script:WPFcomboBoxHistFile.SelectedIndex -eq 1){"delete"}elseif($script:WPFcomboBoxHistFile.SelectedIndex -eq 2){"ignore"})
            # search subfolders in input-path
            $script:InputSubfolderSearch = $(if($script:WPFcheckBoxInSubSearch.IsChecked -eq $true){1}else{0})
            # check all hashes
            $script:DupliCompareHashes = $(if($script:WPFcheckBoxCheckInHash.IsChecked -eq $true){1}else{0})
            # check duplis in output-path
            $script:CheckOutputDupli = $(if($script:WPFcheckBoxOutputDupli.IsChecked -eq $true){1}else{0})
            # write to history-file
            $script:WriteHist = $(if($script:WPFcheckBoxWriteHist.IsChecked -eq $true){1}else{0})
            # prevent standby
            $script:PreventStandby = $(if($script:WPFcheckBoxPreventStandby.IsChecked -eq $true){1}else{0})
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
                Write-Host "Invalid choice of -MirrorEnable." -ForegroundColor Red
                return $false
            }
            if($script:PresetFormats.Length -gt 0 -and ("Can" -notin $script:PresetFormats -and "Nik" -notin $script:PresetFormats -and "Son" -notin $script:PresetFormats -and "Jpeg" -notin $script:PresetFormats -and "Jpg" -notin $script:PresetFormats -and "Mov" -notin $script:PresetFormats -and "Aud" -notin $script:PresetFormats)){
                Write-Host "Invalid choice of -PresetFormats." -ForegroundColor Red
                return $false
            }
            if($script:CustomFormatsEnable -notin (0..1)){
                Write-Host "Invalid choice of -CustomFormatsEnable." -ForegroundColor Red
                return $false
            }
            if("none" -notin $script:OutputSubfolderStyle -and "yyyy-mm-dd" -notin $script:OutputSubfolderStyle -and "yy-mm-dd" -notin $script:OutputSubfolderStyle -and "yyyy_mm_dd" -notin $script:OutputSubfolderStyle -and "yy_mm_dd" -notin $script:OutputSubfolderStyle){
                Write-Host "Invalid choice of -OutputSubfolderStyle." -ForegroundColor Red
                return $false
            }
            if("use" -notin $script:HistoryFile -and "delete" -notin $script:HistoryFile -and "ignore" -notin $script:HistoryFile){
                Write-Host "Invalid choice of -HistoryFile." -ForegroundColor Red
                return $false
            }
            if($script:InputSubfolderSearch -notin (0..1)){
                Write-Host "Invalid choice of -InputSubfolderSearch." -ForegroundColor Red
                return $false
            }
            if($script:DupliCompareHashes -notin (0..1)){
                Write-Host "Invalid choice of -DupliCompareHashes." -ForegroundColor Red
                return $false
            }
            if($script:CheckOutputDupli -notin (0..1)){
                Write-Host "Invalid choice of -CheckOutputDupli." -ForegroundColor Red
                return $false
            }
            if($script:WriteHist -notin (0..1)){
                Write-Host "Invalid choice of -WriteHist." -ForegroundColor Red
                return $false
            }
            if($script:PreventStandby -notin (0..1)){
                Write-Host "Invalid choice of -PreventStandby." -ForegroundColor Red
                return $false
            }
            if($script:RememberInPath -notin (0..1)){
                Write-Host "Invalid choice of -RememberInPath." -ForegroundColor Red
                return $false
            }
            if($script:RememberOutPath -notin (0..1)){
                Write-Host "Invalid choice of -RememberOutPath." -ForegroundColor Red
                return $false
            }
            if($script:RememberMirrorPath -notin (0..1)){
                Write-Host "Invalid choice of -RememberMirrorPath." -ForegroundColor Red
                return $false
            }
            if($script:RememberSettings -notin (0..1)){
                Write-Host "Invalid choice of -RememberSettings." -ForegroundColor Red
                return $false
            }
        }

        if($script:InputPath -match '[$|[]*]'){
            Write-Host "`r`nBrackets [ ] are not allowed due to issues with PowerShell.`r`n" -ForegroundColor Magenta
            return $false
        }
        if($script:InputPath -lt 2 -or (Test-Path -Path $script:InputPath -PathType Container) -eq $false){
            Write-Host "`r`nInput-path $script:InputPath could not be found.`r`n" -ForegroundColor Red
            return $false
        }
        # output-path
        if($script:OutputPath -match '[$|[]*]'){
            Write-Host "`r`nBrackets [ ] are not allowed due to issues with PowerShell.`r`n" -ForegroundColor Magenta
            return $false
        }
        if($script:OutputPath -eq $script:InputPath){
            Write-Host "`r`nOutput-path is the same as input-path.`r`n" -ForegroundColor Red
            return $false
        }
        if($script:OutputPath.Length -lt 2 -or (Test-Path -Path $script:OutputPath -PathType Container) -eq $false){
            if((Split-Path -Parent -Path $script:OutputPath).Length -gt 1 -and (Test-Path -Path $(Split-Path -Parent -Path $script:OutputPath) -PathType Container) -eq $true){
                while($true){
                    [int]$request = Read-Host "Output-path not found, but parent directory of it was found. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                    if($request -eq 1){
                        New-Item -ItemType Directory -Path $script:OutputPath | Out-Null
                        break
                    }elseif($request -eq 0){
                        Write-Host"`r`nOutput-path not found.`r`n" -ForegroundColor Red
                        return $false
                        break
                    }else{continue}
                }
            }else{
                Write-Host "`r`nOutput-path not found.`r`n" -ForegroundColor Red
                return $false
            }
        }
        # mirror-path
        if($script:MirrorEnable -eq 1){
            if($script:MirrorPath -eq $script:InputPath -or $script:MirrorPath -eq $script:OutputPath){
                Write-Host "`r`nAdditional output-path is the same as input- or output-path.`r`n" -ForegroundColor Red
                return $false
            }
            if($script:MirrorPath -match '[$|[]*]'){
                Write-Host "`r`nBrackets [ ] are not allowed due to issues with PowerShell.`r`n" -ForegroundColor Magenta
                return $false
            }
            if($script:MirrorPath -lt 2 -or (Test-Path -Path $script:MirrorPath -PathType Container) -eq $false){
                if((Split-Path -Parent -Path $script:MirrorPath).Length -gt 1 -and (Test-Path -Path $(Split-Path -Parent -Path $script:MirrorPath) -PathType Container) -eq $true){
                    while($true){
                        [int]$request = Read-Host "Additional output-path not found, but parent directory of it was found. Create chosen directory? `"1`" (w/o quotes) for `"yes`", `"0`" for `"no`""
                        if($request -eq 1){
                            New-Item -ItemType Directory -Path $script:MirrorPath | Out-Null
                            break
                        }elseif($request -eq 0){
                            Write-Host "`r`nAdditional output-path not found.`r`n" -ForegroundColor Red
                            return $false
                            break
                        }else{continue}
                    }
                }else{
                    Write-Host "`r`nAdditional output-path not found.`r`n" -ForegroundColor Red
                    return $false
                }
            }
        }
        if($script:CustomFormats -match '[$|[]*]'){
            Write-Host "Custom formats must not include brackets [ ] due to issues with PowerShell." -ForegroundColor Magenta
            return $false
        }
    }else{
        Write-Host "Invalid choice of -GUI_CLI_Direct." -ForegroundColor Magenta
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
            Write-Host "No file-format specified." -ForegroundColor Red
            return $false
        }
    }

    # build switches
    if($script:InputSubfolderSearch -eq 1){[switch]$script:input_recurse = $true}else{[switch]$script:input_recurse = $false}

    # get minutes (mm) to months (MM):
    $script:OutputSubfolderStyle = $script:OutputSubfolderStyle -Replace 'mm','MM'

    if($script:debug -ne 0){
        Write-Host "InputPath:`t`t$script:InputPath"
        Write-Host "OutputPath:`t`t$script:OutputPath"
        Write-Host "MirrorEnable:`t`t$script:MirrorEnable"
        Write-Host "MirrorPath:`t`t$script:MirrorPath"
        Write-Host "CustomFormatsEnable:`t$script:CustomFormatsEnable"
        Write-Host "allChosenFormats:`t$script:allChosenFormats"
        Write-Host "OutputSubfolderStyle:`t$script:OutputSubfolderStyle"
        Write-Host "HistoryFile:`t`t$script:HistoryFile"
        Write-Host "InputSubfolderSearch:`t$script:InputSubfolderSearch"
        Write-Host "DupliCompareHashes:`t$script:DupliCompareHashes"
        Write-Host "CheckOutputDupli:`t$script:CheckOutputDupli"
        Write-Host "WriteHist:`t`t$script:WriteHist"
        Write-Host "PreventStandby:`t`t$script:PreventStandby"
    }

    # if everything was sucessful, return true:
    return $true
}

# DEFINITION: If checked, remember values for future use:
Function Start-Remembering(){
    Write-Host "$(Get-Date -Format "dd.MM.yy HH:mm:ss")" -NoNewline
    Write-Host "`t- Remembering settings..." -ForegroundColor Cyan

    $lines_old = Get-Content $PSCommandPath
    $lines_new = $lines_old
    
    # $InputPath
    if($script:RememberInPath -ne 0){
        Write-Host "From:`t" -NoNewline
        Write-Host $lines_new[$($script:paramline + 2)] -ForegroundColor Gray
        $lines_new[$($script:paramline + 2)] = '    [string]$InputPath="' + "$script:InputPath" + '",'
        Write-Host "To:`t" -NoNewline
        Write-Host $lines_new[$($script:paramline + 2)] -ForegroundColor Yellow
    }
    # $OutputPath
    if($script:RememberOutPath -ne 0){
        Write-Host "From:`t" -NoNewline
        Write-Host $lines_new[$($script:paramline + 3)] -ForegroundColor Gray
        $lines_new[$($script:paramline + 3)] = '    [string]$OutputPath="' + "$script:OutputPath" + '",'
        Write-Host "To:`t" -NoNewline
        Write-Host $lines_new[$($script:paramline + 3)] -ForegroundColor Yellow
    }
    # $MirrorPath
    if($script:RememberMirrorPath -ne 0){
        Write-Host "From:`t" -NoNewline
        Write-Host $lines_new[$($script:paramline + 5)] -ForegroundColor Gray
        $lines_new[$($script:paramline + 5)] = '    [string]$MirrorPath="' + "$script:MirrorPath" + '",'
        Write-Host "To:`t" -NoNewline
        Write-Host $lines_new[$($script:paramline + 5)] -ForegroundColor Yellow
    }

    # Remember settings
    if($script:RememberSettings -ne 0){
        Write-Host "From:"
        for($i = $($script:paramline + 1); $i -le $($script:paramline + 15); $i++){
            if(-not ($i -eq $($script:paramline + 2) -or $i -eq $($script:paramline + 3) -or $i -eq $($script:paramline + 5))){
                Write-Host $lines_new[$i] -ForegroundColor Gray
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
        # $HistoryFile
        $lines_new[$($script:paramline + 10)] = '    [string]$HistoryFile="' + "$script:HistoryFile" + '",'
        # $WriteHist
        $lines_new[$($script:paramline + 11)] = '    [int]$WriteHist=' + "$script:WriteHist" + ','
        # $InputSubfolderSearch
        $lines_new[$($script:paramline + 12)] = '    [int]$InputSubfolderSearch=' + "$script:InputSubfolderSearch" + ','
        # $DupliCompareHashes
        $lines_new[$($script:paramline + 13)] = '    [int]$DupliCompareHashes=' + "$script:DupliCompareHashes" + ','
        # $CheckOutputDupli
        $lines_new[$($script:paramline + 14)] = '    [int]$CheckOutputDupli=' + "$script:CheckOutputDupli" + ','
        # $PreventStandby
        $lines_new[$($script:paramline + 15)] = '    [int]$PreventStandby=' + "$script:PreventStandby" + ','

        Write-Host "To:"
        for($i = $($script:paramline + 1); $i -le $($script:paramline + 15); $i++){
            if(-not ($i -eq $($script:paramline + 2) -or $i -eq $($script:paramline + 3) -or $i -eq $($script:paramline + 5))){
                Write-Host $lines_new[$i] -ForegroundColor Yellow
            }
        }
    }

    Invoke-Pause
    Out-File -FilePath $PSCommandPath -InputObject $lines_new -Encoding UTF8
}

# DEFINITION: Get History-File
Function Get-Historyfile(){
    param([string]$HistFilePath="$PSScriptRoot\media_copytool_filehistory.json")
    Write-Host "$(Get-Date -Format "dd.MM.yy HH:mm:ss")" -NoNewline
    if($script:HistoryFile -eq "use"){
        Write-Host "`t- Checking for history-file, importing values..." -ForegroundColor Cyan
        while($true){
            if(Test-Path -Path $HistFilePath -PathType Leaf){
                $JSONFile = Get-Content -Path $HistFilePath -Raw | ConvertFrom-Json
                $JSONFile | Out-Null
                $files_history = $JSONFile | ForEach-Object {
                    [PSCustomObject]@{
                        name = $_.inname
                        date = $_.date
                        size = $_.size
                        hash = $_.hash
                    }
                }
                if($script:debug -ne 0){
                    Write-Host "Found values:" -ForegroundColor Yellow
                    for($i = 0; $i -lt $files_history.name.Length; $i++){
                        Write-Host "$($files_history[$i].name)`t" -ForegroundColor Green -NoNewline
                        Write-Host "$($files_history[$i].date)`t" -ForegroundColor White -NoNewline
                        Write-Host "$($files_history[$i].size)`t" -ForegroundColor White -NoNewline
                        Write-Host $files_history[$i].hash -ForegroundColor Magenta
                    }
                }
                Break
            }else{
                Write-Host "History-File $HistFilePath could not be found. This means it's possible that duplicates get copied." -ForegroundColor Magenta
                if((Read-Host "Is that okay? Type '1' (without quotes) to confirm or any other number to abort. Confirm by pressing Enter") -eq 1){
                    # Out-File -InputObject "Name,Date,Size,Hash" -Encoding utf8 -FilePath $HistFilePath
                    $script:HistoryFile = "ignore"
                    break
                }else{
                    Write-Host "`r`nAborting.`r`n" -ForegroundColor Magenta
                    Invoke-Close
                }
            }
        }
        while($true){
            if("null" -in $files_history -or $files_history.name.Length -ne $files_history.date.Length -or $files_history.name.Length -ne $files_history.size.Length -or $files_history.name.Length -ne $files_history.hash.Length -or $files_history.name.Length -eq 0){
                Write-Host "Some values in the history-file $HistFilePath seem wrong - it's safest to delete the whole file." -ForegroundColor Magenta
                if((Read-Host "Is that okay? Type '1' (without quotes) to confirm or any other number to abort. Confirm by pressing Enter") -eq 1){
                    # Out-File -InputObject "Name,Date,Size,Hash" -Encoding utf8 -FilePath $HistFilePath
                    $script:HistoryFile = "delete"
                    break
                }else{
                    Write-Host "`r`nAborting.`r`n" -ForegroundColor Magenta
                    Invoke-Close
                }
            }
        }

        return $files_history

    }else{
        Write-Host "`t- History-file will be ignored." -ForegroundColor Cyan
    }
}

# DEFINITION: Searching for selected formats in Input-Path, getting Path, Name, Time, and calculating Hash:
Function Start-FileSearchAndCheck(){
    param(
        [string]$InPath,
        [string]$OutPath,
        [array]$HistFiles
        )
    Write-Host "$(Get-Date -Format "dd.MM.yy HH:mm:ss")`t" -NoNewline
    Write-Host "- Finding files & checking for duplicates." -ForegroundColor Cyan

    # pre-defining variables:
    $files_in = @()
    $script:files_duplicheck = @()
    $script:resultvalues = @{}

    # Search files and get some information about them:
    [int]$counter = 1
    Write-Host "Find files in $InPath (" -ForegroundColor Yellow -NoNewline
    if($script:DupliCompareHashes -ne 0 -or $script:CheckOutputDupli -ne 0){$inter = "incl."}else{$inter = "excl."}
    Write-Host "$($inter) additional hash-calc.)..." -ForegroundColor Yellow

    for($i=0;$i -lt $script:allChosenFormats.Length; $i++){
       $files_in += Get-ChildItem -Path $InPath -Filter $script:allChosenFormats[$i] -Recurse:$script:input_recurse -File | ForEach-Object {
            Write-Host "$counter " -NoNewline -ForegroundColor Gray
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
                hash = $(if($script:DupliCompareHashes -ne 0 -or $script:CheckOutputDupli -ne 0){Get-FileHash -Path $_.FullName -Algorithm SHA1 -ErrorAction Stop | Select-Object -ExpandProperty Hash}else{"ZYX"})
                tocopy = 1
            }
        }
    }
    if($files_in.fullpath -match '[|[]*]'){
        Write-Host "Files with illegal characters detected. Aborting!" -ForegroundColor Red
        Invoke-Close
    }

    Write-Host "`r`n`r`nTotal in-files:`t" -NoNewline -ForegroundColor Yellow
    Write-Host "$($files_in.fullpath.Length)`r`n" -ForegroundColor DarkYellow
    $script:resultvalues.ingoing = $files_in.fullpath.Length
    Invoke-Pause

    # dupli-check via history-file:
    [array]$dupliindex_hist = @()
    if($script:HistoryFile -eq "use"){
        # Comparing Files between History-File and Input-Folder via history-file:
        Write-Host "Comparing to already copied files (history-file).." -ForegroundColor Yellow
        Write-Host "New, " -ForegroundColor Gray -NoNewline
        Write-Host "already existing." -ForegroundColor DarkGreen
        for($i = 0; $i -lt $files_in.fullpath.Length; $i++){
            $j = 0
            while($true){
                # check resemblance between in_files and hist_files:
                if($files_in[$i].inname -eq $HistFiles.name[$j] -and $files_in[$i].date -eq $HistFiles.date[$j] -and $files_in[$i].size -eq $HistFiles.size[$j] -and ($script:DupliCompareHashes -eq 1 -and $files_in[$i].hash -eq $HistFiles.Hash[$j] -or $script:DupliCompareHashes -eq 0)){
                    Write-Host "$($i + 1) " -NoNewline -ForegroundColor DarkGreen
                    $dupliindex_hist += $i
                    $files_in[$i].tocopy = 0
                    break
                }else{
                    if($j -ge $HistFiles.name.Length){
                        Write-Host "$($i + 1) " -NoNewline -ForegroundColor Gray
                        break
                    }
                    $j++
                    continue
                }
                
            }
        }
        if($script:debug -ne 0){
            Write-Host "`r`n`r`nFiles to " -NoNewline -ForegroundColor Yellow
            Write-Host "skip " -NoNewline -ForegroundColor DarkGreen
            Write-Host "/" -NoNewline
            Write-Host " process" -NoNewline -ForegroundColor Gray
            Write-Host " (after history-check):" -ForegroundColor Yellow
            $indent = 0
            for($i = 0; $i -lt $files_in.fullpath.Length; $i++){
                if($i -notin $dupliindex_hist){
                    $inter = ($($files_in.fullpath[$i]).Replace($InPath,'.'))
                    Write-Host "$inter`t`t" -NoNewline -ForegroundColor Gray
                    $indent++
                    if($indent -ge 2){
                        Write-Host "`r`n" -NoNewline
                        $indent = 0
                    }
                }else{
                    $inter = ($($files_in.fullpath[$i]).Replace($InPath,'.'))
                    Write-Host "$inter`t`t" -NoNewline -ForegroundColor DarkGreen
                    $indent++
                    if($indent -ge 2){
                        Write-Host "`r`n" -NoNewline
                        $indent = 0
                    }
                }
            }
        }
    }else{
        Write-Host "`r`nNo history-file -> no files to skip." -ForegroundColor Yellow
    }
    Write-Host "`r`n`r`nTotal in-files: $($files_in.name.Length)`t" -ForegroundColor Gray -NoNewline
    Write-Host "- Files to skip: $($dupliindex_hist.Length)`t" -NoNewline -ForegroundColor DarkGreen
    Write-Host "- Files left after history-check: $($files_in.name.Length - $dupliindex_hist.Length)" -ForegroundColor Yellow
    $script:resultvalues.duplihist = $dupliindex_hist.Length
    Invoke-Pause

    # dupli-check via output-folder:
    [array]$dupliindex_out = @()
    if($script:CheckOutputDupli -ne 0){
        Write-Host "`r`nAdditional comparison to already existing files in the output-path - " -ForegroundColor Yellow
        [int]$counter = 1
        Write-Host "Find files in $OutPath..." -ForegroundColor Yellow
        for($i=0;$i -lt $script:allChosenFormats.Length; $i++){
            $script:files_duplicheck += Get-ChildItem -Path $OutPath -Filter $script:allChosenFormats[$i] -Recurse -File | ForEach-Object {
                Write-Host "$counter " -NoNewline -ForegroundColor Gray
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
        if($script:files_duplicheck.fullpath.Length -ne 0){
            Write-Host "Comparing to files in out-path..." -ForegroundColor Yellow
            Write-Host "New, " -ForegroundColor Gray -NoNewline
            Write-Host "already existing." -ForegroundColor DarkGreen
            for($i = 0; $i -lt $files_in.fullpath.Length; $i++){
                if($files_in[$i].tocopy -eq 1){
                    $j = 0
                    while($true){
                        # calculate hash only if date and size are the same:
                        if($($files_in[$i].date) -eq $($script:files_duplicheck[$j].date) -and $($files_in[$i].size) -eq $($script:files_duplicheck[$j].size)){
                            $script:files_duplicheck[$j].hash = (Get-FileHash -Path $script:files_duplicheck.fullpath[$j] -Algorithm SHA1 | Select-Object -ExpandProperty Hash)
                            if($files_in[$i].hash -eq $script:files_duplicheck[$j].hash){
                                $dupliindex_out += $i
                                Write-Host "$($i + 1) " -NoNewline -ForegroundColor DarkGreen
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
                                Write-Host "$($i + 1) " -NoNewline -ForegroundColor Gray
                                break
                            }
                            $j++
                            continue
                        }
                    }
                }
            }

            if($script:debug -ne 0){
                Write-Host "`r`n`r`nFiles to " -NoNewline -ForegroundColor Yellow
                Write-Host "skip " -NoNewline -ForegroundColor DarkGreen
                Write-Host "/" -NoNewline
                Write-Host " process" -NoNewline -ForegroundColor Gray
                Write-Host " (after out-path-check):" -ForegroundColor Yellow
                $indent = 0
                for($i = 0; $i -lt $script:files_duplicheck.fullpath.Length; $i++){
                    if($i -notin $dupliindex_out){
                        $inter = ($($script:files_duplicheck.fullpath[$i]).Replace($InPath,'.'))
                        Write-Host "$inter`t`t" -NoNewline -ForegroundColor Gray
                        $indent++
                        if($indent -ge 2){
                            Write-Host "`r`n" -NoNewline
                            $indent = 0
                    }
                    }else{
                        
                        $inter = ($($script:files_duplicheck.fullpath[$i]).Replace($InPath,'.'))
                        Write-Host "$inter`t`t" -NoNewline -ForegroundColor DarkGreen
                        $indent++
                        if($indent -ge 2){
                            Write-Host "`r`n" -NoNewline
                            $indent = 0
                        }
                    }
                }
            }
        }else{
            Write-Host "No files in $OutPath - skipping additional verification." -ForegroundColor Magenta
        }
    }
    Write-Host "`r`n`r`nTotal in-files: $($files_in.name.Length)`t" -ForegroundColor Gray -NoNewline
    Write-Host "- Files to skip: $($dupliindex_hist.Length + $dupliindex_out.Length)`t" -NoNewline -ForegroundColor DarkGreen
    Write-Host "- Files left after history-check: $($files_in.name.Length - $dupliindex_hist.Length - $dupliindex_out.Length)" -ForegroundColor Yellow
    $script:resultvalues.dupliout = $dupliindex_out.Length
    Invoke-Pause

    # calculate hash (if not yet done), get index of files,...
    if($script:DupliCompareHashes -eq 0 -and $script:CheckOutputDupli -eq 0){
        Write-Host "Calculating hashes for files to copy: " -ForegroundColor Yellow
        for($i = 0; $i -lt $files_in.hash.Length; $i++){
            if($files_in[$i].tocopy -eq 1){
                Write-Host "$($i + 1) " -NoNewline -ForegroundColor Gray
                $files_in[$i].hash = (Get-FileHash -Path $files_in[$i].fullpath -Algorithm SHA1 | Select-Object -ExpandProperty Hash)
            }
        }
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
    Write-Host "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")" -NoNewline
    Write-Host "`t- Prevent overwriting existing files in $OutPath ..." -ForegroundColor Cyan

    [array]$allpaths = @()

    for($i=0; $i -lt $InFiles.fullpath.Length; $i++){
        if($InFiles.tocopy -eq 1){
            # create outpath:
            $InFiles[$i].outpath = "$OutPath$($InFiles[$i].sub_date)"
            $InFiles[$i].outbasename = $InFiles[$i].basename
            # check for files with same name from input:
            [int]$j = 1
            [int]$k = 1
            while($true){
                [string]$check = "$($InFiles[$i].outpath)\$($InFiles[$i].outname)"
                if($check -notin $allpaths -and (Test-Path -Path $check -PathType Leaf) -eq $false){
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
                    # if($script:debug -ne 0){Write-Host $InFiles[$i].outbasename}
                    continue
                }elseif((Test-Path -Path $check -PathType Leaf) -eq $true){
                    if($k -eq 1){
                        $InFiles[$i].outbasename = "$($InFiles[$i].outbasename)_OutCopy$k"
                    }else{
                        $InFiles[$i].outbasename = $InFiles[$i].outbasename -replace "_OutCopy$($k - 1)","_OutCopy$k"
                    }
                    $InFiles[$i].outname = "$($InFiles[$i].outbasename)$($InFiles[$i].extension)"
                    $k++
                    # if($script:debug -ne 0){Write-Host $InFiles[$i].outbasename}
                    continue
                }
            }
            if($script:debug -ne 0){
                Write-Host "$($InFiles[$i].outpath)\$($InFiles[$i].outname)"
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

    Write-Host "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")" -NoNewline
    if($script:OutputSubfolderStyle -eq "none"){
        Write-Host "`t- Copy files from $InPath to $($OutPath)..." -ForegroundColor Cyan
    }else{
        Write-Host "`t- Copy files from $InPath to $OutPath\$($script:OutputSubfolderStyle)..." -ForegroundColor Cyan
    }

    $InFiles = $InFiles | Sort-Object -Property inpath,outpath

    # setting up robocopy:
    [array]$rc_command = @()
    [string]$rc_suffix = " /R:5 /W:15 /MT:4 /NJH /NC /J"
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
        Write-Host "`r`nROBOCOPY:"
        foreach($i in $rc_command){Write-Host $i}
        Write-Host "`r`nXCOPY:"
        foreach($i in $xc_command){Write-Host $i}
        Invoke-Pause
    }

    # start robocopy:
    for($i=0; $i -lt $rc_command.Length; $i++){
        Start-Process robocopy -ArgumentList $rc_command[$i] -Wait -NoNewWindow
    }

    # start xcopy:
    $activeProcessCounter = 0
    for($i = 0; $i -lt $xc_command.Length; $i++){
        # Only allow 4 instances of xcopy simultaneously:
        while($activeProcessCounter -ge 4){
            $activeProcessCounter = @(Get-Process -ErrorAction SilentlyContinue -Name xcopy).count
            Start-Sleep -Milliseconds 25
        }
        Write-Host "$($i + 1)/$($xc_command.Length):`t" -NoNewLine
        $inter = $xc_command[$i].replace($xc_suffix,'').replace($OutputPath,'.').replace($InPath,'.')
        Write-Host $inter
        Start-Process xcopy -ArgumentList $xc_command[$i] -WindowStyle Hidden
        Start-Sleep -Milliseconds 1
        $activeProcessCounter++
    }

    # When finished copying, wait until all xcopy-instances are done:
    while($activeProcessCounter -gt 0){
        $activeProcessCounter = @(Get-Process -ErrorAction SilentlyContinue -Name xcopy).count
        Start-Sleep -Milliseconds 25
    }
    Start-Sleep -Milliseconds 250
}

# DEFINITION: Verify newly copied files
Function Start-FileVerification(){
    param(
        [array]$InFiles
    )
    Write-Host "`r`n$(Get-Date -Format "dd.MM.yy HH:mm:ss")" -NoNewline
    Write-Host "`t- Verify newly copied files..." -ForegroundColor Cyan

    for($i = 0; $i -lt $InFiles.fullpath.Length; $i++){
        if($InFiles[$i].tocopy -eq 1){
            $inter = "$($InFiles[$i].outpath)\$($InFiles[$i].outname)"
            if((Test-Path -Path $inter -PathType Leaf) -eq $true){
                if($InFiles[$i].hash -ne $(Get-FileHash -Path $inter -Algorithm SHA1 | Select-Object -ExpandProperty Hash)){
                    Write-Host "$($i + 1) " -NoNewline -ForegroundColor Red
                    Rename-Item -Path $inter -NewName "$($inter)_broken"
                }else{
                    Write-Host "$($i + 1) " -NoNewline -ForegroundColor DarkGreen
                    $InFiles[$i].tocopy = 0
                    if((Test-Path -Path "$($InFiles[$i].outpath)\$($InFiles[$i].outname)_broken" -PathType Leaf) -eq $true){
                        Remove-Item -Path "$($InFiles[$i].outpath)\$($InFiles[$i].outname)_broken"
                    }
                }
            }else{
                Write-Host "$($i + 1)" -NoNewline -ForegroundColor White -BackgroundColor Red; Write-Host " " -NoNewline
                New-Item -Path "$($inter)_broken" | Out-Null
            }
        }
    }
    if(1 -in $InFiles.tocopy){
        Write-Host "`r`n`r`nBROKEN FILE(S):" -ForegroundColor Red
        for($i = 0; $i -lt $InFiles.tocopy.Length; $i++){
            if(1 -eq $InFiles[$i].tocopy){
                Write-Host $InFiles[$i].fullpath
            }
        }
        Write-Host " "
    }Else{
        Write-Host "`r`n`r`nAll files successfully verified!`r`n" -ForegroundColor Green
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
Function Set-Historyfile(){
    param(
        [array]$InFiles,
        [string]$HistFilePath="$PSScriptRoot\media_copytool_filehistory.json"
    )
    Write-Host "$(Get-Date -Format "dd.MM.yy HH:mm:ss")" -NoNewline
    Write-Host "`t- Write attributes of successfully copied files to history-file..." -ForegroundColor Cyan

    $results = ($InFiles | Where-Object {$_.tocopy -eq 0 -and $_.hash -ne "ZYX"} | Select-Object -Property inname,date,size,hash)

    if($script:HistoryFile -ne "delete"){
        $JSON = Get-Content -Path $HistFilePath -Raw | ConvertFrom-Json
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
        $results | Out-File -FilePath $HistFilePath -Encoding utf8
    }
    catch{
        Write-Host "Writing to history-file failed! Trying again..." -ForegroundColor Red
        Pause
        Continue
    }
}

# DEFINITION: Pause the programme if debug-var is active.
Function Invoke-Pause(){
    if($script:debug -eq 2){Pause}
}

# DEFINITION: Exit the program (and close all windows) + option to pause before exiting.
Function Invoke-Close(){
    $script:Form.Close()
    Set-Location $PSScriptRoot
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
    [string]$preventStandbyFile = "$PSScriptRoot\media_copytool_progress.txt"
    while($true){
        # Clear-Host
        Write-Host "    Welcome to Flo's Media-Copytool! // Willkommen bei Flos Media-Copytool!    " -ForegroundColor DarkCyan -BackgroundColor Gray
        Write-Host "                          v0.5 ALPHA - 24.7.2017                               `r`n" -ForegroundColor DarkCyan -BackgroundColor Gray
        if((Get-UserValues) -eq $false){
            Start-Sound(0)
            Start-Sleep -Seconds 2
            if($script:GUI_CLI_Direct -eq "GUI"){
                $script:Form.WindowState ='Normal'
            }
            break
        }
        Invoke-Pause
        iF($script:RememberInPath -ne 0 -or $script:RememberOutPath -ne 0 -or $script:RememberMirrorPath -ne 0 -or $script:RememberSettings -ne 0){
            Start-Remembering
            Invoke-Pause
        }
        if($script:PreventStandby -eq 1){
            "0" | Out-File -FilePath $preventStandbyFile -Encoding utf8
            if((Test-Path -Path $PSScriptRoot\preventsleep.ps1) -eq $true){
                Start-Process powershell -ArgumentList "$PSScriptRoot\preventsleep.ps1 -fileToCheck `"$preventStandbyFile`" -mode 0 -userProcessCount 2 -userProcess `"xcopy`",`"robocopy`" -timeBase 150 -shutdown 0 -counterMax 5" -WindowStyle Hidden
            }else{
                Write-Host "Couldn't find .\preventsleep.ps1, so can't prevent standby." -ForegroundColor Magenta
                Start-Sleep -Seconds 3
            }
        }
        if($script:debug -lt 3){
            $histfiles = Get-Historyfile
            Invoke-Pause
            $inputfiles = (Start-FileSearchAndCheck -InPath $script:InputPath -OutPath $script:OutputPath -HistFiles $histfiles)
            Invoke-Pause
            if(1 -notin $inputfiles.tocopy){
                Write-Host "0 files left to copy - aborting rest of the script." -ForegroundColor Magenta
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
                    Write-Host "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                    if((Read-Host "`"1`" (w/o quotes) for `"yes`", other number for `"no`"") -ne 1){
                        Write-Host "Aborting." -ForegroundColor Cyan
                        Start-Sleep -Seconds 2
                        if($script:GUI_CLI_Direct -eq "GUI"){
                            $script:Form.WindowState ='Normal'
                        }
                        break
                    }
                }
                $inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -OutPath $script:OutputPath)
                Invoke-Pause
                Start-FileCopy -InFiles $inputfiles -InPath $script:InputPath -OutPath $script:OutputPath
                Invoke-Pause
                $inputfiles = (Start-FileVerification -InFiles $inputfiles)
                Invoke-Pause
                $j++
            }
            if($script:WriteHist -eq 1){
                Set-Historyfile -InFiles $inputfiles
                Invoke-Pause
            }
            if($script:MirrorEnable -ne 0){
                Write-Host "MIRRORING"
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
                Write-Host "BLA"
                $j = 1
                while(1 -in $inputfiles.tocopy){
                    if($j -gt 1){
                        Write-Host "Some of the copied files are corrupt. Attempt re-copying them?" -ForegroundColor Magenta
                        if((Read-Host "`"1`" (w/o quotes) for `"yes`", other number for `"no`"") -ne 1){
                            break
                        }
                    }
                    $inputfiles = (Start-OverwriteProtection -InFiles $inputfiles -OutPath $script:MirrorPath)
                    Invoke-Pause
                    Start-FileCopy -InFiles $inputfiles -InPath $script:OutputPath -OutPath $script:MirrorPath
                    Invoke-Pause
                    $inputfiles = (Start-FileVerification -InFiles $inputfiles)
                    Invoke-Pause
                    $j++
                }
            }
        }else{
            Write-Host "-Debug 3 not defined at the moment."
        }
        break
    }

    # $script:resultvalues.unverified
    Write-Host "`r`nStats:" -ForegroundColor DarkCyan
    Write-Host "Found:`t`t$($script:resultvalues.ingoing)`tfiles." -ForegroundColor Cyan
    Write-Host "Skipped:`t$($script:resultvalues.duplihist) (history) + $($script:resultvalues.dupliout) (out-path)`tfiles." -ForegroundColor DarkGreen
    Write-Host "Copied: `t$($script:resultvalues.copyfiles)`tfiles." -ForegroundColor Yellow
    Write-Host "Verified:`t$($script:resultvalues.verified)`tfiles." -ForegroundColor Green
    Write-Host "Unverified:`t$($script:resultvalues.unverified)`tfiles.`r`n" -ForegroundColor DarkRed
    if($script:resultvalues.unverified -eq 0){
        Start-Sound(1)
    }else{
        Start-Sound(0)
    }
    
    if($script:PreventStandby -eq 1){
        "1" | Out-File -FilePath $preventStandbyFile -Encoding utf8
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
    # CREDIT: code (except from content of inputXML and small modifications) by
    # https://foxdeploy.com/series/learning-gui-toolmaking-series/
$inputXML = @"
<Window x:Class="MediaCopytool.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        mc:Ignorable="d"
        Title="Flo's Media-Copytool v0.5 ALPHA" Height="276" Width="800" ResizeMode="CanMinimize">
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
            <ComboBoxItem Content=" - - - Preset formats to copy - - - "/>
            <CheckBox x:Name="checkBoxCan" Content="Canon - CR2"/>
            <CheckBox x:Name="checkBoxNik" Content="Nikon - NEF, NRW"/>
            <CheckBox x:Name="checkBoxSon" Content="Sony - ARW"/>
            <CheckBox x:Name="checkBoxJpg" Content="JPEG - JPG, JPEG"/>
            <CheckBox x:Name="checkBoxMov" Content="Movies - MOV, MP4"/>
            <CheckBox x:Name="checkBoxAud" Content="Audio - WAV, MP3, M4A"/>
        </ComboBox>
        <CheckBox x:Name="checkBoxCustom" Content="Custom:" ToolTip="Enable to copy customised file-formats." HorizontalAlignment="Left" Margin="50,159,0,0" VerticalAlignment="Top" VerticalContentAlignment="Center" Height="22" Padding="4,-2,0,0"/>
        <TextBox x:Name="textBoxCustom" Text="custom-formats" ToolTip="*.ext1,*.ext2,*.ext3 - Brackets [ ] lead to errors!"  HorizontalAlignment="Left" Height="22" Margin="120,158,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="140" VerticalContentAlignment="Center" VerticalScrollBarVisibility="Disabled"/>
        <TextBlock x:Name="textBlockOutSubStyle" Text="Subfolder-Style:" HorizontalAlignment="Center" Margin="0,129,140,0" VerticalAlignment="Top" Width="90" TextAlignment="Right"/>
        <ComboBox x:Name="comboBoxOutSubStyle" ToolTip="Choose your favorite subfolder-style." HorizontalAlignment="Center" Margin="100,126,0,0" VerticalAlignment="Top" Width="120" SelectedIndex="1" Height="23" VerticalContentAlignment="Center">
            <ComboBoxItem Content="No subfolders"/>
            <ComboBoxItem Content="yyyy-mm-dd" ToolTip="e.g.: 2017-12-31"/>
            <ComboBoxItem Content="yyyy_mm_dd" ToolTip="e.g.: 2017_12_31" Width="120"/>
            <ComboBoxItem Content="yy-mm-dd" ToolTip="e.g.: 17-12-31"/>
            <ComboBoxItem Content="yy_mm_dd" ToolTip="e.g.: 17_12_31"/>
        </ComboBox>
        <TextBlock x:Name="textBlockHistFile" Text="History-File:" HorizontalAlignment="Center" Margin="0,162,140,0" VerticalAlignment="Top" Width="90" TextAlignment="Right" Height="16"/>
        <ComboBox x:Name="comboBoxHistFile" HorizontalAlignment="Center" Margin="100,158,0,0" VerticalAlignment="Top" Width="120" SelectedIndex="0" Height="22" VerticalContentAlignment="Center">
            <ComboBoxItem Content="Use"/>
            <ComboBoxItem Content="Delete (before)" ToolTip="Deletes the history-file before copying. w/o additional verification possible to duplicate files. Best practise: use after formatting card."/>
            <ComboBoxItem Content="Ignore" ToolTip="If you want duplicates, but you want to keep the history-file."/>
        </ComboBox>
        <ComboBox x:Name="comboBoxOptions" HorizontalAlignment="Right" Margin="0,126,50,0" VerticalAlignment="Top" Width="200" SelectedIndex="0" VerticalContentAlignment="Center">
            <ComboBoxItem Content="Select some options"/>
            <CheckBox x:Name="checkBoxInSubSearch" Content="Include subfolders in in-path" ToolTip="E.g. not only searching files in E:\DCIM, but also in E:\DCIM\abc"/>
            <CheckBox x:Name="checkBoxCheckInHash" Content="Check hashes of in-files (slow)" ToolTip="For history-check: If unchecked, dupli-check is done via name, size, date. If checked, hash is added. Dupli-Check in out-path disables this function."/>
            <CheckBox x:Name="checkBoxOutputDupli" Content="Check for duplis in out-path" ToolTip="Ideal if you have used LR or other import-tools since the last card-formatting."/>
            <CheckBox x:Name="checkBoxWriteHist" Content="Write to history-file" ToolTip="When activated, newly copied files will be added in the history-file." Foreground="#FFFF6800"/>
            <CheckBox x:Name="checkBoxPreventStandby" Content="Prevent standby w/ script" ToolTip="Prevents system from hibernating by starting a small script." Foreground="#FF0080FF"/>
        </ComboBox>
        <CheckBox x:Name="checkBoxRememberSettings" Content=":Remember settings" ToolTip="Remember all parameters (excl. Remember-Params)" HorizontalAlignment="Right" Margin="0,158,50,0" VerticalAlignment="Top" Foreground="#FFC90000" VerticalContentAlignment="Center" HorizontalContentAlignment="Center" Padding="4,-2,0,0" Height="22" FlowDirection="RightToLeft"/>
        <Button x:Name="buttonStart" Content="START" HorizontalAlignment="Center" Margin="0,0,0,20" VerticalAlignment="Bottom" Width="100" IsDefault="True"/>
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
        Write-Host "Unable to load Windows.Markup.XamlReader. Usually this means that you haven't installed .NET Framework. Please download and install the latest .NET Framework Web-Installer for your OS: " -NoNewline -ForegroundColor Red
        Write-Host "https://www.google.com/webhp?q=net+framework+web+installer"
        Write-Host "Alternatively, start this script with '-GUI_CLI_Direct `"CLI`"' (w/o single-quotes) to run it via CLI (find other parameters via '-Help 2' or via README-File ('-Help 1')." -ForegroundColor Yellow
        Pause
        Exit
    }
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}

    if($getWPF -ne 0){
        Write-Host "Found the following interactable elements:`r`n" -ForegroundColor Cyan
        Get-Variable WPF*
        Pause
        Exit
    }

    # Fill the TextBoxes with user parameters:
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
    $WPFcomboBoxHistFile.SelectedIndex = $(if("use" -eq $HistoryFile){0}elseif("delete" -eq $HistoryFile){1}elseif("ignore" -eq $HistoryFile){2})
    $WPFcheckBoxInSubSearch.IsChecked = $InputSubfolderSearch
    $WPFcheckBoxCheckInHash.IsChecked = $DupliCompareHashes
    $WPFcheckBoxOutputDupli.IsChecked = $CheckOutputDupli
    $WPFcheckBoxWriteHist.IsChecked = $WriteHist
    $WPFcheckBoxPreventStandby.IsChecked = $PreventStandby
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
        if((Test-Path -Path "$PSScriptRoot\media_copytool_README_v0-5.rtf") -eq $true){
            Start-Process wordpad.exe -ArgumentList "`"$PSScriptRoot\media_copytool_README_v0-5.rtf`""
        }else{
            Start-Process powershell -ArgumentList "Get-Help $PSCommandPath -detailed" -NoNewWindow -Wait
        }
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
