#!/usr/bin/env bash
# Stress-tests notifications, markup, action callbacks, and bar pill states (Wi-Fi, battery, updates).

mode="${1:-all}"

run_notif_tests() {
  echo "--- 1. XML / HTML / Pango Markup Injection ---"
  notify-send "Test: <b>Bold</b> <i>Italic</i> <span color='red'>Red</span>" \
    "Payload: <script>alert('xss')</script> &amp; &lt;tag&gt; \"quotes\" 'single' \nNewline 1\nNewline 2" \
    -a "MarkupApp"

  echo "--- 2. Single Action Button (click button to verify callback) ---"
  (
    act=$(notify-send "Single Action" "Click the Confirm button to verify DBus ActionInvoked." \
      -a "SingleAct" \
      --action="confirm=Confirm" 2>/dev/null)
    if [ -n "$act" ]; then
      echo "[PASS] SingleAct button invoked: $act"
      notify-send "Action Callback OK" "SingleAct invoked action: $act" -a "TestRunner"
    fi
  ) &

  echo "--- 3. Button Flooding (7 Actions on Flow Wrap, click any to verify callback) ---"
  (
    act=$(notify-send "Multiple Actions" "Seven distinct action buttons to test multi-line flow wrapping." \
      -a "MultiAct" \
      --action="act1=Approve" \
      --action="act2=Reject" \
      --action="act3=Defer" \
      --action="act4=Mark as Read" \
      --action="act5=Open in Browser" \
      --action="act6=Forward" \
      --action="act7=Delete Permanently" 2>/dev/null)
    if [ -n "$act" ]; then
      echo "[PASS] MultiAct button invoked: $act"
      notify-send "Action Callback OK" "MultiAct invoked action: $act" -a "TestRunner"
    fi
  ) &
  sleep 0.2

  echo "--- 4. Unbroken Monolithic String (No spaces / Boundary overflow) ---"
  notify-send "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" \
    "https://verylongdomainname.example.internal/path/to/resource?query=1&param=verylongtokenstringwithoutanyspacesorbreakstotesttextelisionandwrappingbounds1234567890" \
    -a "ELIDE_TEST"

  echo "--- 5. Rapid Notification Spam (Grouping & Repeat Counter Stress) ---"
  for i in {1..12}; do
    notify-send "Spam Burst Message" "Identical payload stress sequence index: $i" \
      -a "SpamDaemon" \
      -u low
  done

  echo "--- 6. Unicode, RTL, Emoji, & Null-like strings ---"
  notify-send "Unicode & RTL: ﷽ 💖 ⚡  󰥔" \
    "Zero-width: a​b​c | Whitespace test: [           ] | Null strings: undefined null NaN" \
    -a "SpecialGlyphs"
}

run_pill_tests() {
  echo "--- 7. Bar Pill State Simulation (Battery, Wi-Fi, Updates) ---"
  echo "  -> Battery: Critical (10% Discharging)"
  quickshell ipc call test battery 10 Discharging
  sleep 1.2

  echo "  -> Battery: Warning (25% Discharging)"
  quickshell ipc call test battery 25 Discharging
  sleep 1.2

  echo "  -> Battery: Medium (50% Discharging)"
  quickshell ipc call test battery 50 Discharging
  sleep 1.2

  echo "  -> Battery: Charging (85% Charging)"
  quickshell ipc call test battery 85 Charging
  sleep 1.2

  echo "  -> Wi-Fi: Weak Signal (20%)"
  quickshell ipc call test wifi "TestNet-5G" 20
  sleep 1.2

  echo "  -> Wi-Fi: Medium Signal (55%)"
  quickshell ipc call test wifi "TestNet-5G" 55
  sleep 1.2

  echo "  -> Wi-Fi: Strong Signal (95%)"
  quickshell ipc call test wifi "TestNet-5G" 95
  sleep 1.2

  echo "  -> Wi-Fi: Disconnected"
  quickshell ipc call test wifi "disconnected" 0
  sleep 1.2

  echo "  -> Updates: Low Tier (3 Arch, 1 AUR, 0 Flatpak)"
  quickshell ipc call test updates 3 1 0
  sleep 1.2

  echo "  -> Updates: Noticeable Tier (25 Arch, 4 AUR, 5 Flatpak)"
  quickshell ipc call test updates 25 4 5
  sleep 1.2

  echo "  -> Updates: Critical Tier (60 Arch, 12 AUR, 10 Flatpak)"
  quickshell ipc call test updates 60 12 10
  sleep 2.0

  echo "  -> Resetting bar pills to live system state"
  quickshell ipc call test reset
}

case "$mode" in
  notifs) run_notif_tests ;;
  pills|hw) run_pill_tests ;;
  reset) quickshell ipc call test reset ;;
  *)
    run_notif_tests
    run_pill_tests
    ;;
esac
