#!/usr/bin/env python3
import json
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
MD = ROOT / "assets" / "data" / "metadata"
OUT = MD / "surah_metadata_merge.json"


def load_json(path: Path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def to_int(value, default=None):
    try:
        return int(value)
    except Exception:
        return default


def parse_verse_index(s: str):
    # Accept forms like "verse_1", "1", 1
    if isinstance(s, int):
        return s
    if isinstance(s, str):
        s = s.strip()
        if s.startswith("verse_"):
            return to_int(s.split("_", 1)[1])
        return to_int(s)
    return None


def build_maps():
    # 1) Base meta (English/Arabic/type/rukus/juz ranges/etc.)
    surah_meta_list = load_json(MD / "surah_meta_final.json")
    surah_meta = {int(item["number"]): item for item in surah_meta_list}

    # 2) Surah list with juz segments and place/type/count
    surah_list = load_json(MD / "surah.json")
    surah_segments = {}
    for it in surah_list:
        idx = to_int(it.get("index"))
        if not idx:
            continue
        segs = []
        for sg in it.get("juz", []):
            j = to_int(sg.get("index"))
            verse = sg.get("verse", {})
            s_ayah = parse_verse_index(verse.get("start"))
            e_ayah = parse_verse_index(verse.get("end"))
            if j and s_ayah and e_ayah:
                segs.append({"juz": j, "start_ayah": s_ayah, "end_ayah": e_ayah})
        surah_segments[idx] = {
            "place": it.get("place"),
            "type": it.get("type"),
            "count": it.get("count"),
            "segments": segs,
        }

    # 3) Indonesian daftar surat (name + translation + ayah count)
    daftar = load_json(MD / "daftar-surat.json").get("data", [])
    daftar_map = {int(d["id"]): d for d in daftar if "id" in d}

    # 4) Page map: per (surah, ayah) -> page
    # Build page start/end and per-page ayah ranges per surah
    page_map_iter = load_json(MD / "page_map.json")
    page_stats = {}
    page_ranges = {}
    for row in page_map_iter:
        s = to_int(row.get("surah"))
        a = to_int(row.get("ayah"))
        p = to_int(row.get("page"))
        if not (s and a and p):
            continue
        if s not in page_stats:
            page_stats[s] = {"start": p, "end": p}
        page_stats[s]["start"] = min(page_stats[s]["start"], p)
        page_stats[s]["end"] = max(page_stats[s]["end"], p)

        page_ranges.setdefault(s, {}).setdefault(p, []).append(a)

    # Compress page ranges
    page_ranges_comp = {}
    for s, per_page in page_ranges.items():
        items = []
        for p, ayat in per_page.items():
            if not ayat:
                continue
            items.append(
                {
                    "page": p,
                    "start_ayah": min(ayat),
                    "end_ayah": max(ayat),
                }
            )
        page_ranges_comp[s] = sorted(items, key=lambda x: x["page"])

    return surah_meta, surah_segments, daftar_map, page_stats, page_ranges_comp


def pick(*values, default=None):
    for v in values:
        if v is not None:
            if isinstance(v, str):
                if v.strip() != "":
                    return v
            else:
                return v
    return default


def main():
    surah_meta, surah_segments, daftar_map, page_stats, page_ranges = build_maps()

    out = {
        "version": "1.0",
        "source": "quran-indonesia.sql",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "surahs": [],
    }

    for s in range(1, 115):
        sm = surah_meta.get(s, {})
        sj = surah_segments.get(s, {})
        df = daftar_map.get(s, {})

        # Names
        name_ar = pick(
            sm.get("name_ar"),
            sj.get("titleAr"),
            (df.get("surat_text") or "").strip() if df else None,
        )
        name_id = pick(
            sm.get("name_id"),
            df.get("surat_name") if df else None,
            sj.get("title"),
        )
        name_id_translation = df.get("surat_terjemahan") if df else None
        name_en = sm.get("name_en")

        # Type/Place and counts
        place = sj.get("place")
        typ = pick(sj.get("type"), sm.get("type"))
        ayah_count = pick(sm.get("ayat_count"), df.get("count_ayat") if df else None, sj.get("count"))
        rukus = sm.get("rukus")

        # Juz metadata - prioritize juz_segments over surah_meta
        segs = sj.get("segments", []) or []
        if segs:
            # Use juz_segments as primary source (more accurate)
            juz_start = min(seg["juz"] for seg in segs)
            juz_end = max(seg["juz"] for seg in segs)
        else:
            # Fallback to surah_meta if no segments
            juz_start = sm.get("juz_start")
            juz_end = sm.get("juz_end")

        # Pages
        pages_stats = page_stats.get(s, None)
        pr = page_ranges.get(s, [])

        out["surahs"].append(
            {
                "surah": s,
                "code_3": f"{s:03d}",
                "name_ar": name_ar,
                "name_id": name_id,
                "name_id_translation": name_id_translation,
                "name_en": name_en,
                # name_translit intentionally omitted per requirement
                "place": place,
                "type": typ,
                "ayah_count": ayah_count,
                "rukus": rukus,
                "juz": {"start": juz_start, "end": juz_end} if (juz_start and juz_end) else None,
                "juz_segments": segs,
                "pages": (
                    {"start": pages_stats["start"], "end": pages_stats["end"]} if pages_stats else None
                ),
                "page_ranges": pr,
            }
        )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()


