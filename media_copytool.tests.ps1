# Comment out the last block of media_copytool (i.e. "Start-up") before running this script!
. $PSScriptRoot\media_copytool.ps1


Describe "Get-Parameters"{
    It "Get parameters from JSON file"{

    }
}

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
