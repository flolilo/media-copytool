# media-copytool
:uk: [Here's the path to the English readme file](https://github.com/flolilo/media-copytool/blob/master/README.md). :uk:

PowerShell-basiertes Skript mit GUI, das Datien nicht nur kopiert, sondern auch verifiziert. *Jetzt mit Multithreading für höhere Geschwindigkeiten!*


## Voraussetzungen
- Windows >= XP (Robocopy und Xcopy werden benötigt)
    - Für Windows XP wird das [Windows Server 2003 Resource Kit Tools](https://www.microsoft.com/de-de/download/details.aspx?id=17657) benötigt, um Robocopy zu installieren. Ab Vista ist es sowieso enthalten.
    - Ich bin nicht sicher, ob PowerShell >= Version 3 auf/von WinXP unterstützt wird.
- [PowerShell >= Version 3](https://www.microsoft.com/en-us/download/details.aspx?id=50395)
- Für die graphische Oberfläche (GUI): [.NET Framework >= 4.6](https://www.microsoft.com/de-DE/download/details.aspx?id=55170)
- Seit v0.6: [PoshRSJob](https://github.com/proxb/PoshRSJob); bisher ersetzt es nur preventsleep.ps1, aber in Zukunft werden damit auch die Hash-Berechnungen beschleunigt werden.
    - Die alte Version ohne PoshRSJob ist in der [0.5-branch](https://github.com/flolilo/media-copytool/archive/0.5---without-RSJob.zip) und bekommt Updates, solange der Code dem der master-branch ähnlich genug ist. (Kein Versprechen!)
    - Um PoshRSJob zu installieren: PowerShell als Administrator starten und `Install-Module -Name PoshRSJob` eingeben.

## Installation
- [Zip downloaden](https://github.com/flolilo/media-copytool/archive/master.zip)
- Die Dateien der Zip in ein gewünschtes Verzeichnis entpacken
- Das `media_copytool.ps1`-Skript starten.

## Wie media-copytool benutzt wird
- PowerShell öffnen und `Get-Help .\media_copytool.ps1 -detailed` eingeben - die Informationen sind zwar in englischer Sprache, sollten aber leicht verständlich sein.

## Problembehandlung
Falls das Skript nicht startet:
- Überprüfen, ob PowerShells `Set-ExecutionPolicy` [korrekt gesetzt ist](https://superuser.com/a/106363/703240),
    - PowerShell als Administrator starten, `Set-ExecutionPolicy RemoteSigned` eingeben.
- Überprüfen, ob die Voraussetzungen alle eingehalten wurden.
- Das Skript nicht im Basisverzeichnis von `C:\` ablegen. ;-)
- Wurden eckige Klammern `[ ]` verwendet? Lt. Tests sollten sie funktionieren, Fehlfunktionen kann ich aber noch nicht mit absoluter Sicherheit ausschließen.

## To do
- [ ] Checking if the volume exists if output-path(s) are not found (instead of looking for the parent directory) (High priority)
- [x] Multithreading Get-FileHash operations (High priority)
- [x] Allowing special characters like brackets in Paths
- [ ] Option to create a 7zip-archive for mirror-copying (Medium priority)
- [ ] Option to unmount USB drives after finishing (first) copy (Medium priority)
- [ ] Option to avoid copying a file that exists more than once in the input more than one time. (E.g. .\DCIM\File_1.jpeg & .\DCIM\Sub\File_1.jpeg -> .\Out\File_1.jpeg) (Low priority)
- [x] Making the output look nice(r) and especially make errors more transparent to users (Low priority)
- [ ] Multithreading the GUI (Low priority)
- [ ] Creating a second JSON-file for looked up files in output-path (eventually)
- [ ] :de: Deutsche Übersetzung (sinnvollerweise erst mit Message-Variablen, daher in weiter Ferne)
- [ ] :de: Funktionen hier auf Deutsch beschreiben.
- [ ] :de: To do fertig übersetzen.