# Comment out the last block of media_copytool (i.e. "Start-up") before running this script!
# Maybe also comment out write-colorout function.

# DEFINITION: Get all error-outputs in English:
    [Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -typename System.Text.UTF8Encoding
    [Console]::OutputEncoding = New-Object -typename System.Text.UTF8Encoding

. $PSScriptRoot\media_copytool.ps1

Describe "Get-Parameters" {
    $BlaDrive = "$TestDrive\TEST"
    # DEFINITION: Combine all parameters into a hashtable:
    BeforeEach {
        [hashtable]$UserParams = @{
            ShowParams = 0
            GUI_CLI_Direct = "direct"
            JSONParamPath = "$BlaDrive\In_Test\param_uncomplicated.json"
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
    tree /F /A | Out-Host
    Pop-Location

    Context "Uncomplicated file interaction" {
        It "Work fine with proper parameters" {
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName   | Should Be "default"
        }
        It "Nonexistent/Empty LoadParamPresetName leads to `"default`"" {
            $UserParams.LoadParamPresetName = "nonexistent"
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName   | Should Be "default"

            $UserParams.LoadParamPresetName = ""
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName   | Should Be "default"
        }
        It "Return false when not finding anything" {
            $UserParams.JSONParamPath = "$BlaDrive\In_Test\notthere.json"
            Get-Parameters -UserParams $UserParams -Renew 1 | Should Be $false
        }
        It "Throw error when UserParams are of wrong type" {
            {Get-Parameters -UserParams "hallo" -Renew 1} | Should Throw
            {Get-Parameters -UserParams $UserParams -Renew "hallo"} | Should Throw
        }
        It "Throw error with empty UserParams" {
            {Get-Parameters} | Should Throw
            {Get-Parameters -UserParams @{} -Renew 1} | Should Throw
            {Get-Parameters -UserParams $UserParams} | Should Throw
            {Get-Parameters -Renew 1} | Should Throw
        }
        It "Throw error when param.JSON is empty" {
            $UserParams.JSONParamPath = "$BlaDrive\In_Test\param_empty.json"
            Get-Parameters  -UserParams $UserParams -Renew 1 | Should Be $false
        }
    }
    It "Special characters file&preset interaction" {
        $UserParams.JSONParamPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©\param specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©.json"
        $UserParams.LoadParamPresetName = "specchar"
        $test = Get-Parameters -UserParams $UserParams -Renew 1
        $test | Should BeOfType hashtable
        $test.LoadParamPresetName | Should Be "specchar"
        $test.InputPath             | Should Be "F:\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
        $test.OutputPath            | Should Be "F:\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
        $test.MirrorPath            | Should Be "F:\Mirr_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
        $test.HistFilePath          | Should Be "F:\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©\hist specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©.json"
    }
    <# TODO: Long filename DOES NOT WORK ATM
        It "Long filename file&preset interaction" {
            $UserParams.JSONParamPath = "$BlaDrive\In_Test\folder_with_ultimately_long_filename_that_exceeds_256_characters_easily_because_it_is_extremely_long_and_will_absolutely_not_work_if_windows_does_not_support_long_filenames_which_would_be_a_p\param_with_ultimately_long_filename_that_exceeds_256_characters_easily_because_it_is_extremely_long_and_will_absolutely_not_work_if_windows_does_not_support_long_filenames_which_would_be.json"
            $UserParams.LoadParamPresetName = "long"
            $test = Get-Parameters -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName | Should Be "long"
            $test.InputPath             | Should Be "F:\In_Test\folder_with_ultimately_long_filename_that_exceeds_256_characters_easily_because_it_is_extremely_long_and_will_absolutely_not_work_if_windows_does_not_support_long_filenames_which_would_be_a_p"
            $test.OutputPath            | Should Be "F:\Out_Test\folder_with_ultimately_long_filename_that_exceeds_256_characters_easily_because_it_is_extremely_long_and_will_absolutely_not_work_if_windows_does_not_support_long_filenames_which_would_be_a_p"
            $test.MirrorPath            | Should Be "F:\Mirr_Test\folder_with_ultimately_long_filename_that_exceeds_256_characters_easily_because_it_is_extremely_long_and_will_absolutely_not_work_if_windows_does_not_support_long_filenames_which_would_be_a_p"
            $test.HistFilePath          | Should Be "F:\In_Test\folder_with_ultimately_long_filename_that_exceeds_256_characters_easily_because_it_is_extremely_long_and_will_absolutely_not_work_if_windows_does_not_support_long_filenames_which_would_be_a_p\hist_with_ultimately_long_filename_that_exceeds_256_characters_easily_because_it_is_extremely_long_and_will_absolutely_not_work_if_windows_does_not_support_long_filenames_which_would_be.json"
        }
    #>
    Context "Test the returned values" {
        $UserParams.LoadParamPresetName = "bla"
        $test = (Get-Parameters -UserParams $UserParams -Renew 1)
        It "InputPath" {
            $test.InputPath     | Should BeOfType string
            $test.InputPath     | Should Be "F:\ooBar"
        }
        It "OutputPath" {
            $test.OutputPath    | Should BeOfType string
            $test.OutputPath    | Should Be "F:\ooBar\MooBar"
        }
        It "MirrorEnable" {
            $test.MirrorEnable  | Should BeOfType int
            $test.MirrorEnable  | Should Be 13
        }
        It "MirrorPath" {
            $test.MirrorPath    | Should BeOfType string
            $test.MirrorPath    | Should Be "F:\BooBar"
        }
        It "PresetFormats" {
            ,$test.PresetFormats    | Should BeOfType array
            $test.PresetFormats     | Should Be @("Foo","Bar")
        }
        It "CustomFormatsEnable" {
            $test.CustomFormatsEnable   | Should BeOfType int
            $test.CustomFormatsEnable   | Should Be 14
        }
        It "CustomFormats" {
            ,$test.CustomFormats    | Should BeOfType array
            $test.CustomFormats     | Should Be @("*Foobar")
        }
        It "OutputSubfolderStyle" {
            $test.OutputSubfolderStyle | Should BeOfType string
            $test.OutputSubfolderStyle | Should Be "yyyy-MM-dd-FOO"
        }
        It "OutputFileStyle" {
            $test.OutputFileStyle   | Should BeOfType string
            $test.OutputFileStyle   | Should Be "unchanged-BAR"
        }
        It "HistFilePath" {
            $test.HistFilePath      | Should BeOfType string
            $test.HistFilePath      | Should Be "$($PSScriptRoot)\hist_MooBar.json"
        }
        It "UseHistFile" {
            $test.UseHistFile       | Should BeOfType int
            $test.UseHistFile       | Should Be 15
        }
        It "WriteHistFile" {
            $test.WriteHistFile     | Should BeOfType string
            $test.WriteHistFile     | Should Be "fooyes"
        }
        It "HistCompareHashes" {
            $test.HistCompareHashes | Should BeOfType int
            $test.HistCompareHashes | Should Be 16
        }
        It "InputSubfolderSearch" {
            $test.InputSubfolderSearch  | Should BeOfType int
            $test.InputSubfolderSearch  | Should Be 17
        }
        It "CheckOutputDupli" {
            $test.CheckOutputDupli  | Should BeOfType int
            $test.CheckOutputDupli  | Should Be 18
        }
        It "VerifyCopies" {
            $test.VerifyCopies  | Should BeOfType int
            $test.VerifyCopies  | Should Be 19
        }
        It "OverwriteExistingFiles" {
            $test.OverwriteExistingFiles    | Should BeOfType int
            $test.OverwriteExistingFiles    | Should Be 20
        }
        It "AvoidIdenticalFiles" {
            $test.AvoidIdenticalFiles   | Should BeOfType int
            $test.AvoidIdenticalFiles   | Should Be 21
        }
        It "ZipMirror" {
            $test.ZipMirror | Should BeOfType int
            $test.ZipMirror | Should Be 22
        }
        It "UnmountInputDrive" {
            $test.UnmountInputDrive | Should BeOfType int
            $test.UnmountInputDrive | Should Be 23
        }
        <# TODO: find a way to get Preventstandby working
            It "Preventstandby" {
                $test.Preventstandby    | Should BeOfType int
                $test.Preventstandby    | Should Be 24
            }
        #>
    }
}

<# TODO: hrmph. get everything right in GUI (in original file!): JSON-loading.
    Describe "Start-GUI" {
        $BlaDrive = "$TestDrive\TEST"
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
        $BlaDrive = "$TestDrive\TEST"
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
        $BlaDrive = "$TestDrive\TEST"
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

Describe "Get-UserValuesDirect" {
    $BlaDrive = "$TestDrive\TEST"
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
            $bla = @("*.cr2","*.cr3","*.nef","*.nrw")
            $test = (Compare-Object $bla $test -ErrorAction SilentlyContinue).Count
            $test | Should Be 0

            $UserParams.PresetFormats = @("Son")
            $test = (Get-UserValuesDirect -UserParams $UserParams).allChosenFormats
            ,$test | Should BeOfType array
            $bla = @("*.arw")
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
    Context "Special characters" {
        It "Find existing folders" {
            $UserParams.JSONParamPath   = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©\param specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©.json"
            $UserParams.InputPath       = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
            $UserParams.OutputPath      = "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
            $UserParams.MirrorPath      = "$BlaDrive\Mirr_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
            $UserParams.HistFilePath    = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©\hist specChar.(]){[}à°^âaà``$öäüß'#+,;-Æ©.json"
            $test = Get-UserValuesDirect -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.JSONParamPath | Should Be $UserParams.JSONParamPath
            $test.InputPath     | Should Be $UserParams.InputPath
            $test.OutputPath    | Should Be $UserParams.OutputPath
            $test.MirrorPath    | Should Be $UserParams.MirrorPath
            $test.HistFilePath  | Should Be $UserParams.HistFilePath
        }
        It "Create non-existing folders" {
            Get-ChildItem "$BlaDrive\Out_Test" -Recurse     | Remove-Item
            Get-ChildItem "$BlaDrive\Mirr_Test" -Recurse    | Remove-Item
            (Get-ChildItem "$BlaDrive\Out_Test" -Recurse -ErrorAction SilentlyContinue).Count   | Out-Host
            (Get-ChildItem "$BlaDrive\Mirr_Test" -Recurse -ErrorAction SilentlyContinue).Count  | Out-Host

            $UserParams.JSONParamPath   = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©\param specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©.json"
            $UserParams.InputPath       = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
            $UserParams.OutputPath      = "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
            $UserParams.MirrorPath      = "$BlaDrive\Mirr_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
            $UserParams.HistFilePath    = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©\hist specChar.(]){[}à°^âaà``$öäüß'#+,;-Æ©.json"
            $test = Get-UserValuesDirect -UserParams $UserParams
            $test | Should BeOfType hashtable
            Test-Path -LiteralPath "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©" -PathType Container | Should Be $true
            Test-Path -LiteralPath "$BlaDrive\Mirr_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©" -PathType Container | Should Be $true
        }
    }
    Context "Long paths" {
        It "Find existing folders" {
            $UserParams.JSONParamPath   = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\param_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_END.json"
            $UserParams.InputPath       = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.OutputPath      = "$BlaDrive\Out_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.MirrorPath      = "$BlaDrive\Mirr_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.HistFilePath    = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\hist_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_tEND.json"
            $test = Get-UserValuesDirect -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.JSONParamPath | Should Be $UserParams.JSONParamPath
            $test.InputPath     | Should Be $UserParams.InputPath
            $test.OutputPath    | Should Be $UserParams.OutputPath
            $test.MirrorPath    | Should Be $UserParams.MirrorPath
            $test.HistFilePath  | Should Be $UserParams.HistFilePath
        }
        It "Create non-existing folders" {
            Get-ChildItem "$BlaDrive\Out_Test" -Recurse     | Remove-Item
            Get-ChildItem "$BlaDrive\Mirr_Test" -Recurse    | Remove-Item
            (Get-ChildItem "$BlaDrive\Out_Test" -Recurse -ErrorAction SilentlyContinue).Count   | Out-Host
            (Get-ChildItem "$BlaDrive\Mirr_Test" -Recurse -ErrorAction SilentlyContinue).Count  | Out-Host

            $UserParams.JSONParamPath   = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\param_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_END.json"
            $UserParams.InputPath       = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.OutputPath      = "$BlaDrive\Out_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.MirrorPath      = "$BlaDrive\Mirr_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.HistFilePath    = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\hist_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_tEND.json"
            $test = Get-UserValuesDirect -UserParams $UserParams
            $test | Should BeOfType hashtable
            Test-Path -LiteralPath "$BlaDrive\Out_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND" -PathType Container | Should Be $true
            Test-Path -LiteralPath "$BlaDrive\Mirr_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND" -PathType Container | Should Be $true
        }
    }
}

Describe "Show-Parameters" {
    BeforeEach {
        [hashtable]$UserParams = @{
            ShowParams = 0
            GUI_CLI_Direct = "Direct"
            JSONParamPath = "$BlaDrive\In_Test\param_uncomplicated.json"
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
            HistFilePath = "$BlaDrive\In_Test\hist_uncomplicated.json"
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
    It "No problems with SpecChars" {
        $UserParams.JSONParamPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©\param specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©.json"
        $UserParams.InputPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
        $UserParams.OutputPath = "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
        $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©"
        $UserParams.HistFilePath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©\hist specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©.json"
        {Show-Parameters -UserParams $UserParams} | Should not Throw
    }
}

# TODO: Further renewal from here: TODO:
Describe "Set-Parameters" {
    $BlaDrive = "$TestDrive\TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            JSONParamPath = "$TestDrive\TEST\In_Test\param_simpleset.json"
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
            HistFilePath = "$BlaDrive\In_Test\hist_empty.json"
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
        $UserParams.JSONParamPath = "\\0.0.0.0\noparam.json"
        $test = Set-Parameters -UserParams $UserParams
        $test | Should Be $false
    }
    Context "Work correctly with valid param" {
        It "Return `$true when param is correct" {
            $test = Set-Parameters -UserParams $UserParams
            $test | Should Be $true
        }
        It "Replace `"default`"" {
            $test = @(Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
            ,$test | Should BeOfType array
            $bla = @("default")
            (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0
            $test.ParamPresetValues[0].InputPath                | Should Be $UserParams.InputPath
            $test.ParamPresetValues[0].OutputPath               | Should Be $UserParams.OutputPath
            $test.ParamPresetValues[0].MirrorEnable             | Should Be $UserParams.MirrorEnable
            $test.ParamPresetValues[0].MirrorPath               | Should Be $UserParams.MirrorPath
            $test.ParamPresetValues[0].PresetFormats            | Should Be $UserParams.PresetFormats
            $test.ParamPresetValues[0].CustomFormatsEnable      | Should Be $UserParams.CustomFormatsEnable
            $test.ParamPresetValues[0].CustomFormats            | Should Be $UserParams.CustomFormats
            $test.ParamPresetValues[0].OutputSubfolderStyle     | Should Be $UserParams.OutputSubfolderStyle
            $test.ParamPresetValues[0].OutputFileStyle          | Should Be $UserParams.OutputFileStyle
            $test.ParamPresetValues[0].HistFilePath             | Should Be $UserParams.HistFilePath
            $test.ParamPresetValues[0].UseHistFile              | Should Be $UserParams.UseHistFile
            $test.ParamPresetValues[0].WriteHistFile            | Should Be $UserParams.WriteHistFile
            $test.ParamPresetValues[0].HistCompareHashes        | Should Be $UserParams.HistCompareHashes
            $test.ParamPresetValues[0].InputSubfolderSearch     | Should Be $UserParams.InputSubfolderSearch
            $test.ParamPresetValues[0].CheckOutputDupli         | Should Be $UserParams.CheckOutputDupli
            $test.ParamPresetValues[0].VerifyCopies             | Should Be $UserParams.VerifyCopies
            $test.ParamPresetValues[0].OverwriteExistingFiles   | Should Be $UserParams.OverwriteExistingFiles
            $test.ParamPresetValues[0].AvoidIdenticalFiles      | Should Be $UserParams.AvoidIdenticalFiles
            $test.ParamPresetValues[0].ZipMirror                | Should Be $UserParams.ZipMirror
            $test.ParamPresetValues[0].UnmountInputDrive        | Should Be $UserParams.UnmountInputDrive
            $test.ParamPresetValues[0].Preventstandby           | Should Be $script:Preventstandby
        }
        It "Add `"BLA`"" {
            $UserParams.SaveParamPresetName = "BLA"

            $test = Set-Parameters -UserParams $UserParams
            $test | Should Be $true

            $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $bla = @("default","BLA")
            (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

            $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
            $test = $test.ParamPresetValues
            $test.InputPath                 | Should Be $UserParams.InputPath
            $test.OutputPath                | Should Be $UserParams.OutputPath
            $test.MirrorEnable              | Should Be $UserParams.MirrorEnable
            $test.MirrorPath                | Should Be $UserParams.MirrorPath
            $test.PresetFormats             | Should Be $UserParams.PresetFormats
            $test.CustomFormatsEnable       | Should Be $UserParams.CustomFormatsEnable
            $test.CustomFormats             | Should Be $UserParams.CustomFormats
            $test.OutputSubfolderStyle      | Should Be $UserParams.OutputSubfolderStyle
            $test.OutputFileStyle           | Should Be $UserParams.OutputFileStyle
            $test.HistFilePath              | Should Be $UserParams.HistFilePath
            $test.UseHistFile               | Should Be $UserParams.UseHistFile
            $test.WriteHistFile             | Should Be $UserParams.WriteHistFile
            $test.HistCompareHashes         | Should Be $UserParams.HistCompareHashes
            $test.InputSubfolderSearch      | Should Be $UserParams.InputSubfolderSearch
            $test.CheckOutputDupli          | Should Be $UserParams.CheckOutputDupli
            $test.VerifyCopies              | Should Be $UserParams.VerifyCopies
            $test.OverwriteExistingFiles    | Should Be $UserParams.OverwriteExistingFiles
            $test.AvoidIdenticalFiles       | Should Be $UserParams.AvoidIdenticalFiles
            $test.ZipMirror                 | Should Be $UserParams.ZipMirror
            $test.UnmountInputDrive         | Should Be $UserParams.UnmountInputDrive
            $test.Preventstandby            | Should Be $script:Preventstandby
        }
        It "Replace only preset" {
            [array]$inter = @([PSCustomObject]@{
                ParamPresetName = $UserParams.SaveParamPresetName
                ParamPresetValues = [PSCustomObject]@{
                    InputPath =                 $UserParams.InputPath
                    OutputPath =                $UserParams.OutputPath
                    MirrorEnable =              $UserParams.MirrorEnable
                    MirrorPath =                $UserParams.MirrorPath
                    PresetFormats =             $UserParams.PresetFormats
                    CustomFormatsEnable =       $UserParams.CustomFormatsEnable
                    CustomFormats =             $UserParams.CustomFormats
                    OutputSubfolderStyle =      $UserParams.OutputSubfolderStyle
                    OutputFileStyle =           $UserParams.OutputFileStyle
                    HistFilePath =              $UserParams.HistFilePath.Replace($PSScriptRoot,'$($PSScriptRoot)')
                    UseHistFile =               $UserParams.UseHistFile
                    WriteHistFile =             $UserParams.WriteHistFile
                    HistCompareHashes =         $UserParams.HistCompareHashes
                    InputSubfolderSearch =      $UserParams.InputSubfolderSearch
                    CheckOutputDupli =          $UserParams.CheckOutputDupli
                    VerifyCopies =              $UserParams.VerifyCopies
                    OverwriteExistingFiles =    $UserParams.OverwriteExistingFiles
                    AvoidIdenticalFiles =       $UserParams.AvoidIdenticalFiles
                    ZipMirror =                 $UserParams.ZipMirror
                    UnmountInputDrive =         $UserParams.UnmountInputDrive
                    PreventStandby =            $script:PreventStandby
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
            $test.ParamPresetValues[0].InputPath                | Should Be $UserParams.InputPath
            $test.ParamPresetValues[0].OutputPath               | Should Be $UserParams.OutputPath
            $test.ParamPresetValues[0].MirrorEnable             | Should Be $UserParams.MirrorEnable
            $test.ParamPresetValues[0].MirrorPath               | Should Be $UserParams.MirrorPath
            $test.ParamPresetValues[0].PresetFormats            | Should Be $UserParams.PresetFormats
            $test.ParamPresetValues[0].CustomFormatsEnable      | Should Be $UserParams.CustomFormatsEnable
            $test.ParamPresetValues[0].CustomFormats            | Should Be $UserParams.CustomFormats
            $test.ParamPresetValues[0].OutputSubfolderStyle     | Should Be $UserParams.OutputSubfolderStyle
            $test.ParamPresetValues[0].OutputFileStyle          | Should Be $UserParams.OutputFileStyle
            $test.ParamPresetValues[0].HistFilePath             | Should Be $UserParams.HistFilePath
            $test.ParamPresetValues[0].UseHistFile              | Should Be $UserParams.UseHistFile
            $test.ParamPresetValues[0].WriteHistFile            | Should Be $UserParams.WriteHistFile
            $test.ParamPresetValues[0].HistCompareHashes        | Should Be $UserParams.HistCompareHashes
            $test.ParamPresetValues[0].InputSubfolderSearch     | Should Be $UserParams.InputSubfolderSearch
            $test.ParamPresetValues[0].CheckOutputDupli         | Should Be $UserParams.CheckOutputDupli
            $test.ParamPresetValues[0].VerifyCopies             | Should Be $UserParams.VerifyCopies
            $test.ParamPresetValues[0].OverwriteExistingFiles   | Should Be $UserParams.OverwriteExistingFiles
            $test.ParamPresetValues[0].AvoidIdenticalFiles      | Should Be $UserParams.AvoidIdenticalFiles
            $test.ParamPresetValues[0].ZipMirror                | Should Be $UserParams.ZipMirror
            $test.ParamPresetValues[0].UnmountInputDrive        | Should Be $UserParams.UnmountInputDrive
            $test.ParamPresetValues[0].Preventstandby           | Should Be $script:Preventstandby
        }
    }
    It "Special characters work properly" {
        $UserParams.JSONParamPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©\param specChar.(]){[}à°^âaà`````$öäüß'#+,;-Æ©.json"
        $UserParams.SaveParamPresetName = "bla"

        $test = Set-Parameters -UserParams $UserParams
        $test | Should Be $true

        $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        ,$test | Should BeOfType array
        $bla = @("bla","default","default2","123456789","ae","bracket","backtick","dots","special")
        (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

        $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
        $test = $test.ParamPresetValues
        $test.InputPath                 | Should Be $UserParams.InputPath
        $test.OutputPath                | Should Be $UserParams.OutputPath
        $test.MirrorEnable              | Should Be $UserParams.MirrorEnable
        $test.MirrorPath                | Should Be $UserParams.MirrorPath
        $test.PresetFormats             | Should Be $UserParams.PresetFormats
        $test.CustomFormatsEnable       | Should Be $UserParams.CustomFormatsEnable
        $test.CustomFormats             | Should Be $UserParams.CustomFormats
        $test.OutputSubfolderStyle      | Should Be $UserParams.OutputSubfolderStyle
        $test.OutputFileStyle           | Should Be $UserParams.OutputFileStyle
        $test.HistFilePath              | Should Be $UserParams.HistFilePath
        $test.UseHistFile               | Should Be $UserParams.UseHistFile
        $test.WriteHistFile             | Should Be $UserParams.WriteHistFile
        $test.HistCompareHashes         | Should Be $UserParams.HistCompareHashes
        $test.InputSubfolderSearch      | Should Be $UserParams.InputSubfolderSearch
        $test.CheckOutputDupli          | Should Be $UserParams.CheckOutputDupli
        $test.VerifyCopies              | Should Be $UserParams.VerifyCopies
        $test.OverwriteExistingFiles    | Should Be $UserParams.OverwriteExistingFiles
        $test.AvoidIdenticalFiles       | Should Be $UserParams.AvoidIdenticalFiles
        $test.ZipMirror                 | Should Be $UserParams.ZipMirror
        $test.UnmountInputDrive         | Should Be $UserParams.UnmountInputDrive
        $test.Preventstandby            | Should Be $script:Preventstandby
    }
}

Describe "Start-FileSearch" {
    $BlaDrive = "$TestDrive\TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath = "$BlaDrive\In_Test"
            InputSubfolderSearch = 1
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
            $test.length | Should Be 49
        }
        It "Return array even if only one file is found" {
            $UserParams.allChosenFormats = @("*.cr3")
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $bla = Get-ChildItem -LiteralPath "$($UserParams.InputPath)\single file.cr3" | ForEach-Object {
                [PSCustomObject]@{
                    InFullName = $_.FullName
                    InPath = (Split-Path -Path $_.FullName -Parent)
                    InName = $_.Name
                    InBaseName = $(if($UserParams.OutputFileStyle -eq "unchanged"){$_.BaseName}else{$_.LastWriteTime.ToString("$($UserParams.OutputFileStyle)")})
                    Extension = $_.Extension
                    Size = $_.Length
                    Date = $_.LastWriteTime.ToString("yyyy-MM-dd_HH-mm-ss")
                    OutSubfolder = $(if($UserParams.OutputSubfolderStyle -eq "none"){""}elseif($UserParams.OutputSubfolderStyle -eq "unchanged"){$($(Split-Path -Parent -Path $_.FullName).Replace($UserParams.InputPath,""))}else{"\$($_.LastWriteTime.ToString("$($UserParams.OutputSubfolderStyle)"))"}) # TODO: should there really be a backslash? # TODO: should it really be empty for unchanged in root folder?
                    Hash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash
                }
            }
            $test.length        | Should Be 1
            $test.InPath        | Should Be $UserParams.InputPath
            $test.InName        | Should Be $bla.InName
            $test.InFullName    | Should Be "$($UserParams.InputPath)\single file.cr3"
            $test.InBaseName    | Should Be $bla.InBaseName
            $test.Extension     | Should Be $UserParams.allChosenFormats.Replace("*","")
            $test.Size          | Should Be $bla.Size
            $test.Date          | Should Be $bla.Date
            $test.OutSubfolder  | Should Be $bla.OutSubfolder
            $test.OutPath       | Should Be "ZYX"
            $test.OutName       | Should Be "ZYX"
            $test.OutBaseName   | Should Be "ZYX"
            $test.Hash          | Should Be $bla.Hash
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
            $UserParams.allChosenFormats = @("*.cr3")
            $UserParams.HistCompareHashes = 0
            $UserParams.UseHistFile = 0
            $UserParams.CheckOutputDupli = 0
        }
        It "none" {
            $UserParams.OutputSubfolderStyle = "none"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
            $test.OutSubfolder  | Should Be ""
            $test.OutPath       | Should Be "ZYX"
        }
        It "unchanged" {
            $UserParams.allChosenFormats = @("*.cr4")
            $UserParams.OutputSubfolderStyle = "unchanged"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
            $test.OutSubfolder  | Should Be "\123456789 ordner"
            $test.OutPath       | Should Be "ZYX"
        }
        It "yyyy-MM-dd" {
            $UserParams.OutputSubfolderStyle = "yyyy-MM-dd"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
            $test.OutSubfolder  | Should Be "\2018-03-12"
            $test.OutPath       | Should Be "ZYX"
        }
        It "yyyy_MM_dd" {
            $UserParams.OutputSubfolderStyle = "yyyy_MM_dd"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
            $test.OutSubfolder  | Should Be "\2018_03_12"
            $test.OutPath       | Should Be "ZYX"
        }
        It "yyyy.MM.dd" {
            $UserParams.OutputSubfolderStyle = "yyyy.MM.dd"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
            $test.OutSubfolder  | Should Be "\2018.03.12"
            $test.OutPath       | Should Be "ZYX"
        }
        It "yyyyMMdd" {
            $UserParams.OutputSubfolderStyle = "yyyyMMdd"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
            $test.OutSubfolder  | Should Be "\20180312"
            $test.OutPath       | Should Be "ZYX"
        }
        It "yy-MM-dd" {
            $UserParams.OutputSubfolderStyle = "yy-MM-dd"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
            $test.OutSubfolder  | Should Be "\18-03-12"
            $test.OutPath       | Should Be "ZYX"
        }
        It "yy_MM_dd" {
            $UserParams.OutputSubfolderStyle = "yy_MM_dd"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
            $test.OutSubfolder  | Should Be "\18_03_12"
            $test.OutPath       | Should Be "ZYX"
        }
        It "yy.MM.dd" {
            $UserParams.OutputSubfolderStyle = "yy.MM.dd"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
            $test.OutSubfolder  | Should Be "\18.03.12"
            $test.OutPath       | Should Be "ZYX"
        }
        It "yyMMdd" {
            $UserParams.OutputSubfolderStyle = "yyMMdd"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
            $test.OutSubfolder      | Should Be "\180312"
            $test.OutPath       | Should Be "ZYX"
        }
    }
    Context "Proper implementation of OutputFileStyle" {
        BeforeEach {
            $UserParams.allChosenFormats = @("*.cr3")
            $UserParams.HistCompareHashes = 0
            $UserParams.UseHistFile = 0
            $UserParams.CheckOutputDupli = 0
        }
        It "unchanged" {
            $UserParams.OutputFileStyle = "unchanged"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "single File"
            $test.Date          | Should Be "2018-03-12_18-01-43"
        }
        It "yyyy-MM-dd_HH-mm-ss" {
            $UserParams.OutputFileStyle = "yyyy-MM-dd_HH-mm-ss"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "2018-03-12_18-01-43"
            $test.Date          | Should Be "2018-03-12_18-01-43"
        }
        It "yyyyMMdd_HHmmss" {
            $UserParams.OutputFileStyle = "yyyyMMdd_HHmmss"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "20180312_180143"
            $test.Date          | Should Be "2018-03-12_18-01-43"
        }
        It "yyyyMMddHHmmss" {
            $UserParams.OutputFileStyle = "yyyyMMddHHmmss"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "20180312180143"
            $test.Date          | Should Be "2018-03-12_18-01-43"
        }
        It "yy-MM-dd_HH-mm-ss" {
            $UserParams.OutputFileStyle = "yy-MM-dd_HH-mm-ss"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "18-03-12_18-01-43"
            $test.Date          | Should Be "2018-03-12_18-01-43"
        }
        It "yyMMdd_HHmmss" {
            $UserParams.OutputFileStyle = "yyMMdd_HHmmss"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "180312_180143"
            $test.Date          | Should Be "2018-03-12_18-01-43"
        }
        It "yyMMddHHmmss" {
            $UserParams.OutputFileStyle = "yyMMddHHmmss"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "180312180143"
            $test.Date          | Should Be "2018-03-12_18-01-43"
        }
        It "HH-mm-ss" {
            $UserParams.OutputFileStyle = "HH-mm-ss"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "18-01-43"
            $test.Date          | Should Be "2018-03-12_18-01-43"
        }
        It "HH_mm_ss" {
            $UserParams.OutputFileStyle = "HH_mm_ss"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "18_01_43"
            $test.Date          | Should Be "2018-03-12_18-01-43"
        }
        It "HHmmss" {
            $UserParams.OutputFileStyle = "HHmmss"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.length        | Should Be 1
            $test.InBaseName    | Should Be "180143"
            $test.Date          | Should Be "2018-03-12_18-01-43"
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
            $test.length    | Should Be 86
        }
        It "12345" {
            $UserParams.InputPath = "$BlaDrive\In_Test\123456789 ordner"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be 12
            $test = $test | Where-Object {$_.InBaseName -match '123412356789\ file$' -and $_.Extension -eq ".cr2"}
            $test.InPath            | Should Be $UserParams.InputPath
            $test.InName            | Should Be "123412356789 file.cr2"
            $test.InBaseName        | Should Be "123412356789 file"
            $test.Hash              | Should Be "3A3514D39089FAF261CAF7EC50CB06D44021C424"
        }
        It "Æ" {
            $UserParams.InputPath = "$BlaDrive\In_Test\ÆOrdner ©"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be 11
            $test = $test | Where-Object {$_.InBaseName -match 'Æfile©$'}
            $test.InPath        | Should Be $UserParams.InputPath
            $test.InName        | Should Be "Æfile©.jpeg"
            $test.InBaseName    | Should Be "Æfile©"
            $test.Hash          | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"
        }
        It "backtick" {
            $UserParams.InputPath = "$BlaDrive\In_Test\backtick ````ordner ``"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be 11
            $test = $test | Where-Object {$_.InBaseName -match 'backtick\ \`\ file\ \`\`$'}
            $test.InPath        | Should Be $UserParams.InputPath
            $test.InName        | Should Be "backtick `` file ````.jpg"
            $test.InBaseName    | Should Be "backtick `` file ````"
            $test.Hash          | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"

        }
        It "bracket" {
            $UserParams.InputPath = "$BlaDrive\In_Test\bracket [ ] ordner"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be 11
            $test = $test | Where-Object {$_.InBaseName -match 'bracket\ \[\ \]\ file$'}
            $test.InPath        | Should Be $UserParams.InputPath
            $test.InName        | Should Be "bracket [ ] file.jpg"
            $test.InBaseName    | Should Be "bracket [ ] file"
            $test.Hash          | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"

        }
        It "dots" {
            $UserParams.InputPath = "$BlaDrive\In_Test\ordner.mit.punkten"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be 11
            $test = $test | Where-Object {$_.InBaseName -like "file.with.dots"}
            $test.InPath        | Should Be $UserParams.InputPath
            $test.InName        | Should Be "file.with.dots.jpg"
            $test.InBaseName    | Should Be "file.with.dots"
            $test.Hash          | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"

        }
        It "specials" {
            $UserParams.InputPath = "$BlaDrive\In_Test\special ' ! ,; . ordner"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be 11
            $test = $test | Where-Object {$_.InBaseName -like "special '!, ;. file"}
            $test.InPath        | Should Be $UserParams.InputPath
            $test.InName        | Should Be "special '!, ;. file.jpg"
            $test.InBaseName    | Should Be "special '!, ;. file"
            $test.Hash          | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"
        }
    }
}

Describe "Get-HistFile"{
    $BlaDrive = "$TestDrive\TEST"
    # DEFINITION: Combine all parameters into a hashtable:
    BeforeEach {
        [hashtable]$UserParams = @{
            HistFilePath = "$BlaDrive\In_Test\mc_hist.json"
            UseHistFile = 1
            WriteHistFile = "yes"
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
            $test = $test | Where-Object {$_.InName -eq "123412356789 file.jpg"}
            $test.InName | Should Be "123412356789 file.jpg"
            $test.Date   | Should Be "2018-03-17_15-10-58"
            $test.size   | Should Be 4408
            $test.hash   | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"
        }
        It "Æ" {
            $UserParams.HistFilePath = "$BlaDrive\In_Test\ÆOrdner ©\Æ hist ©.json"
            $test = @(Get-HistFile -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test = $test | Where-Object {$_.InName -eq "Æfile©.jpeg"}
            $test.InName | Should Be "Æfile©.jpeg"
            $test.Date   | Should Be "2018-03-17_15-11-08"
            $test.size   | Should Be 4408
            $test.hash   | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"
        }
        It "backtick" {
            $UserParams.HistFilePath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````hist ``.json"
            $test = @(Get-HistFile -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test = $test | Where-Object {$_.InName -eq "backtick `` file ```` _1.jpg"}
            $test.InName | Should Be "backtick `` file ```` _1.jpg"
            $test.Date   | Should Be "2018-03-17_15-10-59"
            $test.size   | Should Be 4408
            $test.hash   | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"
        }
        It "bracket" {
            $UserParams.HistFilePath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] hist.json"
            $test = @(Get-HistFile -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test = $test | Where-Object {$_.InName -eq "bracket [ ] file.jpg"}
            $test.InName | Should Be "bracket [ ] file.jpg"
            $test.Date   | Should Be "2018-03-17_15-11-01"
            $test.size   | Should Be 4408
            $test.hash   | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"
        }
        It "dots" {
            $UserParams.HistFilePath = "$BlaDrive\In_Test\ordner.mit.punkten\dot.hist.json"
            $test = @(Get-HistFile -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test = $test | Where-Object {$_.InName -eq "file.with.dots.jpg"}
            $test.InName | Should Be "file.with.dots.jpg"
            $test.Date   | Should Be "2018-03-17_15-11-02"
            $test.size   | Should Be 4408
            $test.hash   | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"
        }
        It "specials" {
            $UserParams.HistFilePath = "$BlaDrive\In_Test\special ' ! ,; . ordner\special ' ! ,; . hist.json"
            $test = @(Get-HistFile -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test = $test | Where-Object {$_.InName -eq "special '!, ;. file.jpg"}
            $test.InName | Should Be "special '!, ;. file.jpg"
            $test.Date   | Should Be "2018-03-17_15-11-02"
            $test.size   | Should Be 4408
            $test.hash   | Should Be "BDF90B1006CEADA6355E5274CDCDD96788624D7C"
        }
    }
}

    Describe "Start-DupliCheckHist"{
        $BlaDrive = "$TestDrive\TEST"
        # DEFINITION: Combine all parameters into a hashtable:
        BeforeEach {
            [hashtable]$UserParams = @{
                InputPath = "$BlaDrive\In_Test"
                OutputPath = "$BlaDrive\Out_Test"
                allChosenFormats = @("*")
                OutputSubfolderStyle = "yyyy-MM-dd"
                OutputFileStyle = "unchanged"
                HistFilePath = "$BlaDrive\In_Test\mc_hist.json" #TODO: renew file?
                UseHistFile = 1
                WriteHistFile = "yes"
                HistCompareHashes = 1
            }
        }
        New-Item -ItemType Directory -Path $BlaDrive
        Push-Location $BlaDrive
        Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
        Pop-Location

        Context "Working normal" {
            $HistFiles = @(Get-HistFile -UserParams $UserParams)
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            
            It "Return array with correct params, don't overlap w/ HistFiles" {
                $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
                ,$test | Should BeOfType array
                (Compare-Object $test $HistFiles -ExcludeDifferent -IncludeEqual -Property InName,Date,Size,Hash).count | Should Be 0
            }
            It "Throws Error when parameters are wrong / missing" {
                {Start-DupliCheckHist} | Should Throw
                {Start-DupliCheckHist -InFiles @() -HistFiles @() -UserParams @()} | Should Throw
            }
        }
        Context "No problems with SpecChars" {
            It "12345" {
                $UserParams.InputPath = "$BlaDrive\In_Test\123456789 ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\123456789 ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\123456789 ordner\123456789 hist.json"
                $HistFiles = @(Get-HistFile -UserParams $UserParams)
                $InFiles = @(Start-FileSearch -UserParams $UserParams)

                $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
                ,$test | Should BeOfType array
                (Compare-Object $test $HistFiles -ExcludeDifferent -IncludeEqual -Property InName,Date,Size,Hash).count | Should Be 0
            }
            It "Æ ©" {
                $UserParams.InputPath = "$BlaDrive\In_Test\ÆOrdner ©"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\ÆOrdner ©"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\ÆOrdner ©\Æ hist ©.json"
                $HistFiles = @(Get-HistFile -UserParams $UserParams)
                $InFiles = @(Start-FileSearch -UserParams $UserParams)

                $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
                ,$test | Should BeOfType array
                (Compare-Object $test $HistFiles -ExcludeDifferent -IncludeEqual -Property InName,Date,Size,Hash).count | Should Be 0
            }
            It "backtick" {
                $UserParams.InputPath = "$BlaDrive\In_Test\backtick ````ordner ``"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\backtick ````ordner ``"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\backtick ````ordner ``\backtick ````hist ``.json"
                $HistFiles = @(Get-HistFile -UserParams $UserParams)
                $InFiles = @(Start-FileSearch -UserParams $UserParams)

                $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
                ,$test | Should BeOfType array
                (Compare-Object $test $HistFiles -ExcludeDifferent -IncludeEqual -Property InName,Date,Size,Hash).count | Should Be 0
            }
            It "bracket" {
                $UserParams.InputPath = "$BlaDrive\In_Test\bracket [ ] ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\bracket [ ] ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\bracket [ ] ordner\bracket [ ] hist.json"
                $HistFiles = @(Get-HistFile -UserParams $UserParams)
                $InFiles = @(Start-FileSearch -UserParams $UserParams)

                $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
                ,$test | Should BeOfType array
                (Compare-Object $test $HistFiles -ExcludeDifferent -IncludeEqual -Property InName,Date,Size,Hash).count | Should Be 0
            }
            It "dots" {
                $UserParams.InputPath = "$BlaDrive\In_Test\ordner.mit.punkten"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\ordner.mit.punkten"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\ordner.mit.punkten\123456789 hist.json"
                $HistFiles = @(Get-HistFile -UserParams $UserParams)
                $InFiles = @(Start-FileSearch -UserParams $UserParams)

                $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
                ,$test | Should BeOfType array
                (Compare-Object $test $HistFiles -ExcludeDifferent -IncludeEqual -Property InName,Date,Size,Hash).count | Should Be 0
            }
            It "specials" {
                $UserParams.InputPath = "$BlaDrive\In_Test\123456789 ordner"
                $UserParams.OutputPath = "$BlaDrive\Out_Test\123456789 ordner"
                $UserParams.HistFilePath = "$BlaDrive\In_Test\123456789 ordner\123456789 hist.json"
                $HistFiles = @(Get-HistFile -UserParams $UserParams)
                $InFiles = @(Start-FileSearch -UserParams $UserParams)

                $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
                ,$test | Should BeOfType array
                (Compare-Object $test $HistFiles -ExcludeDifferent -IncludeEqual -Property InName,Date,Size,Hash).count | Should Be 0
            }
        }
    }

<#
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