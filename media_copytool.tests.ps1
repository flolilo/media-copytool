# Comment out the last block of media_copytool (i.e. "Start-up") before running this script!
# Maybe also comment out write-colorout function.

# DEFINITION: Get all error-outputs in English:
[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
# DEFINITION: Hopefully avoiding errors by wrong encoding now:
    $OutputEncoding = New-Object -TypeName System.Text.UTF8Encoding
    [Console]::InputEncoding = New-Object -TypeName System.Text.UTF8Encoding

. $PSScriptRoot\media_copytool.ps1

Describe "Get-ParametersFromJSON" {
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            ShowParams =            0
            Enable_GUI =            0
            JSONParamPath =         "$BlaDrive\In_Test\param_uncomplicated.json"
            LoadParamPresetName =   ""
            SaveParamPresetName =   ""
            RememberInPath =        0
            RememberOutPath =       0
            RememberMirrorPath =    0
            RememberSettings =      0
            # DEFINITION: From here on, parameters can be set both via parameters and via JSON file(s).
            InputPath =             ""
            OutputPath =            ""
            MirrorEnable =          -1
            MirrorPath =            ""
            FormatPreference =      ""
            FormatInExclude =       @()
            OutputSubfolderStyle =  ""
            OutputFileStyle =       ""
            HistFilePath =          ""
            UseHistFile =           -1
            WriteHistFile =         ""
            HistCompareHashes =     -1
            CheckOutputDupli =      -1
            InputSubfolderSearch =  -1
            AvoidIdenticalFiles =   -1
            AcceptTimeDiff =        -1
            VerifyCopies =          -1
            OverwriteExistingFiles = -1
            ZipMirror =             -1
            UnmountInputDrive =     -1
        }
    }
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    # tree /F /A | Out-Host
    Pop-Location

    Context "Uncomplicated file interaction" {
        It "Work fine with proper parameters" {
            $test = Get-ParametersFromJSON -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName   | Should Be "default"
        }
        It "Nonexistent/Empty LoadParamPresetName leads to `"default`"" {
            $UserParams.LoadParamPresetName = "nonexistent"
            $test = Get-ParametersFromJSON -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName   | Should Be "default"

            $UserParams.LoadParamPresetName = ""
            $test = Get-ParametersFromJSON -UserParams $UserParams -Renew 1
            $test | Should BeOfType hashtable
            $test.LoadParamPresetName   | Should Be "default"
        }
        It "Throw when not finding anything" {
            $UserParams.JSONParamPath = "$BlaDrive\In_Test\notthere.json"
            {Get-ParametersFromJSON -UserParams $UserParams -Renew 1} | Should Throw
        }
        It "Throw error when UserParams are of wrong type" {
            {Get-ParametersFromJSON -UserParams "hallo" -Renew 1} | Should Throw
            {Get-ParametersFromJSON -UserParams $UserParams -Renew "hallo"} | Should Throw
        }
        It "Throw error with empty UserParams" {
            {Get-ParametersFromJSON} | Should Throw
            {Get-ParametersFromJSON -UserParams @{} -Renew 1} | Should Throw
            {Get-ParametersFromJSON -UserParams $UserParams} | Should Throw
            {Get-ParametersFromJSON -Renew 1} | Should Throw
        }
        It "Throw error when param.JSON is empty" {
            $UserParams.JSONParamPath = "$BlaDrive\In_Test\param_empty.json"
            {Get-ParametersFromJSON  -UserParams $UserParams -Renew 1} | Should Throw
        }
    }
    It "Special characters file&preset interaction" {
        $UserParams.JSONParamPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\param specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.json"
        "specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $UserParams.LoadParamPresetName = "specchar"
        $test = Get-ParametersFromJSON -UserParams $UserParams -Renew 1
        $test | Should BeOfType hashtable
        $test.LoadParamPresetName | Should Be "specchar"
        $test.InputPath             | Should Be "F:\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $test.OutputPath            | Should Be "F:\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $test.MirrorPath            | Should Be "F:\Mirr_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $test.HistFilePath          | Should Be "F:\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\hist specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.json"
    }
    It "Long filename file&preset interaction" {
        $UserParams.JSONParamPath = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\param_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_END.json"
        $UserParams.LoadParamPresetName = "long"
        $test = Get-ParametersFromJSON -UserParams $UserParams -Renew 1
        $test | Should BeOfType hashtable
        $test.LoadParamPresetName | Should Be "long"
        $test.InputPath             | Should Be "F:\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
        $test.OutputPath            | Should Be "F:\Out_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
        $test.MirrorPath            | Should Be "F:\Mirr_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
        $test.HistFilePath          | Should Be "F:\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\hist_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_tEND.json"
    }
    Context "Test the returned values" {
        $UserParams.JSONParamPath = "$BlaDrive\In_Test\param_uncomplicated.json"
        $UserParams.LoadParamPresetName = "bla"
        $test = Get-ParametersFromJSON -UserParams $UserParams -Renew 1
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
        It "FormatPreference" {
            $test.FormatPreference  | Should BeOfType string
            $test.FormatPreference  | Should Be "FooBar"
        }
        It "FormatInExclude" {
            ,$test.FormatInExclude  | Should BeOfType array
            $test.FormatInExclude   | Should Be @("*Foobar")
        }
        It "OutputSubfolderStyle" {
            $test.OutputSubfolderStyle | Should BeOfType string
            $test.OutputSubfolderStyle | Should Be "%y4%-%mo%-%d%-FOO"
        }
        It "OutputFileStyle" {
            $test.OutputFileStyle   | Should BeOfType string
            $test.OutputFileStyle   | Should Be "%n-BAR%"
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
        It "EnableLongPaths" {
            $test.EnableLongPaths    | Should BeOfType int
            $test.EnableLongPaths    | Should Be 21
        }
        It "AvoidIdenticalFiles" {
            $test.AvoidIdenticalFiles   | Should BeOfType int
            $test.AvoidIdenticalFiles   | Should Be 22
        }
        It "ZipMirror" {
            $test.ZipMirror | Should BeOfType int
            $test.ZipMirror | Should Be 23
        }
        It "UnmountInputDrive" {
            $test.UnmountInputDrive | Should BeOfType int
            $test.UnmountInputDrive | Should Be 24
        }
        It "AcceptTimeDiff" {
            $test.AcceptTimeDiff | Should BeOfType int
            $test.AcceptTimeDiff | Should Be 26
        }
        It "Preventstandby (TODO: find a way to get Preventstandby working)" {
            # $test.Preventstandby    | Should BeOfType int
            # $test.Preventstandby    | Should Be 24
        }
    }
}

Describe "Start-GUI" {
    It "TODO: find a way to get this working." {

    }
}


Describe "Test-UserValues" {
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            ShowParams =            0
            Enable_GUI =            0
            JSONParamPath =         "$BlaDrive\In_Test\param_uncomplicated.json"
            LoadParamPresetName =   "default"
            SaveParamPresetName =   "default"
            RememberInPath =        0
            RememberOutPath =       0
            RememberMirrorPath =    0
            RememberSettings =      0
            # DEFINITION: From here on, parameters can be set both via parameters and via JSON file(s).
            InputPath =             "$BlaDrive\In_Test"
            OutputPath =            "$BlaDrive\Out_Test"
            MirrorEnable =          1
            MirrorPath =            "$BlaDrive\Mirr_Test"
            FormatPreference =      "include"
            FormatInExclude =       @("*.cr2")
            OutputSubfolderStyle =  "%y4%-%mo%-%d%"
            OutputFileStyle =       "%n%"
            HistFilePath =          "$BlaDrive\In_Test\mc_hist.json"
            UseHistFile =           0
            WriteHistFile =         "no"
            HistCompareHashes =     0
            InputSubfolderSearch =  0
            CheckOutputDupli =      0
            VerifyCopies =          0
            OverwriteExistingFiles = 0
            EnableLongPaths =       0
            AvoidIdenticalFiles =   0
            AcceptTimeDiff =        0
            ZipMirror =             0
            UnmountInputDrive =     0
        }
        $script:Preventstandby = 0
    }
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    Context "Test the returned values" {
        It "If everything is correct, return hashtable" {
            $test = Test-UserValues -UserParams $UserParams
            $test | Should BeOfType hashtable
        }
        It "InputPath" {
            $test = (Test-UserValues -UserParams $UserParams).InputPath
            $test | Should BeOfType string
            $test | Should Be "$BlaDrive\In_Test"
        }
        It "InputPath - trailing backslash" {
            $UserParams.InputPath = "$BlaDrive\In_Test\"
            $test = (Test-UserValues -UserParams $UserParams).InputPath
            $test | Should BeOfType string
            $test | Should Be "$BlaDrive\In_Test"
        }
        It "OutputPath" {
            $test = (Test-UserValues -UserParams $UserParams).OutputPath
            $test | Should BeOfType string
            $test | Should Be "$BlaDrive\Out_Test"
        }
        It "OutputPath - trailing backslash" {
            $UserParams.OutputPath = "$BlaDrive\Out_Test\"
            $test = (Test-UserValues -UserParams $UserParams).OutputPath
            $test | Should BeOfType string
            $test | Should Be "$BlaDrive\Out_Test"
        }
        It "MirrorEnable" {
            $test = (Test-UserValues -UserParams $UserParams).MirrorEnable
            $test | Should BeOfType int
            $test | Should Be 1
        }
        It "MirrorPath" {
            $test = (Test-UserValues -UserParams $UserParams).MirrorPath
            $test | Should BeOfType string
            $test | Should Be "$BlaDrive\Mirr_Test"
        }
        It "MirrorPath - trailing backslash" {
            $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\"
            $test = (Test-UserValues -UserParams $UserParams).MirrorPath
            $test | Should BeOfType string
            $test | Should Be "$BlaDrive\Mirr_Test"
        }
        It "FormatPreference" {
            $test = (Test-UserValues -UserParams $UserParams).FormatPreference
            $test | Should BeOfType string
            $test | Should Be "include"
        }
        It "FormatInExclude" {
            $test = (Test-UserValues -UserParams $UserParams).FormatInExclude
            ,$test | Should BeOfType array
            $test | Should Be @("*.cr2")
        }
        It "OutputSubfolderStyle" {
            $test = (Test-UserValues -UserParams $UserParams).OutputSubfolderStyle
            $test | Should BeOfType string
            $test | Should Be "%y4%-%mo%-%d%"
        }
        It "OutputFileStyle" {
            $test = (Test-UserValues -UserParams $UserParams).OutputFileStyle
            $test | Should BeOfType string
            $test | Should Be "%n%"
        }
        It "HistFilePath" {
            $test = (Test-UserValues -UserParams $UserParams).HistFilePath
            $test | Should BeOfType string
            $test | Should Be "$BlaDrive\In_Test\mc_hist.json"
        }
        It "UseHistFile" {
            $test = (Test-UserValues -UserParams $UserParams).UseHistFile
            $test | Should BeOfType int
            $test | Should Be 0
        }
        It "WriteHistFile" {
            $test = (Test-UserValues -UserParams $UserParams).WriteHistFile
            $test | Should BeOfType string
            $test | Should Be "no"
        }
        It "HistCompareHashes" {
            $test = (Test-UserValues -UserParams $UserParams).HistCompareHashes
            $test | Should BeOfType int
            $test | Should Be 0
        }
        It "InputSubfolderSearch" {
            $test = (Test-UserValues -UserParams $UserParams).InputSubfolderSearch
            $test | Should BeOfType switch
            $test | Should Be $false
        }
        It "CheckOutputDupli" {
            $test = (Test-UserValues -UserParams $UserParams).CheckOutputDupli
            $test | Should BeOfType int
            $test | Should Be 0
        }
        It "VerifyCopies" {
            $test = (Test-UserValues -UserParams $UserParams).VerifyCopies
            $test | Should BeOfType int
            $test | Should Be 0
        }
        It "OverwriteExistingFiles" {
            $test = (Test-UserValues -UserParams $UserParams).OverwriteExistingFiles
            $test | Should BeOfType int
            $test | Should Be 0
        }
        It "EnableLongPaths" {
            $test = (Test-UserValues -UserParams $UserParams).EnableLongPaths
            $test | Should BeOfType int
            $test | Should Be 0
        }
        It "AvoidIdenticalFiles" {
            $test = (Test-UserValues -UserParams $UserParams).AvoidIdenticalFiles
            $test | Should BeOfType int
            $test | Should Be 0
        }
        It "AcceptTimeDiff" {
            $test = (Test-UserValues -UserParams $UserParams).AcceptTimeDiff
            $test | Should BeOfType int
            $test | Should Be 0
        }
        It "ZipMirror" {
            $test = (Test-UserValues -UserParams $UserParams).ZipMirror
            $test | Should BeOfType int
            $test | Should Be 0
        }
        It "UnmountInputDrive" {
            $test = (Test-UserValues -UserParams $UserParams).UnmountInputDrive
            $test | Should BeOfType int
            $test | Should Be 0
        }
        It "Preventstandby (TODO: Make this work)" {
            # $test = (Get-ParametersFromJSON -UserParams $UserParams -Renew 1).Preventstandby
            # $test | Should BeOfType int
            # $test | Should Be 112
        }
    }
    Context "If anything is wrong, throw" {
        It "InputPath is non-existing" {
            $UserParams.InputPath = "$BlaDrive\NONE"
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "InputPath is too short" {
            $UserParams.InputPath = "A"
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "OutputPath same as InputPath" {
            $UserParams.InputPath = "$BlaDrive\In_Test"
            $UserParams.OutputPath = "$BlaDrive\In_Test"
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "OutputPath is non-existing" {
            $UserParams.OutputPath = "\\0.0.0.0"
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "OutputPath is too short" {
            $UserParams.OutputPath = "A"
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "MirrorEnable is wrong" {
            $UserParams.MirrorEnable = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.MirrorEnable = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.MirrorEnable = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "MirrorPath same as InputPath" {
            $UserParams.InputPath = "$BlaDrive\In_Test"
            $UserParams.MirrorPath = "$BlaDrive\In_Test"
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "MirrorPath same as OutputPath" {
            $UserParams.MirrorPath = "$BlaDrive\Out_Test"
            $UserParams.OutputPath = "$BlaDrive\Out_Test"
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "MirrorPath is non-existing" {
            $UserParams.MirrorEnable = 1
            $UserParams.MirrorPath = "\\0.0.0.0"
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "MirrorPath is too short" {
            $UserParams.MirrorEnable = 1
            $UserParams.MirrorPath = "A"
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "FormatPreference is wrong" {
            $UserParams.FormatPreference = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.FormatPreference = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.FormatPreference = ""
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "FormatInExclude is wrong" {
            $UserParams.FormatInExclude = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.FormatInExclude = 123
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "OutputSubfolderStyle is wrong (TODO: not possible?)" {
            <#
                $UserParams.OutputSubfolderStyle = 123
                {Test-UserValues -UserParams $UserParams} | Should Throw
                $UserParams.OutputSubfolderStyle = ""
                {Test-UserValues -UserParams $UserParams} | Should Throw
            #>
        }
        It "OutputFileStyle is wrong" {
            $UserParams.OutputFileStyle = 123
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.OutputFileStyle = ""
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "UseHistFile is wrong" {
            $UserParams.UseHistFile = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.UseHistFile = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.UseHistFile = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "WriteHistFile is wrong" {
            $UserParams.WriteHistFile = ""
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.WriteHistFile = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.WriteHistFile = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "HistFilePath is wrong" {
            $UserParams.UseHistFile = 1
            $UserParams.HistFilePath = "\\0.0.0.0"
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "HistCompareHashes is wrong" {
            $UserParams.HistCompareHashes = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.HistCompareHashes = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.HistCompareHashes = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "InputSubfolderSearch is wrong" {
            $UserParams.InputSubfolderSearch = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.InputSubfolderSearch = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.InputSubfolderSearch = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "CheckOutputDupli is wrong" {
            $UserParams.CheckOutputDupli = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.CheckOutputDupli = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.CheckOutputDupli = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "VerifyCopies is wrong" {
            $UserParams.VerifyCopies = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.VerifyCopies = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.VerifyCopies = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "OverwriteExistingFiles is wrong" {
            $UserParams.OverwriteExistingFiles = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.OverwriteExistingFiles = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.OverwriteExistingFiles = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "EnableLongPaths is wrong" {
            $UserParams.EnableLongPaths = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.EnableLongPaths = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.EnableLongPaths = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "AvoidIdenticalFiles is wrong" {
            $UserParams.AvoidIdenticalFiles = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.AvoidIdenticalFiles = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.AvoidIdenticalFiles = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "AcceptTimeDiff is wrong" {
            $UserParams.AcceptTimeDiff = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.AcceptTimeDiff = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.AcceptTimeDiff = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "ZipMirror is wrong" {
            $UserParams.ZipMirror = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.ZipMirror = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.ZipMirror = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "UnmountInputDrive is wrong" {
            $UserParams.UnmountInputDrive = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.UnmountInputDrive = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.UnmountInputDrive = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "script:PreventStandby is wrong" {
            $script:PreventStandby = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $script:PreventStandby = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "RememberInPath is wrong" {
            $UserParams.RememberInPath = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.RememberInPath = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.RememberInPath = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "RememberOutPath is wrong" {
            $UserParams.RememberOutPath = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.RememberOutPath = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.RememberOutPath = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "RememberMirrorPath is wrong" {
            $UserParams.RememberMirrorPath = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.RememberMirrorPath = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.RememberMirrorPath = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
        It "RememberSettings is wrong" {
            $UserParams.RememberSettings = -1
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.RememberSettings = "hallo"
            {Test-UserValues -UserParams $UserParams} | Should Throw
            $UserParams.RememberSettings = 11
            {Test-UserValues -UserParams $UserParams} | Should Throw
        }
    }
    It "Throw if no/wrong param is specified" {
        {Test-UserValues} | Should Throw
        {Test-UserValues -UserParams "hallo"} | Should Throw
        {Test-UserValues -UserParams @{}} | Should Throw
    }
    Context "Special characters" {
        It "Find existing folders" {
            $UserParams.JSONParamPath   = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\param specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.json"
            $UserParams.InputPath       = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
            $UserParams.OutputPath      = "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
            $UserParams.MirrorPath      = "$BlaDrive\Mirr_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
            $UserParams.HistFilePath    = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\hist specChar.(]){[}à°^âaà``$öäüß'#+,;-Æ©.json"
            $test = Test-UserValues -UserParams $UserParams
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
            # (Get-ChildItem "$BlaDrive\Out_Test" -Recurse -ErrorAction SilentlyContinue).Count   | Out-Host
            # (Get-ChildItem "$BlaDrive\Mirr_Test" -Recurse -ErrorAction SilentlyContinue).Count  | Out-Host

            $UserParams.JSONParamPath   = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\param specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.json"
            $UserParams.InputPath       = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
            $UserParams.OutputPath      = "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
            $UserParams.MirrorPath      = "$BlaDrive\Mirr_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
            $UserParams.HistFilePath    = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\hist specChar.(]){[}à°^âaà``$öäüß'#+,;-Æ©.json"
            $test = Test-UserValues -UserParams $UserParams
            $test | Should BeOfType hashtable
            Test-Path -LiteralPath "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©" -PathType Container | Should Be $true
            Test-Path -LiteralPath "$BlaDrive\Mirr_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©" -PathType Container | Should Be $true
        }
    }
    Context "Long paths" {
        It "Find existing folders" {
            $UserParams.JSONParamPath   = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\param_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_END.json"
            $UserParams.InputPath       = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.OutputPath      = "$BlaDrive\Out_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.MirrorPath      = "$BlaDrive\Mirr_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.HistFilePath    = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\hist_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_tEND.json"
            $test = Test-UserValues -UserParams $UserParams
            $test | Should BeOfType hashtable
            $test.JSONParamPath | Should Be $UserParams.JSONParamPath
            $test.InputPath     | Should Be $UserParams.InputPath
            $test.OutputPath    | Should Be $UserParams.OutputPath
            $test.MirrorPath    | Should Be $UserParams.MirrorPath
            $test.HistFilePath  | Should Be $UserParams.HistFilePath
        }
        It "Create non-existing folders (TODO: Test with short paths)" {
            Get-ChildItem "$BlaDrive\Out_Test" -Recurse     | Remove-Item
            Get-ChildItem "$BlaDrive\Mirr_Test" -Recurse    | Remove-Item
            # (Get-ChildItem "$BlaDrive\Out_Test" -Recurse -ErrorAction SilentlyContinue).Count   | Out-Host
            # (Get-ChildItem "$BlaDrive\Mirr_Test" -Recurse -ErrorAction SilentlyContinue).Count  | Out-Host
            $UserParams.EnableLongPaths = 1
            $UserParams.JSONParamPath   = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\param_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_END.json"
            $UserParams.InputPath       = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.OutputPath      = "$BlaDrive\Out_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.MirrorPath      = "$BlaDrive\Mirr_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $UserParams.HistFilePath    = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\hist_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_tEND.json"
            $test = Test-UserValues -UserParams $UserParams
            $test | Should BeOfType hashtable
            Test-Path -LiteralPath "$BlaDrive\Out_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND" -PathType Container | Should Be $true
            Test-Path -LiteralPath "$BlaDrive\Mirr_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND" -PathType Container | Should Be $true
        }
    }
}

Describe "Show-Parameters" {
    BeforeEach {
        [hashtable]$UserParams = @{
            ShowParams =            0
            Enable_GUI =            0
            JSONParamPath =         "$BlaDrive\In_Test\param_uncomplicated.json"
            LoadParamPresetName =   "default"
            SaveParamPresetName =   "default"
            RememberInPath =        0
            RememberOutPath =       0
            RememberMirrorPath =    0
            RememberSettings =      0
            # DEFINITION: From here on, parameters can be set both via parameters and via JSON file(s).
            InputPath =             "$BlaDrive\In_Test"
            OutputPath =            "$BlaDrive\Out_Test"
            MirrorEnable =          1
            MirrorPath =            "$BlaDrive\Mirr_Test"
            FormatPreference =      "include"
            FormatInExclude =       @("*.cr2")
            OutputSubfolderStyle =  "%y4%-%mo%-%d%"
            OutputFileStyle =       "%n%"
            HistFilePath =          "$BlaDrive\In_Test\mc_hist.json"
            UseHistFile =           0
            WriteHistFile =         "no"
            HistCompareHashes =     0
            InputSubfolderSearch =  0
            CheckOutputDupli =      0
            VerifyCopies =          0
            OverwriteExistingFiles = 0
            EnableLongPaths =       0
            AvoidIdenticalFiles =   0
            AcceptTimeDiff =      0
            ZipMirror =             0
            UnmountInputDrive =     0
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
        $UserParams.JSONParamPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\param specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.json"
        $UserParams.InputPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $UserParams.OutputPath = "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $UserParams.MirrorPath = "$BlaDrive\Mirr_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $UserParams.HistFilePath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\hist specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.json"
        {Show-Parameters -UserParams $UserParams} | Should not Throw
    }
}

Describe "Set-Parameters" {
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            ShowParams =            0
            Enable_GUI =            0
            JSONParamPath =         "$BlaDrive\In_Test\param_simpleset.json"
            LoadParamPresetName =   "default"
            SaveParamPresetName =   "default"
            RememberInPath =        1
            RememberOutPath =       1
            RememberMirrorPath =    1
            RememberSettings =      1
            InputPath =             "$BlaDrive\In_Test"
            OutputPath =            "$BlaDrive\Out_Test"
            MirrorEnable =          1
            MirrorPath =            "$BlaDrive\Mirr_Test"
            FormatPreference =      "include"
            FormatInExclude =       @("*.cr2")
            OutputSubfolderStyle =  "%y4%-%mo%-%d%lala"
            OutputFileStyle =       "%n%lala"
            HistFilePath =          "$BlaDrive\In_Test\mc_hist.json"
            UseHistFile =           987
            WriteHistFile =         "maybe"
            HistCompareHashes =     987
            InputSubfolderSearch =  $false
            CheckOutputDupli =      987
            VerifyCopies =          987
            OverwriteExistingFiles = 987
            EnableLongPaths =       987
            AvoidIdenticalFiles =   987
            AcceptTimeDiff =        987
            ZipMirror =             987
            UnmountInputDrive =     987
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
        It "Replace only preset" {
            [array]$inter = @([PSCustomObject]@{
                ParamPresetName = $UserParams.SaveParamPresetName
                ParamPresetValues = [PSCustomObject]@{
                    InputPath =                 $UserParams.InputPath
                    OutputPath =                $UserParams.OutputPath
                    MirrorEnable =              $UserParams.MirrorEnable
                    MirrorPath =                $UserParams.MirrorPath
                    FormatPreference =          $UserParams.FormatPreference
                    FormatInExclude =           $UserParams.FormatInExclude
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
                    AcceptTimeDiff =            $UserParams.AcceptTimeDiff
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
            $test.FormatPreference          | Should Be $UserParams.FormatPreference
            $test.FormatInExclude           | Should Be $UserParams.FormatInExclude
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
            $test.EnableLongPaths           | Should Be $UserParams.EnableLongPaths
            $test.AvoidIdenticalFiles       | Should Be $UserParams.AvoidIdenticalFiles
            $test.AcceptTimeDiff            | Should Be $UserParams.AcceptTimeDiff
            $test.ZipMirror                 | Should Be $UserParams.ZipMirror
            $test.UnmountInputDrive         | Should Be $UserParams.UnmountInputDrive
            $test.Preventstandby            | Should Be $script:Preventstandby
        }
        It "Create a new JSON" {
            Remove-Item -LiteralPath $UserParams.JSONParamPath
            $test = Set-Parameters -UserParams $UserParams
            $test | Should Be $true
            $test = @(Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
            ,$test | Should BeOfType array

            $bla = @("default")
            (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0
            $test = $test.ParamPresetValues
            $test[0].InputPath                  | Should Be $UserParams.InputPath
            $test[0].OutputPath                 | Should Be $UserParams.OutputPath
            $test[0].MirrorEnable               | Should Be $UserParams.MirrorEnable
            $test[0].MirrorPath                 | Should Be $UserParams.MirrorPath
            $test[0].FormatPreference           | Should Be $UserParams.FormatPreference
            $test[0].FormatInExclude            | Should Be $UserParams.FormatInExclude
            $test[0].OutputSubfolderStyle       | Should Be $UserParams.OutputSubfolderStyle
            $test[0].OutputFileStyle            | Should Be $UserParams.OutputFileStyle
            $test[0].HistFilePath               | Should Be $UserParams.HistFilePath
            $test[0].UseHistFile                | Should Be $UserParams.UseHistFile
            $test[0].WriteHistFile              | Should Be $UserParams.WriteHistFile
            $test[0].HistCompareHashes          | Should Be $UserParams.HistCompareHashes
            $test[0].InputSubfolderSearch       | Should Be $UserParams.InputSubfolderSearch
            $test[0].CheckOutputDupli           | Should Be $UserParams.CheckOutputDupli
            $test[0].VerifyCopies               | Should Be $UserParams.VerifyCopies
            $test[0].OverwriteExistingFiles     | Should Be $UserParams.OverwriteExistingFiles
            $test[0].AvoidIdenticalFiles        | Should Be $UserParams.AvoidIdenticalFiles
            $test[0].AcceptTimeDiff             | Should Be $UserParams.AcceptTimeDiff
            $test[0].ZipMirror                  | Should Be $UserParams.ZipMirror
            $test[0].UnmountInputDrive          | Should Be $UserParams.UnmountInputDrive
            $test[0].Preventstandby             | Should Be $script:Preventstandby
        }
        It "Replace `"default`"" {
            $test = @(Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
            ,$test | Should BeOfType array
            $bla = @("default")
            $bla = (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count
            $test = $test.ParamPresetValues
            $bla | Should Be 0
            $test[0].InputPath                  | Should Be $UserParams.InputPath
            $test[0].OutputPath                 | Should Be $UserParams.OutputPath
            $test[0].MirrorEnable               | Should Be $UserParams.MirrorEnable
            $test[0].MirrorPath                 | Should Be $UserParams.MirrorPath
            $test[0].FormatPreference           | Should Be $UserParams.FormatPreference
            $test[0].FormatInExclude            | Should Be $UserParams.FormatInExclude
            $test[0].OutputSubfolderStyle       | Should Be $UserParams.OutputSubfolderStyle
            $test[0].OutputFileStyle            | Should Be $UserParams.OutputFileStyle
            $test[0].HistFilePath               | Should Be $UserParams.HistFilePath
            $test[0].UseHistFile                | Should Be $UserParams.UseHistFile
            $test[0].WriteHistFile              | Should Be $UserParams.WriteHistFile
            $test[0].HistCompareHashes          | Should Be $UserParams.HistCompareHashes
            $test[0].InputSubfolderSearch       | Should Be $UserParams.InputSubfolderSearch
            $test[0].CheckOutputDupli           | Should Be $UserParams.CheckOutputDupli
            $test[0].VerifyCopies               | Should Be $UserParams.VerifyCopies
            $test[0].OverwriteExistingFiles     | Should Be $UserParams.OverwriteExistingFiles
            $test[0].AvoidIdenticalFiles        | Should Be $UserParams.AvoidIdenticalFiles
            $test[0].AcceptTimeDiff             | Should Be $UserParams.AcceptTimeDiff
            $test[0].ZipMirror                  | Should Be $UserParams.ZipMirror
            $test[0].UnmountInputDrive          | Should Be $UserParams.UnmountInputDrive
            $test[0].Preventstandby             | Should Be $script:Preventstandby
        }
    }
    It "Special characters work properly" {
        $UserParams.JSONParamPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\param specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.json"
        $UserParams.SaveParamPresetName = "bla"

        $test = Set-Parameters -UserParams $UserParams
        $test | Should Be $true

        $test = Get-Content -LiteralPath $UserParams.JSONParamPath -Encoding UTF8 -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        ,$test | Should BeOfType array
        $bla = @("bla","default","uncomplicated","specchar","long")
        (Compare-Object $test.ParamPresetName $bla -ErrorAction SilentlyContinue).count | Should Be 0

        $test = $test | Where-Object {$_.ParamPresetName -eq $UserParams.SaveParamPresetName}
        $test = $test.ParamPresetValues
        $test.InputPath                 | Should Be $UserParams.InputPath
        $test.OutputPath                | Should Be $UserParams.OutputPath
        $test.MirrorEnable              | Should Be $UserParams.MirrorEnable
        $test.MirrorPath                | Should Be $UserParams.MirrorPath
        $test.FormatPreference          | Should Be $UserParams.FormatPreference
        $test.FormatInExclude           | Should Be $UserParams.FormatInExclude
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
        $test.AcceptTimeDiff            | Should Be $UserParams.AcceptTimeDiff
        $test.ZipMirror                 | Should Be $UserParams.ZipMirror
        $test.UnmountInputDrive         | Should Be $UserParams.UnmountInputDrive
        $test.Preventstandby            | Should Be $script:Preventstandby
    }
}

Describe "Start-FileSearch" {
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath = "$BlaDrive\In_Test"
            InputSubfolderSearch = 1
            FormatPreference = "include"
            FormatInExclude = @("*.JPG")
            OutputFileStyle = "%n%"
            OutputSubfolderStyle = "%y4%-%mo%-%d%"
        }
    }
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    Context "Basic functions" {
        It "Return array if successful" {
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be (Get-ChildItem -LiteralPath $UserParams.InputPath -Filter $UserParams.FormatInExclude[0] -Recurse).count
        }
        It "Return array even if only one file is found" {
            $UserParams.FormatInExclude = @("*.cr3")
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be 1
        }
        It "Throw if no/wrong param" {
            {Start-FileSearch} | Should Throw
            {Start-FileSearch -UserParams 123} | Should Throw
            {Start-FileSearch -UserParams @{}} | Should Throw
        }
        It "No problems with SpecChars" {
            $script:input_recurse = $false
            $UserParams.FormatInExclude = @("*")
            $UserParams.InputPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be 8
            $test = $test | Where-Object {$_.InBaseName -match 'file\ specChar\.\(]\)\{\[}à°\^âaà``\$öäüß''\#!%&=´@€\+,;-Æ©$' -and $_.Extension -eq ".cr2"}
            $test.InPath            | Should Be $UserParams.InputPath
            $test.InName            | Should Be "file specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.cr2"
            $test.InBaseName        | Should Be "file specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
            $test.Date              | Should Be 1533978891
        }
        It "No problems with Long paths" {
            $script:input_recurse = $false
            $UserParams.FormatInExclude = @("*")
            $UserParams.InputPath = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be 8
            $test = $test | Where-Object {$_.InBaseName -match 'file_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_thEND$' -and $_.Extension -eq ".cr2"}
            $test.InPath            | Should Be $UserParams.InputPath
            $test.InName            | Should Be "file_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_thEND.cr2"
            $test.InBaseName        | Should Be "file_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_thEND"
            $test.Date              | Should Be 1532682860
        }
    }
    Context "Include, All, Exclude" {
        It "All" {
            $UserParams.InputPath = "$BlaDrive\In_Test"
            $UserParams.FormatPreference = "all"
            $UserParams.FormatInExclude = @("*.JPG")
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be (Get-ChildItem -LiteralPath $UserParams.InputPath -Filter "*" -Recurse -File).count
        }
        It "Include" {
            $UserParams.FormatPreference = "include"
            $UserParams.FormatInExclude = @("*.JPG","*.cr3")
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be (Get-ChildItem -Path $($UserParams.InputPath -Replace '\\$','\\\*') -Include $UserParams.FormatInExclude -File -Recurse).count
        }
        It "Exclude" {
            $UserParams.FormatPreference = "exclude"
            $UserParams.FormatInExclude = @("*.JPG")
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test          | Should BeOfType array
            $test.length    | Should Be (Get-ChildItem -Path $($UserParams.InputPath -Replace '\\$','\\\*') -Exclude $UserParams.FormatInExclude -File -Recurse).count
        }
    }
    Context "OutputSubfolderStyle" {
        BeforeEach {
            $UserParams.FormatInExclude = @("*.CR2")
        }
        It "none (`"`")" {
            $UserParams.OutputSubfolderStyle = ""
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test[0].OutSubfolder   | Should Be ""
            $test[11].OutSubfolder  | Should Be ""

            $UserParams.OutputSubfolderStyle = " "
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test[0].OutSubfolder   | Should Be ""
            $test[11].OutSubfolder  | Should Be ""
        }
        It "unchanged (`"%n%`")" {
            $UserParams.OutputSubfolderStyle = "%n%"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test[0].OutSubfolder   | Should Be "\"
            $test[8].OutSubfolder   | Should Be "\folder_uncomplicated"

            $UserParams.OutputSubfolderStyle = "%n% "
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test[0].OutSubfolder   | Should Be "\"
            $test[8].OutSubfolder   | Should Be "\folder_uncomplicated"
        }
        It "%y4%-%mo%-%d%" {
            $UserParams.OutputSubfolderStyle = "%y4%-%mo%-%d%"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test[0].OutSubfolder   | Should Be "\2018-08-11"
            $test[11].OutSubfolder  | Should Be "\2018-07-27"
        }
        It "(%y4%_%mo%_%d%) BLA" {
            $UserParams.OutputSubfolderStyle = "(%y4%_%mo%_%d%) BLA"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test[0].OutSubfolder   | Should Be "\(2018_08_11) BLA"
            $test[11].OutSubfolder  | Should Be "\(2018_07_27) BLA"
        }
        It "%y4%.%mo%.%d% %n% (TODO: Why 2nd test 8th item?)" {
            $UserParams.OutputSubfolderStyle = "%y4%.%mo%.%d% %n%"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test[0].OutSubfolder   | Should Be "\2018.08.11"
            $test[8].OutSubfolder   | Should Be "\2018.07.27 folder_uncomplicated" #
        }
        It "%y4%%mo%%d% %y2%BLA" {
            $UserParams.OutputSubfolderStyle = "%y4%%mo%%d% %y2%BLA"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test[0].OutSubfolder   | Should Be "\20180811 18BLA"
            $test[11].OutSubfolder  | Should Be "\20180727 18BLA"
        }
        It "%y2%-%mo%-%d%" {
            $UserParams.OutputSubfolderStyle = "%y2%-%mo%-%d%"
            $test = @(Start-FileSearch -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test[0].OutSubfolder   | Should Be "\18-08-11"
            $test[11].OutSubfolder  | Should Be "\18-07-27"
        }
    }
    It "OutputFileStyle" {
        $UserParams.FormatInExclude = @("*.cr2")
        $UserParams.OutputFileStyle = "BLA_%c3% %n% %y4%-%mo%-%d%_%h%-%mi%-%s%_%y2% %n% %c1% %y4%-%mo%-%d%_%h%-%mi%-%s%"
        $test = @(Start-FileSearch -UserParams $UserParams)
        ,$test | Should BeOfType array
        $test[0].InBaseName | Should Be "BLA_001 file specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ© 2018-08-11_09-14-51_18 file specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ© 1 2018-08-11_09-14-51"
        $test[1].InBaseName | Should Be "BLA_002 file_uncomplicated 2018-07-09_09-14-36_18 file_uncomplicated 2 2018-07-09_09-14-36"
        $test[11].InBaseName | Should Be "BLA_012 file_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_thEND 2018-07-27_09-14-20_18 file_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_thEND 12 2018-07-27_09-14-20"
    }
}

Describe "Get-HistFile" {
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            HistFilePath = "$BlaDrive\In_Test\hist_uncomplicated.json"
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
            $test[3].InName | Should Be "file_single.CR4"
            $test[3].Date   | Should Be 1520874103
            $test[3].size   | Should Be 990
            $test[3].hash   | Should Be "3A3514D39089FAF261CAF7EC50CB06D44021C424"
        }
        It "Get array even if just one file is found" {
            $UserParams.HistFilePath = "$BlaDrive\In_Test\hist_simpleset.json"
            $test = @(Get-HistFile -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.InName | Should Be "file_uncomplicated.CR2"
            $test.Date | Should Be 1531127676
            $test.size | Should Be 540
            $test.hash | Should Be "0EDB0FA60F13FFE645FA3C502D46707F68232561"
        }
        It "Return empty array for empty histfile" {
            Mock Read-Host {return 1}
            $UserParams.HistFilePath = "$BlaDrive\In_Test\hist_empty.json"
            $test = @(Get-HistFile -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test | Should Be @()
        }
        It "Throw if user does not want to work with empty histfile" {
            Mock Read-Host {return 0}
            $UserParams.HistFilePath = "$BlaDrive\In_Test\hist_empty.json"
            {Get-HistFile -UserParams $UserParams} | Should Throw
        }
        It "Return array for broken histfile" {
            $UserParams.HistFilePath = "$BlaDrive\In_Test\hist_broken.json"
            Mock Read-Host {return 1}
            $test = @(Get-HistFile -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test | Should Be @()
        }
        It "Throw if user does not want to work with broken histfile" {
            Mock Read-Host {return 0}
            $UserParams.HistFilePath = "$BlaDrive\In_Test\hist_broken.json"
            {Get-HistFile -UserParams $UserParams} | Should Throw
        }
        It "Return empty array for no histfile" {
            Mock Read-Host {return 1}
            $UserParams.HistFilePath = "$BlaDrive\In_Test\nohistfile.json"
            $test = @(Get-HistFile -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test | Should Be @()
        }
        It "Throw if user does not want to work with no histfile" {
            Mock Read-Host {return 0}
            $UserParams.HistFilePath = "$BlaDrive\In_Test\nohistfile.json"
            {Get-HistFile -UserParams $UserParams} | Should Throw
        }
        It "Throw if params are wrong/missing" {
            {Get-HistFile} | Should Throw
            {Get-HistFile -UserParams 123} | Should Throw
            {Get-HistFile -UserParams @{}} | Should Throw
        }
    }
    It "No problems with SpecChars" {
        $UserParams.HistFilePath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\hist specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.json"
        $test = @(Get-HistFile -UserParams $UserParams)
        ,$test | Should BeOfType array
        $test = $test | Where-Object {$_.InName -eq "file specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.jpg"}
        $test.InName | Should Be "file specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.jpg"
        $test.Date   | Should Be 1535793091
        $test.size   | Should Be 1342
        $test.hash   | Should Be "1D2E6B753FBFB23FB8C4D636DBD8A09547328870"
    }
    It "No problems with long paths" {
        $UserParams.HistFilePath = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\hist_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_tEND.json"
        $test = @(Get-HistFile -UserParams $UserParams)
        ,$test | Should BeOfType array
        $test = $test | Where-Object {$_.InName -eq "file specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.jpg"}
        $test.InName | Should Be "file specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.jpg"
        $test.Date   | Should Be 1535793091
        $test.size   | Should Be 1342
        $test.hash   | Should Be "1D2E6B753FBFB23FB8C4D636DBD8A09547328870"
    }
}

Describe "Start-DupliCheckHist" {
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath =             "$BlaDrive\In_Test"
            OutputPath =            "$BlaDrive\Out_Test"
            FormatPreference =      "include"
            FormatInExclude =       @("*.cr2","*.jpg")
            OutputFileStyle =       "%n%"
            OutputSubfolderStyle =  "%y4%-%mo%-%d%"
            HistFilePath =          "$BlaDrive\In_Test\hist_uncomplicated.json"
            UseHistFile =           1
            WriteHistFile =         "yes"
            HistCompareHashes =     1
            AcceptTimeDiff =        0
            InputSubfolderSearch =  1
        }
    }
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    Context "Working normal" {
        It "Return array with correct params, find duplicates" {
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $HistFiles = @(Get-HistFile -UserParams $UserParams)
            $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 0
        }
        It "Return array with correct params, don't false-positive things" {
            $UserParams.HistFilePath = "$BlaDrive\In_Test\hist_uncomplicated_nodup.json"
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $HistFiles = @(Get-HistFile -UserParams $UserParams)
            $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 24
        }
        It "Works with `$AcceptTimeDiff (1/2)" {
            $UserParams.AcceptTimeDiff = 1
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $HistFiles = @(Get-HistFile -UserParams $UserParams)
            $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 0
        }
        It "Works with `$AcceptTimeDiff (2/2)" {
            $UserParams.AcceptTimeDiff = 1
            $UserParams.HistFilePath = "$BlaDrive\In_Test\hist_uncomplicated_accepttime.json"
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $HistFiles = @(Get-HistFile -UserParams $UserParams)
            $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 20
        }
        It "Throws Error when parameters are wrong / missing" {
            {Start-DupliCheckHist} | Should Throw
            {Start-DupliCheckHist -InFiles @() -HistFiles @() -UserParams @()} | Should Throw
        }
        It "Does find a new file" {
            $UserParams.AcceptTimeDiff = 1
            $UserParams.WriteHistFile = "no"
            "Blabla" | Out-File "$BlaDrive\In_Test\NEWFILE.jpg" -Encoding utf8

            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $HistFiles = @(Get-HistFile -UserParams $UserParams)
            $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 1
            $test.InFullName | Should Be "$BlaDrive\In_Test\NEWFILE.jpg"

            Remove-Item "$BlaDrive\In_Test\NEWFILE.jpg"
        }
    }
    It "No problems with SpecChars" {
        $UserParams.InputPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $UserParams.OutputPath = "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $UserParams.HistFilePath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©\hist specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©.json"

        $InFiles = @(Start-FileSearch -UserParams $UserParams)
        $HistFiles = @(Get-HistFile -UserParams $UserParams)

        $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
        ,$test | Should BeOfType array
        $test.length | Should Be 0
    }
    It "No problems with long paths" {
        $UserParams.InputPath = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
        $UserParams.OutputPath = "$BlaDrive\Out_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
        $UserParams.HistFilePath = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND\hist_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_before_tEND.json"

        $InFiles = @(Start-FileSearch -UserParams $UserParams)
        $HistFiles = @(Get-HistFile -UserParams $UserParams)

        $test = @(Start-DupliCheckHist -InFiles $InFiles -HistFiles $HistFiles -UserParams $UserParams)
        ,$test | Should BeOfType array
        $test.length | Should Be 0
    }
}

Describe "Start-DupliCheckOut" {
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath =             "$BlaDrive\In_Test"
            OutputPath =            "$BlaDrive\Out_Test"
            FormatPreference =      "include"
            FormatInExclude =       @("*.cr2","*.jpg")
            OutputFileStyle =       "%n%"
            OutputSubfolderStyle =  "%y4%-%mo%-%d%"
            InputSubfolderSearch =  1
            AcceptTimeDiff =        0
        }
    }
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    Context "Works as planned" {
        It "Throw if wron/no parameter" {
            {Start-DupliCheckOut} | Should Throw
            {Start-DupliCheckOut -InFiles @("Bla")} | Should Throw
            {Start-DupliCheckOut -InFiles @() -UserParams @{}} | Should Throw
        }
        It "Mark no file if no file is double" {
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $test = @(Start-DupliCheckOut -InFiles $InFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 24
        }
        It "Mark all CR2s as already copied (as they are)" {
            Get-ChildItem -LiteralPath "$BlaDrive\Out_Test" -Recurse | Remove-Item -Recurse
            Get-ChildItem -LiteralPath "$BlaDrive\In_Test" -Recurse | Copy-Item -Destination "$BlaDrive\Out_Test" -Recurse
            Get-ChildItem -Path "$BlaDrive\Out_Test" -Exclude *.cr2 -File -Recurse | Remove-Item
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $test = @(Start-DupliCheckOut -InFiles $InFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 12
            $test.Extension | Should -Not -Contain ".cr2"
            $test.Extension | Should -Contain ".jpg"

            Get-ChildItem -LiteralPath "$BlaDrive\Out_Test" -Recurse -File | Remove-Item -Recurse
        }
        It "Check time difference w/ `$AcceptTimeDiff=0" {
            Get-ChildItem -LiteralPath "$BlaDrive\Out_Test" -Recurse | Remove-Item -Recurse
            Get-ChildItem -LiteralPath "$BlaDrive\In_Test" -Recurse | Copy-Item -Destination "$BlaDrive\Out_Test" -Recurse
            Get-ChildItem -LiteralPath "$BlaDrive\Out_Test" -Recurse -File | ForEach-Object {$_.LastWriteTime = $_.LastWriteTime.AddSeconds(2)}
            Start-Sleep -Milliseconds 250
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $test = @(Start-DupliCheckOut -InFiles $InFiles -UserParams $UserParams)
            ,$test | Should BeOfType array
            $test.Length | Should Be 24
        }
        It "Check time difference w/ `$AcceptTimeDiff=1" {
            $UserParams.AcceptTimeDiff = 1
            Get-ChildItem -LiteralPath "$BlaDrive\Out_Test" -Recurse | Remove-Item -Recurse
            Get-ChildItem -LiteralPath "$BlaDrive\In_Test" -Recurse | Copy-Item -Destination "$BlaDrive\Out_Test" -Recurse
            Get-ChildItem -LiteralPath "$BlaDrive\Out_Test" -Recurse -File | ForEach-Object {$_.LastWriteTime = $_.LastWriteTime.AddSeconds(2)}
            Start-Sleep -Milliseconds 250
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $test = @(Start-DupliCheckOut -InFiles $InFiles -UserParams $UserParams)
            , $test | Should BeOfType array
            $test.Length | Should Be 0
        }
        It "Check different hashes and sizes, too" {
            Get-ChildItem -LiteralPath "$BlaDrive\Out_Test" -Recurse | Remove-Item -Recurse
            Get-ChildItem -LiteralPath "$BlaDrive\In_Test" -Recurse | Copy-Item -Destination "$BlaDrive\Out_Test" -Recurse
            Get-ChildItem -LiteralPath "$BlaDrive\Out_Test" -Recurse -File | ForEach-Object {Out-File -InputObject "a" -LiteralPath $_.FullName -Append -Encoding utf8 -Force}
            Start-Sleep -Milliseconds 250
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $test = @(Start-DupliCheckOut -InFiles $InFiles -UserParams $UserParams)
            , $test | Should BeOfType array
            $test.Length | Should Be 24
        }
    }
    It "No problems with SpecChars" {
        Get-ChildItem -LiteralPath "$BlaDrive\Out_Test" -Recurse | Remove-Item -Recurse
        Get-ChildItem -LiteralPath "$BlaDrive\In_Test" -Recurse -Directory | Copy-Item -Destination "$BlaDrive\Out_Test"

        $UserParams.InputPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $UserParams.OutputPath = "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"

        $InFiles = @(Start-FileSearch -UserParams $UserParams)
        $test = @(Start-DupliCheckOut -InFiles $InFiles -UserParams $UserParams)
        ,$test | Should BeOfType array
        $test.length | Should Be 6
    }
    It "No problems with long paths" {
        $UserParams.InputPath = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
        $UserParams.OutputPath = "$BlaDrive\Out_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"

        $InFiles = @(Start-FileSearch -UserParams $UserParams)
        $test = @(Start-DupliCheckOut -InFiles $InFiles -UserParams $UserParams)
        ,$test | Should BeOfType array
        $test.length | Should Be 6
    }
}

Describe "Start-InputGetHash" {
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath =             "$BlaDrive\In_Test"
            OutputPath =            "$BlaDrive\Out_Test"
            FormatPreference =      "include"
            FormatInExclude =       @("*.cr2","*.jpg")
            OutputFileStyle =       "%n%"
            OutputSubfolderStyle =  "%y4%-%mo%-%d%"
            HistFilePath =          "$BlaDrive\In_Test\hist_uncomplicated.json"
            UseHistFile =           1
            WriteHistFile =         "yes"
            HistCompareHashes =     1
            InputSubfolderSearch =  1
        }
    }
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    Context "Works as planned" {
        It "Throw if no/wrong parameter" {
            {Start-InputGetHash} | Should Throw
            {Start-InputGetHash -InFiles @()} | Should Throw
        }
        It "Works as planned" {
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $test = @(Start-InputGetHash -InFiles $InFiles)
            ,$test | Should BeOfType array
            foreach($i in $test.Hash){
                $i | Should Not Be ("ZYX")
            }
        }
        It "No re-hashing of files" {
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $InFiles | ForEach-Object {$_.Hash = "123"}
            $test = @(Start-InputGetHash -InFiles $InFiles)
            ,$test | Should BeOfType array
            foreach($i in $test.Hash){
                $i | Should Be ("123")
            }
        }
        It "Work even if one file already has a hash" {
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $InFiles[2].Hash = "TEST"
            $test = @(Start-InputGetHash -InFiles $InFiles)
            ,$test | Should BeOfType array
            $Test[2].Hash | Should Be "TEST"
            $test = $test | Where-Object {$_.Hash -match '^ZYX$'}
            $test.Length | Should Be 0
        }
    }
    It "No problems with SpecChars" {
        $UserParams.InputPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"

        $InFiles = @(Start-FileSearch -UserParams $UserParams)
        $test = @(Start-InputGetHash -InFiles $InFiles)
        ,$test | Should BeOfType array
        foreach($i in $test.Hash){
            $i | Should Not Be ("ZYX")
        }
    }
    It "No problems with long paths" {
        $UserParams.InputPath = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"

        $InFiles = @(Start-FileSearch -UserParams $UserParams)
        $test = @(Start-InputGetHash -InFiles $InFiles)
        ,$test | Should BeOfType array
        foreach($i in $test.Hash){
            $i | Should Not Be ("ZYX")
        }
    }
}

Describe "Start-PreventingDoubleCopies" {
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath =             "$BlaDrive\In_Test"
            OutputPath =            "$BlaDrive\Out_Test"
            FormatPreference =      "include"
            FormatInExclude =       @("*.cr2","*.jpg","*.cr3")
            OutputFileStyle =       "%n%"
            OutputSubfolderStyle =  "%y4%-%mo%-%d%"
            HistFilePath =          "$BlaDrive\In_Test\hist_uncomplicated.json"
            UseHistFile =           1
            WriteHistFile =         "yes"
            HistCompareHashes =     1
            InputSubfolderSearch =  1
        }
    }
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    Context "Works as planned" {
        It "Throw if no/wrong parameter" {
            {Start-PreventingDoubleCopies} | Should Throw
            {Start-PreventingDoubleCopies -InFiles @()} | Should Throw
        }
        It "Works as it should" {
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $test = @(Start-PreventingDoubleCopies -InFiles $InFiles)
            ,$test | Should BeOfType array
            $test.Length | Should Be 7
        }
    }
}

Describe "Start-SpaceCheck"{
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath =             "$BlaDrive\In_Test"
            OutputPath =            "$BlaDrive\Out_Test"
            FormatPreference =      "include"
            FormatInExclude =       @("*.cr2","*.jpg","*.cr3")
            OutputFileStyle =       "%n%"
            OutputSubfolderStyle =  "%y4%-%mo%-%d%"
            HistFilePath =          "$BlaDrive\In_Test\hist_uncomplicated.json"
            UseHistFile =           1
            WriteHistFile =         "yes"
            HistCompareHashes =     1
            InputSubfolderSearch =  1
        }
    }
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    Context "Works as planned" {
        It "Throw if no/wrong parameter" {
            {Start-SpaceCheck} | Should Throw
            {Start-SpaceCheck -InFiles @()} | Should Throw
        }
        It "Works as it should" {
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $test = Start-SpaceCheck -InFiles $InFiles -UserParams $UserParams
            $test | Should BeOfType boolean
        }
    }
    It "No problems with SpecChars" {
        $UserParams.InputPath = "$BlaDrive\In_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
        $InFiles = @(Start-FileSearch -UserParams $UserParams)
        $test = Start-SpaceCheck -InFiles $InFiles -UserParams $UserParams
        $test | Should BeOfType boolean
        $test | Should Be $true
    }
    It "No problems with long paths" {
        $UserParams.InputPath = "$BlaDrive\In_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
        $InFiles = @(Start-FileSearch -UserParams $UserParams)
        $test = Start-SpaceCheck -InFiles $InFiles -UserParams $UserParams
        $test | Should BeOfType boolean
    }
    It "Test with small volume" {
        Write-Host "This only works if A:\Out_Test exists and is on a very small drive (e.g. RAM-volume)"
        Pause
        $UserParams.OutputPath = "A:\Out_Test"
        $InFiles = @(Start-FileSearch -UserParams $UserParams)
        $test = Start-SpaceCheck -InFiles $InFiles -UserParams $UserParams
        $test | Should BeOfType boolean
        $test | Should Be $False
    }
}

Describe "Start-OverwriteProtection" {
    $BlaDrive = "$TestDrive\media-copytool_TEST"
    BeforeEach {
        [hashtable]$UserParams = @{
            InputPath =             "$BlaDrive\In_Test"
            OutputPath =            "$BlaDrive\Out_Test"
            FormatPreference =      "include"
            FormatInExclude =       @("*.cr2","*.jpg","*.cr3")
            OutputFileStyle =       "%n%"
            OutputSubfolderStyle =  "%y4%-%mo%-%d%"
            InputSubfolderSearch =  1
            OverwriteExistingFiles = 0
            EnableLongPaths = 1
        }
    }
    New-Item -ItemType Directory -Path $BlaDrive
    Push-Location $BlaDrive
    Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$($PSScriptRoot)\media_copytool_TESTFILES.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
    Pop-Location

    Context "Works as planned" {
        It "Throw if no/wrong parameter" {
            {Start-OverwriteProtection} | Should Throw
            {Start-OverwriteProtection -InFiles @()} | Should Throw
            {Start-OverwriteProtection -Mirror 1} | Should Throw
        }
        It "Add nothing if not needed" {
            $UserParams.InputSubfolderSearch = 0
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $NewFiles = $InFiles | Select-Object *
            $test = @(Start-OverwriteProtection -InFiles $NewFiles -UserParams $UserParams -Mirror 0)
            ,$test | Should BeOfType array
            (Compare-Object $InFiles $test -Property InFullName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Extension -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Size -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Date -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutSubfolder -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property Hash -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property ToCopy -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            $counter = 0
            foreach($i in $test.OutPath){
                if($i -match $([regex]::Escape("$($("$($UserParams.OutputPath)$($InFiles[$i].OutSubfolder)").Replace("\\","\").Replace("\\","\"))"))){
                    $counter++
                }
            }
            $counter | Should be $InFiles.Length
            $counter = 0
            foreach($i in $test.OutName){
                # $i | Out-Host
                if($i -match '^.*_OutCopy\d.*$'){$counter++}
                if($i -match '^.*_InCopy\d.*$'){$counter++}
            }
            $counter | Should be 0
            $counter = 0
            foreach($i in $test.OutBaseName){
                if($i -match '^.*_OutCopy\d.*'){$counter++}
                if($i -match '^.*_InCopy\d.*'){$counter++}
            }
            $counter | Should be 0
        }
        It "Add _InCopyXY if file is there multiple times (TODO: probably does not work w/ OutputSubfolderStyle like %n%?)" {
            $UserParams.InputSubfolderSearch = 1
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $NewFiles = $InFiles | Select-Object *
            $test = @(Start-OverwriteProtection -InFiles $NewFiles -UserParams $UserParams -Mirror 0)
            ,$test | Should BeOfType array
            (Compare-Object $InFiles $test -Property InFullName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Extension -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Size -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Date -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutSubfolder -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property Hash -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property ToCopy -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            $counter = 0
            foreach($i in $test.OutPath){
                if($i -match $([regex]::Escape("$($("$($UserParams.OutputPath)$($InFiles[$i].OutSubfolder)").Replace("\\","\").Replace("\\","\"))"))){$counter++}
            }
            $counter | Should be $InFiles.Length
            $counter = 0
            $wrong = 0
            foreach($i in $test.OutName){
                if($i -match '^.*_InCopy\d\....$'){$counter++}
                if($i -match '^.*_OutCopy\d.*$'){$wrong++}
            }
            $counter | Should be $([math]::Floor(($InFiles.Length * 3 / 4)))
            $wrong  | Should be 0
            $counter = 0
            $wrong = 0
            foreach($i in $test.OutBaseName){
                if($i -match '^.*_InCopy\d$'){$counter++}
                if($i -match '^.*_OutCopy\d.*'){$wrong++}
            }
            $counter | Should be $([math]::Floor(($InFiles.Length * 3 / 4)))
            $wrong  | Should be 0
        }
        It "Test if length is restricted with EnableLongPaths=0" {
            $UserParams.EnableLongPaths = 0
            $UserParams.OutputSubfolderStyle =  "%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%"
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $NewFiles = $InFiles | Select-Object *
            $test = @(Start-OverwriteProtection -InFiles $NewFiles -UserParams $UserParams -Mirror 0)
            ,$test | Should BeOfType array
            (Compare-Object $InFiles $test -Property InFullName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Extension -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Size -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Date -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutSubfolder -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property Hash -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property ToCopy -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            foreach($i in $test.OutName){
                $i.Length | Should BeLessOrEqual 255
            }
            foreach($i in $test.OutSubfolder){
                $i.Length | Should BeLessOrEqual 255
            }
            foreach($i in $test.ToCopy){
                $i | Should Be 0
            }
        }
        It "Test if length is not restricted with EnableLongPaths=1" {
            $UserParams.EnableLongPaths = 1
            $UserParams.OutputSubfolderStyle =  "%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%-%y4%"
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $NewFiles = $InFiles | Select-Object *
            $test = @(Start-OverwriteProtection -InFiles $NewFiles -UserParams $UserParams -Mirror 0)
            ,$test | Should BeOfType array
            (Compare-Object $InFiles $test -Property InFullName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Extension -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Size -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Date -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutSubfolder -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property Hash -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property ToCopy -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            [int]$counter = 0
            foreach($i in $test.OutName){
                if($i.Length -gt 255){
                    $counter++
                }
            }
            $counter | Should BeGreaterThan 0
            [int]$counter = 0
            foreach($i in $test.OutSubfolder){
                if($i.Length -gt 255){
                    $counter++
                }
            }
            $counter | Should BeGreaterThan 0
        }
        It "Add _OutCopyXY if file is there mutliple times" {
            $UserParams.InputSubfolderSearch = 0
            $UserParams.OutputSubfolderStyle = ""
            Get-ChildItem -LiteralPath "$BlaDrive\In_Test" -Recurse | Copy-Item -Destination "$BlaDrive\Out_Test" -Recurse -ErrorAction SilentlyContinue

            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $NewFiles = $InFiles | Select-Object *
            $test = @(Start-OverwriteProtection -InFiles $NewFiles -UserParams $UserParams -Mirror 0)
            ,$test | Should BeOfType array
            (Compare-Object $InFiles $test -Property InFullName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Extension -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Size -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Date -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutSubfolder -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property Hash -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property ToCopy -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            $counter = 0
            foreach($i in $test.OutPath){
                if($i -match $([regex]::Escape("$($("$($UserParams.OutputPath)$($InFiles[$i].OutSubfolder)").Replace("\\","\").Replace("\\","\"))"))){$counter++}
            }
            $counter | Should be $InFiles.Length
            $counter = 0
            $wrong = 0
            foreach($i in $test.OutName){
                if($i -match '^.*_OutCopy\d\....$'){$counter++}
                if($i -match '^.*_InCopy\d.*$'){$wrong++}
            }
            $counter | Should be $([math]::Floor(($InFiles.Length)))
            $wrong  | Should be 0
            $counter = 0
            $wrong = 0
            foreach($i in $test.OutBaseName){
                if($i -match '^.*_OutCopy\d$'){$counter++}
                if($i -match '^.*_InCopy\d.*'){$wrong++}
            }
            $counter | Should be $([math]::Floor(($InFiles.Length)))
            $wrong  | Should be 0
        }
        It "Add both _InCopyXY and _OutCopyXY if appropriate" {
            $UserParams.InputSubfolderSearch = 1
            $UserParams.OutputSubfolderStyle = ""
            Push-Location "$BlaDrive\Out_Test"
            Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x -aoa -bb0 -pdefault -sccUTF-8 -spf2 `"$BlaDrive\Out_Test\InCopyTEST.7z`" `"-o.\`" " -WindowStyle Minimized -Wait
            Pop-Location

            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $NewFiles = $InFiles | Select-Object *
            $test = @(Start-OverwriteProtection -InFiles $NewFiles -UserParams $UserParams -Mirror 0)
            ,$test | Should BeOfType array
            (Compare-Object $InFiles $test -Property InFullName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Extension -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Size -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Date -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutSubfolder -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property Hash -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property ToCopy -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            # $test | Format-List -Property OutName,OutPath | Out-Host
            $counter = 0
            foreach($i in $test.OutPath){
                if($i -match $([regex]::Escape("$($("$($UserParams.OutputPath)$($InFiles[$i].OutSubfolder)").Replace("\\","\").Replace("\\","\"))"))){
                    $counter++
                }
            }
            $counter | Should be $InFiles.Length
            $counter = 0
            foreach($i in $test.OutName){
                if($i -match '^.*_OutCopy\d_InCopy\d.*$'){$counter++}
            }
            $counter | Should be $([math]::floor($($InFiles.Length - 1) / 4 * 3))
            $counter = 0
            foreach($i in $test.OutBaseName){
                if($i -match '^.*_OutCopy\d_InCopy\d.*'){$counter++}
            }
            $counter | Should be $([math]::floor($($InFiles.Length - 1) / 4 * 3))
        }
        It "Does not add things if not necessary" {
            $UserParams.InputSubfolderSearch = 0
            Get-ChildItem -LiteralPath "$BlaDrive\Out_Test" -Recurse | Remove-Item -Recurse
            Start-Sleep -Milliseconds 250

            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $NewFiles = $InFiles | Select-Object *
            $test = @(Start-OverwriteProtection -InFiles $NewFiles -UserParams $UserParams -Mirror 0)
            ,$test | Should BeOfType array
            (Compare-Object $InFiles $test -Property InFullName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Extension -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Size -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Date -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutSubfolder -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property Hash -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property ToCopy -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            # $test | Format-List -Property OutName,OutPath | Out-Host
            $counter = 0
            foreach($i in $test.OutPath){
                if($i -match $([regex]::Escape("$($("$($UserParams.OutputPath)$($InFiles[$i].OutSubfolder)").Replace("\\","\").Replace("\\","\"))"))){
                    $counter++
                }
            }
            $counter | Should be $InFiles.Length
            $counter = 0
            foreach($i in $test.OutName){
                if($i -match '^.*_OutCopy\d_InCopy\d.*$'){$counter++}
            }
            $counter | Should be 0
            $counter = 0
            foreach($i in $test.OutBaseName){
                if($i -match '^.*_OutCopy\d_InCopy\d.*'){$counter++}
            }
            $counter | Should be 0

        }
        It "Long file names" {
            $UserParams.OutputPath = "$BlaDrive\Out_Test\folder_with_long_name_to_exceed_characters_regrets_collect_like_old_friends_here_to_relive_your_darkest_moments_all_of_the_ghouls_come_out_to_play_every_demon_wants_his_pound_of_flesh_i_like_to_keep_some_things_to_myself_it_s_always_darkest_beforeEND"
            New-Item -ItemType Directory -Path $UserParams.OutputPath
            Get-ChildItem -LiteralPath "$BlaDrive\In_Test" -File | Copy-Item -Destination $UserParams.OutputPath
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $NewFiles = $InFiles | Select-Object *
            $test = @(Start-OverwriteProtection -InFiles $NewFiles -UserParams $UserParams -Mirror 0)
            ,$test | Should BeOfType array
            (Compare-Object $InFiles $test -Property InFullName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Extension -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Size -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Date -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutSubfolder -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property Hash -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property ToCopy -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            # $test | Format-List -Property OutName,OutPath | Out-Host
            $counter = 0
            foreach($i in $test.OutPath){
                if($i -match $([regex]::Escape("$($("$($UserParams.OutputPath)$($InFiles[$i].OutSubfolder)").Replace("\\","\").Replace("\\","\"))"))){
                    $counter++
                }
            }
            $counter | Should be $InFiles.Length
            $counter = 0
            foreach($i in $test.OutName){
                if($i -match '^.*_OutCopy\d_InCopy\d.*$'){$counter++}
            }
            $counter | Should be 0
            $counter = 0
            foreach($i in $test.OutBaseName){
                if($i -match '^.*_OutCopy\d_InCopy\d.*'){$counter++}
            }
            $counter | Should be 0
        }
        It "Special characters" {
            $UserParams.OutputPath = "$BlaDrive\Out_Test\folder specChar.(]){[}à°^âaà`````$öäüß'#!%&=´@€+,;-Æ©"
            New-Item -ItemType Directory -Path $UserParams.OutputPath
            Get-ChildItem -LiteralPath "$BlaDrive\In_Test" -File | Copy-Item -Destination $UserParams.OutputPath
            $InFiles = @(Start-FileSearch -UserParams $UserParams)
            $NewFiles = $InFiles | Select-Object *
            $test = @(Start-OverwriteProtection -InFiles $NewFiles -UserParams $UserParams -Mirror 0)
            ,$test | Should BeOfType array
            (Compare-Object $InFiles $test -Property InFullName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property InBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Extension -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Size -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property Date -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutSubfolder -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property OutPath -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property OutBaseName -IncludeEqual -ExcludeDifferent -PassThru).count | Should be 0
            (Compare-Object $InFiles $test -Property Hash -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            (Compare-Object $InFiles $test -Property ToCopy -IncludeEqual -ExcludeDifferent -PassThru).count | Should be $InFiles.Length
            # $test | Format-List -Property OutName,OutPath | Out-Host
            $counter = 0
            foreach($i in $test.OutPath){
                if($i -match $([regex]::Escape("$($("$($UserParams.OutputPath)$($InFiles[$i].OutSubfolder)").Replace("\\","\").Replace("\\","\"))"))){
                    $counter++
                }
            }
            $counter | Should be $InFiles.Length
            $counter = 0
            foreach($i in $test.OutName){
                if($i -match '^.*_OutCopy\d_InCopy\d.*$'){$counter++}
            }
            $counter | Should be 0
            $counter = 0
            foreach($i in $test.OutBaseName){
                if($i -match '^.*_OutCopy\d_InCopy\d.*'){$counter++}
            }
            $counter | Should be 0
        }
    }
}

Describe "Start-FileCopy"{
    It "Copy Files (TODO: Everything.)"{
        #TODO: From here
    }
}


Describe "Start-7zip"{
    It "Starting 7zip (TODO: everything.)"{

    }
}

Describe "Start-FileVerification"{
    It "Verify newly copied files (TODO: everything.)"{

    }
}

Describe "Set-HistFile"{
    It "Write new file-attributes to history-file (TODO: everything.)"{

    }
}
