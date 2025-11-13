import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MERGED = ROOT / "assets" / "data" / "metadata" / "surah_metadata_merge.json"

def main():
    with open(MERGED, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    surahs = data["surahs"]
    
    print("=" * 60)
    print("VALIDASI HASIL MERGE METADATA")
    print("=" * 60)
    
    # 1. Jumlah surah
    print(f"\n1. Total surah: {len(surahs)} (harus 114)")
    print(f"   [{'PASS' if len(surahs) == 114 else 'FAIL'}]")
    
    # 2. Surah pertama dan terakhir
    print(f"\n2. Surah pertama: {surahs[0]['surah']} - {surahs[0]['name_id']}")
    print(f"   Surah terakhir: {surahs[-1]['surah']} - {surahs[-1]['name_id']}")
    print(f"   [{'PASS' if surahs[0]['surah'] == 1 and surahs[-1]['surah'] == 114 else 'FAIL'}]")
    
    # 3. Missing surahs
    missing = [i for i in range(1, 115) if not any(s['surah'] == i for s in surahs)]
    print(f"\n3. Missing surahs: {missing if missing else 'None'}")
    print(f"   [{'PASS' if not missing else 'FAIL'}]")
    
    # 4. Field validation
    print(f"\n4. Field validation:")
    all_have_translation = all("name_id_translation" in s for s in surahs)
    all_have_page_ranges = all("page_ranges" in s for s in surahs)
    all_have_juz_segments = all("juz_segments" in s for s in surahs)
    no_translit = not any("name_translit" in s for s in surahs)
    
    print(f"   - name_id_translation: {all_have_translation}")
    print(f"   - page_ranges: {all_have_page_ranges}")
    print(f"   - juz_segments: {all_have_juz_segments}")
    print(f"   - NO name_translit: {no_translit}")
    print(f"   [{'PASS' if all([all_have_translation, all_have_page_ranges, all_have_juz_segments, no_translit]) else 'FAIL'}]")
    
    # 5. Code_3 format check
    print(f"\n5. Code_3 format:")
    code3_issues = []
    for s in surahs:
        expected = f"{s['surah']:03d}"
        if s['code_3'] != expected:
            code3_issues.append(f"Surah {s['surah']}: got '{s['code_3']}', expected '{expected}'")
    
    if code3_issues:
        print(f"   Issues found: {len(code3_issues)}")
        for issue in code3_issues[:5]:
            print(f"     - {issue}")
        if len(code3_issues) > 5:
            print(f"     ... and {len(code3_issues) - 5} more")
    else:
        print(f"   All code_3 formats correct")
    print(f"   [{'PASS' if not code3_issues else 'FAIL'}]")
    
    # 6. Sample validation - Surah 2 (Al-Baqarah)
    print(f"\n6. Sample validation - Surah 2 (Al-Baqarah):")
    s2 = next(s for s in surahs if s['surah'] == 2)
    print(f"   Ayah count: {s2['ayah_count']} (expected: 286)")
    print(f"   Pages: {s2['pages']['start']} to {s2['pages']['end']}")
    print(f"   Juz: {s2['juz']['start']} to {s2['juz']['end']}")
    print(f"   Juz segments: {len(s2['juz_segments'])} (expected: 3)")
    print(f"   Page ranges: {len(s2['page_ranges'])}")
    print(f"   First page range: page {s2['page_ranges'][0]['page']}, ayah {s2['page_ranges'][0]['start_ayah']}-{s2['page_ranges'][0]['end_ayah']}")
    print(f"   Last page range: page {s2['page_ranges'][-1]['page']}, ayah {s2['page_ranges'][-1]['start_ayah']}-{s2['page_ranges'][-1]['end_ayah']}")
    print(f"   Translation: {s2['name_id_translation']}")
    
    # 7. Page ranges consistency check
    print(f"\n7. Page ranges consistency:")
    page_range_issues = []
    for s in surahs:
        if s['page_ranges']:
            # Check if first page matches pages.start
            if s['page_ranges'][0]['page'] != s['pages']['start']:
                page_range_issues.append(f"Surah {s['surah']}: first page_range.page ({s['page_ranges'][0]['page']}) != pages.start ({s['pages']['start']})")
            # Check if last page matches pages.end
            if s['page_ranges'][-1]['page'] != s['pages']['end']:
                page_range_issues.append(f"Surah {s['surah']}: last page_range.page ({s['page_ranges'][-1]['page']}) != pages.end ({s['pages']['end']})")
    
    if page_range_issues:
        print(f"   Issues found: {len(page_range_issues)}")
        for issue in page_range_issues[:5]:
            print(f"     - {issue}")
    else:
        print(f"   All page ranges consistent with pages.start/end")
    print(f"   [{'PASS' if not page_range_issues else 'FAIL'}]")
    
    # 8. Juz segments consistency
    print(f"\n8. Juz segments consistency:")
    juz_issues = []
    for s in surahs:
        if s['juz_segments']:
            juz_nums = [seg['juz'] for seg in s['juz_segments']]
            expected_start = min(juz_nums)
            expected_end = max(juz_nums)
            if s['juz']['start'] != expected_start:
                juz_issues.append(f"Surah {s['surah']}: juz.start ({s['juz']['start']}) != min juz_segments ({expected_start})")
            if s['juz']['end'] != expected_end:
                juz_issues.append(f"Surah {s['surah']}: juz.end ({s['juz']['end']}) != max juz_segments ({expected_end})")
    
    if juz_issues:
        print(f"   Issues found: {len(juz_issues)}")
        for issue in juz_issues[:5]:
            print(f"     - {issue}")
    else:
        print(f"   All juz segments consistent with juz.start/end")
    print(f"   [{'PASS' if not juz_issues else 'FAIL'}]")
    
    print("\n" + "=" * 60)
    print("VALIDASI SELESAI")
    print("=" * 60)

if __name__ == "__main__":
    main()

