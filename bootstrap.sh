#!/bin/bash

# ==============================
# Debian Interaktives Setup
# ==============================

# Root-Check
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Bitte als root ausführen!"
    exit 1
fi

echo "=============================="
echo " Debian Bootstrap Setup"
echo "=============================="

# Benutzername
read -p "Neuen Benutzernamen festlegen: " USERNAME

if id "$USERNAME" &>/dev/null; then
    echo "❌ Benutzer existiert bereits!"
    exit 1
fi

# Passwort (verdeckt)
read -s -p "Passwort festlegen: " PASSWORD
echo
read -s -p "Passwort wiederholen: " PASSWORD2
echo

if [ "$PASSWORD" != "$PASSWORD2" ]; then
    echo "❌ Passwörter stimmen nicht überein!"
    exit 1
fi

# sudo installieren?
read -p "sudo installieren? (j/n): " INSTALL_SUDO

if [[ "$INSTALL_SUDO" =~ ^[Jj]$ ]]; then
    apt update
    apt install -y sudo
fi

# Root-/Sudo-Rechte?
read -p "Soll der Benutzer sudo/root Rechte bekommen? (j/n): " GIVE_SUDO

# Docker installieren?
read -p "Docker + Docker Compose installieren? (j/n): " INSTALL_DOCKER

echo
echo "🚀 Starte Installation..."
echo

# Benutzer erstellen
adduser --disabled-password --gecos "" "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

if [[ "$GIVE_SUDO" =~ ^[Jj]$ ]]; then
    usermod -aG sudo "$USERNAME"
    echo "✔ Benutzer zur sudo-Gruppe hinzugefügt."
fi

# Docker Installation
if [[ "$INSTALL_DOCKER" =~ ^[Jj]$ ]]; then
    echo "🐳 Installiere Docker..."

    apt install -y ca-certificates curl gnupg lsb-release

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    usermod -aG docker "$USERNAME"

    echo "✔ Docker installiert."
fi

echo
echo "=============================="
echo "✅ Setup abgeschlossen!"
echo "Benutzer: $USERNAME"
echo "=============================="
echo "Teste Docker Version"
docker --version

# ==========================
# Docker Compose Template Setup
# ==========================

if [[ "$INSTALL_DOCKER" =~ ^[Jj]$ ]]; then

    echo
    echo "=============================="
    echo " Docker Compose Template Setup"
    echo "=============================="

    read -p "Hostname für Watchtower: " HOSTNAME
    read -p "E-Mail Adresse (From) für Watchtower: " EMAIL_FROM
    read -s -p "Passwort für Watchtower Mail Account: " EMAIL_PASS
    echo

    # Verzeichnis für Compose
    COMPOSE_DIR="/Home/$USERNAME"
    mkdir -p "$COMPOSE_DIR"
    cd "$COMPOSE_DIR" || exit

    echo "Lade Docker Compose Template von GitHub..."
    wget -O docker-compose.yml --no-cache "https://raw.githubusercontent.com/WilkoLu/bootstrap/refs/heads/main/docker-compose.yml"

    # .env Datei erzeugen
    cat > .env <<EOF
WATCHTOWER_HOSTNAME=$HOSTNAME
WATCHTOWER_EMAIL_FROM=$EMAIL_FROM
WATCHTOWER_EMAIL_PASSWORD=$EMAIL_PASS
WATCHTOWER_EMAIL_TO=wilko@luhring.de
WATCHTOWER_EMAIL_SERVER=mail.luhring.de
EOF

    echo "✅ Docker Compose Setup abgeschlossen!"
fi
docker compose version
echo "=============================="
