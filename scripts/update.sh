#!/usr/bin/env bash

yay
flatpak update -y

rm -f /tmp/quickshell-update-cache

echo -e "\nVerifying update status..."
$HOME/.config/quickshell/scripts/check_updates.sh > /dev/null

# Signal Quickshell bar if IPC target exists, or clean exit
echo "Done! Press enter to exit."
read -r
