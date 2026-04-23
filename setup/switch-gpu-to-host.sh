
#!/usr/bin/env bash
set -euo pipefail

# Purpose: stop VM, unbind from vfio-pci, bind to nvidia, optionally start LXC.

# ---- Config (edit if needed) ----
GPU="0000:01:00.0"
GPU_AUDIO="0000:01:00.1"
VMID="${VMID:-400}"
CTID="${CTID:-302}"
START_CT_AFTER="${START_CT_AFTER:-1}"   # 1=yes, 0=no
# -------------------------------

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root."
    exit 1
  fi
}

unbind_if_bound() {
  local dev="$1"
  if [[ -e "/sys/bus/pci/devices/${dev}/driver/unbind" ]]; then
    echo "${dev}" > "/sys/bus/pci/devices/${dev}/driver/unbind"
  fi
}

clear_override() {
  local dev="$1"
  echo "" > "/sys/bus/pci/devices/${dev}/driver_override"
}

bind_to_nvidia() {
  local dev="$1"
  echo "nvidia" > "/sys/bus/pci/devices/${dev}/driver_override"
  echo "${dev}" > /sys/bus/pci/drivers_probe
}

require_root

echo "Stopping VM ${VMID} (if running)..."
qm status "${VMID}" | grep -q running && qm stop "${VMID}" || true

echo "Stopping CT ${CTID} (if running) to avoid busy GPU handles..."
pct status "${CTID}" | grep -q running && pct stop "${CTID}" || true

echo "Unbinding GPU functions from current driver..."
unbind_if_bound "${GPU}"
unbind_if_bound "${GPU_AUDIO}"

echo "Loading NVIDIA modules..."
modprobe nvidia
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia_drm || true

echo "Binding GPU functions to nvidia..."
bind_to_nvidia "${GPU}"
bind_to_nvidia "${GPU_AUDIO}"

echo "Clearing driver_override..."
clear_override "${GPU}"
clear_override "${GPU_AUDIO}"

echo "Verification:"
lspci -nnk -s "${GPU#0000:}" | sed -n '1,6p'
echo
nvidia-smi || {
  echo "nvidia-smi failed. Check host driver install/modules."
  exit 1
}

if [[ "${START_CT_AFTER}" == "1" ]]; then
  echo "Starting CT ${CTID}..."
  pct start "${CTID}" || true
fi

echo "Done. GPU is now in HOST/LXC mode."
