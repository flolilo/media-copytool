# Comment out the last block of media_copytool (i.e. "Start-up") before running this script!

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
$TestDrive = "TestDrive:\TEST"
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

. $PSScriptRoot\media_copytool.ps1

Describe "Get-Parameters"{
    New-Item -ItemType Directory -Path $TestDrive
    Expand-Archive $PSScriptRoot\media_copytool_TESTFILES.zip $TestDrive

    It "Get parameters from JSON file"{
        Get-Parameters -JSONPath $JSONParamPath -Renew $Renew
        $VerifyCopies | Should not be -1
    }
}

<#
Describe "Get-UserValues"{
    It "Get values from GUI, then check the main input- and outputfolder"{

    }
}

Describe "Set-Parameters"{
    It "remember values for future use"{

    }
}

Describe "Start-FileSearch"{
    It "Searching for selected formats in Input-Path, getting Path, Name, Time, and calculating Hash"{

    }
}

Describe "Get-HistFile"{
    It "Get History-File"{

    }
}

Describe "Start-DupliCheckHist"{
    It "dupli-check via history-file"{

    }
}

Describe "Start-DupliCheckOut"{
    It "dupli-check via output-folder"{

    }
}

Describe "Start-InputGetHash"{
    It "Calculate hash (if not yet done)"{

    }
}

Describe "Start-PreventingDoubleCopies"{
    It "Avoid copying identical files from the input-path"{

    }
}

Describe "Start-SpaceCheck"{
    It "Check for free space on the destination volume"{
        
    }
}

Describe "Start-OverwriteProtection"{
    It "Check if filename already exists and if so, then choose new name for copying"{
        
    }
}

Describe "Start-FileCopy"{
    It "Copy Files"{

    }
}

Describe "Start-7zip"{
    It "Starting 7zip"{

    }
}

Describe "Start-FileVerification"{
    It "Verify newly copied files"{

    }
}

Describe "Set-HistFile"{
    It "Write new file-attributes to history-file"{

    }
}
#>