#!/bin/bash -e

INSTALL_DIR="/opt/pymc-repeater"
CONFIG_DIR="/etc/pymc-repeater"
LOG_DIR="/var/log/pymc-repeater"
SERVICE_USER="repeater"
SERVICE_NAME="pymc-repeater"

# Create service user
if ! id "$SERVICE_USER" &>/dev/null; then
    useradd --system --home /var/lib/pymc_repeater --shell /sbin/nologin "$SERVICE_USER"
fi

# Add user to groups
usermod -a -G gpio,i2c,spi "$SERVICE_USER" 2>/dev/null || true
usermod -a -G dialout "$SERVICE_USER" 2>/dev/null || true

# Create directories
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$LOG_DIR" /var/lib/pymc_repeater

# Install yq
if ! command -v yq &> /dev/null; then
    wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.40.5/yq_linux_arm64" && chmod +x /usr/local/bin/yq
fi

# Clone repo
git clone -b dev https://github.com/rightup/pyMC_Repeater.git "$INSTALL_DIR/repo"

# Install Python dependencies
cd "$INSTALL_DIR/repo"
export PIP_ROOT_USER_ACTION=ignore
export PIP_ONLY_BINARY=pycryptodome,cffi,PyNaCl,psutil
pip3 install --break-system-packages setuptools_scm
pip3 install --break-system-packages --force-reinstall --no-cache-dir .

# Install files
cp -r repeater "$INSTALL_DIR/"
cp pyproject.toml "$INSTALL_DIR/"
cp README.md "$INSTALL_DIR/"
cp manage.sh "$INSTALL_DIR/"
cp pymc-repeater.service "$INSTALL_DIR/"
cp radio-settings.json /var/lib/pymc_repeater/
cp radio-presets.json /var/lib/pymc_repeater/

# Config
cp config.yaml.example "$CONFIG_DIR/config.yaml.example"
if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    cp config.yaml.example "$CONFIG_DIR/config.yaml"
fi

# Service
cp pymc-repeater.service /etc/systemd/system/
systemctl enable "$SERVICE_NAME"

# Permissions
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR" "$CONFIG_DIR" "$LOG_DIR" /var/lib/pymc_repeater
chmod 750 "$CONFIG_DIR" "$LOG_DIR" /var/lib/pymc_repeater
chmod 755 /var/lib/pymc_repeater
mkdir -p /var/lib/pymc_repeater/.config/pymc_repeater
chown -R "$SERVICE_USER:$SERVICE_USER" /var/lib/pymc_repeater/.config

# Polkit
mkdir -p /etc/polkit-1/rules.d
cat > /etc/polkit-1/rules.d/10-pymc-repeater.rules <<'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "pymc-repeater.service" &&
        subject.user == "repeater") {
        return polkit.Result.YES;
    }
});
EOF
chmod 0644 /etc/polkit-1/rules.d/10-pymc-repeater.rules

# Enable SPI
if [ -f /boot/firmware/config.txt ]; then
    if ! grep -q "dtparam=spi=on" /boot/firmware/config.txt; then
        echo "dtparam=spi=on" >> /boot/firmware/config.txt
    fi
elif [ -f /boot/config.txt ]; then
    if ! grep -q "dtparam=spi=on" /boot/config.txt; then
        echo "dtparam=spi=on" >> /boot/config.txt
    fi
fi

# Cleanup repo clone used for install
rm -rf "$INSTALL_DIR/repo"
