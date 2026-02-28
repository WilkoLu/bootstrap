#!/bin/bash
# Bootstrap Skript für Debian

# ========================
# Konfiguration
# ========================
USERNAME="${1:-debian}"        # Standard: debian, kann als Argument übergeben werden
PASSWORD="${2:-changeme}"      # Standardpasswort
SUDO="${3:-yes}"               # yes/no
INSTALL_DOCKER="${4:-yes}"     # yes/no
# ========================

# Nur als root ausführbar
if [ "$(id -u)" -ne 0 ]; then
    echo "Bitte als root ausführen!"
    exit 1
fi

# User erstellen
if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME existiert bereits."
else
    echo "Erstelle Benutzer $USERNAME..."
    adduser --disabled-password --gecos "" "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd

    if [ "$SUDO" = "yes" ]; then
        usermod -aG sudo "$USERNAME"
        echo "$USERNAME wurde zur sudo-Gruppe hinzugefügt."
    fi
fi

# Docker installieren
if [ "$INSTALL_DOCKER" = "yes" ]; then
    echo "Installiere Docker..."
    apt update
    apt install -y ca-certificates curl gnupg lsb-release

    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    usermod -aG docker "$USERNAME"
    echo "Docker installiert und $USERNAME zur Docker-Gruppe hinzugefügt."
fi

echo "Bootstrap abgeschlossen!"