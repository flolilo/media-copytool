# media-copytool
:uk: [Here's the path to the English readme file](https://github.com/flolilo/media-copytool/blob/master/README.md). :uk:

Media-Copytool ist mein Versuch, die Dateien von den Speicherkarten meiner DSLR einfach (und schnell) auf den Computer zu kopieren. Die Funktionen des Skripts übertreffen inzwischen die der meisten (wenn nicht alle) professionellen RAW-Converter (natürlich nicht, wenn es um's Konvertieren von RAWs geht ;-) ). Doch der Spaß hört hier nicht auf: es kommen immer weitere Features! Und das beste daran: das Skript kann mit **jedem** Dateity umgehen! (Außerdem ist es gratis.)


**Bug-Reports, Fragen und Feature-Requests sind jederzeit gern gesehen!**

## Features
- Dateien werden mit robusten Tools kopiert und dann mit SHA1-Hashes verifiziert, sodass keine Möglichkeit besteht, dass die kopierte Datei fehlerhaft ist.
- Möglichkeit, 2 verschiedene Ausgabe-Pfade anzugeben, um schnelle & einfache Backups zu ermöglichen.
- Durch eine History-Datei ist es dem Skript möglich, das erneute Kopieren von Dateien zu vermeiden - großartig, wenn man seine Speicherkarten nicht jedes Mal formatiert.
- Ansteuerung sowohl über GUI als auch über Parameter möglich
- Durch Multithreading werden die Hash-Berechnungen und das Kopieren beschleunigt (durchschnittlich 2-8x schneller als `for`-Schleifen - siehe [die eigens gefertigte Statistik!](https://github.com/flolilo/media-copytool/blob/master/Stats/Stats.md))
- Durch das Verwenden von eingebauten Tools und Cmdlets wie Robocopy und Get-FileHash hat dieses Skript sehr wenige Voraussetzungen.
- Möglichkeit, aus einer Vielzahl an Unterordner-Stilen zu wählen
- Eingebaute Fail-Saves verhindern grobe Schnitzer durch den User (z.B. Kopieren auf nicht vorhandenes Laufwerk,...)
- Möglichkeit, den Computer vom Wechsel in den Standby-Modus abzuhalten, während das Skript läuft.
- Voreingestellte Dateitypen für die wichtigsten Kamera-Typen; Möglichkeit, benutzerdefinierte Dateien zu definieren (z.B. `*.rtf`)
- Option, um alle Einstellungen als Voreinstellung für künftige usführungen zu speichern.

## Voraussetzungen
- Windows >= XP (Robocopy und Xcopy werden benötigt)
    - Für Windows XP wird das [Windows Server 2003 Resource Kit Tools](https://www.microsoft.com/de-de/download/details.aspx?id=17657) benötigt, um Robocopy zu installieren. Ab Vista ist es sowieso enthalten.
    - Ich bin nicht sicher, ob PowerShell >= Version 3 auf/von WinXP unterstützt wird. Wenn nicht wird das Skript wohl auch nicht auf WinXP laufen.
- [PowerShell >= Version 3](https://www.microsoft.com/en-us/download/details.aspx?id=50395)
- Für die graphische Oberfläche (GUI): [.NET Framework >= 4.6](https://www.microsoft.com/de-DE/download/details.aspx?id=55170)
- Seit v0.6: [PoshRSJob](https://github.com/proxb/PoshRSJob); bisher ersetzt es nur preventsleep.ps1, aber in Zukunft werden damit auch die Hash-Berechnungen beschleunigt werden.
    - Die alte Version ohne PoshRSJob ist in der [ST-branch](https://github.com/flolilo/media-copytool/archive/0.5---without-RSJob.zip) und bekommt Updates, solange der Code dem der master-branch ähnlich genug ist. (Kein Versprechen!)
    - Um PoshRSJob zu installieren: PowerShell als Administrator starten und `Install-Module -Name PoshRSJob` eingeben.
- Für die Nutzung von `-ZipMirror`(.zip-Archiv im zweiten Ausgabepfad) wird [7-Zip](http://www.7-zip.org/) benötigt - das Skript durchsucht seinen eigenenPfad nach `7z.exe`, wenn sie dort nicht gefunden wird sucht es in den Standard-Installationspfaden (32bit und 64 bit) danach - eine vorhandene Installation genügt also.

## Installation
- [Zip downloaden](https://github.com/flolilo/media-copytool/archive/master.zip)
- Die Dateien der Zip in ein gewünschtes Verzeichnis entpacken
- Das `media_copytool.ps1`-Skript starten.

## Wie media-copytool benutzt wird
- PowerShell öffnen und `Get-Help .\media_copytool.ps1 -detailed` eingeben - die Informationen sind zwar in englischer Sprache, sollten aber leicht verständlich sein.

## Problembehandlung
#### Falls das Skript nicht startet:
- Skript nicht direkt starten, sondern eine PowerShell-Konsole öffnen, mit `cd` (oder `Set-Location`) zum Ordner des Skripts navigieren und es dann von dort aufrufen: so kann sich das Fenster nicht schließen, bevor man die Fehlermeldung gesehen hat.
- Überprüfen, ob PowerShells `Set-ExecutionPolicy` [korrekt gesetzt ist](https://superuser.com/a/106363/703240),
    - PowerShell als Administrator starten, `Set-ExecutionPolicy RemoteSigned` eingeben.
- Überprüfen, ob die Voraussetzungen alle eingehalten wurden.
- Das Skript nicht im Basisverzeichnis von `C:\` ablegen. ;-)
- Wurden eckige Klammern `[ ]` verwendet? Lt. Tests sollten sie funktionieren, Fehlfunktionen kann ich aber noch nicht mit absoluter Sicherheit ausschließen.

#### Wenn das Skript sehr lange braucht:
- Im Taksmanager nachsehen: Limitieren die CPU / das Laufwerk? Falls es das Laufwerk ist: schnelleres kaufen. ;-)
    - Wenn es die CPU ist (und sie neuer ist als ein [8086](https://de.wikipedia.org/wiki/8086)) bitte ich um Kontaktaufnahme mit Informationen zu den kopierten Daeien und wann genau der Vorgang anfing langsam zu werden.
- Große History-Dateien verlangsamen den Duplikats-Check erheblich. Man kann diese History-Datei manuell (oder via Skript) löschen / überschreiben, sobald die Speicherkarte formatiert wurde und somit keine Gefahr mehr besteht, alte Dateien mitzukopieren.
- `-ThreadCount 2` oder `-ThreadCount 24` versuchen - gerade bei langsamen Laufwerken kann das helfen.

#### Falls das Skript mit komischen Fehlern aufwartet:
- Bitte so viele Dinge wie möglich notieren: Parameters, Pfade und wann genau die Fehler auftauchten. Bitte auch die Fehlermeldung kopieren (wird immer in English angezeigt, damit sie im Internet leichter auffindbar ist). Ticket öffnen und/oder mich kontaktieren!
    - Das Skript mit `-debug 2` ausführen wenn es schwierig ist zu verfolgen, wann die Fehler starten.
- Wurden eckige Klammern `[ ]` in Pfaden oder Dateien benutzt? Diese sollten inzwischen (seit 0.6.3) funktionieren, absolute sicher bin ich diesbezüglich aber noch nicht.

#### Falls man die GUI sehen will, aber das Skript stattdessen einfach startet:
- Den Parameter `-GUI_CLI_direct "GUI"` beim Start angeben - falls das die Standard-Auswahl sein soll bitte "Remember Settings" in der GUI auswählen.

#### Falls in der GUI mit Netzwerk-Pfaden (wie `\\192.168.0.2\bilder`) gearbeitet werden soll:
- Entweder den Netzwerkpfad als Netzlaufwerk verbinden (via Windows Explorer oder PowerShell)...
- ...oder einfach den Pfad in die Passende Zeile eintragen.

## Was nicht funktioniert
- MTP-Geräte (wie Android-Smartphones). Workaround: Dateien zuerst via Explorer vom MTP-Gerät zum Computer kopieren, dann mit media-copytool weitermachen.
- Das sichere Entfernen funktioniert bei manchen Geräten nicht. *Soll behoben werden, ist aber scheinbar schwierig.*
- Auch wenn Fail-Saves eingebaut sind, die grobe Probleme vermeiden sollten: Wenn man es drauf anlegt ist es dennoch möglich, das Skript zu Fehlern zu bewegen. (Datenverlust sollte aber nicht möglich sein.)
- Obwohl das Multi-Threading funktioniert, kannes gerade bei höheren Nummern das Skript immens verlangsamen - deswegen gibt es einen Parameter bzw. einen Slider hierfür.
- Kein Support für andere Betriebssysteme als Windows *- Support ist aber irgendwann geplant*.

## To do
- [ ] Alle `for`-Schleifen multithreaden (hohe Priorität)
- [x] Evaluierung von Posh-RSJob (**Mithilfe erwünscht!**)
- [x] GUI mit Tabs statt Dropdowns
- [x] Option um Kopien-Verifikation zu deaktivieren, um so die Ausführung zu beschleunigen.
- [x] Option um nur Robocopy zu verwenden und die originale Struktur mitzukopieren (also wie `robocopy InputPath OutputPath /MIR`)
- [x] Mehr Unterordner-Stile
- [x] Option um Dateien nach Datum zu benennen
- [x] Bei nicht vorhandendn Ausgabe-Pfaden: Statt suche nach Überverzeichnis nun kontrollieren, ob Laufwerk existiert
- [x] Multithreading der Get-FileHash Operationen
- [x] Sonderzeichen wie eckige Klammern in Pfaden und Dateien erlauben (Alle Tests sagen, dass es funktioniert)
- [x] Option um zip-Archive auf den Spiegel-Ausgabepfad abzulegen
- [x] Option um USB-Geräte nach dem Abschluss der (ersten) Kopie sicher auszuwerfen
- [x] Option um das Kopieren doppelt vorhandener Dateien zu vermeiden. (Z.B. .\DCIM\File_1.jpeg & .\DCIM\Sub\File_1.jpeg -> .\Out\File_1.jpeg) (Niedrige Priorität)
- [x] Schönere/lesbarere Ausgabe in der Konsole
- [x] Multithreading der GUI
- [x] ~~Zweite JSON-Datei für~~ Inkuldiere die Dateien, die im Ausgabepfad kontrolliert wurden, in die History-Datei.
- [ ] :de: Deutsche Übersetzung (sinnvollerweise erst mit Message-Variablen, daher in weiter Ferne)
- [ ] :de: Parameter des Skripts hier auf Deutsch beschreiben.
