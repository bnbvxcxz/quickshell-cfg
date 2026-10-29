#!/usr/bin/env bash

cache_file="/tmp/quickshell-update-cache"
now=$(date +%s)
cache_age=$(stat -c \%Y "$cache_file" 2>/dev/null || echo 0)

if [ ! -f "$cache_file" ] || (( now - cache_age > 1800 )); then
    tmp_dir=$(mktemp -d /tmp/qs-upd.XXXXXX)

    # Parallel queries: pending updates & total installed packages
    (checkupdates 2>/dev/null | grep -cve '^\s*$' > "$tmp_dir/arch_up") &
    (pacman -Qqn 2>/dev/null | wc -l > "$tmp_dir/arch_total") &

    (yay -Qua 2>/dev/null | grep -cve '^\s*$' > "$tmp_dir/aur_up") &
    (pacman -Qqm 2>/dev/null | wc -l > "$tmp_dir/aur_total") &

    (flatpak remote-ls --updates 2>/dev/null | grep -cve '^\s*$' > "$tmp_dir/flat_up") &
    (flatpak list --app 2>/dev/null | wc -l > "$tmp_dir/flat_total") &
    wait

    arch_up=$(cat "$tmp_dir/arch_up" 2>/dev/null || echo 0)
    arch_tot=$(cat "$tmp_dir/arch_total" 2>/dev/null || echo 1)
    aur_up=$(cat "$tmp_dir/aur_up" 2>/dev/null || echo 0)
    aur_tot=$(cat "$tmp_dir/aur_total" 2>/dev/null || echo 1)
    flat_up=$(cat "$tmp_dir/flat_up" 2>/dev/null || echo 0)
    flat_tot=$(cat "$tmp_dir/flat_total" 2>/dev/null || echo 1)
    rm -rf "$tmp_dir"

    # Sane lower bounds to prevent divide-by-zero
    (( arch_tot < 1 )) && arch_tot=1
    (( aur_tot < 1 )) && aur_tot=1
    (( flat_tot < 1 )) && flat_tot=1

    payload="${arch_up}:${arch_tot}:${aur_up}:${aur_tot}:${flat_up}:${flat_tot}"
    echo "$payload" > "$cache_file"
    echo "$payload"
else
    cat "$cache_file"
fi
