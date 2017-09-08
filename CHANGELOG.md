# Changelog
All notable changes to this project will be documented in this file.

(The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html). )

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
