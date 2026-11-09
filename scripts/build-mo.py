#!/usr/bin/env python3
"""Compile gettext .po files to .mo (tiny msgfmt replacement, no gettext needed).
    scripts/build-mo.py <po-dir> <plasmoid-dir>
For every <po-dir>/<lang>.po it writes
    <plasmoid-dir>/contents/locale/<lang>/LC_MESSAGES/plasma_applet_<plasmoid id>.mo
"""
import ast, json, pathlib, struct, sys

def parse_po(text):
    msgs, mid, mstr, cur = {}, None, None, None
    def flush():
        if mid is not None and mstr is not None and (mid == "" or mstr):
            msgs[mid] = mstr
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("msgid "):
            flush(); mid, mstr, cur = ast.literal_eval(line[6:]), None, "id"
        elif line.startswith("msgstr "):
            mstr, cur = ast.literal_eval(line[7:]), "str"
        elif line.startswith('"') and cur:
            val = ast.literal_eval(line)
            if cur == "id": mid += val
            else: mstr += val
    flush()
    return msgs

def write_mo(msgs, out):
    keys = sorted(msgs)
    ids = b"".join(k.encode() + b"\0" for k in keys)
    strs = b"".join(msgs[k].encode() + b"\0" for k in keys)
    n = len(keys); start = 7 * 4 + 16 * n
    koffs, voffs, o = [], [], 0
    for k in keys: koffs.append((len(k.encode()), start + o)); o += len(k.encode()) + 1
    o = 0
    for k in keys: voffs.append((len(msgs[k].encode()), start + len(ids) + o)); o += len(msgs[k].encode()) + 1
    data = struct.pack("Iiiiiii", 0x950412de, 0, n, 7 * 4, 7 * 4 + 8 * n, 0, 0)
    for l, off in koffs: data += struct.pack("ii", l, off)
    for l, off in voffs: data += struct.pack("ii", l, off)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(data + ids + strs)

def main():
    po_dir, applet = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    pid = json.loads((applet / "metadata.json").read_text())["KPlugin"]["Id"]
    for po in sorted(po_dir.glob("*.po")):
        lang = po.stem
        write_mo(parse_po(po.read_text(encoding="utf-8")),
                 applet / "contents/locale" / lang / "LC_MESSAGES" / f"plasma_applet_{pid}.mo")
        print(f"  translation: {lang}")

if __name__ == "__main__":
    main()
