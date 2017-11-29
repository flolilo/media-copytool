Media-Copytool ist ein PowerShell-Skript - Das macht es sehr einfach zu installieren, allerdings heißt es auch, dass einige Voraussetzungen erfüllt werden müssen:

## Voraussetzungen:
- Windows >= XP (Robocopy und Xcopy werden benötigt)
    - Für Windows XP wird das [Windows Server 2003 Resource Kit Tools](https://www.microsoft.com/de-de/download/details.aspx?id=17657) benötigt, um Robocopy zu installieren. Ab Vista ist es sowieso enthalten.
    - Ich bin nicht sicher, ob PowerShell >= Version 3 auf/von WinXP unterstützt wird. Wenn nicht wird das Skript wohl auch nicht auf WinXP laufen.
- [PowerShell >= Version 3](https://www.microsoft.com/en-us/download/details.aspx?id=50395)
- Für die graphische Oberfläche (GUI): [.NET Framework >= 4.6](https://www.microsoft.com/de-DE/download/details.aspx?id=55170)
- Seit v0.6: [PoshRSJob](https://github.com/proxb/PoshRSJob); damit werden die Hash-Berechnungen beschleunigt.
    - Die alte Version ohne PoshRSJob ist in der [ST-branch](https://github.com/flolilo/media-copytool/archive/0.5---without-RSJob.zip) und bekommt Updates, solange der Code dem der master-branch ähnlich genug ist. (Kein Versprechen!)
    - Um PoshRSJob zu installieren: PowerShell als Administrator starten und `Install-Module -Name PoshRSJob` eingeben.
- Für die Nutzung von `-ZipMirror`(.zip-Archiv im zweiten Ausgabepfad) wird [7-Zip](http://www.7-zip.org/) benötigt - das Skript durchsucht seinen eigenenPfad nach `7z.exe`, wenn sie dort nicht gefunden wird sucht es in den Standard-Installationspfaden (32bit und 64 bit) danach - eine vorhandene Installation genügt also.

## Installation:
- [Die ZIP downloaden](https://github.com/flolilo/media-copytool/archive/master.zip),
- Den Inhalt der ZIP in einen beliebigen Ordner extrahieren,
- Das Skript `media_copytool.ps1` starten.
