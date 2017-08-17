# Changelog
All notable changes to this project will be documented in this file.

(The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html). )

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
