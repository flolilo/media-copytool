# Comment out the last block of media_copytool (i.e. "Start-up") before running this script!
# Maybe also comment out write-colorout function.

# DEFINITION: Get all error-outputs in English:
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -typename System.Text.UTF8Encoding
    [Console]::OutputEncoding = New-Object -typename System.Text.UTF8Encoding

. $PSScriptRoot\media_copytool.ps1

<# DONE:    Describe "Get-Parameters" {
        $BlaDrive = "TestDrive:\TEST"
        # DEFINITION: Combine all parameters into a hashtable:
        BeforeEach {
            [hashtable]$UserParams = @{
                ShowParams = 0
                GUI_CLI_Direct = "direct"
                JSONParamPath = "$BlaDrive\In_Test\mc_parameters.json"
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
        New-Item -ItemType Directory -Path $BlaDrive
        Push-Location $BlaDrive
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
        Pop-Location

        It "First basic test" {
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
        }
        Context "Get JSON-params from multiple specchar-names, test ability to get different presets" {
            It "mc parameters[1] - `"default`" is second preset" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\mc parameters[1].json"
                $test = Get-Parameters -UserParams $UserParams -Renew 1
                $test | Should BeOfType hashtable
                $test.LoadParamPresetName | Should Be "default"
                $test.VerifyCopies | Should Be 999
            }
            It "123456789 - load preset `"12345`"" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\123456789 ordner\123456789 parameters.json"
                $UserParams.LoadParamPresetName = "12345"
                $test = Get-Parameters -UserParams $UserParams -Renew 1
                $test | Should BeOfType hashtable
                $test.LoadParamPresetName | Should Be "12345"
                $test.VerifyCopies | Should Be 999
            }
            It "ÆParameters - preset `"ae`"" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\ÆOrdner\ÆParameters.json"
                $test = Get-Parameters -UserParams $UserParams -Renew 1
                $test | Should BeOfType hashtable
                $test.LoadParamPresetName | Should Be "ae"
            }
            It "backtick" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````params``.json"
                $test = Get-Parameters -UserParams $UserParams -Renew 1
                $test | Should BeOfType hashtable
                $test.LoadParamPresetName | Should Be "backtick"
            }
            It "bracket - preset `"defaultbracket`"" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] Parameter.json"
                $test = Get-Parameters -UserParams $UserParams -Renew 1
                $test | Should BeOfType hashtable
                $test.LoadParamPresetName | Should Be "defaultbracket"
            }
            It "dots" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\ordner.mit.punkten\mc.parameters.json"
                $test = Get-Parameters -UserParams $UserParams -Renew 1
                $test | Should BeOfType hashtable
                $test.LoadParamPresetName | Should Be "dots"
            }
            It "special" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . parameter.json"
                $test = Get-Parameters -UserParams $UserParams -Renew 1
                $test | Should BeOfType hashtable
                $test.LoadParamPresetName | Should Be "special"
            }
        }
        Context "Check if wrong/no JSON file throws" {
            It "Return false when not finding anything" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\notthere.json"
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
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\mc_parameters - empty.json"
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
            # TODO: It "Preventstandby" {
                # $test = (Get-Parameters -UserParams $UserParams -Renew 1).Preventstandby
                # $test | Should BeOfType int
                # $test | Should Be 112
            # }
        }
    }
#>

<# TODO: hrmph. get everything right in GUI (in original file!): JSON-loading.
    Describe "Start-GUI" {
        $BlaDrive = "TestDrive:\TEST"
        # DEFINITION: Combine all parameters into a hashtable:
        BeforeEach {
            [hashtable]$UserParams = @{
                ShowParams = 0
                GUI_CLI_Direct = "GUI"
                JSONParamPath = "$BlaDrive\In_Test\mc_parameters.json"
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
        New-Item -ItemType Directory -Path $BlaDrive
        Push-Location $BlaDrive
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
        Pop-Location

        # TODO: check how to auto-close form
        It "Check if returned filetype is correct" {
            $test = Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams -GetXAML 1
            $test | Should BeOfType System.Windows.Window
        }
        It "Throws if parameters are empty" {
            {Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml"} | Should Throw
            {Start-GUI -UserParams $UserParams} | Should Throw
            {Start-GUI -GetXAML 0} | Should Throw
            {Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams} | Should Throw
            {Start-GUI -UserParams $UserParams -GetXAML 0} | Should Throw
            {Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -GetXAML 0} | Should Throw
            {Start-GUI} | Should Throw
        }
        It "Throws if parameters are wrong type" {
            {Start-GUI -GUIPath $null -UserParams $UserParams -GetXAML 1} | Should Throw
            {Start-GUI -GUIPath "" -UserParams $UserParams -GetXAML 1} | Should Throw
            # TODO: {Start-GUI -GUIPath 123 -UserParams $UserParams} | Should Throw
            {Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams 123 -GetXAML 1} | Should Throw
            {Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams @{} -GetXAML 1} | Should Throw
            # TODO: {Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams -GetXAML $null} | Should Throw
            {Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams -GetXAML @()} | Should Throw
            {Start-GUI -GUIPath "$($PSScriptRoot)\mc_GUI.xaml" -UserParams $UserParams -GetXAML "hallo"} | Should Throw
        }
        It "Returns false if GUI file is not found" {
            $test = Start-GUI -GUIPath "$($PSScriptRoot)\NOFILE.xaml" -UserParams $UserParams -GetXAML 1
            $test | Should Be $false
        }
    }
#>
<#    Describe "Get-UserValuesGUI" {
        $BlaDrive = "TestDrive:\TEST"
        # DEFINITION: Combine all parameters into a hashtable:
        BeforeEach {
            [hashtable]$UserParams = @{
                ShowParams = 0
                GUI_CLI_Direct = "GUI"
                JSONParamPath = "$BlaDrive\In_Test\mc_parameters.json"
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
        New-Item -ItemType Directory -Path $BlaDrive
        # Expand-Archive $PSScriptRoot\media_copytool_TESTFILES.7z $BlaDrive
        Push-Location $BlaDrive
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
        Pop-Location

        It ""{
            $test = Get-UserValuesGUI -UserParams $UserParams -GUIParams 
            $test | Should BeOfType hashtable
        }

    }
#>
<# TODO: get a way to test anything about CLI
    Describe "Get-UserValuesCLI"{
        $BlaDrive = "TestDrive:\TEST"
        # DEFINITION: Combine all parameters into a hashtable:
        BeforeEach {
            [hashtable]$UserParams = @{
                ShowParams = 0
                GUI_CLI_Direct = "GUI"
                JSONParamPath = "$BlaDrive\In_Test\mc_parameters.json"
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
        New-Item -ItemType Directory -Path $BlaDrive
        # Expand-Archive $PSScriptRoot\media_copytool_TESTFILES.7z $BlaDrive
        Push-Location $BlaDrive
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
        Pop-Location

        It "Get values from CLI, then check the main input- and outputfolder"{

        }
    }
#>

<# DONE:    Describe "Get-UserValuesDirect" {
        $BlaDrive = "TestDrive:\TEST"
        # DEFINITION: Combine all parameters into a hashtable:
        BeforeEach {
            [hashtable]$UserParams = @{
                ShowParams = 0
                GUI_CLI_Direct = "Direct"
                JSONParamPath = "$BlaDrive\In_Test\mc_parameters.json"
                LoadParamPresetName = "default"
                SaveParamPresetName = "default"
                RememberInPath = 0
                RememberOutPath = 0
                RememberMirrorPath = 0
                RememberSettings = 0
                # DEFINITION: From here on, parameters can be set both via parameters and via JSON file(s).
                InputPath = "$BlaDrive\In_Test"
                OutputPath = "$BlaDrive\Out_Test"
                MirrorEnable = 1
                MirrorPath = "$BlaDrive\Mirr_Test"
                PresetFormats = @("Can")
                CustomFormatsEnable = 0
                CustomFormats = @()
                OutputSubfolderStyle = "yyyy-MM-dd"
                OutputFileStyle = "unchanged"
                HistFilePath = "$BlaDrive\In_Test\mc_hist.json"
                UseHistFile = 0
                WriteHistFile = "no"
                HistCompareHashes = 0
                InputSubfolderSearch = 0
                CheckOutputDupli = 0
                VerifyCopies = 0
                OverwriteExistingFiles = 0
                AvoidIdenticalFiles = 0
                ZipMirror = 0
                UnmountInputDrive = 0
                allChosenFormats = @()
            }
            $script:Preventstandby = 0
        }
        New-Item -ItemType Directory -Path $BlaDrive
        Push-Location $BlaDrive
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
        Pop-Location
        $bla = Get-ChildItem -LiteralPath $BlaDrive -Recurse

        Context "Test the returned values" {
            It "If everything is correct, return hashtable" {
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
            }
            It "InputPath" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).InputPath
                $test | Should BeOfType string
                $test | Should Be "$BlaDrive\In_Test"
            }
            It "InputPath - trailing backslash" {
                $UserParams.InputPath = "$BlaDrive\In_Test\"
                $test = (Get-UserValuesDirect -UserParams $UserParams).InputPath
                $test | Should BeOfType string
                $test | Should Be "$BlaDrive\In_Test"
            }
            It "OutputPath" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).OutputPath
                $test | Should BeOfType string
                $test | Should Be "$BlaDrive\Out_Test"
            }
            It "OutputPath - trailing backslash" {
                $UserParams.OutputPath = "$BlaDrive\Out_Test\"
                $test = (Get-UserValuesDirect -UserParams $UserParams).OutputPath
                $test | Should BeOfType string
                $test | Should Be "$BlaDrive\Out_Test"
            }
            It "MirrorEnable" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).MirrorEnable
                $test | Should BeOfType int
                $test | Should Be 1
            }
            It "MirrorPath" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).MirrorPath
                $test | Should BeOfType string
                $test | Should Be "$BlaDrive\Mirr_Test"
            }
            It "MirrorPath - trailing backslash" {
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\"
                $test = (Get-UserValuesDirect -UserParams $UserParams).MirrorPath
                $test | Should BeOfType string
                $test | Should Be "$BlaDrive\Mirr_Test"
            }
            It "PresetFormats" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).PresetFormats
                ,$test | Should BeOfType array
                $test | Should Be @("Can")
            }
            It "CustomFormatsEnable" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).CustomFormatsEnable
                $test | Should BeOfType int
                $test | Should Be 0
            }
            It "CustomFormats" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).CustomFormats
                ,$test | Should BeOfType array
                $test | Should Be @()
            }
            It "OutputSubfolderStyle" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).OutputSubfolderStyle
                $test | Should BeOfType string
                $test | Should Be "yyyy-MM-dd"
            }
            It "OutputFileStyle" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).OutputFileStyle
                $test | Should BeOfType string
                $test | Should Be "unchanged"
            }
            It "HistFilePath" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).HistFilePath
                $test | Should BeOfType string
                $test | Should Be "$BlaDrive\In_Test\mc_hist.json"
            }
            It "UseHistFile" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).UseHistFile
                $test | Should BeOfType int
                $test | Should Be 0
            }
            It "WriteHistFile" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).WriteHistFile
                $test | Should BeOfType string
                $test | Should Be "no"
            }
            It "HistCompareHashes" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).HistCompareHashes
                $test | Should BeOfType int
                $test | Should Be 0
            }
            It "InputSubfolderSearch" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).InputSubfolderSearch
                $test | Should BeOfType int
                $test | Should Be 0
            }
            It "CheckOutputDupli" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).CheckOutputDupli
                $test | Should BeOfType int
                $test | Should Be 0
            }
            It "VerifyCopies" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).VerifyCopies
                $test | Should BeOfType int
                $test | Should Be 0
            }
            It "OverwriteExistingFiles" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).OverwriteExistingFiles
                $test | Should BeOfType int
                $test | Should Be 0
            }
            It "AvoidIdenticalFiles" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).AvoidIdenticalFiles
                $test | Should BeOfType int
                $test | Should Be 0
            }
            It "ZipMirror" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).ZipMirror
                $test | Should BeOfType int
                $test | Should Be 0
            }
            It "UnmountInputDrive" {
                $test = (Get-UserValuesDirect -UserParams $UserParams).UnmountInputDrive
                $test | Should BeOfType int
                $test | Should Be 0
            }
            # TODO: It "Preventstandby" {
                # $test = (Get-Parameters -UserParams $UserParams -Renew 1).Preventstandby
                # $test | Should BeOfType int
                # $test | Should Be 112
            # }
            It "allChosenFormats" {
                $UserParams.PresetFormats = @("Can","Nik")
                $test = (Get-UserValuesDirect -UserParams $UserParams).allChosenFormats
                ,$test | Should BeOfType array
                $bla = @("*.cr2","*.nef","*.nrw")
                (Compare-Object $bla $test -ErrorAction SilentlyContinue).Count | Should Be 0

                $UserParams.PresetFormats = @("Can")
                $test = (Get-UserValuesDirect -UserParams $UserParams).allChosenFormats
                ,$test | Should BeOfType array
                $bla = @("*.cr2")
                (Compare-Object $bla $test -ErrorAction SilentlyContinue).Count | Should Be 0

                $UserParams.PresetFormats = @()
                $UserParams.CustomFormatsEnable = 0
                Mock Read-Host {Return 1}
                $test = (Get-UserValuesDirect -UserParams $UserParams).allChosenFormats
                ,$test | Should BeOfType array
                $bla = @("*")
                (Compare-Object $bla $test -ErrorAction SilentlyContinue).Count | Should Be 0

                $UserParams.PresetFormats = @()
                $UserParams.CustomFormatsEnable = 1
                Mock Read-Host {Return 1}
                $test = (Get-UserValuesDirect -UserParams $UserParams).allChosenFormats
                ,$test | Should BeOfType array
                $bla = @("*")
                (Compare-Object $bla $test -ErrorAction SilentlyContinue).Count | Should Be 0

                $UserParams.PresetFormats = @()
                $UserParams.CustomFormatsEnable = 1
                $UserParams.CustomFormats = @("*.bla")
                $test = (Get-UserValuesDirect -UserParams $UserParams).allChosenFormats
                ,$test | Should BeOfType array
                $bla = @("*.bla")
                (Compare-Object $bla $test -ErrorAction SilentlyContinue).Count | Should Be 0
            }
        }
        Context "If anything is wrong, return `$false" {
            It "InputPath is non-existing" {
                $UserParams.InputPath = "$BlaDrive\NONE"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "InputPath is too short" {
                $UserParams.InputPath = "A"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "OutputPath same as InputPath" {
                $UserParams.InputPath = "$BlaDrive\In_Test"
                $UserParams.OutputPath = "$BlaDrive\In_Test"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "OutputPath is non-existing" {
                $UserParams.OutputPath = "\\0.0.0.0"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "OutputPath is too short" {
                $UserParams.OutputPath = "A"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "MirrorEnable is wrong" {
                $UserParams.MirrorEnable = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.MirrorEnable = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.MirrorEnable = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "MirrorPath same as InputPath" {
                $UserParams.InputPath = "$BlaDrive\In_Test"
                $UserParams.MirrorPath = "$BlaDrive\In_Test"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "MirrorPath same as OutputPath" {
                $UserParams.MirrorPath = "$BlaDrive\Out_Test"
                $UserParams.OutputPath = "$BlaDrive\Out_Test"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "MirrorPath is non-existing" {
                $UserParams.MirrorEnable = 1
                $UserParams.MirrorPath = "\\0.0.0.0"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "MirrorPath is too short" {
                $UserParams.MirrorEnable = 1
                $UserParams.MirrorPath = "A"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "PresetFormats is wrong" {
                $UserParams.PresetFormats = 123
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.PresetFormats = @()
                Mock Read-Host {return 0}
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.PresetFormats = @("Can","Nik","Soy")
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "CustomFormatsEnable is wrong" {
                $UserParams.CustomFormatsEnable = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.CustomFormatsEnable = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.CustomFormatsEnable = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "CustomFormats is wrong" {
                $UserParams.CustomFormats = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.CustomFormats = 123
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "OutputSubfolderStyle is wrong" {
                $UserParams.OutputSubfolderStyle = "bla"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.OutputSubfolderStyle = "yyymdd"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.OutputSubfolderStyle = 123
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.OutputSubfolderStyle = ""
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "OutputFileStyle is wrong" {
                $UserParams.OutputFileStyle = "bla"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.OutputFileStyle = "yyymdd"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.OutputFileStyle = 123
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.OutputFileStyle = ""
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "UseHistFile is wrong" {
                $UserParams.UseHistFile = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.UseHistFile = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.UseHistFile = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "WriteHistFile is wrong" {
                $UserParams.WriteHistFile = ""
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.WriteHistFile = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.WriteHistFile = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "HistFilePath is wrong" {
                $UserParams.UseHistFile = 1
                $UserParams.HistFilePath = "\\0.0.0.0"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "HistCompareHashes is wrong" {
                $UserParams.HistCompareHashes = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.HistCompareHashes = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.HistCompareHashes = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "InputSubfolderSearch is wrong" {
                $UserParams.InputSubfolderSearch = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.InputSubfolderSearch = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.InputSubfolderSearch = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "CheckOutputDupli is wrong" {
                $UserParams.CheckOutputDupli = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.CheckOutputDupli = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.CheckOutputDupli = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "VerifyCopies is wrong" {
                $UserParams.VerifyCopies = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.VerifyCopies = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.VerifyCopies = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "OverwriteExistingFiles is wrong" {
                $UserParams.OverwriteExistingFiles = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.OverwriteExistingFiles = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.OverwriteExistingFiles = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "AvoidIdenticalFiles is wrong" {
                $UserParams.AvoidIdenticalFiles = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.AvoidIdenticalFiles = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.AvoidIdenticalFiles = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "ZipMirror is wrong" {
                $UserParams.ZipMirror = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.ZipMirror = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.ZipMirror = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "UnmountInputDrive is wrong" {
                $UserParams.UnmountInputDrive = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.UnmountInputDrive = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.UnmountInputDrive = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "script:PreventStandby is wrong" {
                $script:PreventStandby = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $script:PreventStandby = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "RememberInPath is wrong" {
                $UserParams.RememberInPath = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.RememberInPath = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.RememberInPath = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "RememberOutPath is wrong" {
                $UserParams.RememberOutPath = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.RememberOutPath = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.RememberOutPath = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "RememberMirrorPath is wrong" {
                $UserParams.RememberMirrorPath = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.RememberMirrorPath = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.RememberMirrorPath = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
            It "RememberSettings is wrong" {
                $UserParams.RememberSettings = -1
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.RememberSettings = "hallo"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
                $UserParams.RememberSettings = 11
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should Be $false
            }
        }
        It "Throw if no/wrong param is specified" {
            {Get-UserValuesDirect} | Should Throw
            {Get-UserValuesDirect -UserParams "hallo"} | Should Throw
            {Get-UserValuesDirect -UserParams @{}} | Should Throw
        }
        Context "Test Special characters - existing" {
            It "Brackets" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\mc parameters[1].json"
                $UserParams.InputPath = "$BlaDrive\In_Test"
                $UserParams.OutputPath = "$BlaDrive\Out_Test"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\mc hist[1].json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
                $test.JSONParamPath | Should Be $UserParams.JSONParamPath
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                (Compare-Object $bla $(Get-ChildItem -LiteralPath $BlaDrive -Recurse) -ErrorAction SilentlyContinue).count | Should Be 0
            }
            It "12345" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\123456789 ordner\123456789 parameters.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\123456789 ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\123456789 ordner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\123456789 ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\123456789 ordner\123456789 hist.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
                $test.JSONParamPath | Should Be $UserParams.JSONParamPath
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                (Compare-Object $bla $(Get-ChildItem -LiteralPath $BlaDrive -Recurse) -ErrorAction SilentlyContinue).count | Should Be 0
            }
            It "Æ" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\ÆOrdner\ÆParameters.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\ÆOrdner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\ÆOrdner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\ÆOrdner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\ÆOrdner\Æhist.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
                $test.JSONParamPath | Should Be $UserParams.JSONParamPath
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                (Compare-Object $bla $(Get-ChildItem -LiteralPath $BlaDrive -Recurse) -ErrorAction SilentlyContinue).count | Should Be 0
            }
            It "backtick" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````params``.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\backtick ````ordner ``"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\backtick ````ordner ``"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\backtick ````ordner ``"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````hist``.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
                $test.JSONParamPath | Should Be $UserParams.JSONParamPath
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                (Compare-Object $bla $(Get-ChildItem -LiteralPath $BlaDrive -Recurse) -ErrorAction SilentlyContinue).count | Should Be 0
            }
            It "bracket 2" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] Parameter.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\bracket [ ] ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\bracket [ ] ordner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\bracket [ ] ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] hist.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
                $test.JSONParamPath | Should Be $UserParams.JSONParamPath
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                (Compare-Object $bla $(Get-ChildItem -LiteralPath $BlaDrive -Recurse) -ErrorAction SilentlyContinue).count | Should Be 0
            }
            It "dots" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\ordner.mit.punkten\mc.parameters.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\ordner.mit.punkten"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\ordner.mit.punkten"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\ordner.mit.punkten"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\ordner.mit.punkten\mc.hist.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
                $test.JSONParamPath | Should Be $UserParams.JSONParamPath
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                (Compare-Object $bla $(Get-ChildItem -LiteralPath $BlaDrive -Recurse) -ErrorAction SilentlyContinue).count | Should Be 0
            }
            It "specials" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . parameter.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\special ' ! ,; . ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\special ' ! ,; . ordner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\special ' ! ,; . ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . hist.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
                $test.JSONParamPath | Should Be $UserParams.JSONParamPath
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                (Compare-Object $bla $(Get-ChildItem -LiteralPath $BlaDrive -Recurse) -ErrorAction SilentlyContinue).count | Should Be 0
            }
        }
        Context "Test Special characters - non-existing" {
            Get-ChildItem "$BlaDrive\Out_Test" -Recurse | Remove-Item
            Get-ChildItem "$BlaDrive\Mirr_Test" -Recurse | Remove-Item
            (Get-ChildItem "$BlaDrive\Out_Test" -Recurse -ErrorAction SilentlyContinue).Count | Out-Host
            (Get-ChildItem "$BlaDrive\Mirr_Test" -Recurse -ErrorAction SilentlyContinue).Count | Out-Host
            It "Brackets" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\mc parameters[1].json"
                $UserParams.InputPath = "$BlaDrive\In_Test"
                $UserParams.OutputPath = "$BlaDrive\Out_Test"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\mc hist[1].json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
            }
            It "12345" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\123456789 ordner\123456789 parameters.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\123456789 ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\123456789 ordner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\123456789 ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\123456789 ordner\123456789 hist.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
            }
            It "Æ" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\ÆOrdner\ÆParameters.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\ÆOrdner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\ÆOrdner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\ÆOrdner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\ÆOrdner\Æhist.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
            }
            It "backtick" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````params``.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\backtick ````ordner ``"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\backtick ````ordner ``"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\backtick ````ordner ``"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````hist``.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
            }
            It "bracket 2" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] Parameter.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\bracket [ ] ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\bracket [ ] ordner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\bracket [ ] ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] hist.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
            }
            It "dots" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\ordner.mit.punkten\mc.parameters.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\ordner.mit.punkten"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\ordner.mit.punkten"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\ordner.mit.punkten"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\ordner.mit.punkten\mc.hist.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
            }
            It "specials" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . parameter.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\special ' ! ,; . ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\special ' ! ,; . ordner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\special ' ! ,; . ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . hist.json"
                $test = Get-UserValuesDirect -UserParams $UserParams
                $test | Should BeOfType hashtable
            }
            It "Created all folders" {
                (Compare-Object $bla $(Get-ChildItem -LiteralPath $BlaDrive -Recurse) -ErrorAction SilentlyContinue).count | Should Be 0
            }
        }
    }
#>
<# DONE:    Describe "Show-Parameters" {
        BeforeEach {
            [hashtable]$UserParams = @{
                ShowParams = 0
                GUI_CLI_Direct = "Direct"
                JSONParamPath = "$BlaDrive\In_Test\mc_parameters.json"
                LoadParamPresetName = "default"
                SaveParamPresetName = "default"
                RememberInPath = 0
                RememberOutPath = 0
                RememberMirrorPath = 0
                RememberSettings = 0
                # DEFINITION: From here on, parameters can be set both via parameters and via JSON file(s).
                InputPath = "$BlaDrive\In_Test"
                OutputPath = "$BlaDrive\Out_Test"
                MirrorEnable = 1
                MirrorPath = "$BlaDrive\Mirr_Test"
                PresetFormats = @("Can")
                CustomFormatsEnable = 0
                CustomFormats = @()
                OutputSubfolderStyle = "yyyy-MM-dd"
                OutputFileStyle = "unchanged"
                HistFilePath = "$BlaDrive\In_Test\mc_hist.json"
                UseHistFile = 0
                WriteHistFile = "no"
                HistCompareHashes = 0
                InputSubfolderSearch = 0
                CheckOutputDupli = 0
                VerifyCopies = 0
                OverwriteExistingFiles = 0
                AvoidIdenticalFiles = 0
                ZipMirror = 0
                UnmountInputDrive = 0
                allChosenFormats = @()
            }
            $script:Preventstandby = 0
        }
        It "Throws when no/wrong param" {
            {Show-Parameters} | Should Throw
            {Show-Parameters -UserParams @{}} | Should Throw
            {Show-Parameters -UserParams 123} | Should Throw
        }
        It "Does not throw when param is correct" {
            {Show-Parameters -UserParams $UserParams} | Should not Throw
        }
        Context "No problems with SpecChars" {
            It "Brackets" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\mc parameters[1].json"
                $UserParams.InputPath = "$BlaDrive\In_Test"
                $UserParams.OutputPath = "$BlaDrive\Out_Test"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\mc hist[1].json"
                {Show-Parameters -UserParams $UserParams} | Should not Throw
            }
            It "12345" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\123456789 ordner\123456789 parameters.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\123456789 ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\123456789 ordner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\123456789 ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\123456789 ordner\123456789 hist.json"
                {Show-Parameters -UserParams $UserParams} | Should not Throw
            }
            It "Æ" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\ÆOrdner\ÆParameters.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\ÆOrdner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\ÆOrdner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\ÆOrdner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\ÆOrdner\Æhist.json"
                {Show-Parameters -UserParams $UserParams} | Should not Throw
            }
            It "backtick" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````params``.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\backtick ````ordner ``"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\backtick ````ordner ``"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Tes\backtick ````ordner ``t"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````hist``.json"
                {Show-Parameters -UserParams $UserParams} | Should not Throw
            }
            It "bracket 2" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] Parameter.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\bracket [ ] ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\bracket [ ] ordner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\bracket [ ] ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] hist.json"
                {Show-Parameters -UserParams $UserParams} | Should not Throw
            }
            It "dots" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\ordner.mit.punkten\mc.parameters.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\ordner.mit.punkten"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\ordner.mit.punkten"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\ordner.mit.punkten"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\ordner.mit.punkten\mc.hist.json"
                {Show-Parameters -UserParams $UserParams} | Should not Throw
            }
            It "specials" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . parameter.json"
                $UserParams.InputPath = "$BlaDrive\In_Test\special ' ! ,; . ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\special ' ! ,; . ordner"
                $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\special ' ! ,; . ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . hist.json"
                {Show-Parameters -UserParams $UserParams} | Should not Throw
            }
        }
    }
#>
<# DONE:    Describe "Set-Parameters" {
        $BlaDrive = "TestDrive:\TEST"
        BeforeEach {
            [hashtable]$UserParams = @{
                JSONParamPath = "$TestDrive\TEST\In_Test\mc_parameters.json"
                SaveParamPresetName = "default"
                RememberInPath = 1
                RememberOutPath = 1
                RememberMirrorPath = 1
                RememberSettings = 1
                InputPath = "$BlaDrive\In_Test"
                OutputPath = "$BlaDrive\Out_Test"
                MirrorEnable = 1
                MirrorPath = "$BlaDrive\Mirr_Test"
                PresetFormats = @("Can","Franz")
                CustomFormatsEnable = 987
                CustomFormats = @()
                OutputSubfolderStyle = "yyyy-MM-ddlala"
                OutputFileStyle = "unchangedlala"
                HistFilePath = "$BlaDrive\In_Test\mc_hist.json"
                UseHistFile = 987
                WriteHistFile = "maybe"
                HistCompareHashes = 987
                InputSubfolderSearch = 987
                CheckOutputDupli = 987
                VerifyCopies = 987
                OverwriteExistingFiles = 987
                AvoidIdenticalFiles = 987
                ZipMirror = 987
                UnmountInputDrive = 987
                allChosenFormats = @("*.franz")
            }
            $script:Preventstandby = 987
        }
        New-Item -ItemType Directory -Path $BlaDrive
        Push-Location $BlaDrive
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
        Pop-Location

        It "Throws when no/wrong param" {
            {Set-Parameters} | Should Throw
            {Set-Parameters -UserParams @{}} | Should Throw
            {Set-Parameters -UserParams 123} | Should Throw
        }
        It "Returns `$false if JSON cannot be made" {
            $UserParams.JSONParamPath = "\\0.0.0.0\mc_parameters.json"
            $test = Set-Parameters -UserParams $UserParams
            $test | Should Be $false
        }
        Context "Work correctly with valid param" {
            It "Return `$true when param is correct" {
                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true
            }
            It "Replace `"default`"" {
                $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                ,$test | Should BeOfType array
                $bla = @("default","default2","privat","professionell","projekte")
                (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0
                $test.ParamPresetValues[0].InputPath | Should Be $UserParams.InputPath
                $test.ParamPresetValues[0].OutputPath | Should Be $UserParams.OutputPath
                $test.ParamPresetValues[0].MirrorEnable | Should Be $UserParams.MirrorEnable
                $test.ParamPresetValues[0].MirrorPath | Should Be $UserParams.MirrorPath
                $test.ParamPresetValues[0].PresetFormats | Should Be $UserParams.PresetFormats
                $test.ParamPresetValues[0].CustomFormatsEnable | Should Be $UserParams.CustomFormatsEnable
                $test.ParamPresetValues[0].CustomFormats | Should Be $UserParams.CustomFormats
                $test.ParamPresetValues[0].OutputSubfolderStyle | Should Be $UserParams.OutputSubfolderStyle
                $test.ParamPresetValues[0].OutputFileStyle | Should Be $UserParams.OutputFileStyle
                $test.ParamPresetValues[0].HistFilePath | Should Be $UserParams.HistFilePath
                $test.ParamPresetValues[0].UseHistFile | Should Be $UserParams.UseHistFile
                $test.ParamPresetValues[0].WriteHistFile | Should Be $UserParams.WriteHistFile
                $test.ParamPresetValues[0].HistCompareHashes | Should Be $UserParams.HistCompareHashes
                $test.ParamPresetValues[0].InputSubfolderSearch | Should Be $UserParams.InputSubfolderSearch
                $test.ParamPresetValues[0].CheckOutputDupli | Should Be $UserParams.CheckOutputDupli
                $test.ParamPresetValues[0].VerifyCopies | Should Be $UserParams.VerifyCopies
                $test.ParamPresetValues[0].OverwriteExistingFiles | Should Be $UserParams.OverwriteExistingFiles
                $test.ParamPresetValues[0].AvoidIdenticalFiles | Should Be $UserParams.AvoidIdenticalFiles
                $test.ParamPresetValues[0].ZipMirror | Should Be $UserParams.ZipMirror
                $test.ParamPresetValues[0].UnmountInputDrive | Should Be $UserParams.UnmountInputDrive
                $test.ParamPresetValues[0].Preventstandby | Should Be $script:Preventstandby
            }
            It "Add `"BLA`"" {
                $UserParams.SaveParamPresetName = "BLA"

                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true

                $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                $bla = @("default","default2","privat","professionell","projekte","BLA")
                (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

                $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
                $test = $test.ParamPresetValues
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorEnable | Should Be $UserParams.MirrorEnable
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.PresetFormats | Should Be $UserParams.PresetFormats
                $test.CustomFormatsEnable | Should Be $UserParams.CustomFormatsEnable
                $test.CustomFormats | Should Be $UserParams.CustomFormats
                $test.OutputSubfolderStyle | Should Be $UserParams.OutputSubfolderStyle
                $test.OutputFileStyle | Should Be $UserParams.OutputFileStyle
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                $test.UseHistFile | Should Be $UserParams.UseHistFile
                $test.WriteHistFile | Should Be $UserParams.WriteHistFile
                $test.HistCompareHashes | Should Be $UserParams.HistCompareHashes
                $test.InputSubfolderSearch | Should Be $UserParams.InputSubfolderSearch
                $test.CheckOutputDupli | Should Be $UserParams.CheckOutputDupli
                $test.VerifyCopies | Should Be $UserParams.VerifyCopies
                $test.OverwriteExistingFiles | Should Be $UserParams.OverwriteExistingFiles
                $test.AvoidIdenticalFiles | Should Be $UserParams.AvoidIdenticalFiles
                $test.ZipMirror | Should Be $UserParams.ZipMirror
                $test.UnmountInputDrive | Should Be $UserParams.UnmountInputDrive
                $test.Preventstandby | Should Be $script:Preventstandby
            }
            It "Replace only preset" {
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
                $jsonparams = $inter | ConvertTo-Json
                $jsonparams | Out-Null
                [System.IO.File]::WriteAllText($UserParams.JSONParamPath, $jsonparams)
                Start-Sleep -Milliseconds 25
                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true
            }
            It "Create a new JSON" {
                Remove-Item -LiteralPath $UserParams.JSONParamPath
                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true
                $test = @(Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
                ,$test | Should BeOfType array
                $bla = @("default")
                (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0
                $test.ParamPresetValues[0].InputPath | Should Be $UserParams.InputPath
                $test.ParamPresetValues[0].OutputPath | Should Be $UserParams.OutputPath
                $test.ParamPresetValues[0].MirrorEnable | Should Be $UserParams.MirrorEnable
                $test.ParamPresetValues[0].MirrorPath | Should Be $UserParams.MirrorPath
                $test.ParamPresetValues[0].PresetFormats | Should Be $UserParams.PresetFormats
                $test.ParamPresetValues[0].CustomFormatsEnable | Should Be $UserParams.CustomFormatsEnable
                $test.ParamPresetValues[0].CustomFormats | Should Be $UserParams.CustomFormats
                $test.ParamPresetValues[0].OutputSubfolderStyle | Should Be $UserParams.OutputSubfolderStyle
                $test.ParamPresetValues[0].OutputFileStyle | Should Be $UserParams.OutputFileStyle
                $test.ParamPresetValues[0].HistFilePath | Should Be $UserParams.HistFilePath
                $test.ParamPresetValues[0].UseHistFile | Should Be $UserParams.UseHistFile
                $test.ParamPresetValues[0].WriteHistFile | Should Be $UserParams.WriteHistFile
                $test.ParamPresetValues[0].HistCompareHashes | Should Be $UserParams.HistCompareHashes
                $test.ParamPresetValues[0].InputSubfolderSearch | Should Be $UserParams.InputSubfolderSearch
                $test.ParamPresetValues[0].CheckOutputDupli | Should Be $UserParams.CheckOutputDupli
                $test.ParamPresetValues[0].VerifyCopies | Should Be $UserParams.VerifyCopies
                $test.ParamPresetValues[0].OverwriteExistingFiles | Should Be $UserParams.OverwriteExistingFiles
                $test.ParamPresetValues[0].AvoidIdenticalFiles | Should Be $UserParams.AvoidIdenticalFiles
                $test.ParamPresetValues[0].ZipMirror | Should Be $UserParams.ZipMirror
                $test.ParamPresetValues[0].UnmountInputDrive | Should Be $UserParams.UnmountInputDrive
                $test.ParamPresetValues[0].Preventstandby | Should Be $script:Preventstandby
            }
        }
        Context "No problems with SpecChars" {
            It "Brackets" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\mc parameters[1].json"
                $UserParams.SaveParamPresetName = "bla"

                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true

                $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                ,$test | Should BeOfType array
                $bla = @("default","default2","bla","professionell","projekte")
                (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

                $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
                $test = $test.ParamPresetValues
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorEnable | Should Be $UserParams.MirrorEnable
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.PresetFormats | Should Be $UserParams.PresetFormats
                $test.CustomFormatsEnable | Should Be $UserParams.CustomFormatsEnable
                $test.CustomFormats | Should Be $UserParams.CustomFormats
                $test.OutputSubfolderStyle | Should Be $UserParams.OutputSubfolderStyle
                $test.OutputFileStyle | Should Be $UserParams.OutputFileStyle
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                $test.UseHistFile | Should Be $UserParams.UseHistFile
                $test.WriteHistFile | Should Be $UserParams.WriteHistFile
                $test.HistCompareHashes | Should Be $UserParams.HistCompareHashes
                $test.InputSubfolderSearch | Should Be $UserParams.InputSubfolderSearch
                $test.CheckOutputDupli | Should Be $UserParams.CheckOutputDupli
                $test.VerifyCopies | Should Be $UserParams.VerifyCopies
                $test.OverwriteExistingFiles | Should Be $UserParams.OverwriteExistingFiles
                $test.AvoidIdenticalFiles | Should Be $UserParams.AvoidIdenticalFiles
                $test.ZipMirror | Should Be $UserParams.ZipMirror
                $test.UnmountInputDrive | Should Be $UserParams.UnmountInputDrive
                $test.Preventstandby | Should Be $script:Preventstandby
            }
            It "12345" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\123456789 ordner\123456789 parameters.json"
                $UserParams.SaveParamPresetName = "12345"

                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true

                $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                ,$test | Should BeOfType array
                $bla = @("default","12345")
                (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

                $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
                $test = $test.ParamPresetValues
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorEnable | Should Be $UserParams.MirrorEnable
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.PresetFormats | Should Be $UserParams.PresetFormats
                $test.CustomFormatsEnable | Should Be $UserParams.CustomFormatsEnable
                $test.CustomFormats | Should Be $UserParams.CustomFormats
                $test.OutputSubfolderStyle | Should Be $UserParams.OutputSubfolderStyle
                $test.OutputFileStyle | Should Be $UserParams.OutputFileStyle
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                $test.UseHistFile | Should Be $UserParams.UseHistFile
                $test.WriteHistFile | Should Be $UserParams.WriteHistFile
                $test.HistCompareHashes | Should Be $UserParams.HistCompareHashes
                $test.InputSubfolderSearch | Should Be $UserParams.InputSubfolderSearch
                $test.CheckOutputDupli | Should Be $UserParams.CheckOutputDupli
                $test.VerifyCopies | Should Be $UserParams.VerifyCopies
                $test.OverwriteExistingFiles | Should Be $UserParams.OverwriteExistingFiles
                $test.AvoidIdenticalFiles | Should Be $UserParams.AvoidIdenticalFiles
                $test.ZipMirror | Should Be $UserParams.ZipMirror
                $test.UnmountInputDrive | Should Be $UserParams.UnmountInputDrive
                $test.Preventstandby | Should Be $script:Preventstandby
            }
            It "Æ" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\ÆOrdner\ÆParameters.json"
                $UserParams.SaveParamPresetName = "default"

                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true

                $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                ,$test | Should BeOfType array
                $bla = @("default","ae")
                (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

                $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
                $test = $test.ParamPresetValues
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorEnable | Should Be $UserParams.MirrorEnable
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.PresetFormats | Should Be $UserParams.PresetFormats
                $test.CustomFormatsEnable | Should Be $UserParams.CustomFormatsEnable
                $test.CustomFormats | Should Be $UserParams.CustomFormats
                $test.OutputSubfolderStyle | Should Be $UserParams.OutputSubfolderStyle
                $test.OutputFileStyle | Should Be $UserParams.OutputFileStyle
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                $test.UseHistFile | Should Be $UserParams.UseHistFile
                $test.WriteHistFile | Should Be $UserParams.WriteHistFile
                $test.HistCompareHashes | Should Be $UserParams.HistCompareHashes
                $test.InputSubfolderSearch | Should Be $UserParams.InputSubfolderSearch
                $test.CheckOutputDupli | Should Be $UserParams.CheckOutputDupli
                $test.VerifyCopies | Should Be $UserParams.VerifyCopies
                $test.OverwriteExistingFiles | Should Be $UserParams.OverwriteExistingFiles
                $test.AvoidIdenticalFiles | Should Be $UserParams.AvoidIdenticalFiles
                $test.ZipMirror | Should Be $UserParams.ZipMirror
                $test.UnmountInputDrive | Should Be $UserParams.UnmountInputDrive
                $test.Preventstandby | Should Be $script:Preventstandby
            }
            It "backtick" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````params``.json"
                $UserParams.SaveParamPresetName = "backtick"

                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true

                $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                ,$test | Should BeOfType array
                $bla = @("backtick","blaaa")
                (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

                $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
                $test = $test.ParamPresetValues
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorEnable | Should Be $UserParams.MirrorEnable
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.PresetFormats | Should Be $UserParams.PresetFormats
                $test.CustomFormatsEnable | Should Be $UserParams.CustomFormatsEnable
                $test.CustomFormats | Should Be $UserParams.CustomFormats
                $test.OutputSubfolderStyle | Should Be $UserParams.OutputSubfolderStyle
                $test.OutputFileStyle | Should Be $UserParams.OutputFileStyle
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                $test.UseHistFile | Should Be $UserParams.UseHistFile
                $test.WriteHistFile | Should Be $UserParams.WriteHistFile
                $test.HistCompareHashes | Should Be $UserParams.HistCompareHashes
                $test.InputSubfolderSearch | Should Be $UserParams.InputSubfolderSearch
                $test.CheckOutputDupli | Should Be $UserParams.CheckOutputDupli
                $test.VerifyCopies | Should Be $UserParams.VerifyCopies
                $test.OverwriteExistingFiles | Should Be $UserParams.OverwriteExistingFiles
                $test.AvoidIdenticalFiles | Should Be $UserParams.AvoidIdenticalFiles
                $test.ZipMirror | Should Be $UserParams.ZipMirror
                $test.UnmountInputDrive | Should Be $UserParams.UnmountInputDrive
                $test.Preventstandby | Should Be $script:Preventstandby
            }
            It "bracket 2" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] Parameter.json"
                $UserParams.SaveParamPresetName = "defaultbracket"

                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true

                $test = @(Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
                ,$test | Should BeOfType array
                $bla = @("defaultbracket")
                (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

                $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
                $test = $test.ParamPresetValues
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorEnable | Should Be $UserParams.MirrorEnable
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.PresetFormats | Should Be $UserParams.PresetFormats
                $test.CustomFormatsEnable | Should Be $UserParams.CustomFormatsEnable
                $test.CustomFormats | Should Be $UserParams.CustomFormats
                $test.OutputSubfolderStyle | Should Be $UserParams.OutputSubfolderStyle
                $test.OutputFileStyle | Should Be $UserParams.OutputFileStyle
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                $test.UseHistFile | Should Be $UserParams.UseHistFile
                $test.WriteHistFile | Should Be $UserParams.WriteHistFile
                $test.HistCompareHashes | Should Be $UserParams.HistCompareHashes
                $test.InputSubfolderSearch | Should Be $UserParams.InputSubfolderSearch
                $test.CheckOutputDupli | Should Be $UserParams.CheckOutputDupli
                $test.VerifyCopies | Should Be $UserParams.VerifyCopies
                $test.OverwriteExistingFiles | Should Be $UserParams.OverwriteExistingFiles
                $test.AvoidIdenticalFiles | Should Be $UserParams.AvoidIdenticalFiles
                $test.ZipMirror | Should Be $UserParams.ZipMirror
                $test.UnmountInputDrive | Should Be $UserParams.UnmountInputDrive
                $test.Preventstandby | Should Be $script:Preventstandby
            }
            It "dots" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\ordner.mit.punkten\mc.parameters.json"
                $UserParams.SaveParamPresetName = "default"

                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true

                $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                ,$test | Should BeOfType array
                $bla = @("default","dots")
                (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

                $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
                $test = $test.ParamPresetValues
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorEnable | Should Be $UserParams.MirrorEnable
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.PresetFormats | Should Be $UserParams.PresetFormats
                $test.CustomFormatsEnable | Should Be $UserParams.CustomFormatsEnable
                $test.CustomFormats | Should Be $UserParams.CustomFormats
                $test.OutputSubfolderStyle | Should Be $UserParams.OutputSubfolderStyle
                $test.OutputFileStyle | Should Be $UserParams.OutputFileStyle
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                $test.UseHistFile | Should Be $UserParams.UseHistFile
                $test.WriteHistFile | Should Be $UserParams.WriteHistFile
                $test.HistCompareHashes | Should Be $UserParams.HistCompareHashes
                $test.InputSubfolderSearch | Should Be $UserParams.InputSubfolderSearch
                $test.CheckOutputDupli | Should Be $UserParams.CheckOutputDupli
                $test.VerifyCopies | Should Be $UserParams.VerifyCopies
                $test.OverwriteExistingFiles | Should Be $UserParams.OverwriteExistingFiles
                $test.AvoidIdenticalFiles | Should Be $UserParams.AvoidIdenticalFiles
                $test.ZipMirror | Should Be $UserParams.ZipMirror
                $test.UnmountInputDrive | Should Be $UserParams.UnmountInputDrive
                $test.Preventstandby | Should Be $script:Preventstandby
            }
            It "specials" {
                $UserParams.JSONParamPath = "$BlaDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . parameter.json"
                $UserParams.SaveParamPresetName = "special"

                $test = Set-Parameters -UserParams $UserParams
                $test | Should Be $true

                $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                ,$test | Should BeOfType array
                $bla = @("special","default2","professionell","projekte")
                (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

                $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
                $test = $test.ParamPresetValues
                $test.InputPath | Should Be $UserParams.InputPath
                $test.OutputPath | Should Be $UserParams.OutputPath
                $test.MirrorEnable | Should Be $UserParams.MirrorEnable
                $test.MirrorPath | Should Be $UserParams.MirrorPath
                $test.PresetFormats | Should Be $UserParams.PresetFormats
                $test.CustomFormatsEnable | Should Be $UserParams.CustomFormatsEnable
                $test.CustomFormats | Should Be $UserParams.CustomFormats
                $test.OutputSubfolderStyle | Should Be $UserParams.OutputSubfolderStyle
                $test.OutputFileStyle | Should Be $UserParams.OutputFileStyle
                $test.HistFilePath | Should Be $UserParams.HistFilePath
                $test.UseHistFile | Should Be $UserParams.UseHistFile
                $test.WriteHistFile | Should Be $UserParams.WriteHistFile
                $test.HistCompareHashes | Should Be $UserParams.HistCompareHashes
                $test.InputSubfolderSearch | Should Be $UserParams.InputSubfolderSearch
                $test.CheckOutputDupli | Should Be $UserParams.CheckOutputDupli
                $test.VerifyCopies | Should Be $UserParams.VerifyCopies
                $test.OverwriteExistingFiles | Should Be $UserParams.OverwriteExistingFiles
                $test.AvoidIdenticalFiles | Should Be $UserParams.AvoidIdenticalFiles
                $test.ZipMirror | Should Be $UserParams.ZipMirror
                $test.UnmountInputDrive | Should Be $UserParams.UnmountInputDrive
                $test.Preventstandby | Should Be $script:Preventstandby
            }
        }
    }
#>
<# DONE:    Describe "Start-FileSearch" {
        $BlaDrive = "$TestDrive\TEST"
        BeforeEach {
            [hashtable]$UserParams = @{
                InputPath = "$BlaDrive\In_Test"
                UseHistFile = 1
                HistCompareHashes = 1
                CheckOutputDupli = 1
                allChosenFormats = @("*.JPG")
                OutputFileStyle = "unchanged"
                OutputSubfolderStyle = "yyyy-MM-dd"
            }
            $script:input_recurse = $true
        }
        New-Item -ItemType Directory -Path $BlaDrive
        Push-Location $BlaDrive
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
        Pop-Location

        Context "Normal functions" {
            It "Return array if successful" {
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length | Should Be 26
            }
            It "Return array even if only one file is found" {
                $UserParams.allChosenFormats = @("*.pptx")
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InPath        | Should Be $UserParams.InputPath
                $test.InName        | Should Be "singleFile.pptx"
                $test.InFullName    | Should Be "$($UserParams.InputPath)\singleFile.pptx"
                $test.InBaseName    | Should Be "singleFile"
                $test.Extension     | Should Be $UserParams.allChosenFormats.Replace("*","")
                $test.Size          | Should Be 32652
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder  | Should Be "\2018-03-10"
                $test.OutPath       | Should Be "ZYX"
                $test.OutName       | Should Be "ZYX"
                $test.OutBaseName   | Should Be "ZYX"
                $test.Hash          | Should Be "A8FD5A691EC2C81B0BD597A4B78616ED01BFE6F9"
                $test.ToCopy        | Should Be 1
            }
            It "Throw if no/wrong param" {
                {Start-FileSearch} | Should Throw
                {Start-FileSearch -UserParams 123} | Should Throw
                {Start-FileSearch -UserParams @{}} | Should Throw
            }
        }
        Context "Proper implementations of OutputSubfolderStyle" {
            BeforeEach {
                $UserParams.allChosenFormats = @("*.pptx")
                $UserParams.HistCompareHashes = 0
                $UserParams.UseHistFile = 0
                $UserParams.CheckOutputDupli = 0
            }
            It "none" {
                $UserParams.OutputSubfolderStyle = "none"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder  | Should Be ""
                $test.OutPath       | Should Be "ZYX"
            }
            It "unchanged" {
                $UserParams.allChosenFormats = @("*.docx")
                $UserParams.OutputSubfolderStyle = "unchanged"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder  | Should Be "\backtick ````ordner ``"
                $test.OutPath       | Should Be "ZYX"
            }
            It "yyyy-MM-dd" {
                $UserParams.OutputSubfolderStyle = "yyyy-MM-dd"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder  | Should Be "\2018-03-10"
                $test.OutPath       | Should Be "ZYX"
            }
            It "yyyy_MM_dd" {
                $UserParams.OutputSubfolderStyle = "yyyy_MM_dd"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder  | Should Be "\2018_03_10"
                $test.OutPath       | Should Be "ZYX"
            }
            It "yyyy.MM.dd" {
                $UserParams.OutputSubfolderStyle = "yyyy.MM.dd"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder  | Should Be "\2018.03.10"
                $test.OutPath       | Should Be "ZYX"
            }
            It "yyyyMMdd" {
                $UserParams.OutputSubfolderStyle = "yyyyMMdd"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder  | Should Be "\20180310"
                $test.OutPath       | Should Be "ZYX"
            }
            It "yy-MM-dd" {
                $UserParams.OutputSubfolderStyle = "yy-MM-dd"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder  | Should Be "\18-03-10"
                $test.OutPath       | Should Be "ZYX"
            }
            It "yy_MM_dd" {
                $UserParams.OutputSubfolderStyle = "yy_MM_dd"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder  | Should Be "\18_03_10"
                $test.OutPath       | Should Be "ZYX"
            }
            It "yy.MM.dd" {
                $UserParams.OutputSubfolderStyle = "yy.MM.dd"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder  | Should Be "\18.03.10"
                $test.OutPath       | Should Be "ZYX"
            }
            It "yyMMdd" {
                $UserParams.OutputSubfolderStyle = "yyMMdd"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
                $test.OutSubfolder      | Should Be "\180310"
                $test.OutPath       | Should Be "ZYX"
            }
        }
        Context "Proper implementation of OutputFileStyle" {
            BeforeEach {
                $UserParams.allChosenFormats = @("*.pptx")
                $UserParams.HistCompareHashes = 0
                $UserParams.UseHistFile = 0
                $UserParams.CheckOutputDupli = 0
            }
            It "unchanged" {
                $UserParams.OutputFileStyle = "unchanged"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "singleFile"
                $test.Date          | Should Be "2018-03-10_19-51-21"
            }
            It "yyyy-MM-dd_HH-mm-ss" {
                $UserParams.OutputFileStyle = "yyyy-MM-dd_HH-mm-ss"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "2018-03-10_19-51-21"
                $test.Date          | Should Be "2018-03-10_19-51-21"
            }
            It "yyyyMMdd_HHmmss" {
                $UserParams.OutputFileStyle = "yyyyMMdd_HHmmss"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "20180310_195121"
                $test.Date          | Should Be "2018-03-10_19-51-21"
            }
            It "yyyyMMddHHmmss" {
                $UserParams.OutputFileStyle = "yyyyMMddHHmmss"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "20180310195121"
                $test.Date          | Should Be "2018-03-10_19-51-21"
            }
            It "yy-MM-dd_HH-mm-ss" {
                $UserParams.OutputFileStyle = "yy-MM-dd_HH-mm-ss"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "18-03-10_19-51-21"
                $test.Date          | Should Be "2018-03-10_19-51-21"
            }
            It "yyMMdd_HHmmss" {
                $UserParams.OutputFileStyle = "yyMMdd_HHmmss"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "180310_195121"
                $test.Date          | Should Be "2018-03-10_19-51-21"
            }
            It "yyMMddHHmmss" {
                $UserParams.OutputFileStyle = "yyMMddHHmmss"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "180310195121"
                $test.Date          | Should Be "2018-03-10_19-51-21"
            }
            It "HH-mm-ss" {
                $UserParams.OutputFileStyle = "HH-mm-ss"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "19-51-21"
                $test.Date          | Should Be "2018-03-10_19-51-21"
            }
            It "HH_mm_ss" {
                $UserParams.OutputFileStyle = "HH_mm_ss"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "19_51_21"
                $test.Date          | Should Be "2018-03-10_19-51-21"
            }
            It "HHmmss" {
                $UserParams.OutputFileStyle = "HHmmss"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.length        | Should Be 1
                $test.InBaseName    | Should Be "195121"
                $test.Date          | Should Be "2018-03-10_19-51-21"
            }
        }
        Context "No problems with SpecChars" {
            BeforeEach {
                $script:input_recurse = $false
                $UserParams.allChosenFormats = @("*")
            }
            It "All" {
                $script:input_recurse = $true
                $UserParams.InputPath = "$BlaDrive\In_Test"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test          | Should BeOfType array
                $test.length    | Should Be 176
            }
            It "12345" {
                $UserParams.InputPath = "$BlaDrive\In_Test\123456789 ordner"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test          | Should BeOfType array
                $test.length    | Should Be 14
                $test = $test | Where-Object {$_.InBaseName -like "123412356789 file"}
                $test.InPath        | Should Be $UserParams.InputPath
                $test.InName        | Should Be "123412356789 file.rtf"
                $test.InBaseName    | Should Be "123412356789 file"
                $test.Hash          | Should Be "84BFA364C661714A5BC94153E0F61BDFEB9F22B5"
            }
            It "Æ" {
                $UserParams.InputPath = "$BlaDrive\In_Test\ÆOrdner"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test          | Should BeOfType array
                $test.length    | Should Be 14
                $test = $test | Where-Object {$_.InBaseName -like "Æfile"}
                $test.InPath | Should Be $UserParams.InputPath
                $test.InName | Should Be "Æfile.dng"
                $test.InBaseName | Should Be "Æfile"
                $test.Hash | Should Be "BCB74FB637763B80F40912378DEA4FBC86BF24D5"

            }
            It "backtick" {
                $UserParams.InputPath = "$BlaDrive\In_Test\backtick ````ordner ``"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test          | Should BeOfType array
                $test.length    | Should Be 15
                $test = $test | Where-Object {$_.InBaseName -match 'backtick\ \`\ file\ \`\`$'}
                $test.InPath        | Should Be $UserParams.InputPath
                $test.InName        | Should Be "backtick `` file ````.arw"
                $test.InBaseName    | Should Be "backtick `` file ````"
                $test.Hash          | Should Be "33363A338DAC63D151C74958A4EC0E09E38E1464"

            }
            It "bracket" {
                $UserParams.InputPath = "$BlaDrive\In_Test\bracket [ ] ordner"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test          | Should BeOfType array
                $test.length    | Should Be 14
                $test = $test | Where-Object {$_.InBaseName -match 'bracket\ \[\ \]\ file$'}
                $test.InPath        | Should Be $UserParams.InputPath
                $test.InName        | Should Be "bracket [ ] file.jpg"
                $test.InBaseName    | Should Be "bracket [ ] file"
                $test.Hash          | Should Be "FDB53458F2EDCE324FA5444A807CF615C41ECDB4"

            }
            It "dots" {
                $UserParams.InputPath = "$BlaDrive\In_Test\ordner.mit.punkten"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test          | Should BeOfType array
                $test.length    | Should Be 14
                $test = $test | Where-Object {$_.InBaseName -like "file.with.dots"}
                $test.InPath        | Should Be $UserParams.InputPath
                $test.InName        | Should Be "file.with.dots.JPEG"
                $test.InBaseName    | Should Be "file.with.dots"
                $test.Hash          | Should Be "DB94F404ADF02E0D704D62801CB0F1EBD6D8B278"

            }
            It "specials" {
                $UserParams.InputPath = "$BlaDrive\In_Test\special ' ! ,; . ordner"
                $test = @(Start-FileSearch -UserParams $UserParams)
                ,$test          | Should BeOfType array
                $test.length    | Should Be 14
                $test = $test | Where-Object {$_.InBaseName -like "special '!, ;. file"}
                $test.InPath        | Should Be $UserParams.InputPath
                $test.InName        | Should Be "special '!, ;. file.cr2"
                $test.InBaseName    | Should Be "special '!, ;. file"
                $test.Hash          | Should Be "19829E8250E0B98F1F71EE3507C9BB3AC1739F33"
            }
        }
    }
#>
<# DONE:    Describe "Get-HistFile"{
        $BlaDrive = "$TestDrive\TEST"
        # DEFINITION: Combine all parameters into a hashtable:
        BeforeEach {
            [hashtable]$UserParams = @{
                InputPath = "$BlaDrive\In_Test"
                OutputPath = "$BlaDrive\Out_Test"
                allChosenFormats = @("*")
                OutputSubfolderStyle = "yyyy-MM-dd"
                OutputFileStyle = "unchanged"
                HistFilePath = "$BlaDrive\In_Test\mc_hist.json"
                UseHistFile = 0
                WriteHistFile = "no"
                HistCompareHashes = 0
            }
        }
        New-Item -ItemType Directory -Path $BlaDrive
        Push-Location $BlaDrive
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
        Pop-Location

        Context "Work properly" {
            It "Get array from regular histfile"{
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test[2].InName | Should Be "123456789 hist.json"
                $test[2].Date   | Should Be "2018-03-05_22-37-50"
                $test[2].size   | Should Be 3710
                $test[2].hash   | Should Be "DA0FD69AEF6A704430CC94C589953B3BA6E5FE01"
            }
            It "Get array even if just one file is found" {
                $UserParams.HistFilePath = "$BlaDrive\In_Test\mc_hist single.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test.InName | Should Be "123412356789 file - Copy.rtf"
                $test.Date | Should Be "2018-02-25_13-52-15"
                $test.size | Should Be 5994
                $test.hash | Should Be "84BFA364C661714A5BC94153E0F61BDFEB9F22B5"
            }
            It "Return empty array for empty histfile" {
                Mock Read-Host {return 1}
                $UserParams.HistFilePath = "$BlaDrive\In_Test\mc_parameters - empty.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test | Should Be @()
            }
            It "Return `$false if user does not want to work with empty histfile" {
                Mock Read-Host {return 0}
                $UserParams.HistFilePath = "$BlaDrive\In_Test\mc_parameters - empty.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test | Should Be $false
            }
            It "Return array for broken histfile" {
                $UserParams.HistFilePath = "$BlaDrive\In_Test\mc_hist broken.json"
                Mock Read-Host {return 1}
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test | Should Be @()
            }
            It "Return `$false if user does not want to work with broken histfile" {
                Mock Read-Host {return 0}
                $UserParams.HistFilePath = "$BlaDrive\In_Test\mc_hist broken.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test | Should Be $false
            }
            It "Return empty array for no histfile" {
                Mock Read-Host {return 1}
                $UserParams.HistFilePath = "$BlaDrive\In_Test\nofile.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test | Should Be @()
            }
            It "Return `$false if user does not want to work with no histfile" {
                Mock Read-Host {return 0}
                $UserParams.HistFilePath = "$BlaDrive\In_Test\nofile.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test | Should Be $false
            }
            It "Throw if params are wrong/missing" {
                {Get-HistFile} | Should Throw
                {Get-HistFile -UserParams 123} | Should Throw
                {Get-HistFile -UserParams @{}} | Should Throw
            }
        }
        Context "No problems with SpecChars" {
            It "12345" {
                $UserParams.HistFilePath = "$BlaDrive\In_Test\123456789 ordner\123456789 hist.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test[2].InName | Should Be "123456789 hist.json"
                $test[2].Date   | Should Be "2018-03-05_22-37-50"
                $test[2].size   | Should Be 3710
                $test[2].hash   | Should Be "DA0FD69AEF6A704430CC94C589953B3BA6E5FE01"
            }
            It "Æ" {
                $UserParams.HistFilePath = "$BlaDrive\In_Test\ÆOrdner\Æhist.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test[2].InName | Should Be "123456789 hist.json"
                $test[2].Date   | Should Be "2018-03-05_22-37-50"
                $test[2].size   | Should Be 3710
                $test[2].hash   | Should Be "DA0FD69AEF6A704430CC94C589953B3BA6E5FE01"
            }
            It "backtick" {
                $UserParams.HistFilePath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````hist``.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test[2].InName | Should Be "123456789 hist.json"
                $test[2].Date   | Should Be "2018-03-05_22-37-50"
                $test[2].size   | Should Be 3710
                $test[2].hash   | Should Be "DA0FD69AEF6A704430CC94C589953B3BA6E5FE01"
            }
            It "bracket" {
                $UserParams.HistFilePath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] history.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test[2].InName | Should Be "123456789 hist.json"
                $test[2].Date   | Should Be "2018-03-05_22-37-50"
                $test[2].size   | Should Be 3710
                $test[2].hash   | Should Be "DA0FD69AEF6A704430CC94C589953B3BA6E5FE01"
            }
            It "dots" {
                $UserParams.HistFilePath = "$BlaDrive\In_Test\ordner.mit.punkten\mc.hist.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test[2].InName | Should Be "123456789 hist.json"
                $test[2].Date   | Should Be "2018-03-05_22-37-50"
                $test[2].size   | Should Be 3710
                $test[2].hash   | Should Be "DA0FD69AEF6A704430CC94C589953B3BA6E5FE01"
            }
            It "specials" {
                $UserParams.HistFilePath = "$BlaDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . hist.json"
                $test = @(Get-HistFile -UserParams $UserParams)
                ,$test | Should BeOfType array
                $test[2].InName | Should Be "123456789 hist.json"
                $test[2].Date   | Should Be "2018-03-05_22-37-50"
                $test[2].size   | Should Be 3710
                $test[2].hash   | Should Be "DA0FD69AEF6A704430CC94C589953B3BA6E5FE01"
            }
        }
    }
#>

<#
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