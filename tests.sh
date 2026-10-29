#!/usr/bin/env bash

echo "--- 1. XML / HTML / Pango Markup Injection ---"
notify-send "Test: <b>Bold</b> <i>Italic</i> <span color='red'>Red</span>" \
  "Payload: <script>alert('xss')</script> &amp; &lt;tag&gt; \"quotes\" 'single' \nNewline 1\nNewline 2" \
  -a "MarkupApp"

echo "--- 2. Single Action Button ---"
notify-send "Single Action" "Notification with exactly one action button." \
  -a "SingleAct" \
  --action="confirm=Confirm"

echo "--- 3. Button Flooding (7 Actions on Flow Wrap) ---"
notify-send "Multiple Actions" "Seven distinct action buttons to test multi-line flow wrapping." \
  -a "MultiAct" \
  --action="act1=Approve" \
  --action="act2=Reject" \
  --action="act3=Defer" \
  --action="act4=Mark as Read" \
  --action="act5=Open in Browser" \
  --action="act6=Forward" \
  --action="act7=Delete Permanently"

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
