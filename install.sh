# Verify installation
echo "Teste Installation..."#!/bin/bash

# Modbus-Proxy Setup Script (basierend auf blog.caina.de)
set -e

SERVICE_NAME="modbus-proxy"
CONFIG_FILE="/etc/modbus-proxy.yaml"
INSTALL_DIR="/opt/modbus-proxy"

echo "=== Modbus-Proxy Setup Script ==="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Dieses Script muss als root ausgefuehrt werden"
   exit 1
fi

# Complete cleanup of all existing installations
echo "=== Komplette Bereinigung aller vorhandenen Installationen ==="

# Stop and remove service
systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true
rm -f "/etc/systemd/system/$SERVICE_NAME.service"

# Remove global pip installations
pip uninstall -y modbus-proxy 2>/dev/null || true
pip3 uninstall -y modbus-proxy 2>/dev/null || true

# Remove pipx installation
pipx uninstall modbus-proxy 2>/dev/null || true

# Remove old config files
rm -f "/etc/modbus-proxy.conf"
rm -f "/etc/modbus-proxy.yaml"
rm -f "/var/log/modbus-proxy.log"

# Remove directories
rm -rf "/opt/modbus-proxy"

# Remove global binaries
rm -f "/usr/local/bin/modbus-proxy"
rm -f "/usr/bin/modbus-proxy"

# Remove user
userdel modbus-proxy 2>/dev/null || true

systemctl daemon-reload

echo "✓ Alle alten Installationen entfernt"
echo ""

# Installation method selection
echo "=== Installationsmethode waehlen ==="
echo "1) pipx (empfohlen - saubere globale Installation)"
echo "2) venv (lokale Virtual Environment)"
echo ""
read -p "Installationsmethode (1/2): " install_method

case $install_method in
    1|pipx)
        INSTALL_METHOD="pipx"
        echo "✓ pipx gewaehlt"
        ;;
    2|venv)
        INSTALL_METHOD="venv"
        echo "✓ venv gewaehlt"
        ;;
    *)
        echo "Ungueltige Auswahl. Verwende pipx als Standard."
        INSTALL_METHOD="pipx"
        ;;
esac

echo ""

# Network configuration
echo "=== Netzwerk-Konfiguration ==="

# Ask for multi-device setup first
echo "Modbus-Konfiguration:"
read -p "Mehrere Modbus-Geraete konfigurieren? (y/N): " -n 1 -r
echo
MULTI_DEVICE=false
if [[ $REPLY =~ ^[Yy]$ ]]; then
    MULTI_DEVICE=true
    echo "✓ Multi-Modbus-Modus aktiviert"
else
    echo "✓ Einzel-Modbus-Modus (Standard)"
fi

echo ""

# First device (always required)
if [[ "$MULTI_DEVICE" == true ]]; then
    echo "=== Erstes Modbus-Geraet ==="
else
    echo "=== Modbus-Geraet Konfiguration ==="
fi

# Listen Port
read -p "Listen Port [502]: " listen_port1
listen_port1=${listen_port1:-502}

# Listen Interface
read -p "Listen Interface [0.0.0.0]: " listen_interface1
listen_interface1=${listen_interface1:-0.0.0.0}

# Upstream Host
read -p "Upstream IP-Adresse [192.168.178.198]: " upstream_host1
upstream_host1=${upstream_host1:-192.168.178.198}

# Upstream Port
read -p "Upstream Port [1502]: " upstream_port1
upstream_port1=${upstream_port1:-1502}

if [[ "$MULTI_DEVICE" == true ]]; then
    echo ""
    echo "Erstes Geraet: $listen_interface1:$listen_port1 -> $upstream_host1:$upstream_port1"
    
    # Second device configuration
    echo ""
    echo "=== Zweites Modbus-Geraet ==="
    
    read -p "Listen Port [9001]: " listen_port2
    listen_port2=${listen_port2:-9001}
    
    read -p "Listen Interface [0]: " listen_interface2
    listen_interface2=${listen_interface2:-0}
    
    read -p "Upstream IP-Adresse [192.168.178.199]: " upstream_host2
    upstream_host2=${upstream_host2:-192.168.178.199}
    
    read -p "Upstream Port [1502]: " upstream_port2
    upstream_port2=${upstream_port2:-1502}
    
    echo ""
    echo "Zweites Geraet: $listen_interface2:$listen_port2 -> $upstream_host2:$upstream_port2"
    
    # Option for third device
    echo ""
    read -p "Drittes Modbus-Geraet hinzufuegen? (y/N): " -n 1 -r
    echo
    ADD_THIRD_DEVICE=false
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ADD_THIRD_DEVICE=true
        echo ""
        echo "=== Drittes Modbus-Geraet ==="
        
        read -p "Listen Port [9002]: " listen_port3
        listen_port3=${listen_port3:-9002}
        
        read -p "Listen Interface [0]: " listen_interface3
        listen_interface3=${listen_interface3:-0}
        
        read -p "Upstream IP-Adresse [192.168.178.200]: " upstream_host3
        upstream_host3=${upstream_host3:-192.168.178.200}
        
        read -p "Upstream Port [1502]: " upstream_port3
        upstream_port3=${upstream_port3:-1502}
        
        echo ""
        echo "Drittes Geraet: $listen_interface3:$listen_port3 -> $upstream_host3:$upstream_port3"
    fi
fi

echo ""
echo "=== Konfiguration ==="
echo "Installationsmethode: $INSTALL_METHOD"
if [[ "$MULTI_DEVICE" == true ]]; then
    echo "Modus: Multi-Modbus"
    echo "Erstes Geraet: $listen_interface1:$listen_port1 -> $upstream_host1:$upstream_port1"
    echo "Zweites Geraet: $listen_interface2:$listen_port2 -> $upstream_host2:$upstream_port2"
    if [[ "$ADD_THIRD_DEVICE" == true ]]; then
        echo "Drittes Geraet: $listen_interface3:$listen_port3 -> $upstream_host3:$upstream_port3"
    fi
else
    echo "Modus: Einzel-Modbus"
    echo "Modbus-Geraet: $listen_interface1:$listen_port1 -> $upstream_host1:$upstream_port1"
fi
echo ""

read -p "Installation mit diesen Einstellungen starten? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Installation abgebrochen."
    exit 0
fi

echo ""
echo "=== Installation ==="

# Install system dependencies
echo "Installiere System-Abhaengigkeiten..."
apt-get update

if [[ "$INSTALL_METHOD" == "pipx" ]]; then
    apt-get install -y python3 python3-pip pipx

    # Install modbus-proxy with YAML support using pipx
    echo "Installiere modbus-proxy[yaml] mit pipx..."
    pipx install modbus-proxy[yaml]

    # Add pipx binaries to PATH
    echo "Fuege pipx zum PATH hinzu..."
    pipx ensurepath

    PROXY_BINARY="/root/.local/bin/modbus-proxy"

else
    apt-get install -y python3 python3-venv python3-pip

    # Create installation directory
    echo "Erstelle Installationsverzeichnis..."
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Create virtual environment
    echo "Erstelle Python Virtual Environment..."
    python3 -m venv venv
    source venv/bin/activate

    # Install modbus-proxy with YAML support
    echo "Installiere modbus-proxy[yaml]..."
    pip install --upgrade pip
    pip install modbus-proxy[yaml]

    PROXY_BINARY="$INSTALL_DIR/venv/bin/modbus-proxy"
fi

if [[ ! -f "$PROXY_BINARY" ]]; then
    echo "✗ modbus-proxy Binary nicht gefunden: $PROXY_BINARY"
    echo "pipx Installation fehlgeschlagen"
    exit 1
fi

if ! "$PROXY_BINARY" --help >/dev/null 2>&1; then
    echo "✗ modbus-proxy Binary nicht ausfuehrbar"
    exit 1
fi

echo "✓ modbus-proxy erfolgreich installiert"

# Create YAML configuration for single or multiple devices
echo "Erstelle YAML-Konfigurationsdatei..."

cat > "$CONFIG_FILE" << EOF
devices:
- modbus:
    url: $upstream_host1:$upstream_port1
  listen:
    bind: $listen_interface1:$listen_port1
EOF

# Add additional devices if configured
if [[ "$MULTI_DEVICE" == true ]]; then
cat >> "$CONFIG_FILE" << EOF
- modbus:
    url: $upstream_host2:$upstream_port2
  listen:
    bind: $listen_interface2:$listen_port2
EOF

    if [[ "$ADD_THIRD_DEVICE" == true ]]; then
cat >> "$CONFIG_FILE" << EOF
- modbus:
    url: $upstream_host3:$upstream_port3
  listen:
    bind: $listen_interface3:$listen_port3
EOF
    fi
fi

echo "Debug: Erstellte Konfigurationsdatei:"
echo "=== $CONFIG_FILE ==="
cat "$CONFIG_FILE"
echo "=================="

# Test YAML syntax
echo "Teste YAML-Syntax..."
if ! python3 -c "import yaml; yaml.safe_load(open('$CONFIG_FILE'))" 2>/dev/null; then
    echo "✗ YAML-Syntax-Fehler in der Konfigurationsdatei"
    exit 1
fi
echo "✓ YAML-Syntax korrekt"

# Create systemd service (adapted for installation method)
echo "Erstelle Systemd Service..."

if [[ "$INSTALL_METHOD" == "pipx" ]]; then
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=Modbus-Proxy service
After=network.target

[Service]
Type=simple
Restart=always
ExecStart=$PROXY_BINARY -c $CONFIG_FILE

[Install]
WantedBy=multi-user.target
EOF
else
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=Modbus-Proxy service
After=network.target

[Service]
Type=simple
Restart=always
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStart=$PROXY_BINARY -c $CONFIG_FILE

[Install]
WantedBy=multi-user.target
EOF
fi

# Enable and start service
echo "Aktiviere und starte Service..."

# Set ownership for venv installation
if [[ "$INSTALL_METHOD" == "venv" ]]; then
    chown -R root:root "$INSTALL_DIR"
fi

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

echo ""
echo "=== Installation abgeschlossen ==="
echo "Installationsmethode: $INSTALL_METHOD"
echo "Binary: $PROXY_BINARY"
echo "Konfiguration: $CONFIG_FILE"
echo "Service: $SERVICE_NAME"
echo ""
if [[ "$MULTI_DEVICE" == true ]]; then
    echo "Konfigurierte Geraete:"
    echo "  Erstes Geraet: $listen_interface1:$listen_port1 -> $upstream_host1:$upstream_port1"
    echo "  Zweites Geraet: $listen_interface2:$listen_port2 -> $upstream_host2:$upstream_port2"
    if [[ "$ADD_THIRD_DEVICE" == true ]]; then
        echo "  Drittes Geraet: $listen_interface3:$listen_port3 -> $upstream_host3:$upstream_port3"
    fi
else
    echo "Modbus-Geraet: $listen_interface1:$listen_port1 -> $upstream_host1:$upstream_port1"
fi
echo ""

# Start service and test
read -p "Service jetzt starten? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Starte Service..."
    systemctl start "$SERVICE_NAME"
    sleep 3
    
    echo ""
    echo "Service Status:"
    systemctl status "$SERVICE_NAME" --no-pager
    
    # Extensive debugging if service failed
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        echo ""
        echo "=== DEBUG: Service fehlgeschlagen ==="
        
        echo "1. Service Logs:"
        journalctl -u "$SERVICE_NAME" -n 20 --no-pager
        
        echo ""
        echo "2. Manual Binary Test:"
        echo "Befehl: $PROXY_BINARY --help"
        "$PROXY_BINARY" --help 2>&1 | head -10 || echo "Help failed"
        
        echo ""
        echo "3. Manual Config Test:"
        echo "Befehl: $PROXY_BINARY -c $CONFIG_FILE"
        timeout 5 "$PROXY_BINARY" -c "$CONFIG_FILE" 2>&1 || echo "Config test failed or timed out"
        
        echo ""
        echo "4. Python YAML Test:"
        python3 -c "
import yaml
try:
    with open('$CONFIG_FILE') as f:
        config = yaml.safe_load(f)
        print('YAML parsed successfully:', config)
except Exception as e:
    print('YAML error:', e)
"
        
        echo ""
        echo "5. Port Test:"
        if command -v netstat >/dev/null; then
            echo "Teste Port $listen_port1:"
            netstat -tln | grep ":$listen_port1 " || echo "Port $listen_port1 not in use"
            if [[ "$MULTI_DEVICE" == true ]]; then
                echo "Teste Port $listen_port2:"
                netstat -tln | grep ":$listen_port2 " || echo "Port $listen_port2 not in use"
                if [[ "$ADD_THIRD_DEVICE" == true ]]; then
                    echo "Teste Port $listen_port3:"
                    netstat -tln | grep ":$listen_port3 " || echo "Port $listen_port3 not in use"
                fi
            fi
        fi
        
        echo ""
        echo "6. pipx Environment Test:"
        pipx list | grep modbus-proxy || echo "modbus-proxy not in pipx list"
        
        echo "========================="
        exit 1
    else
        echo ""
        echo "✓ Service erfolgreich gestartet!"
        
        # Test port binding
        sleep 2
        if command -v netstat >/dev/null; then
            if netstat -tln | grep -q ":$listen_port1 "; then
                echo "✓ Service hoert auf Port $listen_port1"
            else
                echo "⚠️ Port $listen_port1 moeglicherweise nicht geoeffnet"
            fi
            
            if [[ "$MULTI_DEVICE" == true ]]; then
                if netstat -tln | grep -q ":$listen_port2 "; then
                    echo "✓ Service hoert auf Port $listen_port2"
                else
                    echo "⚠️ Port $listen_port2 moeglicherweise nicht geoeffnet"
                fi
                
                if [[ "$ADD_THIRD_DEVICE" == true ]] && netstat -tln | grep -q ":$listen_port3 "; then
                    echo "✓ Service hoert auf Port $listen_port3"
                elif [[ "$ADD_THIRD_DEVICE" == true ]]; then
                    echo "⚠️ Port $listen_port3 moeglicherweise nicht geoeffnet"
                fi
            fi
        fi
        
        # Test upstream connectivity
        if [[ "$MULTI_DEVICE" == true ]]; then
            echo "Teste Upstream-Verbindung zu $upstream_host1:$upstream_port1..."
            if timeout 5 bash -c "echo >/dev/tcp/$upstream_host1/$upstream_port1" 2>/dev/null; then
                echo "✓ Erstes Upstream-Geraet erreichbar"
            else
                echo "⚠️ Erstes Upstream-Geraet nicht erreichbar (normal wenn Server nicht laeuft)"
            fi
            
            echo "Teste Upstream-Verbindung zu $upstream_host2:$upstream_port2..."
            if timeout 5 bash -c "echo >/dev/tcp/$upstream_host2/$upstream_port2" 2>/dev/null; then
                echo "✓ Zweites Upstream-Geraet erreichbar"
            else
                echo "⚠️ Zweites Upstream-Geraet nicht erreichbar (normal wenn Server nicht laeuft)"
            fi
            
            if [[ "$ADD_THIRD_DEVICE" == true ]]; then
                echo "Teste Upstream-Verbindung zu $upstream_host3:$upstream_port3..."
                if timeout 5 bash -c "echo >/dev/tcp/$upstream_host3/$upstream_port3" 2>/dev/null; then
                    echo "✓ Drittes Upstream-Geraet erreichbar"
                else
                    echo "⚠️ Drittes Upstream-Geraet nicht erreichbar (normal wenn Server nicht laeuft)"
                fi
            fi
        else
            echo "Teste Upstream-Verbindung zu $upstream_host1:$upstream_port1..."
            if timeout 5 bash -c "echo >/dev/tcp/$upstream_host1/$upstream_port1" 2>/dev/null; then
                echo "✓ Upstream-Geraet erreichbar"
            else
                echo "⚠️ Upstream-Geraet nicht erreichbar (normal wenn Server nicht laeuft)"
            fi
        fi
    fi
fi

echo ""
echo "=== Management-Befehle ==="
echo "Status pruefen:    systemctl status $SERVICE_NAME"
echo "Logs anzeigen:     journalctl -u $SERVICE_NAME -f"
echo "Service stoppen:   systemctl stop $SERVICE_NAME"
echo "Service starten:   systemctl start $SERVICE_NAME"
echo "Config bearbeiten: nano $CONFIG_FILE"
echo "Binary testen:     $PROXY_BINARY --help"
echo ""
echo "=== Setup abgeschlossen ==="
