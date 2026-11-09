#!/usr/bin/env python3
"""Generate Glasspane artwork: SVG sources in assets/ and the rendered images used by the
global theme (previews, splash). Needs ImageMagick with the RSVG delegate.
    python3 scripts/make-art.py
"""
import subprocess, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
LAF = ROOT / "src/share/plasma/look-and-feel/com.joansitoh.Glasspane/contents"
FONT = "Noto Sans, DejaVu Sans, Helvetica, Arial, sans-serif"

# ------------------------------------------------------------------ shared pieces
def defs():
    return f'''<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#060a1c"/><stop offset=".55" stop-color="#0e1946"/><stop offset="1" stop-color="#1c2f86"/>
  </linearGradient>
  <linearGradient id="pane" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#fff" stop-opacity=".16"/><stop offset="1" stop-color="#fff" stop-opacity=".02"/>
  </linearGradient>
  <linearGradient id="logo" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#6fd6ff"/><stop offset="1" stop-color="#0a74e6"/>
  </linearGradient>
  <filter id="b90" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="90"/></filter>
  <filter id="shadow" x="-20%" y="-20%" width="140%" height="150%">
    <feDropShadow dx="0" dy="14" stdDeviation="22" flood-color="#000" flood-opacity=".55"/>
  </filter>
  <filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="14"/></filter>
</defs>'''

def wallpaper(w=1920, h=1080):
    return f'''<rect width="{w}" height="{h}" fill="url(#bg)"/>
<g filter="url(#b90)">
  <circle cx="1500" cy="240" r="520" fill="#2f6bff" opacity=".55"/>
  <circle cx="380" cy="860" r="430" fill="#22d3ee" opacity=".28"/>
  <circle cx="930" cy="130" r="380" fill="#8b5cf6" opacity=".34"/>
</g>
<g fill="url(#pane)" stroke="#fff" stroke-opacity=".16" stroke-width="1.5">
  <rect x="1100" y="110" width="540" height="350" rx="30" transform="rotate(-8 1370 285)"/>
  <rect x="240" y="500" width="660" height="390" rx="34" transform="rotate(6 570 695)"/>
  <rect x="1330" y="560" width="400" height="270" rx="26" transform="rotate(10 1530 695)"/>
  <rect x="60" y="90" width="360" height="240" rx="26" transform="rotate(-5 240 210)"/>
</g>'''

def logo(x, y, s):
    """Four panes, s = total size."""
    u = s / 64.0
    r = 2.2 * u
    tiles = [(13, 13), (33, 13), (13, 33), (33, 33)]
    return "".join(
        f'<rect x="{x + a*u:.2f}" y="{y + b*u:.2f}" width="{18*u:.2f}" height="{18*u:.2f}" rx="{r:.2f}" fill="url(#logo)"/>'
        for a, b in tiles)

PALETTE = [("#ff8a4c", "#e5532a"), ("#4fb0ff", "#2a6df0"), ("#86e060", "#3bb04a"), ("#ffd84a", "#f0a420"),
           ("#c08bff", "#7a4be0"), ("#ff6b9a", "#e03a72"), ("#37d6c4", "#14998f"), ("#7b94ff", "#4a5fe0")]

def app_icon(x, y, s, i):
    c1, c2 = PALETTE[i % len(PALETTE)]
    gid = f"g{i % len(PALETTE)}"
    inner = s * 0.42
    shapes = [f'<circle cx="{x+s/2}" cy="{y+s/2}" r="{inner/2}" fill="#fff" fill-opacity=".92"/>',
              f'<rect x="{x+s/2-inner/2}" y="{y+s/2-inner/2}" width="{inner}" height="{inner}" rx="{s*.08}" fill="#fff" fill-opacity=".92"/>',
              f'<path d="M{x+s/2-inner/2} {y+s/2+inner/2} L{x+s/2} {y+s/2-inner/2} L{x+s/2+inner/2} {y+s/2+inner/2} Z" fill="#fff" fill-opacity=".92"/>']
    return (f'<linearGradient id="{gid}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{c1}"/>'
            f'<stop offset="1" stop-color="{c2}"/></linearGradient>'
            f'<rect x="{x}" y="{y}" width="{s}" height="{s}" rx="{s*.26}" fill="url(#{gid})"/>' + shapes[i % 3])

def text(x, y, s, t, fill="#e8eaf0", weight=400, anchor="start", op=1):
    return (f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{s}" font-weight="{weight}" '
            f'fill="{fill}" fill-opacity="{op}" text-anchor="{anchor}">{t}</text>')

def window(x, y, w, h, title, lines=True, accent="#7ee787"):
    out = [f'<g filter="url(#shadow)"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="#10131b" fill-opacity=".9" '
           f'stroke="#fff" stroke-opacity=".1"/></g>',
           f'<rect x="{x}" y="{y}" width="{w}" height="34" rx="12" fill="#fff" fill-opacity=".05"/>',
           text(x + 16, y + 22, 12, title, "#aab1c4"),
           f'<path d="M{x+w-86} {y+17} h10 M{x+w-56} {y+12} h10 v10 h-10 z M{x+w-26} {y+12} l10 10 M{x+w-26} {y+22} l10 -10" '
           f'stroke="#cfd3de" stroke-width="1.4" fill="none" stroke-linecap="round"/>']
    if lines:
        for i in range(9):
            lw = [320, 250, 400, 180, 360, 290, 220, 340, 150][i]
            out.append(f'<rect x="{x+22}" y="{y+56+i*30}" width="{lw}" height="9" rx="4.5" '
                       f'fill="{accent if i % 3 == 0 else "#fff"}" fill-opacity="{.55 if i % 3 == 0 else .14}"/>')
    return "".join(out)

def start_menu(x, y):
    o = [f'<g transform="translate({x} {y})">',
         '<g filter="url(#shadow)"><rect width="640" height="720" rx="14" fill="#15171d" fill-opacity=".96" '
         'stroke="#fff" stroke-opacity=".09"/></g>',
         '<rect x="16" y="16" width="608" height="40" rx="9" fill="#23262f" stroke="#fff" stroke-opacity=".06"/>',
         '<circle cx="38" cy="35" r="6.5" fill="none" stroke="#9aa0ae" stroke-width="1.6"/>'
         '<path d="M43 40 l6 6" stroke="#9aa0ae" stroke-width="1.6" stroke-linecap="round"/>',
         text(58, 41, 13, "Search apps, settings and documents", "#9aa0ae"),
         text(16, 88, 14, "Pinned", weight=700), text(624, 88, 12, "All apps  ›", "#cfd3de", anchor="end")]
    names = ["Browser", "Files", "Terminal", "Settings", "Store", "Mail", "Notes", "Music", "Photos",
             "Video", "Calc", "Maps", "Code", "Chat", "Cloud", "Games", "Clock", "Camera"]
    for i, n in enumerate(names):
        r, c = divmod(i, 6)
        cx = 16 + c * (608 / 6) + (608 / 6) / 2
        top = 104 + r * 88 + 8
        o.append(app_icon(cx - 18, top, 36, i))
        o.append(text(cx, top + 36 + 17, 11, n, "#cfd3de", anchor="middle"))
    o.append(text(16, 398, 14, "Recommended", weight=700))
    rec = [("Notes", "Opened just now"), ("Photos", "Opened 12 min ago"), ("Terminal", "Opened 1 h ago"),
           ("Documents", "Yesterday"), ("Screenshots", "Yesterday"), ("Downloads", "Monday")]
    for i, (a, b) in enumerate(rec):
        r, c = divmod(i, 2)
        px, py = 16 + c * 304, 414 + r * 54
        o.append(app_icon(px + 8, py + 10, 30, i + 2))
        o.append(text(px + 48, py + 24, 13, a))
        o.append(text(px + 48, py + 40, 11, b, "#8d93a3"))
    o += ['<rect x="16" y="664" width="608" height="1" fill="#fff" fill-opacity=".1"/>',
          '<circle cx="36" cy="692" r="15" fill="#1fb5a5"/><circle cx="36" cy="687" r="5" fill="#fff" fill-opacity=".9"/>'
          '<path d="M26 702 a10 8 0 0 1 20 0 z" fill="#fff" fill-opacity=".9"/>',
          text(60, 697, 13, "User"),
          '<circle cx="602" cy="693" r="8" fill="none" stroke="#cfd3de" stroke-width="1.6"/>'
          '<path d="M602 685 v7" stroke="#cfd3de" stroke-width="1.6" stroke-linecap="round"/>',
          '</g>']
    return "".join(o)

def taskbar(w=1920, y=1042, h=38):
    o = [f'<rect x="0" y="{y}" width="{w}" height="{h}" fill="#202020"/>',
         f'<rect x="0" y="{y}" width="{w}" height="1" fill="#fff" fill-opacity=".06"/>']
    cells = 7
    x0 = (w - cells * h) / 2
    # active cell (terminal)
    o.append(f'<rect x="{x0 + 3*h + 1}" y="{y + 1}" width="{h - 2}" height="{h - 2}" rx="6" fill="#fff" fill-opacity=".1"/>')
    o.append(logo(x0 + (h - 24) / 2 - 8.5 * 24 / 64 * 0, y + (h - 24) / 2 - 0, 24) if False else logo(x0 + 3, y + 3, 32))
    for i in range(1, cells):
        o.append(app_icon(x0 + i * h + (h - 24) / 2, y + (h - 24) / 2, 24, i - 1))
    o.append(f'<rect x="{x0 + 3*h + h/2 - 7}" y="{y + h - 4}" width="14" height="2.4" rx="1.2" fill="#6fd6ff"/>')
    tx = w - 190
    o.append(f'<path d="M{tx} {y+23} l6 -6 l6 6" stroke="#e8eaf0" stroke-width="1.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
    o.append(f'<path d="M{tx+36} {y+22} q8 -9 16 0 M{tx+39} {y+25} q5 -5 10 0" stroke="#e8eaf0" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
             f'<circle cx="{tx+44}" cy="{y+28.5}" r="1.3" fill="#e8eaf0"/>')
    o.append(f'<path d="M{tx+68} {y+15} h4 l5 -4 v16 l-5 -4 h-4 z" fill="#e8eaf0"/>'
             f'<path d="M{tx+81} {y+16} q4 3 0 6" stroke="#e8eaf0" stroke-width="1.5" fill="none" stroke-linecap="round"/>')
    o.append(f'<rect x="{tx+98}" y="{y+13}" width="18" height="10" rx="2" fill="none" stroke="#f4b740" stroke-width="1.4"/>'
             f'<rect x="{tx+100}" y="{y+15}" width="9" height="6" rx="1" fill="#f4b740"/>')
    o.append(text(w - 38, y + 17, 12, "00:00:00", "#fff", anchor="middle"))
    o.append(text(w - 38, y + 31, 11, "09/11/2026", "#fff", anchor="middle"))
    return "".join(o)

# ------------------------------------------------------------------ files
def svg(w, h, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'{defs()}{body}</svg>')

def write_svgs():
    ASSETS.mkdir(exist_ok=True)
    (ASSETS / "wallpaper.svg").write_text(svg(1920, 1080, wallpaper()))
    desktop = (wallpaper() + window(240, 170, 640, 400, "Terminal", accent="#7ee787")
               + window(1160, 300, 560, 340, "Files", accent="#6fd6ff")
               + start_menu(640, 310) + taskbar())
    (ASSETS / "preview.svg").write_text(svg(1920, 1080, desktop))
    splash_logo = (logo(860, 340, 200) + f'<rect x="780" y="720" width="360" height="6" rx="3" fill="#505050"/>'
                   f'<rect x="780" y="720" width="190" height="6" rx="3" fill="#fff"/>')
    (ASSETS / "splash-preview.svg").write_text(svg(1920, 1080, wallpaper() + f'<g filter="url(#glow)" opacity=".6">{logo(860,340,200)}</g>' + splash_logo))
    # logo for the splash screen (200x200)
    (LAF / "splash/images/kde.svg").write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">'
        '<defs><linearGradient id="logo" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6fd6ff"/>'
        '<stop offset="1" stop-color="#0a74e6"/></linearGradient></defs>' + logo(0, 0, 200) + '</svg>')
    # banner
    banner = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="320" viewBox="0 0 1280 320">
{defs()}
<clipPath id="card"><rect width="1280" height="320" rx="26"/></clipPath>
<g clip-path="url(#card)">
  <rect width="1280" height="320" fill="url(#bg)"/>
  <g filter="url(#b90)"><circle cx="1080" cy="60" r="260" fill="#2f6bff" opacity=".6"/><circle cx="180" cy="330" r="240" fill="#22d3ee" opacity=".3"/><circle cx="640" cy="-40" r="200" fill="#8b5cf6" opacity=".35"/></g>
  <g fill="url(#pane)" stroke="#fff" stroke-opacity=".16" stroke-width="1.4">
    <rect x="840" y="40" width="340" height="190" rx="22" transform="rotate(-7 1010 135)"/>
    <rect x="980" y="150" width="240" height="140" rx="18" transform="rotate(8 1100 220)"/>
  </g>
  <g filter="url(#glow)" opacity=".55">{logo(70, 70, 180)}</g>
  {logo(70, 70, 180)}
  {text(300, 160, 88, "Glasspane", "#ffffff", 700)}
  {text(304, 208, 25, "A dark, glassy Windows 11–style global theme for KDE Plasma 6", "#b9c3e0")}
  <g font-family="{FONT}" font-size="15" fill="#dfe6ff">
    <rect x="304" y="238" width="104" height="32" rx="16" fill="#fff" fill-opacity=".09"/><text x="356" y="259" text-anchor="middle">Plasma 6</text>
    <rect x="420" y="238" width="104" height="32" rx="16" fill="#fff" fill-opacity=".09"/><text x="472" y="259" text-anchor="middle">Wayland</text>
    <rect x="536" y="238" width="176" height="32" rx="16" fill="#fff" fill-opacity=".09"/><text x="624" y="259" text-anchor="middle">Centered taskbar</text>
    <rect x="724" y="238" width="132" height="32" rx="16" fill="#fff" fill-opacity=".09"/><text x="790" y="259" text-anchor="middle">Start menu</text>
    <rect x="868" y="238" width="96" height="32" rx="16" fill="#fff" fill-opacity=".09"/><text x="916" y="259" text-anchor="middle">GPL-3.0</text>
  </g>
</g>
<rect x=".5" y=".5" width="1279" height="319" rx="26" fill="none" stroke="#fff" stroke-opacity=".12"/>
</svg>'''
    (ASSETS / "banner.svg").write_text(banner)

def render(src, dst, w, h, fmt=None):
    cmd = ["magick", "-background", "none", "-density", "96", str(src), "-resize", f"{w}x{h}!"]
    if str(dst).endswith(".jpg"):
        cmd += ["-background", "#0e1946", "-alpha", "remove", "-quality", "92"]
    cmd.append(str(dst))
    subprocess.run(cmd, check=True)

def main():
    write_svgs()
    P = LAF / "previews"
    render(ASSETS / "preview.svg", P / "preview.png", 960, 540)
    render(ASSETS / "preview.svg", P / "fullscreenpreview.jpg", 1920, 1080)
    render(ASSETS / "splash-preview.svg", P / "splash.png", 960, 540)
    render(ASSETS / "wallpaper.svg", LAF / "splash/images/background.jpg", 1920, 1080)
    render(ASSETS / "preview.svg", ASSETS / "preview.png", 1280, 720)
    print("art generated")

if __name__ == "__main__":
    main()
