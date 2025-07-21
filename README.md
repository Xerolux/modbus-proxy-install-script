# Modbus-Proxy Setup Script

Automatisches Setup-Script für Modbus-Proxy unter Debian/Ubuntu mit systemd Service.

## Übersicht

Dieses Script installiert und konfiguriert automatisch einen Modbus TCP Proxy, der Modbus-Anfragen zwischen verschiedenen Netzwerk-Segmenten weiterleiten kann.

## Features

- ✅ **Automatische Installation** von modbus-proxy mit YAML-Unterstützung
- ✅ **Zwei Installationsmethoden**: pipx (empfohlen) oder Python venv
- ✅ **Einzel- oder Multi-Modbus-Konfiguration**
- ✅ **Systemd Service** mit Auto-Restart
- ✅ **Komplette Bereinigung** alter Installationen
- ✅ **Umfassende Debug-Funktionen**
- ✅ **Automatische Tests** für Konnektivität

## Systemvoraussetzungen

- **Debian 12 (Bookworm)** oder **Ubuntu 20.04+**
- **Root-Rechte** für die Installation
- **Internetverbindung** für Paket-Downloads

## Schnellstart

```bash
# Script herunterladen und ausführbar machen
chmod +x modbus_universal_setup.sh

# Als root ausführen
sudo ./modbus_universal_setup.sh
```

## Installationsoptionen

### 1. Installationsmethode wählen

```bash
=== Installationsmethode waehlen ===
1) pipx (empfohlen - saubere globale Installation)
2) venv (lokale Virtual Environment)
```

**pipx (empfohlen):**
- Globale Installation ohne System-Konflikte
- Einfache Wartung und Updates
- Automatische PATH-Integration

**venv:**
- Isolierte Python-Umgebung
- Lokale Installation in `/opt/modbus-proxy`

### 2. Modbus-Konfiguration

**Standard (Einzel-Modbus):**
```bash
Mehrere Modbus-Geraete konfigurieren? (y/N): [ENTER]
✓ Einzel-Modbus-Modus (Standard)

Listen Port [502]: 502
Listen Interface [0.0.0.0]: 0.0.0.0
Upstream IP-Adresse [192.168.178.198]: 192.168.178.198
Upstream Port [1502]: 1502
```

**Multi-Modbus (optional):**
```bash
Mehrere Modbus-Geraete konfigurieren? (y/N): y
✓ Multi-Modbus-Modus aktiviert

=== Erstes Modbus-Geraet ===
Listen Port [502]: 502
Upstream IP-Adresse [192.168.178.198]: 192.168.178.198

=== Zweites Modbus-Geraet ===
Listen Port [9001]: 9001
Upstream IP-Adresse [192.168.178.199]: 192.168.178.199

Drittes Modbus-Geraet hinzufuegen? (y/N): n
```

## Konfigurationsbeispiele

### Einfacher Proxy
```yaml
devices:
- modbus:
    url: 192.168.178.198:1502
  listen:
    bind: 0.0.0.0:502
```

### Multi-Modbus-Setup
```yaml
devices:
- modbus:
    url: 192.168.178.198:1502
  listen:
    bind: 0.0.0.0:502
- modbus:
    url: 192.168.178.199:1502
  listen:
    bind: 0:9001
- modbus:
    url: 192.168.178.200:1502
  listen:
    bind: 0:9002
```

## Dateien und Pfade

| Komponente | pipx | venv |
|------------|------|------|
| **Binary** | `/root/.local/bin/modbus-proxy` | `/opt/modbus-proxy/venv/bin/modbus-proxy` |
| **Config** | `/etc/modbus-proxy.yaml` | `/etc/modbus-proxy.yaml` |
| **Service** | `/etc/systemd/system/modbus-proxy.service` | `/etc/systemd/system/modbus-proxy.service` |
| **Logs** | `journalctl -u modbus-proxy` | `journalctl -u modbus-proxy` |

## Service-Management

### Status prüfen
```bash
sudo systemctl status modbus-proxy
```

### Service starten/stoppen
```bash
sudo systemctl start modbus-proxy
sudo systemctl stop modbus-proxy
sudo systemctl restart modbus-proxy
```

### Logs anzeigen
```bash
# Live-Logs
sudo journalctl -u modbus-proxy -f

# Letzte 50 Einträge
sudo journalctl -u modbus-proxy -n 50

# Logs seit heute
sudo journalctl -u modbus-proxy --since today
```

### Service aktivieren/deaktivieren
```bash
# Autostart aktivieren
sudo systemctl enable modbus-proxy

# Autostart deaktivieren
sudo systemctl disable modbus-proxy
```

## Konfiguration ändern

### 1. Config-Datei bearbeiten
```bash
sudo nano /etc/modbus-proxy.yaml
```

### 2. Service neu starten
```bash
sudo systemctl restart modbus-proxy
```

### 3. Status prüfen
```bash
sudo systemctl status modbus-proxy
```

## Troubleshooting

### Service startet nicht

**1. Debug-Informationen sammeln:**
```bash
# Service Status
sudo systemctl status modbus-proxy

# Service Logs
sudo journalctl -u modbus-proxy -n 20

# Manual Binary Test
sudo /root/.local/bin/modbus-proxy --help
```

**2. YAML-Syntax prüfen:**
```bash
python3 -c "import yaml; yaml.safe_load(open('/etc/modbus-proxy.yaml'))"
```

**3. Port-Konflikte prüfen:**
```bash
sudo netstat -tlnp | grep :502
```

### Häufige Probleme

**Problem:** `ModuleNotFoundError: No module named 'yaml'`
```bash
# Lösung: Script erneut ausführen (installiert modbus-proxy[yaml])
sudo ./modbus_universal_setup.sh
```

**Problem:** `Permission denied` auf Port 502
```bash
# Service läuft als root - sollte nicht auftreten
# Prüfe ob anderer Service bereits Port 502 nutzt
sudo netstat -tlnp | grep :502
```

**Problem:** Upstream-Server nicht erreichbar
```bash
# Test der Verbindung
telnet 192.168.178.198 1502
# oder
timeout 5 bash -c "echo >/dev/tcp/192.168.178.198/1502"
```

### Neuinstallation

Für eine komplette Neuinstallation:
```bash
# Script führt automatische Bereinigung durch
sudo ./modbus_universal_setup.sh
```

## Netzwerk-Konfiguration

### Standard-Ports
- **502**: Standard Modbus TCP Port
- **1502**: Häufig genutzter alternativer Port
- **9001, 9002**: Empfohlene Ports für Multi-Modbus

### Listen Interface
- **0.0.0.0**: Alle Netzwerk-Interfaces (Standard)
- **127.0.0.1**: Nur localhost
- **192.168.1.100**: Spezifische IP-Adresse
- **0**: Kurzform für 0.0.0.0 (bei Multi-Modbus)

## Updates

### modbus-proxy aktualisieren

**pipx:**
```bash
pipx upgrade modbus-proxy
sudo systemctl restart modbus-proxy
```

**venv:**
```bash
cd /opt/modbus-proxy
source venv/bin/activate
pip install --upgrade modbus-proxy[yaml]
sudo systemctl restart modbus-proxy
```

## Sicherheit

- **Service läuft als root** (notwendig für Port 502)
- **Keine Authentifizierung** - Zugriff über Firewall regeln
- **Logging minimal** - nur Fehler werden protokolliert

### Firewall-Regeln (Beispiel)
```bash
# Zugriff auf Port 502 nur aus lokalem Netz
sudo ufw allow from 192.168.0.0/16 to any port 502

# Spezifische IP-Adressen
sudo ufw allow from 192.168.1.100 to any port 502
```

## Deinstallation

```bash
# Service stoppen und deaktivieren
sudo systemctl stop modbus-proxy
sudo systemctl disable modbus-proxy

# Service-Datei entfernen
sudo rm /etc/systemd/system/modbus-proxy.service

# pipx Installation entfernen
pipx uninstall modbus-proxy

# oder venv entfernen
sudo rm -rf /opt/modbus-proxy

# Config entfernen
sudo rm /etc/modbus-proxy.yaml

# systemd neu laden
sudo systemctl daemon-reload
```

## Support

Bei Problemen:

1. **Debug-Output** des Scripts sammeln
2. **Service-Logs** prüfen: `journalctl -u modbus-proxy -n 50`
3. **YAML-Syntax** validieren
4. **Netzwerk-Konnektivität** testen

## Basierend auf

- [Modbus-Proxy PyPI](https://pypi.org/project/modbus-proxy/)

## Lizenz

Dieses Setup-Script steht unter MIT-Lizenz zur freien Verfügung.
