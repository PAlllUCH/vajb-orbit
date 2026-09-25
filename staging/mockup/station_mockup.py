"""station_mockup.py - D11 station-scene look mockup (design pass, not shipping art).

v2 (owner feedback on v1): ONE composition, no second station - today's
env_station.png is pasted as the much-bigger MAIN SPRITE at footprint x 2.2
(frame 298.8 u) at the spawnpoint, carrying its own design language (hull
silhouette, welded platework, window bands, gunmetal palette), with the 6
static element kinds composed onto/around it and the 3 moving kinds' paths
drawn (approach strobe lane at 55 u dot spacing, shuttle loop, crane slew
arc). The scale comparison is a caption + a true-scale steel square on the art
(today 135.8 u / half 67.9 vs proposed 298.8 u / half 149.4). Geometry +
palette are the source of truth: the D11-A0 report's mockup geometry spec
(plan of record), pins from sector.gd:54-77, ENVIRONMENT_SPEC 1.1/6/8/9/11
and CONTRACTS 21 O6. Writes staging/mockup/out/station_mockup_v2.png + .jpg
and the owner sheet staging/phase_g/_review/d11_mockup.png (mockup + plan
table as text, both v2 revisions noted). Nothing renders and no paid call is
made: the D11_BRIEF mockup gate stands.
"""
import math
import random
import textwrap

from PIL import Image, ImageDraw, ImageFont

random.seed(11)

W, H = 3455, 2660
PX = 3
HEADER = 110
WX0, WY0 = -468.0, -300.0

HERO_X = 0.0
TODAY_HALF = 67.9
HERO_FRAME = 149.4
HERO_HULL = 131.0
RING_A = 120.0
RING_B = 175.0

ART = "vajb-orbit/assets/env/poi/env_station.png"
OUT = "staging/mockup/out"
SHEET = "staging/phase_g/_review/d11_mockup.png"

GUN_MID = (58, 63, 70)
GUN_DARK = (43, 47, 53)
IRON = (35, 38, 41)
STEEL = (86, 92, 99)
OCHRE = (110, 91, 74)
DRY_RUST = (138, 106, 80)
UMBER = (74, 66, 59)
EMBER = (200, 70, 27)
EMBER_GLOW = (232, 112, 58)
ASH = (141, 147, 155)
BONE = (201, 205, 210)
DIM = (112, 119, 128)
BG = (13, 17, 26)
LEG_BG = (10, 13, 19)

STROBE_YS = [160.0, 215.0, 270.0, 325.0, 380.0]


def font(px: int, bold: bool = False, mono: bool = False):
    if mono:
        paths = ["/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"] if bold else [
                 "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"]
    else:
        paths = ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"] if bold else [
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]
    for p in paths:
        try:
            return ImageFont.truetype(p, px)
        except OSError:
            continue
    return ImageFont.load_default()


F_TITLE = font(22, bold=True)
F_BLOCK = font(17, bold=True)
F_LBL = font(16, bold=True)
F_TXT = font(13)
F_SM = font(12)


def X(wx: float) -> float:
    return (wx - WX0) * PX


def Y(wy: float) -> float:
    return HEADER + (wy - WY0) * PX


def _walk(pts, dash: float, gap: float):
    on = True
    rem = dash
    prev = pts[0]
    for cur in pts[1:]:
        seg = math.hypot(cur[0] - prev[0], cur[1] - prev[1])
        if seg <= 0.0:
            continue
        pos = 0.0
        a = prev
        while pos < seg - 1e-9:
            step = min(rem, seg - pos)
            b = (prev[0] + (cur[0] - prev[0]) * (pos + step) / seg,
                 prev[1] + (cur[1] - prev[1]) * (pos + step) / seg)
            if on:
                yield (a, b)
            a = b
            pos += step
            rem -= step
            if rem <= 1e-9:
                on = not on
                rem = dash if on else gap
        prev = cur


def dashed(d: ImageDraw.Draw, pts, color, width: int = 2, dash: float = 14.0, gap: float = 9.0):
    for a, b in _walk(pts, dash, gap):
        d.line([a, b], fill=color, width=width)


def circle_pts(cx: float, cy: float, r: float, a0: float = 0.0, a1: float = 360.0,
               step_px: float = 4.0):
    sweep = abs(a1 - a0) / 360.0 * 2.0 * math.pi * r
    n = max(8, int(sweep / step_px))
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def rect_pts(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0)]


def round_rect_pts(x0, y0, x1, y1, r):
    pts = [(x0 + r, y0), (x1 - r, y0)]
    pts += circle_pts(x1 - r, y0 + r, r, -90, 0, 3)
    pts += [(x1, y1 - r)]
    pts += circle_pts(x1 - r, y1 - r, r, 0, 90, 3)
    pts += [(x0 + r, y1)]
    pts += circle_pts(x0 + r, y1 - r, r, 90, 180, 3)
    pts += [(x0, y0 + r)]
    pts += circle_pts(x0 + r, y0 + r, r, 180, 270, 3)
    return pts


def head(d: ImageDraw.Draw, x, y, ang_deg, size=15.0, fill=STEEL):
    a = math.radians(ang_deg)
    d.polygon([(x, y),
               (x - size * math.cos(a - 0.42), y - size * math.sin(a - 0.42)),
               (x - size * math.cos(a + 0.42), y - size * math.sin(a + 0.42))], fill=fill)


def txt(d: ImageDraw.Draw, xy, s, f, fill, anchor="la"):
    d.text(xy, s, font=f, fill=fill, anchor=anchor)


def paste_hero_art(img: Image.Image):
    art = Image.open(ART).convert("RGBA")
    tw = round((HERO_FRAME * 2) * PX)
    th = round(tw * art.size[1] / art.size[0])
    cx, cy = X(HERO_X), Y(0.0)
    art = art.resize((tw, th), Image.LANCZOS)
    img.paste(art, (round(cx - tw / 2), round(cy - th / 2)), art)


def hero_overlay() -> Image.Image:
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    cx = HERO_X
    for x0, x1 in ((cx - 193, cx - 131), (cx + 131, cx + 193)):
        y0 = -8.0
        d.line([(X(x0), Y(y0)), (X(x1), Y(y0))], fill=GUN_MID + (255,), width=6)
        d.line([(X(x0), Y(-y0)), (X(x1), Y(-y0))], fill=GUN_MID + (255,), width=6)
        t = x0 + 5.0
        flip = True
        while t < x1 - 5.0:
            a = (t, y0 if flip else -y0)
            b = (t + 10.0, -y0 if flip else y0)
            d.line([(X(a[0]), Y(a[1])), (X(b[0]), Y(b[1]))], fill=(70, 76, 84, 255), width=4)
            flip = not flip
            t += 10.0
        d.rectangle([X(x1 - 6) if x1 > x0 else X(x0), Y(-10), X(max(x0, x1)),
                     Y(10)], fill=GUN_DARK + (255,), outline=STEEL + (255,), width=3)
    for bx, by, tx, ty in ((cx - 113, -113, cx - 147, -147), (cx + 113, 113, cx + 147, 147)):
        d.rectangle([X(bx - 6), Y(by - 6), X(bx + 6), Y(by + 6)],
                    fill=GUN_MID + (255,), outline=STEEL + (255,), width=3)
        d.line([(X(bx), Y(by)), (X(tx), Y(ty))], fill=STEEL + (255,), width=5)
        d.ellipse([X(tx) - 7, Y(ty) - 7, X(tx) + 7, Y(ty) + 7],
                  fill=GUN_DARK + (255,), outline=STEEL + (255,), width=3)
        d.line([(X(tx) - 10, Y(ty) - 8), (X(tx) + 10, Y(ty) + 8)],
               fill=STEEL + (255,), width=3)
    d.rectangle([X(cx - 95), Y(-157), X(cx - 15), Y(-137)],
                fill=GUN_DARK + (255,), outline=STEEL + (255,), width=3)
    for lx in (cx - 85, cx - 25):
        d.line([(X(lx), Y(-137)), (X(lx), Y(-131))], fill=GUN_MID + (255,), width=6)
    d.line([(X(cx - 55), Y(-157)), (X(cx - 55), Y(-197))], fill=GUN_MID + (255,), width=6)
    d.rectangle([X(cx - 59), Y(-201), X(cx - 51), Y(-193)],
                fill=GUN_DARK + (255,), outline=STEEL + (255,), width=2)
    px0, py0 = cx + 62, -131.0
    d.rectangle([X(px0 - 8), Y(py0 - 8), X(px0 + 8), Y(py0 + 8)],
                fill=GUN_MID + (255,), outline=STEEL + (255,), width=3)
    d.line([(X(px0), Y(py0)), (X(px0), Y(py0 - 46))], fill=GUN_MID + (255,), width=7)
    d.rectangle([X(px0 - 5), Y(py0 - 52), X(px0 + 5), Y(py0 - 44)],
                fill=GUN_DARK + (255,), outline=STEEL + (255,), width=2)
    d.line([(X(px0), Y(py0)), (X(px0), Y(py0 + 14))], fill=GUN_MID + (255,), width=7)
    d.rectangle([X(px0 - 7), Y(py0 + 14), X(px0 + 7), Y(py0 + 22)],
                fill=GUN_DARK + (255,), outline=STEEL + (255,), width=2)
    for wy in (-52.0, 52.0):
        d.rectangle([X(cx - 85), Y(wy - 3.5), X(cx + 85), Y(wy + 3.5)],
                    fill=IRON + (255,))
        xw = cx - 84.0
        while xw < cx + 78:
            d.rectangle([X(xw), Y(wy - 2.5), X(xw + 8), Y(wy + 2.5)],
                        fill=(136, 143, 152, 255))
            xw += 10.0
        d.line([(X(cx - 85), Y(wy + 3.5)), (X(cx + 85), Y(wy + 3.5))],
               fill=STEEL + (255,), width=2)
        for _ in range(8):
            rs = random.uniform(cx - 80, cx + 70)
            d.line([(X(rs), Y(wy + 5)), (X(rs), Y(wy + 5 + random.uniform(4, 12)))],
                   fill=(94, 79, 68, 255), width=3)
    for sx0 in (cx - 107, cx + 51):
        d.rectangle([X(sx0), Y(-131), X(sx0 + 22), Y(131)],
                    fill=(66, 71, 79, 255), outline=IRON + (255,), width=3)
        for ey in (-125.0, 125.0):
            yy = -120.0
            while yy < 120:
                rx = sx0 + 4 if ey < 0 else sx0 + 18
                d.ellipse([X(rx) - 4, Y(yy) - 4, X(rx) + 4, Y(yy) + 4], fill=(78, 83, 91, 255))
                yy += 12.0
        yy = -100.0
        while yy < 110:
            d.line([(X(sx0), Y(yy)), (X(sx0 + 22), Y(yy))], fill=IRON + (255,), width=2)
            yy += 30.0
    for ly in (-123.0, 123.0):
        d.rectangle([X(cx - 102), Y(ly - 4), X(cx + 102), Y(ly + 4)],
                    fill=GUN_DARK + (255,), outline=IRON + (255,), width=2)
        for i in range(11):
            lx = cx - 100 + i * 20
            d.ellipse([X(lx) - 7, Y(ly) - 7, X(lx) + 7, Y(ly) + 7], fill=EMBER + (255,))
    return ov


def draw_hero(img: Image.Image, d: ImageDraw.Draw):
    cx = HERO_X
    txt(d, (X(cx), Y(-280.0)),
        "PROPOSED: today's station as the much-bigger main sprite, footprint x 2.2 "
        "(frame 298.8 u, half 149.4)",
        F_LBL, BONE, "ma")
    txt(d, (X(cx), Y(-258.0)),
        "effective STATION_SCALE 0.0663 x 2.2 = 0.1459 (reversal: STATION_SCALE shipped)",
        F_TXT, ASH, "ma")
    dashed(d, rect_pts(X(cx - HERO_FRAME), Y(-HERO_FRAME), X(cx + HERO_FRAME), Y(HERO_FRAME)),
           ASH, width=2, dash=14, gap=9)
    dashed(d, rect_pts(X(cx - HERO_HULL), Y(-HERO_HULL), X(cx + HERO_HULL), Y(HERO_HULL)),
           ASH, width=2, dash=8, gap=6)
    d.rectangle([X(cx - TODAY_HALF), Y(-TODAY_HALF), X(cx + TODAY_HALF), Y(TODAY_HALF)],
                outline=STEEL, width=3)
    dashed(d, circle_pts(X(cx), Y(0.0), RING_B * PX), EMBER, width=3, dash=16, gap=10)
    dashed(d, circle_pts(X(cx), Y(0.0), RING_A * PX), BG, width=8, dash=999, gap=1)
    dashed(d, circle_pts(X(cx), Y(0.0), RING_A * PX), STEEL, width=3, dash=999, gap=1)
    d.line([(X(cx), Y(120.0)), (X(cx), Y(420.0) - 18)], fill=BG, width=7)
    d.line([(X(cx), Y(120.0)), (X(cx), Y(420.0) - 18)], fill=STEEL, width=3)
    head(d, X(cx), Y(420.0), 90.0, 18.0, STEEL)
    dashed(d, round_rect_pts(X(cx - 255), Y(-225), X(cx + 340), Y(190), 90 * PX),
           EMBER, width=3, dash=18, gap=11)
    for gx, ang in ((cx + 20, 0.0), (cx + 140, 180.0)):
        gy = -225.0 if ang == 0.0 else 190.0
        d.rectangle([X(gx - 9), Y(gy - 3.5), X(gx + 9), Y(gy + 3.5)],
                    fill=GUN_MID, outline=STEEL, width=3)
        ax = gx + (17 if ang == 0.0 else -17)
        head(d, X(ax), Y(gy), ang, 13.0, EMBER)
    d.line([(X(cx), Y(135.0)), (X(cx), Y(410.0))], fill=BG, width=6)
    dashed(d, [(X(cx), Y(135.0)), (X(cx), Y(410.0))], EMBER, width=3, dash=14, gap=9)
    for sy in STROBE_YS:
        d.ellipse([X(cx) - 14, Y(sy) - 14, X(cx) + 14, Y(sy) + 14],
                  fill=EMBER, outline=(120, 38, 12), width=3)
    gate0, gate1 = cx + 215, cx + 470
    brk0, brk1 = cx + 325, cx + 355
    d.line([(X(gate0), Y(0.0)), (X(brk0), Y(0.0))], fill=STEEL, width=4)
    d.line([(X(brk1), Y(0.0)), (X(gate1) - 20, Y(0.0))], fill=STEEL, width=4)
    head(d, X(gate1), Y(0.0), 0.0, 20.0, STEEL)
    txt(d, (X(cx + 420), Y(-30.0)), "GATE 900 u (_gate_bearing(dest), sector.gd:96,581)",
        F_TXT, BONE, "ma")
    pivot = (cx + 62, -131.0)
    dashed(d, circle_pts(X(pivot[0]), Y(pivot[1]), 42 * PX, -150, -30, 3),
           EMBER, width=3, dash=12, gap=8)
    txt(d, (X(cx + 185), Y(-16.0)), "RING B 175 u proposed (A: keep 120, see legend)",
        F_TXT, EMBER)
    txt(d, (X(cx + 126.0), Y(-96.0)),
        "DOCK_RING_RADIUS 120 (shipped, sector.gd:73) = the dock", F_TXT, STEEL)
    txt(d, (X(cx - 64.0), Y(72.0)),
        "TODAY footprint 135.8 u (half 67.9) @0.0663 - steel square = true scale",
        F_SM, BONE)
    txt(d, (X(cx + 10.0), Y(178.0)),
        "art content half 131 u (87.7 % trim) = hull 261.9 u, 2.20x today",
        F_SM, ASH)
    txt(d, (X(cx + 14.0), Y(404.0)),
        "player spawn (0,120) -> (0,420), offset 300 (shipped)", F_TXT, STEEL)
    txt(d, (X(cx - 197.0), Y(-18.0)), "arms x2, tips +/-193", F_TXT, ASH, "ra")
    txt(d, (X(cx - 150.0), Y(-158.0)), "mast_a (-113,-113) to (-147,-147)", F_TXT, ASH, "ra")
    txt(d, (X(cx + 155.0), Y(158.0)), "mast_b (113,113) to (147,147)", F_TXT, ASH)
    txt(d, (X(cx - 55), Y(-212.0)), "gantry_a rail x -95..-15, jib to -197", F_TXT, ASH, "ma")
    txt(d, (X(cx - 10), Y(-192.0)),
        "gantry_b slew +/-60 deg (120 span), 30 s at 4 deg/s", F_TXT, EMBER)
    txt(d, (X(cx - 10), Y(-144.0)), "lit-window bands y +/-52", F_TXT, ASH)
    d.line([(X(cx - 113.0), Y(196.0)), (X(cx - 96.0), Y(136.0))], fill=DIM, width=1)
    txt(d, (X(cx - 115.0), Y(200.0)), "plate spines x2 (22 u, full height)", F_TXT, ASH, "ra")
    d.line([(X(cx - 131.0), Y(126.0)), (X(cx - 102.0), Y(123.0))], fill=DIM, width=1)
    txt(d, (X(cx - 135.0), Y(128.0)), "ember lamp runs x2 (only emissive)", F_TXT, ASH, "ra")
    txt(d, (X(cx + 12.0), Y(345.0)), "approach strobes x5, STROBE_PERIOD 1.2 s",
        F_TXT, EMBER)
    txt(d, (X(cx - 245.0), Y(178.0)),
        "service-shuttle loop x2, 1866 u path, 62 s lap at 30 u/s", F_TXT, EMBER)


def draw_header(d: ImageDraw.Draw):
    txt(d, (16, 8),
        "D11 STATION MOCKUP v2: today's station enlarged IN PLACE as the spawnpoint "
        "composition (one scene, no second station), 3 px/u", F_TITLE, BONE)
    txt(d, (16, 36),
        "plan of record: .agents/gen/slices/D11-station-scene/D11-A0_report.md "
        "(geometry spec) | pins: sector.gd:54-77, ENVIRONMENT_SPEC 1.1/6/8/9/11, "
        "CONTRACTS 21 O6", F_TXT, ASH)
    txt(d, (16, 54),
        "MOCKUP GATE: nothing renders, ships or wires before the owner approves "
        "this sheet (D11_BRIEF hard rules; A0 rendered 0, $0.00)", F_TXT, EMBER)
    txt(d, (16, 72),
        "SCALE CAPTION: TODAY one Sprite2D, frame 135.8 u (half 67.9) @ STATION_SCALE "
        "0.0663 | PROPOSED the same station as the main sprite at x 2.2, frame 298.8 u "
        "(half 149.4)", F_TXT, BONE)
    txt(d, (16, 90),
        "v2 revision 1 (owner): the composition IS the current station - "
        "env_station.png's design language as the much-bigger MAIN SPRITE, the 6 "
        "static kinds composed onto/around it; NO second station.", F_TXT, ASH)
    txt(d, (16, 106),
        "v2 revision 2 (orchestrator ruling): approach strobe lane at 55 u dot "
        "spacing (y 160/215/270/325/380) - the '55 u apart' text is the pin; v1's "
        "drawn 45 u gap was wrong.", F_TXT, ASH)


def draw_legend(d: ImageDraw.Draw):
    d.rectangle([0, 2360, W, H], fill=LEG_BG)
    d.line([(0, 2360), (W, 2360)], fill=STEEL, width=2)
    txt(d, (16, 2364),
        "LEGEND / PROPOSED PINS (owner ticks: mockup, hero scale, inventory, "
        "motion constants, ring A/B, game/ grant)", F_TXT, BONE)
    left = [
        "COLOR KEY: STEEL solid = shipped value | DIM dashed = art content | "
        "EMBER = motion + proposals | filled metal = proposed render content",
        "STATIC, 6 kinds / 12 instances (a+b = 2 instances each):",
        "  docking-arm trusses x2 (tips +/-193)   antenna/mast clusters x2 "
        "(bases +/-113, tips +/-147)",
        "  gantry cranes x2 (a: rail -95..-15, jib -197 | b: slew pivot (62,-131), "
        "arc r42)   lit-window bands x2 (y +/-52, painted light)",
        "  hull-plate spines x2 (x -107 / +51, 22 u wide, full height)   ember lamp "
        "runs x2 (y +/-123, x -100..+100 step 20, 11 each)",
        "  ember warning lamps are the ONLY emissive (ENVIRONMENT_SPEC 6 survives)",
        "MOVING, 3 kinds (code in station_scene.gd, no new Timer):",
        "  approach strobes x5 (lane x 0, y 160/215/270/325/380 - 55 u apart, "
        "dashed to 410, spawn ref 420)",
        "  service-shuttle loop x2 glyphs (rounded rect l-255 r+340 t-225 b+190 "
        "corner 90; 1866 u, 62 s)",
        "  crane slew x1 pivot (arc r42 around (62,-131), -150..-30 deg = 120 span, "
        "30 s)",
        "15 render files / 15 runs = 150 credits = $0.75 (plan table in the A0 "
        "report); strobes reuse lamp art, slew rotates gantry_b",
        "GATE arrow: 900 u on _gate_bearing(dest) (sector.gd:96, 581), shipped "
        "placement drawn for context",
    ]
    right = [
        "PROPOSED PINS, each carries its reversal:",
        "HERO SCALE: frame 298.8 u = today's 135.8 u footprint x 2.2 (>= 11 floor).",
        "  Effective STATION_SCALE 0.0663 x 2.2 = 0.1459. Reversal: STATION_SCALE",
        "  as shipped (sector.gd:65). Measured: art 2060x2073, content trim 87.7 %",
        "  -> hero visible hull 261.9 u = 2.20x today's 119.1 u.",
        "RING A/B (owner tick): A = keep DOCK_RING_RADIUS 120 (needs hero trim",
        "  <= 116 u half, visible hull drops to 1.95x). B = 175 u (hull 131.0 +",
        "  ship half 29.5 + margin 14.5, drawn ember-dashed). B sits outside C1's",
        "  _spawn_station grant, so B needs its own ratification.",
        "MOTION: STROBE_PERIOD 1.2 s | SHUTTLE_SPEED 30.0 u/s | SLEW_RATE 4.0",
        "  deg/s. Reversal: the element stands still (brief owner tick 4).",
        "INVENTORY reversal: drop any kind to zero, the scene still reads (11).",
        'INVARIANTS (defect if violated): group "station", DockZone sibling in',
        "  world units, placement centre (sector.gd:62-71).",
    ]
    for i, s in enumerate(left):
        txt(d, (16, 2390 + i * 19), s, F_SM, ASH if not s.startswith("  ") else DIM)
    for i, s in enumerate(right):
        txt(d, (1740, 2390 + i * 19), s, F_SM,
            ASH if not s.startswith("  ") else DIM)


PLAN = [
    ("env_station_hero.png",
     "top-down station hero: welded platework in gunmetal mid/dark, panel seams + "
     "rivet lines, heavy hull grime films, rust streaks from seams and rivets, pitted "
     "metal, cold steel rim, one value step darker than ships; ember warning lamps "
     "the ONLY emissive (Burnt Ember points, no halo)"),
    ("env_station_arm_a.png",
     "truss docking arm of welded platework in gunmetal mid/dark, weld beads over "
     "the joints, hull grime, rust streaks from the seams, cold steel rim; no emissive"),
    ("env_station_arm_b.png", "same subject as arm_a (distinct weathering pass)"),
    ("env_station_mast_a.png",
     "antenna/mast cluster on a welded platework base, gunmetal mid/dark, hull grime, "
     "rust streaks at the foot, cold steel rim; no emissive"),
    ("env_station_mast_b.png", "same subject as mast_a (distinct weathering pass)"),
    ("env_station_gantry_a.png",
     "rail gantry crane of welded platework in gunmetal mid/dark, heavy hull grime "
     "along the rail, rust streaks at the wheels; no emissive"),
    ("env_station_gantry_b.png",
     "same crane on its slew pivot (pivot plate + counterweight jib), welded "
     "platework gunmetal mid/dark, grime, rust streaks at the pivot; no emissive - "
     "rotates in code"),
    ("env_station_windows_a.png",
     "band of lit hull windows painted pale steel-highlight on gunmetal mid/dark "
     "plating, grime around the frames, rust streaks below the sills; no emissive "
     "(painted light only)"),
    ("env_station_windows_b.png", "same subject as windows_a (distinct weathering pass)"),
    ("env_station_plate_a.png",
     "raised hull-plate spine: welded platework seams and rivet lines in gunmetal "
     "mid/dark, hull grime film, rust streaks bleeding from the rivets; no emissive"),
    ("env_station_plate_b.png", "same subject as plate_a (distinct weathering pass)"),
    ("env_station_lamp_a.png",
     "run of ember warning lamps: small hot Burnt Ember points on a gunmetal dark "
     "strip, rivets + grime; ember warning lamps the ONLY emissive, no halo beyond "
     "the points (\u00a76 exception)"),
    ("env_station_lamp_b.png", "same subject as lamp_a (distinct lamp spacing)"),
    ("env_station_shuttle_a.png",
     "top-down service shuttle, gunmetal mid/dark hull with cold steel rim, hull "
     "grime, rust streaks on the aft plating; no emissive (engines stay dark, "
     "palette-lit only)"),
    ("env_station_shuttle_b.png", "same subject as shuttle_a (distinct weathering pass)"),
]


def build_sheet(mockup: Image.Image):
    f_h = font(20, bold=True)
    f_s = font(14)
    f_m = font(13, mono=True)
    f_mb = font(13, bold=True, mono=True)
    width = 1600
    margin = 12
    thumb_w = width - 2 * margin
    thumb_h = round(thumb_w * H / W)
    header = [
        ("D11-A0 review sheet v2: station mockup + element render plan "
         "(STOP: owner approval before A1)", f_h, BONE),
        ("Wave D11 | brief .agents/gen/slices/D11-station-scene/D11_BRIEF.md | plan "
         "of record: D11-A0_report.md | ENVIRONMENT_SPEC 11, CONTRACTS 21 O6", f_s, ASH),
        ("Owner feedback on v1 (verbatim): \"Okay but i wanted to implement the currect "
         "space station into new composition (as spawnpoint) not next to it. Everythin "
         "else looks good.\"", f_s, BONE),
        ("v2 revision 1 (applied): the composition IS the current station - "
         "env_station.png's own design language (hull silhouette, welded platework, "
         "window bands, gunmetal palette) as the", f_s, ASH),
        ("much-bigger MAIN SPRITE, with the 6 static element kinds composed onto and "
         "around it; NO second station in the scene - the scale comparison is a "
         "caption / scale-bar only", f_s, ASH),
        ("(today ~67.9 u half / 135.8 u frame vs proposed 298.8 u frame). The spawn "
         "arrow and the DockZone ring mark the station's dock as today; it stays the "
         "spawnpoint.", f_s, ASH),
        ("v2 revision 2 (applied): the approach strobe lane is re-spaced to 55 u dot "
         "spacing (y 160/215/270/325/380); ENVIRONMENT_SPEC 11's '55 u apart' text is "
         "the pin - v1's drawn 45 u gap was wrong.", f_s, ASH),
        ("Proposed pins (unchanged from approved v1): hero 298.8 u frame = footprint "
         "x 2.2 (0.1459) | 6 static kinds / 12 instances | 3 moving kinds | "
         "STROBE_PERIOD 1.2 s, SHUTTLE_SPEED 30 u/s,", f_s, ASH),
        ("SLEW_RATE 4 deg/s | ring A 120 vs B 175", f_s, ASH),
        ("15 files, 15 runs = 150 credits = $0.75 (A1); A0 rendered 0 = $0.00. "
         "NOTHING renders before the owner approves this sheet.", f_s, EMBER),
        ("THE MOCKUP (v2): ONE composition at the spawnpoint - today's station art "
         "enlarged in place as the main sprite (steel square = today's footprint, "
         "true scale), 6 static kinds on/around it,", f_s, BONE),
        ("3 moving kinds' paths drawn; same sheet idiom, 3 px/u = the 2x sheet", f_s, BONE),
    ]
    intro = ("ELEMENT RENDER PLAN: 15 files, one object per 2K 1:1 panel, 1 cell, no "
             "grid; panel order is law: render -> panels.py --detect -> cut each -> "
             "key each -> trim; flare --post-only (never native alpha); 2K run = 10 "
             "credits = $0.05. Vocabulary is verbatim ENVIRONMENT_SPEC 1.1/6; the "
             "negative list of 9 applies.")
    footer = [
        ("TOTALS: 15 files, 15 runs, 150 credits = $0.75; A0 rendered 0 = $0.00 "
         "(ceiling A0+A1 <= $1.50 = <= 30 runs, 15 re-run headroom).", f_s, BONE),
        ("Moving elements need NO new file: strobes reuse env_station_lamp_* "
         "toggled in code; the slew rotates env_station_gantry_b.", f_s, ASH),
        ("OWNER TICKS: 1 mockup approval | 2 hero scale as approved | 3 element "
         "inventory | 4 motion constants | 5 game/ grant (sector.gd + "
         "station_scene.gd, one function each).", f_s, EMBER),
    ]
    rows = []
    for name, subject in PLAN:
        rows.append((f"{name}   1 run x 10 cr", f_mb, BONE))
        for ln in textwrap.wrap(subject, 100):
            rows.append(("    " + ln, f_m, DIM))
    intro_lines = [("  " + ln, f_m, ASH) for ln in textwrap.wrap(intro, 100)]
    height = margin
    for _, f, _c in header:
        height += f.size + 8
    height += thumb_h + 26
    height += (f_s.size + 8) + sum(f.size + 6 for _, f, _ in intro_lines)
    height += sum(f.size + 6 for _, f, _ in rows)
    height += 16 + sum(f.size + 8 for _, f, _ in footer) + margin
    sheet = Image.new("RGB", (width, height), (28, 30, 34))
    d = ImageDraw.Draw(sheet)
    y = margin
    for s, f, c in header:
        txt(d, (margin, y), s, f, c)
        y += f.size + 8
    thumb = mockup.copy()
    thumb.thumbnail((thumb_w, thumb_h), Image.LANCZOS)
    sheet.paste(thumb, (margin, y))
    d.rectangle([margin - 1, y - 1, margin + thumb.size[0], y + thumb.size[1]],
                outline=(120, 126, 134))
    y += thumb_h + 26
    txt(d, (margin, y), "ELEMENT RENDER PLAN (task 2 of the brief):", f_s, BONE)
    y += f_s.size + 8
    for s, f, c in intro_lines:
        txt(d, (margin, y), s, f, c)
        y += f.size + 6
    for s, f, c in rows:
        txt(d, (margin, y), s, f, c)
        y += f.size + 6
    y += 16
    for s, f, c in footer:
        txt(d, (margin, y), s, f, c)
        y += f.size + 8
    sheet.save(SHEET)
    print(f"wrote {SHEET} ({width}x{height})")


def main():
    img = Image.new("RGBA", (W, H), BG + (255,))
    d = ImageDraw.Draw(img)
    paste_hero_art(img)
    img.alpha_composite(hero_overlay())
    d = ImageDraw.Draw(img)
    draw_hero(img, d)
    draw_header(d)
    draw_legend(d)
    rgb = img.convert("RGB")
    rgb.save(f"{OUT}/station_mockup_v2.png")
    rgb.save(f"{OUT}/station_mockup_v2.jpg", quality=88)
    print(f"wrote {OUT}/station_mockup_v2.png + .jpg ({W}x{H})")
    build_sheet(rgb)


if __name__ == "__main__":
    main()
