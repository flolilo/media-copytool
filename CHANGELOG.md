# Changelog
All notable changes to this project will be documented in this file.

(The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html). )

## 0.6.3 - 2017-08-21
### Changed
- Changed most `-Path`s to `-LiteralPath`s - therefore, brackets should work now in paths.
- Fixed encoding issues for good: `Start-Remembering` now works, too. 

### Added
- Nothing.

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

### Removed
- Nothing.


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

### Added
- Nothing.

### Removed
- Nothing.


## 0.5 - 2017-07-28
### Initial GitHub publication.
