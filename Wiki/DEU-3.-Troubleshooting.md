## Problembehandlung
#### Falls das Skript nicht startet:
- Skript nicht direkt starten, sondern eine PowerShell-Konsole öffnen, mit `cd` (oder `Set-Location`) zum Ordner des Skripts navigieren und es dann von dort aufrufen: so kann sich das Fenster nicht schließen, bevor man die Fehlermeldung gesehen hat.
- Überprüfen, ob PowerShells `Set-ExecutionPolicy` [korrekt gesetzt ist](https://superuser.com/a/106363/703240),
    - PowerShell als Administrator starten, `Set-ExecutionPolicy RemoteSigned` eingeben.
- Überprüfen, ob [alle Voraussetzungen](https://github.com/flolilo/media-copytool/wiki/DEU-2.-Installation#voraussetzungen) eingehalten wurden.
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
