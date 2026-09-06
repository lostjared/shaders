#!/usr/bin/env python3

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COMPUTE_DIR = ROOT / "compute"

FILTERS = [
    ("Blank", "Blank", "color", "Black output"),
    ("Negate", "Negate", "color", "RGB inversion"),
    ("Grayscale", "Grayscale", "color", "Luma grayscale"),
    ("Darken", "Darken", "color", "Adjustable darkening"),
    ("DarkNegate", "DarkNegate", "color", "Dark inverted color"),
    ("GammaDarken5", "GammaDarken5", "color", "Moderate gamma darkening"),
    ("GammaDarken10", "GammaDarken10", "color", "Strong gamma darkening"),
    ("All Red", "AllRed", "channel", "Red-channel isolation"),
    ("All Green", "AllGreen", "channel", "Green-channel isolation"),
    ("All Blue", "AllBlue", "channel", "Blue-channel isolation"),
    ("ColorOrderSwap", "ColorOrderSwap", "channel", "Fixed RGB permutation"),
    ("ColorOrderSwapMap", "ColorOrderSwapMap", "channel", "Animated RGB permutation"),
    ("FlipX_Axis", "FlipX_Axis", "geometry", "Horizontal flip"),
    ("FlipY_Axis", "FlipY_Axis", "geometry", "Vertical flip"),
    ("FlipBoth", "FlipBoth", "geometry", "Horizontal and vertical flip"),
    ("Sideways Mirror", "SidewaysMirror", "geometry", "Outward horizontal mirror"),
    ("Mirror No Blend", "MirrorNoBlend", "geometry", "Inward horizontal mirror"),
    ("FlipBlendW", "FlipBlendW", "geometry", "Horizontal flip blend"),
    ("FlipBlendH", "FlipBlendH", "geometry", "Vertical flip blend"),
    ("FlipBlendWH", "FlipBlendWH", "geometry", "Dual-axis flip blend"),
    ("RGB Shift", "RGBShift", "channel", "Separated red and blue sampling"),
    ("RGB Sep", "RGBSep", "channel", "Adjustable RGB separation"),
    ("Scanlines", "Scanlines", "line", "Alternating dark scanlines"),
    ("InvertedScanlines", "InvertedScanlines", "line", "Alternating inverted scanlines"),
    ("BlendedScanLines", "BlendedScanLines", "line", "Neighbor-blended scanlines"),
    ("ScanlineBlack", "ScanlineBlack", "line", "Hard black scanlines"),
    ("PixelatedSquare", "PixelatedSquare", "pixelate", "Small square pixelation"),
    ("PixelateBlock", "PixelateBlock", "pixelate", "Six-pixel block sampling"),
    ("PixelateNoResize8", "PixelateNoResize8", "pixelate", "Eight-pixel block sampling"),
    ("PixelateNoResize12", "PixelateNoResize12", "pixelate", "Twelve-pixel block sampling"),
    ("PixelateNoResize16", "PixelateNoResize16", "pixelate", "Sixteen-pixel block sampling"),
    ("PixelateNoResize24", "PixelateNoResize24", "pixelate", "Twenty-four-pixel block sampling"),
    ("PixelateNoResize32", "PixelateNoResize32", "pixelate", "Thirty-two-pixel block sampling"),
    ("PixelateRect", "PixelateRect", "pixelate", "Adjustable rectangular pixelation"),
    ("Block", "Block", "block", "Source and block-color blend"),
    ("BlockXor", "BlockXor", "block", "Block-sampled byte XOR"),
    ("BlockScale", "BlockScale", "block", "Scaled block byte color"),
    ("BlockStrobe", "BlockStrobe", "block", "Animated inverted blocks"),
    ("Bitwise_XOR", "Bitwise_XOR", "bitwise", "Byte XOR with adjustable mask"),
    ("Bitwise_AND", "Bitwise_AND", "bitwise", "Byte AND with adjustable mask"),
    ("Bitwise_OR", "Bitwise_OR", "bitwise", "Byte OR with adjustable mask"),
    ("Bitwise_Rotate", "BitwiseRotate", "bitwise", "Eight-bit channel rotation"),
    ("Bitwise_Rotate Diff", "BitwiseRotateDiff", "bitwise", "XOR with rotated channel bits"),
    ("BitwiseXorScale", "BitwiseXorScale", "bitwise", "XOR with scaled byte channels"),
    ("GradientRGB", "GradientRGB", "gradient", "RGB coordinate gradient modulation"),
    ("GradientLeftRight", "GradientLeftRight", "gradient", "Horizontal animated gradient"),
    ("GradientDown", "GradientDown", "gradient", "Vertical gradient modulation"),
    ("GradientColors", "GradientColors", "gradient", "Animated cosine palette"),
    ("Threshold", "Threshold", "threshold", "Per-channel threshold"),
    ("ThresholdDark", "ThresholdDark", "threshold", "Luma dark-threshold removal"),
]


def shader_name(display_name):
    value = re.sub(r"[^a-z0-9]+", "_", display_name.lower()).strip("_")
    return f"{value}.comp"


def write_shader(effect_id, display_name):
    path = COMPUTE_DIR / shader_name(display_name)
    path.write_text(
        "#version 450\n"
        f"#define AC_EFFECT_ID {effect_id}\n"
        '#include "include/filter_common.glsl"\n',
        encoding="utf-8",
    )
    return path.relative_to(ROOT).as_posix()


def main():
    COMPUTE_DIR.mkdir(parents=True, exist_ok=True)
    shader_paths = [
        write_shader(effect_id, item[0])
        for effect_id, item in enumerate(FILTERS)
    ]
    manifest = {
        "version": 1,
        "backend": "acmxvk",
        "library_type": "source",
        "custom_uniforms": {
            "amount": {"slot": 0, "minimum": 0.0, "maximum": 1.0, "step": 0.01, "value": 0.5},
            "scale_value": {"slot": 1, "minimum": 0.0, "maximum": 1.0, "step": 0.01, "value": 0.5},
            "speed": {"slot": 2, "minimum": 0.0, "maximum": 1.0, "step": 0.01, "value": 0.5},
            "mix_amount": {"slot": 3, "minimum": 0.0, "maximum": 1.0, "step": 0.01, "value": 1.0},
        },
        "shaders": shader_paths,
    }
    (ROOT / "library.json").write_text(
        json.dumps(manifest, indent=4) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
