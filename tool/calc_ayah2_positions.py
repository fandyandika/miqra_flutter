#!/usr/bin/env python3
"""Calculate correct positions for surah 2 ayah 2."""

# Text from SQL: "ذٰلِكَ الْكِتٰبُ لَا رَيْبَ ۛ فِيْهِ ۛ هُدًى لِّلْمُتَّقِيْنَۙ"
text = "ذٰلِكَ الْكِتٰبُ لَا رَيْبَ ۛ فِيْهِ ۛ هُدًى لِّلْمُتَّقِيْنَۙ"

print(f"Text: {text}")
print(f"Length: {len(text)}")
print()

# Find "هُدًى لِّلْمُتَّقِيْنَ"
# Idghaam_no_ghunnah: tanwin (ً) followed by Lam (ل)

# Find tanwin position
tanwin_pos = text.find('ً')
print(f"Tanwin (ً) position: {tanwin_pos}")

# Find Lam after tanwin
# Text after tanwin: " لِّلْمُتَّقِيْنَۙ"
# Lam is at position after tanwin + space + shaddah
lam_pos = text.find('ل', tanwin_pos)
print(f"Lam (ل) position: {lam_pos}")

# Idghaam_no_ghunnah should cover from tanwin to Lam (inclusive)
# But typically it covers the tanwin and the Lam
start = tanwin_pos
end = lam_pos + 1  # +1 to include the Lam

print(f"\nSuggested idghaam_no_ghunnah span:")
print(f"  start: {start}")
print(f"  end: {end}")
print(f"  text: {repr(text[start:end])}")

# Show character breakdown around this area
print(f"\nCharacter breakdown around position {start}-{end}:")
for i in range(max(0, start-3), min(len(text), end+3)):
    char = text[i]
    marker = ""
    if i == start:
        marker = " <-- START"
    elif i == end - 1:
        marker = " <-- END"
    print(f"  {i:3d}: {repr(char)} U+{ord(char):04X}{marker}")

# Current indices from JSON: start=39, end=45
print(f"\nCurrent indices in JSON: start=39, end=45")
print(f"Text at 39-45: {repr(text[39:45]) if 39 < len(text) and 45 <= len(text) else 'OUT OF BOUNDS'}")

