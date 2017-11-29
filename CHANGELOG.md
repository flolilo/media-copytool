# Changelog
All notable changes to this project will be documented in this file.

(The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).)

## 0.8.4 - 2017-11-29
### Changed
- Aesthetics (GUI): broadened `TextBoxes` for paths, rearranged some `checkboxes`, improved behavior of format-`checkboxes`

### Added
- `Start-SpaceCheck()` to check if free space is sufficient.
- `-OverwriteExistingFiles` to overwrite existing files instead of giving new files unique names.

### Removed
- `-ThreadCount`, as it is no longer needed.


## 0.8.3 - 2017-11-27
### Changed
- Bugfix: If no history-entries are found, the duplicate-check would fail because of the `null`-array.
- Improvement/change: if a different preset is loaded, `-SaveParamPresetName` will get changed accordingly. (I always accidentally updated the old profile before...)
- Bugfix: `Set-Parameters()` would also try to save `-GUI_CLI_Direct` and `-Debug`.
- Improvement/change: Always check for specific parameters stored in your `mc_parameters.json` via `Get-Parameters()` if you leave them empty and when `-GUI_CLI_Direct` is `GUI` or `direct`.
- Aesthetics: show PID regardless of `Debug`-level, condense the bars a bit to improve readability.

### Added
- `-PresetFormats "Inter"` - will look for `.DNG`- and `.TIF`-files.
- Parameter `-JSONParamPath`.


## 0.8.2 - 2017-11-26
### Changed
- Improvement towards hashes: calculate only what's needed - when it's needed.
- Changed `-DupliCompareHashes` to `-HistCompareHashes` (also the respective GUI-values), as it is more accurate and less confusing.
- Changed behavior of `Invoke-Pause()` (access `$timer` without parameter)


## 0.8.1 - 2017-11-26
### Changed
- Comparison in `Start-DupliCheckOut()`.
- Small bugfixes and improvements (one `$script:Debug -gt1`, several `$a = $inter; $inter = $a`s were condensed)

### Removed
- Only old code that was already commented out.

### Added
- `Compare-Object` in `Start-DupliCheckOut()`.


## 0.8.0 - 2017-10-28
### Changed
- Parameter-JSON-file is now fixed, but different presets can be saved to and loaded from it.
- `-JSONHistFilePath` is now `-HistFilePath`.
- GUI, so it reflects the changes.

### Added
- `-LoadParameterPresetName` to load parameters from mc_parameters.json.
- `-SaveParameterPresetName` to save parameters to mc_parameters.json.

### Removed
- `-JSONParamPath`.


## 0.7.10 - 2017-10-25
### Changed
- Renamed subfiles from `media_copytool_` to `mc_`
- Improvement: Parameters are now available through a JSON-file via `-JSONParamPath`.
- Improvement: History-file can be set via `-JSONHistFilePath`.

### Added
- `-JSONParamPath` & `parameters.json`
- `-JSONHistFilePath`


## 0.7.9 - 2017-10-03
### Changed
- Bugfix: As Windows has an unattended timeout-counter, `preventsleep` will now poll every 90 seconds.
- Improvement: `Write-ColorOut` needs fewer `[Console]`-queries.
- Improvement: `Start-DupliCheckHist` has realigned `properties`-variable for `Compare-Object` (now before `for`-loop, not inside it).

### Added
- `Start-DupliCheckOut` and `Set-HistFile` now include found files in history-file.


## 0.7.8 - 2017-09-19
### Changed
- GUI gets now called from within function `Start-GUI`, so it can close and open up again (no more window-debris!)
- Unthrottled the `RSJobs`, as it seemingly decreases use of ressources
- `try-catch`ing all file-operations (`Get-FileHash`, `Remove-Item`, `Rename-Item`, `New-Item`)
- Changed the way `Write-ColorOut`-indentations work.

### Added
- Some parts about multithreading the last parts: as they all take longer when multithreaded, these parts are commented out. (They were a lot of work, that's why they stay there.)
- `Write-ColorOut` now has a parameter `-Indentation` which will change the `LeftCursor`-position. 


## 0.7.7. - 2017-09-19
### Added
- `-AvoidIdenticalFiles`-Parameter + GUI-checkbox. Now one can opt to only copy one of multiple identical files that are present on the input-path.


## 0.7.6 - 2017-09-18
### Changed
- Split Function `StartFileSearchAndCheck` into sub-functions `Start-FileSearch`, `Start-DupliCheckHist`, `Start-DupliCheckOut`, `Start-InputGetHash`. Adapted code in `Start-Everything` to reflect this.
- Bugfix: `"$($PSScriptRoot)"` instead of `"$PSScriptRoot"` in `Set-HistFile`
- Bugfix: `"$($PSCommandPath)"` instead of `"$PSCommandPath"` in `$WPFbuttonAbout.Add_Click`
- Bugfix: Check for compromised history-file in `Get-HistFile` would falsely alarm user in case of only one entry.
- Cosmetic: Debug-Output is now competely optional
- Cosmetic: Console-Outputs from Functions are now indented


## 0.7.5 - 2017-09-18
### Changed
- Renamed script (removed "-MT", as both branches are now multithreaded).
- Bugfix: `media_copytool_preventsleep` wouldn't close properly due to a wrongly named variable.
- Bugfix: Progress-bars should now all close properly.
- Change: `-ThreadCount`'s description was updated due to performance-tests. Default-value now is 6, range can go from 2-48.


## 0.7.3-MT - 2017-09-16
### Changed
- Bugfix: preventsleep wasn't working with `PoshRSJob`, so reverted to `preventsleep.ps1`.

### Added
- `media_copytool_preventsleep.ps1`.


## 0.7.2-MT - 2017-09-08
### Changed
- Bugfix: in `-GUI_CLI_direct direct`, `Get-UserValues` would always return `$false`.
- Bugfix: all `for`-loops should now work with single files, too.
- Bugfix: Mirror-Archive would not copy all files.

### Added
- Option to show found input-files in `-debug >= 1`


## 0.7.1-MT - 2017-09-08
### Changed
- Bugfix: If both `-OutputSubfolderStyle` and `-OutputFileStyle` are set to `unchanged`, Robocopy would not copy all files correctly at the first attempt.


## 0.7.0-MT - 2017-09-05
### Changed
- Bugfix: In `-GUI_CLI_Direct "direct"`, `-PresetFormats` wouldn't work.
- Bugfix: If >0 filed were found corrupt/missing, all files were re-copied.

### Added
- `-OutputFileStyle`-Parameter and -Function


## 0.6.9 - 2017-09-02
### Changed
- Small things: remove histfile-variable after use to save a few KB of RAM, mainly

### Added
- `-ZipArchive`-Parameter and -Function
- Failsafe for GUI.


## 0.6.8 - 2017-08-31
### Added
- Option `unchanged` to `-OutputSubfolderStyle` - works like Robocopy's `/MIR`.


## 0.6.7 - 2017-08-31
### Added
- `-VerifyCopies` - now verifying copied files is optional.


## 0.6.6 - 2017-08-23
### Changed
- Small improvements for readability of if-conditions in the code.
- Outsourced XAML-code for GUI from script-file, added `GUI.xaml`-file.
- GUI-Layout for readability

### Added
- `media_copytool_GUI.xaml`

### Removed
- XAML-code from `media_copytool.ps1`


## 0.6.5 - 2017-08-21
### Added
- Rough structure for 7zip (should come with 0.7.0, which should be the next release.)
- Option to remove the input-drive safely after copying and verificating to (first) output-path. Limition: only works on some drives, so please double-check if it worked.


## 0.6.4 - 2017-08-21
### Changed
- Changed test for output-paths in function `Get-UserValues`: `Split-Path -Qualifier` enables to create new directories as long as they point to a valid drive. Thanks to https://stackoverflow.com/a/45596690/8013879 !


## 0.6.3 - 2017-08-21
### Changed
- Changed most `-Path`s to `-LiteralPath`s - therefore, brackets should work now in paths.
- Fixed encoding issues for good: `Start-Remembering` now works, too. 

### Removed
- All special character detectors (because they now should work).


## 0.6.2 - 2017-08-20
### Changed
- Changed `for`-loops with `Get-FileHash`-instances and Xcopy-instances to `Start-RSJob`s - Now the script truly supports multithreading, and it's fast!

### Added
- `Start-RSJob`s for `Get-FileHash` and Xcopy
    - Parameter (and GUI TextBox & Slider) `ThreadCount` to allow the user to experiment with different thread counts. To high numbers (with average equipment: >4) will slow everything down!

### Removed
- `for`-loops with `Get-FileHash`-instances and Xcopy-instances


## 0.6.1 - 2017-08-19
#### Same code as [0.5-branch's 0.5.2 (2017-08-19)](https://github.com/flolilo/media-copytool/blob/0.5---without-RSJob/CHANGELOG.md), except from using PoshRSJob instead of preventsleep.ps1 

### Changed
- Fixing error in function `Start-Remembering` that would result in messing up the parameter-variables
- Changed from `Write-Host` to own function `Write-ColorOut` and function `Write-Progress` for a more readable output and faster performance (`Write-Host` is very slow)
- Changed script's encoding back from `UTF-8` to `UTF-8 with BOM` (hopefully, it stays that way now.)

### Added
- Sub-function in function `Get-UserValues` to remove trailing backslashes in the path-variables' values.
- `$OutputEncoding` is now set to UTF8 (after parameter-block), so hopefully there won't be any more errors because of wrong encodings in the future.


## 0.6.0 - 2017-8-17
### Changed
- Standby-prevention is now done via an RSJob instead of the external script `preventsleep.ps1`

### Added
- New Function to replace `Write-Host` **in future releases** -> increase in performance
- Warning-message if Module PoshRSJob is not installed
- RSJob `PreventSleep` (see "changed")

### Removed
- Script `preventsleep.ps1` (see "changed")


## 0.5.1 - 2017-08-15
### Changed
- Fixed endless loop when getting the history-file.
- Sped up comparison with history-file (especially when it has many entries) by reversing the order of comparison (meaning that the latest files will be compared first).


## 0.5 - 2017-07-28
### Initial GitHub publication.
