#!/bin/bash -e
#
# Install pyMC_Repeater (dev branch) into a pi-gen image
#

APP_ROOT="/opt/pymc_repeater"
SRC_DIR="${APP_ROOT}/src"
VENV_DIR="${APP_ROOT}/venv"
CONF_DIR="/etc/pymc_repeater"
LOG_DIR="/var/log/pymc_repeater"
SERVICE_NAME="pymc-repeater"

echo "=== Installing pyMC_Repeater ==="

# ------------------------------------------------------------
# 1) System packages
# ------------------------------------------------------------
apt-get update
apt-get install -y --no-install-recommends \
  git ca-certificates curl \
  python3 python3-venv python3-pip \
  i2c-tools spi-tools \
  libgpiod2 \
  jq

# ------------------------------------------------------------
# 2) Enable SPI (required by pyMC_Repeater)
# ------------------------------------------------------------
BOOT_CFG="/boot/firmware/config.txt"
grep -q "^dtparam=spi=on" "$BOOT_CFG" || echo "dtparam=spi=on" >> "$BOOT_CFG"

# ------------------------------------------------------------
# 3) Create service user (matches manage.sh behavior)
# ------------------------------------------------------------
if ! id -u repeater >/dev/null 2>&1; then
  useradd -r -m -s /usr/sbin/nologin repeater
fi

# Hardware access groups
for g in spi gpio i2c dialout; do
  getent group "$g" >/dev/null 2>&1 && usermod -aG "$g" repeater || true
done

# ------------------------------------------------------------
# 4) Create directories
# ------------------------------------------------------------
install -d -m 0755 "$APP_ROOT" "$CONF_DIR" "$LOG_DIR"
chown -R repeater:repeater "$APP_ROOT" "$LOG_DIR"

# ------------------------------------------------------------
# 5) Clone pyMC_Repeater (dev branch)
# ------------------------------------------------------------
rm -rf "$SRC_DIR"
git clone --depth=1 --branch dev https://github.com/rightup/pyMC_Repeater.git "$SRC_DIR"
chown -R repeater:repeater "$SRC_DIR"

# ------------------------------------------------------------
# 6) Python virtualenv + editable install
# ------------------------------------------------------------
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel
"$VENV_DIR/bin/pip" install -e "$SRC_DIR"

# ------------------------------------------------------------
# 7) Seed default config
# ------------------------------------------------------------
if [ -f "$SRC_DIR/config.yaml.example" ]; then
  install -m 0644 "$SRC_DIR/config.yaml.example" "$CONF_DIR/config.yaml"
fi

chown -R repeater:repeater "$CONF_DIR"

# ------------------------------------------------------------
# 8) Install and enable systemd service
# ------------------------------------------------------------
if [ ! -f "$SRC_DIR/pymc-repeater.service" ]; then
  echo "ERROR: pymc-repeater.service not found in repo"
  exit 1
fi

install -m 0644 "$SRC_DIR/pymc-repeater.service" \
  "/etc/systemd/system/${SERVICE_NAME}.service"

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"

# ------------------------------------------------------------
# 9) Clean identity (VERY IMPORTANT for shipped images)
# ------------------------------------------------------------
rm -f /etc/ssh/ssh_host_*
truncate -s 0 /etc/machine-id || true
truncate -s 0 /var/lib/dbus/machine-id || true
rm -f /var/lib/systemd/random-seed

# ------------------------------------------------------------
# 10) Cleanup
# ------------------------------------------------------------
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "=== pyMC_Repeater installation complete ==="
