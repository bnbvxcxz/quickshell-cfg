#!/usr/bin/env bash
# Runs system and Flatpak upgrades in an interactive terminal session.
# Invalidates the update cache and triggers an IPC refresh on completion.

yay
flatpak update -y

rm -f /tmp/quickshell-update-cache

echo -e "\nVerifying update status..."
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$script_dir/check_updates.sh" > /dev/null
quickshell ipc call updates refresh >/dev/null 2>&1 || true

echo "Done! Press enter to exit."
read -r
