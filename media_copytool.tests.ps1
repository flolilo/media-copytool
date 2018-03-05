# Comment out the last block of media_copytool (i.e. "Start-up") before running this script!
# Maybe also comment out write-colorout function.

# DEFINITION: Get all error-outputs in English:
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -typename System.Text.UTF8Encoding
    [Console]::OutputEncoding = New-Object -typename System.Text.UTF8Encoding

. $PSScriptRoot\media_copytool.ps1

Describe "Get-Parameters"{
    $TestDrive = "TestDrive:\TEST"
    # DEFINITION: Combine all parameters into a hashtable, then delete the parameter variables:
    BeforeEach {
        [hashtable]$UserParams = @{
            ShowParams = 0
            GUI_CLI_Direct = "direct"
            JSONParamPath = "$TestDrive\In_Test\mc_parameters.json"
            LoadParamPresetName = ""
            SaveParamPresetName = ""
            RememberInPath = 0
            RememberOutPath = 0
            RememberMirrorPath = 0
            RememberSettings = 0
            # DEFINITION: From here on, parameters can be set both via parameters and via JSON file(s).
            InputPath = ""
            OutputPath = ""
            MirrorEnable = -1
            MirrorPath = ""
            PresetFormats = @()
            CustomFormatsEnable = -1
            CustomFormats = @()
            OutputSubfolderStyle = ""
            OutputFileStyle = ""
            HistFilePath = ""
            UseHistFile = -1
            WriteHistFile = ""
            HistCompareHashes = -1
            InputSubfolderSearch = -1
            CheckOutputDupli = -1
            VerifyCopies = -1
            OverwriteExistingFiles = -1
            AvoidIdenticalFiles = -1
            ZipMirror = -1
            UnmountInputDrive = -1
            allChosenFormats = @()
        }
    }
    New-Item -ItemType Directory -Path $TestDrive
    # Expand-Archive $PSScriptRoot\media_copytool_TESTFILES.zip $TestDrive
    Push-Location $TestDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.zip`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    It "First basic test" {
        $test = Get-Parameters -UserParams $UserParams -Renew 1
        $test | Should BeOfType hashtable
    }
    Context "Get JSON-params from multiple specchar-names, test ability to get different presets" {
        It "mc parameters[1] - `"default`" is second preset" {
            $UserParams.JSONParamPath = "$TestDrive\In_Test\mc parameters[1].json"
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName | Should Be "default"
            $test.VerifyCopies | Should Be 999
        }
        It "123456789 - load preset `"12345`"" {
            $UserParams.JSONParamPath = "$TestDrive\In_Test\123456789 ordner\123456789 parameters.json"
            $UserParams.LoadParamPresetName = "12345"
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName | Should Be "12345"
            $test.VerifyCopies | Should Be 999
        }
        It "ÆParameters - preset `"ae`"" {
            $UserParams.JSONParamPath = "$TestDrive\In_Test\ÆOrdner\ÆParameters.json"
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName | Should Be "ae"
        }
        It "backtick" {
            $UserParams.JSONParamPath = "$TestDrive\In_Test\backtick ````ordner ``\backtick ````params``.json"
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName | Should Be "backtick"
        }
        It "bracket - preset `"defaultbracket`"" {
            $UserParams.JSONParamPath = "$TestDrive\In_Test\bracket [ ] ordner\bracket [ ] Parameter.json"
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName | Should Be "defaultbracket"
        }
        It "dots" {
            $UserParams.JSONParamPath = "$TestDrive\In_Test\ordner.mit.punkten\mc.parameters.json"
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName | Should Be "dots"
        }
        It "special" {
            $UserParams.JSONParamPath = "$TestDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . parameter.json"
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName | Should Be "special"
        }
    }
    Context "Check if wrong/no JSON file throws" {
        It "Return false when not finding anything" {
            $UserParams.JSONParamPath = "$TestDrive\In_Test\notthere.json"
            Get-Parameters -UserParams $UserParams -Renew 1 | Should Be $false
        }
        It "Throw error when parameters are of wrong type" {
            {Get-Parameters -UserParams "hallo" -Renew 1} | Should Throw
            {Get-Parameters -UserParams $UserParams -Renew "hallo"} | Should Throw
        }
        It "Throw error with empty params" {
            {Get-Parameters} | Should Throw
            {Get-Parameters -UserParams @{} -Renew 1} | Should Throw
            {Get-Parameters -UserParams $UserParams} | Should Throw
            {Get-Parameters -Renew 1} | Should Throw
        }
        It "Throw error when JSON is empty" {
            $UserParams.JSONParamPath = "$TestDrive\In_Test\mc_parameters - empty.json"
            Get-Parameters  -UserParams $UserParams -Renew 1 | Should Be $false
        }
    }
    Context "Test the returned values" {
        It "InputPath" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).InputPath
            $test | Should BeOfType string
            $test | Should Be "F:\InputPath"
        }
        It "OutputPath" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).OutputPath
            $test | Should BeOfType string
            $test | Should Be "F:\OutputPath"
        }
        It "MirrorEnable" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).MirrorEnable
            $test | Should BeOfType int
            $test | Should Be 101
        }
        It "MirrorPath" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).MirrorPath
            $test | Should BeOfType string
            $test | Should Be "F:\MirrorPath"
        }
        It "PresetFormats" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).PresetFormats
            ,$test | Should BeOfType array
            $test | Should Be @("Preset1","Preset2","Preset3")
        }
        It "CustomFormatsEnable" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).CustomFormatsEnable
            $test | Should BeOfType int
            $test | Should Be 102
        }
        It "CustomFormats" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).CustomFormats
            ,$test | Should BeOfType array
            $test | Should Be @("*stern*","*")
        }
        It "OutputSubfolderStyle" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).OutputSubfolderStyle
            $test | Should BeOfType string
            $test | Should Be "jahrtagmonatOutputSubfolderStyle"
        }
        It "OutputFileStyle" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).OutputFileStyle
            $test | Should BeOfType string
            $test | Should Be "unchangedOutputFileStyle"
        }
        It "HistFilePath" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).HistFilePath
            $test | Should BeOfType string
            $test | Should Be "F:\HistFilePath.json"
        }
        It "UseHistFile" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).UseHistFile
            $test | Should BeOfType int
            $test | Should Be 103
        }
        It "WriteHistFile" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).WriteHistFile
            $test | Should BeOfType string
            $test | Should Be "WriteHistFile"
        }
        It "HistCompareHashes" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).HistCompareHashes
            $test | Should BeOfType int
            $test | Should Be 104
        }
        It "InputSubfolderSearch" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).InputSubfolderSearch
            $test | Should BeOfType int
            $test | Should Be 105
        }
        It "CheckOutputDupli" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).CheckOutputDupli
            $test | Should BeOfType int
            $test | Should Be 106
        }
        It "VerifyCopies" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).VerifyCopies
            $test | Should BeOfType int
            $test | Should Be 107
        }
        It "OverwriteExistingFiles" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).OverwriteExistingFiles
            $test | Should BeOfType int
            $test | Should Be 108
        }
        It "AvoidIdenticalFiles" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).AvoidIdenticalFiles
            $test | Should BeOfType int
            $test | Should Be 109
        }
        It "ZipMirror" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).ZipMirror
            $test | Should BeOfType int
            $test | Should Be 110
        }
        It "UnmountInputDrive" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).UnmountInputDrive
            $test | Should BeOfType int
            $test | Should Be 111
        }
        <# TODO: It "Preventstandby" {
            $test = (Get-Parameters -UserParams $UserParams -Renew 1).Preventstandby
            $test | Should BeOfType int
            $test | Should Be 112
        }#>
    }
}

<#
Describe "Get-UserValues"{
    It "Get values from GUI, then check the main input- and outputfolder"{

    }
}#>

<#
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