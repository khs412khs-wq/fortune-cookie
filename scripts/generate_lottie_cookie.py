#!/usr/bin/env python3
"""Generate fortune cookie Lottie animations for the iOS app."""

import json
import math
from pathlib import Path

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "FortuneCookie" / "Animations"

COOKIE_FILL = [0.933, 0.812, 0.631, 1]       # #eecfa1
COOKIE_EDGE = [0.72, 0.52, 0.28, 1]
COOKIE_SHADOW = [0.55, 0.40, 0.25, 0.35]
PAPER_FILL = [0.98, 0.95, 0.88, 1]
PAPER_EDGE = [0.90, 0.85, 0.70, 1]
CRUMB_COLORS = [
    [0.85, 0.65, 0.35, 1],
    [0.78, 0.58, 0.30, 1],
    [0.70, 0.50, 0.22, 1],
]

CENTER = [100, 102, 0]
FPS = 30
DURATION_BREAK = 90
DURATION_IDLE = 75


def kf(frame: float, value, ease=None):
    item = {"t": frame, "s": value}
    if ease:
        item["i"] = ease["i"]
        item["o"] = ease["o"]
    return item


EASE_OUT = {"i": {"x": [0.2], "y": [1]}, "o": {"x": [0.4], "y": [0]}}
EASE_IN_OUT = {"i": {"x": [0.4], "y": [0.2]}, "o": {"x": [0.6], "y": [0.8]}}
SPRING = {"i": {"x": [0.3], "y": [1.2]}, "o": {"x": [0.2], "y": [0]}}


def shape_transform():
    return {
        "ty": "tr",
        "p": {"a": 0, "k": [0, 0]},
        "a": {"a": 0, "k": [0, 0]},
        "s": {"a": 0, "k": [100, 100]},
        "r": {"a": 0, "k": 0},
        "o": {"a": 0, "k": 100},
    }


def filled_ellipse(width: float, height: float, color: list[float]):
    return {
        "ty": "gr",
        "it": [
            {"ty": "el", "p": {"a": 0, "k": [0, 0]}, "s": {"a": 0, "k": [width, height]}},
            {"ty": "fl", "c": {"a": 0, "k": color}, "o": {"a": 0, "k": 100}, "r": 1},
            shape_transform(),
        ],
    }


def stroked_fold_lines():
    return {
        "ty": "gr",
        "it": [
            {
                "ty": "sh",
                "ks": {
                    "a": 0,
                    "k": {
                        "c": False,
                        "v": [[-18, -28], [0, -8], [18, -28]],
                        "i": [[0, 0], [0, 0], [0, 0]],
                        "o": [[0, 0], [0, 0], [0, 0]],
                    },
                },
            },
            {
                "ty": "st",
                "c": {"a": 0, "k": COOKIE_EDGE},
                "o": {"a": 0, "k": 55},
                "w": {"a": 0, "k": 2.5},
                "lc": 2,
                "lj": 2,
            },
            shape_transform(),
        ],
    }


def cookie_body_shapes(include_fold: bool = True):
    shapes = [
        filled_ellipse(152, 112, COOKIE_FILL),
        {
            "ty": "gr",
            "it": [
                {"ty": "el", "p": {"a": 0, "k": [0, 0]}, "s": {"a": 0, "k": [152, 112]}},
                {
                    "ty": "st",
                    "c": {"a": 0, "k": COOKIE_EDGE},
                    "o": {"a": 0, "k": 100},
                    "w": {"a": 0, "k": 3},
                    "lc": 2,
                    "lj": 2,
                },
                shape_transform(),
            ],
        },
    ]
    if include_fold:
        shapes.append(stroked_fold_lines())
    return shapes


def paper_strip_shapes():
    return [
        {
            "ty": "gr",
            "it": [
                {"ty": "rc", "p": {"a": 0, "k": [0, 0]}, "s": {"a": 0, "k": [34, 72]}, "r": {"a": 0, "k": 4}},
                {"ty": "fl", "c": {"a": 0, "k": PAPER_FILL}, "o": {"a": 0, "k": 100}, "r": 1},
                shape_transform(),
            ],
        },
        {
            "ty": "gr",
            "it": [
                {"ty": "rc", "p": {"a": 0, "k": [0, 0]}, "s": {"a": 0, "k": [34, 72]}, "r": {"a": 0, "k": 4}},
                {
                    "ty": "st",
                    "c": {"a": 0, "k": PAPER_EDGE},
                    "o": {"a": 0, "k": 100},
                    "w": {"a": 0, "k": 1.5},
                    "lc": 2,
                    "lj": 2,
                },
                shape_transform(),
            ],
        },
        {
            "ty": "gr",
            "it": [
                {
                    "ty": "sh",
                    "ks": {
                        "a": 0,
                        "k": {
                            "c": False,
                            "v": [[-8, -18], [8, -18], [8, 18], [-8, 18]],
                            "i": [[0, 0], [0, 0], [0, 0], [0, 0]],
                            "o": [[0, 0], [0, 0], [0, 0], [0, 0]],
                        },
                    },
                },
                {
                    "ty": "st",
                    "c": {"a": 0, "k": [0.75, 0.68, 0.55, 0.8]},
                    "o": {"a": 0, "k": 100},
                    "w": {"a": 0, "k": 1},
                    "lc": 2,
                    "lj": 2,
                    "d": [4, 4],
                },
                shape_transform(),
            ],
        },
    ]


def shape_layer(
    name: str,
    index: int,
    shapes: list,
    position_kf: list,
    rotation_kf: list,
    scale_kf: list,
    opacity_kf: list,
    out_point: int = DURATION_BREAK,
):
    return {
        "ddd": 0,
        "ind": index,
        "ty": 4,
        "nm": name,
        "sr": 1,
        "ks": {
            "o": {"a": 1, "k": opacity_kf},
            "r": {"a": 1, "k": rotation_kf},
            "p": {"a": 1, "k": position_kf},
            "a": {"a": 0, "k": [0, 0, 0]},
            "s": {"a": 1, "k": scale_kf},
        },
        "ao": 0,
        "shapes": shapes,
        "ip": 0,
        "op": out_point,
        "st": 0,
        "bm": 0,
    }


def crumb_layer(index: int, offset: list[float], delay: int, color: list[float]):
    return shape_layer(
        f"Crumb {index}",
        index,
        [filled_ellipse(7, 5, color)],
        [
            kf(0, CENTER),
            kf(delay, CENTER),
            kf(delay + 8, [CENTER[0] + offset[0], CENTER[1] + offset[1], 0], EASE_OUT),
            kf(delay + 22, [CENTER[0] + offset[0] * 1.2, CENTER[1] + offset[1] + 18, 0]),
        ],
        [kf(0, [0]), kf(delay + 8, [offset[2]], EASE_OUT), kf(delay + 22, [offset[2] * 1.3])],
        [kf(0, [100, 100, 100]), kf(delay + 8, [100, 100, 100]), kf(delay + 22, [70, 70, 100])],
        [kf(0, [0]), kf(delay, [0]), kf(delay + 1, [100]), kf(delay + 20, [100]), kf(delay + 24, [0])],
    )


def make_fortune_cookie_open() -> dict:
    shake_frames = [
        (0, 0),
        (8, 0),
        (10, -4),
        (12, 4),
        (14, -3),
        (16, 3),
        (18, 0),
    ]
    shake_pos = [kf(f, [CENTER[0] + x, CENTER[1], 0]) for f, x in shake_frames]
    shake_rot = [kf(f, [0]) for f, _ in shake_frames]

    layers = [
        shape_layer(
            "Shadow",
            1,
            [filled_ellipse(120, 24, COOKIE_SHADOW)],
            [kf(0, [100, 128, 0])],
            [kf(0, [0])],
            [kf(0, [100, 100, 100]), kf(18, [108, 108, 100], EASE_OUT), kf(24, [100, 100, 100])],
            [kf(0, [100])],
        ),
        shape_layer(
            "Cookie Whole",
            2,
            cookie_body_shapes(include_fold=True),
            shake_pos + [kf(19, CENTER)],
            shake_rot + [kf(19, [0])],
            [
                kf(0, [100, 100, 100]),
                kf(10, [103, 103, 100], EASE_IN_OUT),
                kf(18, [100, 100, 100]),
            ],
            [kf(0, [100]), kf(18, [100]), kf(19, [0])],
        ),
        shape_layer(
            "Cookie Left",
            3,
            cookie_body_shapes(include_fold=False),
            [
                kf(0, CENTER),
                kf(18, CENTER),
                kf(19, CENTER),
                kf(34, [74, 100, 0], SPRING),
                kf(48, [70, 100, 0]),
            ],
            [kf(0, [0]), kf(18, [0]), kf(19, [0]), kf(34, [-24], SPRING), kf(48, [-24])],
            [kf(0, [100, 100, 100]), kf(19, [100, 100, 100])],
            [kf(0, [0]), kf(18, [0]), kf(19, [100])],
        ),
        shape_layer(
            "Cookie Right",
            4,
            cookie_body_shapes(include_fold=False),
            [
                kf(0, CENTER),
                kf(18, CENTER),
                kf(19, CENTER),
                kf(34, [126, 100, 0], SPRING),
                kf(48, [130, 100, 0]),
            ],
            [kf(0, [0]), kf(18, [0]), kf(19, [0]), kf(34, [24], SPRING), kf(48, [24])],
            [kf(0, [100, 100, 100]), kf(19, [100, 100, 100])],
            [kf(0, [0]), kf(18, [0]), kf(19, [100])],
        ),
        shape_layer(
            "Fortune Paper",
            5,
            paper_strip_shapes(),
            [
                kf(0, [100, 118, 0]),
                kf(28, [100, 118, 0]),
                kf(42, [100, 88, 0], EASE_OUT),
                kf(55, [100, 84, 0]),
            ],
            [kf(0, [0]), kf(28, [0]), kf(42, [-4], EASE_OUT), kf(55, [-4])],
            [
                kf(0, [40, 20, 100]),
                kf(28, [40, 20, 100]),
                kf(42, [100, 100, 100], SPRING),
                kf(55, [100, 100, 100]),
            ],
            [kf(0, [0]), kf(27, [0]), kf(28, [100])],
        ),
    ]

    crumbs = [
        (12, [-28, -10], -35),
        (13, [30, -8], 40),
        (14, [-18, 14], -20),
        (15, [22, 16], 28),
        (16, [0, -24], 10),
        (17, [-8, 22], -12),
    ]
    for i, (idx, offset, rot) in enumerate(crumbs):
        layers.append(crumb_layer(idx, [offset[0], offset[1], rot], 20 + i, CRUMB_COLORS[i % 3]))

    return {
        "v": "5.7.4",
        "fr": FPS,
        "ip": 0,
        "op": DURATION_BREAK,
        "w": 200,
        "h": 200,
        "nm": "Fortune Cookie Open",
        "ddd": 0,
        "assets": [],
        "layers": layers,
    }


def make_idle_animation() -> dict:
    return {
        "v": "5.7.4",
        "fr": FPS,
        "ip": 0,
        "op": DURATION_IDLE,
        "w": 200,
        "h": 200,
        "nm": "Fortune Cookie Idle",
        "ddd": 0,
        "assets": [],
        "layers": [
            shape_layer(
                "Shadow",
                1,
                [filled_ellipse(118, 22, COOKIE_SHADOW)],
                [kf(0, [100, 126, 0])],
                [kf(0, [0])],
                [
                    kf(0, [100, 100, 100]),
                    kf(18, [104, 104, 100], EASE_IN_OUT),
                    kf(38, [100, 100, 100], EASE_IN_OUT),
                    kf(56, [104, 104, 100], EASE_IN_OUT),
                    kf(DURATION_IDLE, [100, 100, 100]),
                ],
                [kf(0, [100])],
                out_point=DURATION_IDLE,
            ),
            shape_layer(
                "Cookie Idle",
                2,
                cookie_body_shapes(include_fold=True),
                [kf(0, CENTER), kf(DURATION_IDLE, CENTER)],
                [
                    kf(0, [0]),
                    kf(18, [-2], EASE_IN_OUT),
                    kf(38, [2], EASE_IN_OUT),
                    kf(56, [-2], EASE_IN_OUT),
                    kf(DURATION_IDLE, [0]),
                ],
                [
                    kf(0, [100, 100, 100]),
                    kf(18, [103, 103, 100], EASE_IN_OUT),
                    kf(38, [100, 100, 100], EASE_IN_OUT),
                    kf(56, [103, 103, 100], EASE_IN_OUT),
                    kf(DURATION_IDLE, [100, 100, 100]),
                ],
                [kf(0, [100])],
                out_point=DURATION_IDLE,
            ),
        ],
    }


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    break_anim = make_fortune_cookie_open()
    idle_anim = make_idle_animation()

    files = {
        "cookie_break.json": break_anim,
        "cookie_idle.json": idle_anim,
        "fortune_cookie_open.json": break_anim,
    }

    for filename, data in files.items():
        (OUTPUT_DIR / filename).write_text(
            json.dumps(data, separators=(",", ":")),
            encoding="utf-8",
        )

    print(f"Generated {len(files)} Lottie files in {OUTPUT_DIR}")
    for name in files:
        print(f"  - {name}")


if __name__ == "__main__":
    main()
