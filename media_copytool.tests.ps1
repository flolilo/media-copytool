# Comment out the last block of media_copytool (i.e. "Start-up") before running this script!
# Maybe also comment out write-colorout function.

# DEFINITION: Get all error-outputs in English:
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -typename System.Text.UTF8Encoding
    [Console]::OutputEncoding = New-Object -typename System.Text.UTF8Encoding

. $PSScriptRoot\media_copytool.ps1

<#
Describe "Get-Parameters" {
    $TestDrive = "TestDrive:\TEST"
    # DEFINITION: Combine all parameters into a hashtable:
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
        # TODO: It "Preventstandby" {
            # $test = (Get-Parameters -UserParams $UserParams -Renew 1).Preventstandby
            # $test | Should BeOfType int
            # $test | Should Be 112
        # }
    }
}
#>

<# TODO: ufff...alles in GUI machen. vor allem: JSON-loading.
    Describe "Start-GUI" {
        $TestDrive = "TestDrive:\TEST"
        # DEFINITION: Combine all parameters into a hashtable:
        BeforeEach {
            [hashtable]$UserParams = @{
                ShowParams = 0
                GUI_CLI_Direct = "GUI"
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
        Push-Location $TestDrive
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.zip`" `"-o.\`" " -WindowStyle Minimized -Wait
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

<#
    Describe "Get-UserValuesGUI" {
        $TestDrive = "TestDrive:\TEST"
        # DEFINITION: Combine all parameters into a hashtable:
        BeforeEach {
            [hashtable]$UserParams = @{
                ShowParams = 0
                GUI_CLI_Direct = "GUI"
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

        It ""{
            $test = Get-UserValuesGUI -UserParams $UserParams -GUIParams 
            $test | Should BeOfType hashtable
        }

    }
#>

<# TODO: get a way to test anything about CLI
    Describe "Get-UserValuesCLI"{
        $TestDrive = "TestDrive:\TEST"
        # DEFINITION: Combine all parameters into a hashtable:
        BeforeEach {
            [hashtable]$UserParams = @{
                ShowParams = 0
                GUI_CLI_Direct = "GUI"
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

        It "Get values from CLI, then check the main input- and outputfolder"{

        }
    }
#>


Describe "Get-UserValuesDirect"{
    $TestDrive = "TestDrive:\TEST"
    # DEFINITION: Combine all parameters into a hashtable:
    BeforeEach {
        [hashtable]$UserParams = @{
            ShowParams = 0
            GUI_CLI_Direct = "Direct"
            JSONParamPath = "$TestDrive\In_Test\mc_parameters.json"
            LoadParamPresetName = "default"
            SaveParamPresetName = "default"
            RememberInPath = 0
            RememberOutPath = 0
            RememberMirrorPath = 0
            RememberSettings = 0
            # DEFINITION: From here on, parameters can be set both via parameters and via JSON file(s).
            InputPath = "$TestDrive\In_Test"
            OutputPath = "$TestDrive\Out_Test"
            MirrorEnable = 1
            MirrorPath = "$TestDrive\Mirr_Test"
            PresetFormats = @("Can")
            CustomFormatsEnable = 0
            CustomFormats = @()
            OutputSubfolderStyle = "yyyy-MM-dd"
            OutputFileStyle = "unchanged"
            HistFilePath = "$TestDrive\In_Test\mc_hist.json"
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
    New-Item -ItemType Directory -Path $TestDrive
    Push-Location $TestDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.zip`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    Context "Test the returned values" {
        It "If everything is correct, return hashtable" {
            $test = Get-UserValuesDirect -UserParams $UserParams
            $test | Should BeOfType hashtable
        }
        It "InputPath" {
            $test = (Get-UserValuesDirect -UserParams $UserParams).InputPath
            $test | Should BeOfType string
            $test | Should Be "$TestDrive\In_Test"
        }
        It "InputPath - trailing backslash" {
            $UserParams.InputPath = "$TestDrive\In_Test\"
            $test = (Get-UserValuesDirect -UserParams $UserParams).InputPath
            $test | Should BeOfType string
            $test | Should Be "$TestDrive\In_Test"
        }
        It "OutputPath" {
            $test = (Get-UserValuesDirect -UserParams $UserParams).OutputPath
            $test | Should BeOfType string
            $test | Should Be "$TestDrive\Out_Test"
        }
        It "OutputPath - trailing backslash" {
            $UserParams.OutputPath = "$TestDrive\Out_Test\"
            $test = (Get-UserValuesDirect -UserParams $UserParams).OutputPath
            $test | Should BeOfType string
            $test | Should Be "$TestDrive\Out_Test"
        }
        It "MirrorEnable" {
            $test = (Get-UserValuesDirect -UserParams $UserParams).MirrorEnable
            $test | Should BeOfType int
            $test | Should Be 1
        }
        It "MirrorPath" {
            $test = (Get-UserValuesDirect -UserParams $UserParams).MirrorPath
            $test | Should BeOfType string
            $test | Should Be "$TestDrive\Mirr_Test"
        }
        It "MirrorPath - trailing backslash" {
            $UserParams.MirrorPath = "$TestDrive\Mirr_Test\"
            $test = (Get-UserValuesDirect -UserParams $UserParams).MirrorPath
            $test | Should BeOfType string
            $test | Should Be "$TestDrive\Mirr_Test"
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
            $test | Should Be "$TestDrive\In_Test\mc_hist.json"
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
            $UserParams.InputPath = "$TestDrive\NONE"
            $test = Get-UserValuesDirect -UserParams $UserParams
            $test | Should Be $false
        }
        It "InputPath is too short" {
            $UserParams.InputPath = "A"
            $test = Get-UserValuesDirect -UserParams $UserParams
            $test | Should Be $false
        }
        It "OutputPath same as InputPath" {
            $UserParams.InputPath = "$TestDrive\In_Test"
            $UserParams.OutputPath = "$TestDrive\In_Test"
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
            $UserParams.InputPath = "$TestDrive\In_Test"
            $UserParams.MirrorPath = "$TestDrive\In_Test"
            $test = Get-UserValuesDirect -UserParams $UserParams
            $test | Should Be $false
        }
        It "MirrorPath same as OutputPath" {
            $UserParams.MirrorPath = "$TestDrive\Out_Test"
            $UserParams.OutputPath = "$TestDrive\Out_Test"
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
}

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