
#!/usr/bin/env bash
set -euo pipefail

# Purpose: stop LXC, unbind from nvidia, bind to vfio-pci, start VM.

# ---- Config (edit if needed) ----
GPU="0000:01:00.0"
GPU_AUDIO="0000:01:00.1"
VMID="${VMID:-900}"
CTID="${CTID:-302}"
START_VM_AFTER="${START_VM_AFTER:-1}"   # 1=yes, 0=no
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

bind_to_vfio() {
  local dev="$1"
  echo "vfio-pci" > "/sys/bus/pci/devices/${dev}/driver_override"
  echo "${dev}" > /sys/bus/pci/drivers_probe
}

require_root

echo "Stopping CT ${CTID} (if running)..."
pct status "${CTID}" | grep -q running && pct stop "${CTID}" || true

echo "Stopping VM ${VMID} (if running, for clean rebind)..."
qm status "${VMID}" | grep -q running && qm stop "${VMID}" || true

echo "Unbinding GPU functions from current driver..."
unbind_if_bound "${GPU}"
unbind_if_bound "${GPU_AUDIO}"

echo "Loading vfio-pci..."
modprobe vfio-pci

echo "Binding GPU functions to vfio-pci..."
bind_to_vfio "${GPU}"
bind_to_vfio "${GPU_AUDIO}"

echo "Clearing driver_override..."
clear_override "${GPU}"
clear_override "${GPU_AUDIO}"

echo "Verification:"
lspci -nnk -s "${GPU#0000:}" | sed -n '1,6p'

if [[ "${START_VM_AFTER}" == "1" ]]; then
  echo "Starting VM ${VMID}..."
  qm start "${VMID}"
fi

echo "Done. GPU is now in VM passthrough mode."
