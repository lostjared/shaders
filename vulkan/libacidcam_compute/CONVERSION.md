# libacidcam CPU-to-ACMXVK Conversion

This directory tracks standalone `libacidcam` CPU filters being converted into
ACMXVK compute shaders. The target is 300 high-value filters. Filters whose
names contain `SubFilter` and filters that invoke libacidcam's subfilter
dispatch mechanism are excluded.

## Progress

- Target: 300 shaders
- Source shaders created: 50
- Compile validated: 50
- Remaining: 250

The first batch establishes the shared ACMXVK compute ABI and covers direct
color, channel, geometry, scanline, pixelation, block, bitwise, gradient, and
threshold operations. `amount`, `scale_value`, `speed`, and `mix_amount` are
exposed through slots 0 through 3 in `library.json`.

## Conversion ledger

| # | libacidcam filter | CPU function | Family | Compute shader | Status | Notes |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | Blank | `Blank` | color | `compute/blank.comp` | Compiled | Black output |
| 2 | Negate | `Negate` | color | `compute/negate.comp` | Compiled | RGB inversion |
| 3 | Grayscale | `Grayscale` | color | `compute/grayscale.comp` | Compiled | Luma grayscale |
| 4 | Darken | `Darken` | color | `compute/darken.comp` | Compiled | Adjustable darkening |
| 5 | DarkNegate | `DarkNegate` | color | `compute/darknegate.comp` | Compiled | Dark inverted color |
| 6 | GammaDarken5 | `GammaDarken5` | color | `compute/gammadarken5.comp` | Compiled | Moderate gamma darkening |
| 7 | GammaDarken10 | `GammaDarken10` | color | `compute/gammadarken10.comp` | Compiled | Strong gamma darkening |
| 8 | All Red | `AllRed` | channel | `compute/all_red.comp` | Compiled | Red-channel isolation |
| 9 | All Green | `AllGreen` | channel | `compute/all_green.comp` | Compiled | Green-channel isolation |
| 10 | All Blue | `AllBlue` | channel | `compute/all_blue.comp` | Compiled | Blue-channel isolation |
| 11 | ColorOrderSwap | `ColorOrderSwap` | channel | `compute/colororderswap.comp` | Compiled | Fixed RGB permutation |
| 12 | ColorOrderSwapMap | `ColorOrderSwapMap` | channel | `compute/colororderswapmap.comp` | Compiled | Animated RGB permutation |
| 13 | FlipX_Axis | `FlipX_Axis` | geometry | `compute/flipx_axis.comp` | Compiled | Horizontal flip |
| 14 | FlipY_Axis | `FlipY_Axis` | geometry | `compute/flipy_axis.comp` | Compiled | Vertical flip |
| 15 | FlipBoth | `FlipBoth` | geometry | `compute/flipboth.comp` | Compiled | Horizontal and vertical flip |
| 16 | Sideways Mirror | `SidewaysMirror` | geometry | `compute/sideways_mirror.comp` | Compiled | Outward horizontal mirror |
| 17 | Mirror No Blend | `MirrorNoBlend` | geometry | `compute/mirror_no_blend.comp` | Compiled | Inward horizontal mirror |
| 18 | FlipBlendW | `FlipBlendW` | geometry | `compute/flipblendw.comp` | Compiled | Horizontal flip blend |
| 19 | FlipBlendH | `FlipBlendH` | geometry | `compute/flipblendh.comp` | Compiled | Vertical flip blend |
| 20 | FlipBlendWH | `FlipBlendWH` | geometry | `compute/flipblendwh.comp` | Compiled | Dual-axis flip blend |
| 21 | RGB Shift | `RGBShift` | channel | `compute/rgb_shift.comp` | Compiled | Separated red and blue sampling |
| 22 | RGB Sep | `RGBSep` | channel | `compute/rgb_sep.comp` | Compiled | Adjustable RGB separation |
| 23 | Scanlines | `Scanlines` | line | `compute/scanlines.comp` | Compiled | Alternating dark scanlines |
| 24 | InvertedScanlines | `InvertedScanlines` | line | `compute/invertedscanlines.comp` | Compiled | Alternating inverted scanlines |
| 25 | BlendedScanLines | `BlendedScanLines` | line | `compute/blendedscanlines.comp` | Compiled | Neighbor-blended scanlines |
| 26 | ScanlineBlack | `ScanlineBlack` | line | `compute/scanlineblack.comp` | Compiled | Hard black scanlines |
| 27 | PixelatedSquare | `PixelatedSquare` | pixelate | `compute/pixelatedsquare.comp` | Compiled | Small square pixelation |
| 28 | PixelateBlock | `PixelateBlock` | pixelate | `compute/pixelateblock.comp` | Compiled | Six-pixel block sampling |
| 29 | PixelateNoResize8 | `PixelateNoResize8` | pixelate | `compute/pixelatenoresize8.comp` | Compiled | Eight-pixel block sampling |
| 30 | PixelateNoResize12 | `PixelateNoResize12` | pixelate | `compute/pixelatenoresize12.comp` | Compiled | Twelve-pixel block sampling |
| 31 | PixelateNoResize16 | `PixelateNoResize16` | pixelate | `compute/pixelatenoresize16.comp` | Compiled | Sixteen-pixel block sampling |
| 32 | PixelateNoResize24 | `PixelateNoResize24` | pixelate | `compute/pixelatenoresize24.comp` | Compiled | Twenty-four-pixel block sampling |
| 33 | PixelateNoResize32 | `PixelateNoResize32` | pixelate | `compute/pixelatenoresize32.comp` | Compiled | Thirty-two-pixel block sampling |
| 34 | PixelateRect | `PixelateRect` | pixelate | `compute/pixelaterect.comp` | Compiled | Adjustable rectangular pixelation |
| 35 | Block | `Block` | block | `compute/block.comp` | Compiled | Source and block-color blend |
| 36 | BlockXor | `BlockXor` | block | `compute/blockxor.comp` | Compiled | Block-sampled byte XOR |
| 37 | BlockScale | `BlockScale` | block | `compute/blockscale.comp` | Compiled | Scaled block byte color |
| 38 | BlockStrobe | `BlockStrobe` | block | `compute/blockstrobe.comp` | Compiled | Animated inverted blocks |
| 39 | Bitwise_XOR | `Bitwise_XOR` | bitwise | `compute/bitwise_xor.comp` | Compiled | Byte XOR with adjustable mask |
| 40 | Bitwise_AND | `Bitwise_AND` | bitwise | `compute/bitwise_and.comp` | Compiled | Byte AND with adjustable mask |
| 41 | Bitwise_OR | `Bitwise_OR` | bitwise | `compute/bitwise_or.comp` | Compiled | Byte OR with adjustable mask |
| 42 | Bitwise_Rotate | `BitwiseRotate` | bitwise | `compute/bitwise_rotate.comp` | Compiled | Eight-bit channel rotation |
| 43 | Bitwise_Rotate Diff | `BitwiseRotateDiff` | bitwise | `compute/bitwise_rotate_diff.comp` | Compiled | XOR with rotated channel bits |
| 44 | BitwiseXorScale | `BitwiseXorScale` | bitwise | `compute/bitwisexorscale.comp` | Compiled | XOR with scaled byte channels |
| 45 | GradientRGB | `GradientRGB` | gradient | `compute/gradientrgb.comp` | Compiled | RGB coordinate gradient modulation |
| 46 | GradientLeftRight | `GradientLeftRight` | gradient | `compute/gradientleftright.comp` | Compiled | Horizontal animated gradient |
| 47 | GradientDown | `GradientDown` | gradient | `compute/gradientdown.comp` | Compiled | Vertical gradient modulation |
| 48 | GradientColors | `GradientColors` | gradient | `compute/gradientcolors.comp` | Compiled | Animated cosine palette |
| 49 | Threshold | `Threshold` | threshold | `compute/threshold.comp` | Compiled | Per-channel threshold |
| 50 | ThresholdDark | `ThresholdDark` | threshold | `compute/thresholddark.comp` | Compiled | Luma dark-threshold removal |

## Validation policy

Each batch must compile through ACMXVK's source-library builder before its
status is changed to `Compiled`. Batch 1 compiled all 50 sources with zero
failures using the ACMXVK builder. Visual equivalence is tracked separately from
compiler validation because some CPU filters depend on mutable static values
whose GPU equivalents use the normalized library controls and ACMXVK shader
timeline.
