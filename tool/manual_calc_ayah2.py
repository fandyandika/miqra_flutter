# Manual calculation for surah 2 ayah 2
# Text: "ذٰلِكَ الْكِتٰبُ لَا رَيْبَ ۛ فِيْهِ ۛ هُدًى لِّلْمُتَّقِيْنَۙ"

text = "ذٰلِكَ الْكِتٰبُ لَا رَيْبَ ۛ فِيْهِ ۛ هُدًى لِّلْمُتَّقِيْنَۙ"

print("Character positions:")
for i, char in enumerate(text):
    marker = ""
    if char == 'ً':
        marker = " <-- TANWIN"
    elif char == 'ل' and i > 30:  # Lam in "لِّلْمُتَّقِيْنَ"
        marker = " <-- LAM"
    print(f"{i:3d}: {repr(char)} U+{ord(char):04X}{marker}")

# Find "هُدًى"
huda_pos = text.find("هُدًى")
print(f"\n'هُدًى' found at position: {huda_pos}")

# Find tanwin within "هُدًى"
tanwin_in_huda = text.find('ً', huda_pos)
print(f"Tanwin (ً) position: {tanwin_in_huda}")

# Find "لِّلْمُتَّقِيْنَ"
lam_start = text.find("لِّلْمُتَّقِيْنَ")
print(f"'لِّلْمُتَّقِيْنَ' found at position: {lam_start}")

# Lam is at lam_start
print(f"Lam (ل) position: {lam_start}")

# Idghaam_no_ghunnah: from tanwin to Lam (inclusive)
start = tanwin_in_huda
end = lam_start + 1  # Include the Lam

print(f"\nSuggested idghaam_no_ghunnah span:")
print(f"  start: {start}")
print(f"  end: {end}")
print(f"  text: {repr(text[start:end])}")
print(f"  length: {end - start}")

