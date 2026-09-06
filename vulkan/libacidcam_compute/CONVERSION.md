# libacidcam CPU-to-ACMXVK Conversion

This directory tracks standalone `libacidcam` CPU filters being converted into
ACMXVK compute shaders. The target is 300 high-value filters. Filters whose
names contain `SubFilter` and filters that invoke libacidcam's subfilter
dispatch mechanism are excluded.

## Progress

- Target: 300 shaders
- Source shaders created: 300
- Compile validated: 300
- Remaining: 0

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
| 51 | Flash Black | `FlashBlack` | strobe | `compute/flash_black.comp` | Compiled | Alternating source and black |
| 52 | FlashWhite | `FlashWhite` | strobe | `compute/flashwhite.comp` | Compiled | Alternating source and white |
| 53 | FlashBlackAndWhite | `FlashBlackAndWhite` | strobe | `compute/flashblackandwhite.comp` | Compiled | Black-and-white flash |
| 54 | Strobe Red Then Green Then Blue | `StrobeRedGreenBlue` | strobe | `compute/strobe_red_then_green_then_blue.comp` | Compiled | Cycling isolated RGB channels |
| 55 | RGBFlash | `RGBFlash` | strobe | `compute/rgbflash.comp` | Compiled | Animated RGB color flash |
| 56 | StrobeScan | `StrobeScan` | strobe | `compute/strobescan.comp` | Compiled | Moving luminous scan band |
| 57 | NegativeStrobe | `NegativeStrobe` | strobe | `compute/negativestrobe.comp` | Compiled | Source and negative strobe |
| 58 | BrightStrobe | `BrightStrobe` | strobe | `compute/brightstrobe.comp` | Compiled | Brightness strobe |
| 59 | DarkStrobe | `DarkStrobe` | strobe | `compute/darkstrobe.comp` | Compiled | Darkness strobe |
| 60 | HalfNegateStrobe | `HalfNegateStrobe` | strobe | `compute/halfnegatestrobe.comp` | Compiled | Moving partial negative |
| 61 | FadeStrobe | `FadeStrobe` | strobe | `compute/fadestrobe.comp` | Compiled | Smooth source-to-negative fade |
| 62 | MirrorStrobe | `MirrorStrobe` | strobe | `compute/mirrorstrobe.comp` | Compiled | Alternating source and mirror |
| 63 | AndStrobe | `AndStrobe` | strobe | `compute/andstrobe.comp` | Compiled | Animated byte AND mask |
| 64 | OrStrobe | `OrStrobe` | strobe | `compute/orstrobe.comp` | Compiled | Animated byte OR mask |
| 65 | RandomStrobeFlash | `RandomStrobeFlash` | strobe | `compute/randomstrobeflash.comp` | Compiled | Frame-seeded negative flashes |
| 66 | ScaleFlash | `ScaleFlash` | strobe | `compute/scaleflash.comp` | Compiled | Animated center zoom |
| 67 | ColorFlashIncrease | `ColorFlashIncrease` | strobe | `compute/colorflashincrease.comp` | Compiled | Additive animated color flash |
| 68 | Wave | `Wave` | distort | `compute/wave.comp` | Compiled | Horizontal sine displacement |
| 69 | HighWave | `HighWave` | distort | `compute/highwave.comp` | Compiled | High-amplitude sine displacement |
| 70 | Double Vision | `DoubleVision` | distort | `compute/double_vision.comp` | Compiled | Symmetric offset blend |
| 71 | SlideRGB | `SlideRGB` | distort | `compute/slidergb.comp` | Compiled | Multi-axis RGB displacement |
| 72 | Side2Side | `Side2Side` | distort | `compute/side2side.comp` | Compiled | Animated horizontal slide |
| 73 | Top2Bottom | `Top2Bottom` | distort | `compute/top2bottom.comp` | Compiled | Animated vertical slide |
| 74 | Outward | `Outward` | distort | `compute/outward.comp` | Compiled | Animated center expansion |
| 75 | Outward Square | `OutwardSquare` | distort | `compute/outward_square.comp` | Compiled | Square-distance expansion |
| 76 | ShiftPixels | `ShiftPixels` | distort | `compute/shiftpixels.comp` | Compiled | Row-band horizontal displacement |
| 77 | ShiftPixelsDown | `ShiftPixelsDown` | distort | `compute/shiftpixelsdown.comp` | Compiled | Column-band vertical displacement |
| 78 | DiagonalLines | `DiagonalLines` | line | `compute/diagonallines.comp` | Compiled | Animated diagonal line modulation |
| 79 | HorizontalLines | `HorizontalLines` | line | `compute/horizontallines.comp` | Compiled | Animated horizontal line modulation |
| 80 | Lines | `Lines` | line | `compute/lines.comp` | Compiled | Crossed animated line modulation |
| 81 | WhiteLines | `WhiteLines` | line | `compute/whitelines.comp` | Compiled | Thin white line overlay |
| 82 | ThickWhiteLines | `ThickWhiteLines` | line | `compute/thickwhitelines.comp` | Compiled | Thick white line overlay |
| 83 | GradientLines | `GradientLines` | gradient | `compute/gradientlines.comp` | Compiled | Rainbow diagonal gradient lines |
| 84 | GradientSelf | `GradientSelf` | gradient | `compute/gradientself.comp` | Compiled | Horizontal self-gradient |
| 85 | GradientSelfVertical | `GradientSelfVertical` | gradient | `compute/gradientselfvertical.comp` | Compiled | Vertical self-gradient |
| 86 | GradientStripes | `GradientStripes` | gradient | `compute/gradientstripes.comp` | Compiled | Animated color stripes |
| 87 | GradientReverse | `GradientReverse` | gradient | `compute/gradientreverse.comp` | Compiled | Reverse horizontal gradient |
| 88 | GradientReverseVertical | `GradientReverseVertical` | gradient | `compute/gradientreversevertical.comp` | Compiled | Reverse vertical gradient |
| 89 | GradientReverseBox | `GradientReverseBox` | gradient | `compute/gradientreversebox.comp` | Compiled | Repeated box gradient |
| 90 | GradientNewFilter | `GradientNewFilter` | gradient | `compute/gradientnewfilter.comp` | Compiled | Animated palette modulation |
| 91 | GradientLeftRightInOut | `GradientLeftRightInOut` | gradient | `compute/gradientleftrightinout.comp` | Compiled | Centered horizontal gradient |
| 92 | GradientUpDownInOut | `GradientUpDownInOut` | gradient | `compute/gradientupdowninout.comp` | Compiled | Centered vertical gradient |
| 93 | SquareBars | `SquareBars` | grid | `compute/squarebars.comp` | Compiled | Alternating square bar sampling |
| 94 | SquareBars8 | `SquareBars8` | grid | `compute/squarebars8.comp` | Compiled | Eight-pixel square bars |
| 95 | SquareVertical8 | `SquareVertical8` | grid | `compute/squarevertical8.comp` | Compiled | Eight-pixel vertical mirror bars |
| 96 | SquareVertical16 | `SquareVertical16` | grid | `compute/squarevertical16.comp` | Compiled | Sixteen-pixel vertical mirror bars |
| 97 | GridFilter8x | `GridFilter8x` | grid | `compute/gridfilter8x.comp` | Compiled | Eight-pixel grid sampling |
| 98 | GridFilter16x | `GridFilter16x` | grid | `compute/gridfilter16x.comp` | Compiled | Sixteen-pixel grid sampling |
| 99 | GridFilter8xBlend | `GridFilter8xBlend` | grid | `compute/gridfilter8xblend.comp` | Compiled | Blended eight-pixel grid |
| 100 | Circular | `Circular` | distort | `compute/circular.comp` | Compiled | Polar circular distortion |
| 101 | Self AlphaBlend | `SelfAlphaBlend` | blend | `compute/self_alphablend.comp` | Compiled | Adjustable nearby-pixel self blend |
| 102 | Self Scale | `SelfScale` | color | `compute/self_scale.comp` | Compiled | Wrapped byte-channel scaling |
| 103 | Blend #3 | `Blend3` | blend | `compute/blend_3.comp` | Compiled | Source and dual-flip average |
| 104 | MirrorBlend | `MirrorBlend` | mirror | `compute/mirrorblend.comp` | Compiled | Adjustable horizontal mirror blend |
| 105 | Mirror Average | `MirrorAverage` | mirror | `compute/mirror_average.comp` | Compiled | Horizontal mirror average |
| 106 | Mirror Average Mix | `MirrorAverageMix` | mirror | `compute/mirror_average_mix.comp` | Compiled | Source and dual-mirror mix |
| 107 | MoveRed | `MoveRed` | channel | `compute/movered.comp` | Compiled | Animated red-channel displacement |
| 108 | MoveRGB | `MoveRGB` | channel | `compute/movergb.comp` | Compiled | Animated three-channel displacement |
| 109 | MoveRedGreenBlue | `MoveRedGreenBlue` | channel | `compute/moveredgreenblue.comp` | Compiled | Diagonal RGB displacement |
| 110 | HorizontalBlend | `HorizontalBlend` | blend | `compute/horizontalblend.comp` | Compiled | Horizontal neighbor blend |
| 111 | VerticalBlend | `VerticalBlend` | blend | `compute/verticalblend.comp` | Compiled | Vertical neighbor blend |
| 112 | OppositeBlend | `OppositeBlend` | blend | `compute/oppositeblend.comp` | Compiled | Opposite-coordinate blend |
| 113 | Soft_Mirror | `Soft_Mirror` | mirror | `compute/soft_mirror.comp` | Compiled | Edge-weighted mirror |
| 114 | ColorMorphing | `ColorMorphing` | color | `compute/colormorphing.comp` | Compiled | Animated source-driven palette |
| 115 | LineRGB | `LineRGB` | channel | `compute/linergb.comp` | Compiled | RGB channel line bands |
| 116 | PixelRGB | `PixelRGB` | channel | `compute/pixelrgb.comp` | Compiled | RGB channel pixel pattern |
| 117 | BoxedRGB | `BoxedRGB` | channel | `compute/boxedrgb.comp` | Compiled | RGB channel block pattern |
| 118 | ColorRange | `ColorRange` | color | `compute/colorrange.comp` | Compiled | Adjustable color quantization |
| 119 | InterMirror | `InterMirror` | mirror | `compute/intermirror.comp` | Compiled | Interlaced horizontal mirror |
| 120 | InterFullMirror | `InterFullMirror` | mirror | `compute/interfullmirror.comp` | Compiled | Checkerboard dual-axis mirror |
| 121 | MirrorRGB | `MirrorRGB` | mirror | `compute/mirrorrgb.comp` | Compiled | Mirror-separated RGB channels |
| 122 | AverageVertical | `AverageVertical` | blend | `compute/averagevertical.comp` | Compiled | Three-sample vertical average |
| 123 | RGBMirror | `RGBMirror` | mirror | `compute/rgbmirror.comp` | Compiled | RGB dual-axis mirror |
| 124 | RandomXorOpposite | `RandomXorOpposite` | bitwise | `compute/randomxoropposite.comp` | Compiled | Seeded opposite-pixel XOR |
| 125 | RandomMirror | `RandomMirror` | mirror | `compute/randommirror.comp` | Compiled | Frame-selected mirror axis |
| 126 | RandomMirrorBlend | `RandomMirrorBlend` | mirror | `compute/randommirrorblend.comp` | Compiled | Adjustable random-axis mirror blend |
| 127 | RandomMirrorAlphaBlend | `RandomMirrorAlphaBlend` | mirror | `compute/randommirroralphablend.comp` | Compiled | Seeded random mirror alpha |
| 128 | MirrorXor | `MirrorXor` | bitwise | `compute/mirrorxor.comp` | Compiled | Source and horizontal-mirror XOR |
| 129 | MirrorXorAll | `MirrorXorAll` | bitwise | `compute/mirrorxorall.comp` | Compiled | Source and dual-mirror XOR |
| 130 | MirrorXorScale | `MirrorXorScale` | bitwise | `compute/mirrorxorscale.comp` | Compiled | Scaled mirror byte XOR |
| 131 | EnergyMirror | `EnergyMirror` | mirror | `compute/energymirror.comp` | Compiled | Amplified mirror difference |
| 132 | MirrorXorAlpha | `MirrorXorAlpha` | bitwise | `compute/mirrorxoralpha.comp` | Compiled | Alpha blend with mirror XOR |
| 133 | FlipMirror | `FlipMirror` | mirror | `compute/flipmirror.comp` | Compiled | Split-axis mirror |
| 134 | FlipMirrorAverage | `FlipMirrorAverage` | mirror | `compute/flipmirroraverage.comp` | Compiled | Average of source and axis mirrors |
| 135 | AlphaBlendWithSource | `AlphaBlendWithSource` | blend | `compute/alphablendwithsource.comp` | Compiled | Adjustable scaled-source blend |
| 136 | RGBMirror1 | `RGBMirror1` | mirror | `compute/rgbmirror1.comp` | Compiled | Reordered mirrored RGB channels |
| 137 | FlashMirror | `FlashMirror` | mirror | `compute/flashmirror.comp` | Compiled | Mirror negative flash |
| 138 | ReverseMirrorX | `ReverseMirrorX` | mirror | `compute/reversemirrorx.comp` | Compiled | Reverse folded mirror |
| 139 | MirrorXorAll_Reverse | `MirrorXorAll_Reverse` | bitwise | `compute/mirrorxorall_reverse.comp` | Compiled | Reverse all-mirror XOR |
| 140 | MirrorRGBReverse | `MirrorRGBReverse` | mirror | `compute/mirrorrgbreverse.comp` | Compiled | Reverse mirrored channels |
| 141 | MirrorRGBReverseBlend | `MirrorRGBReverseBlend` | mirror | `compute/mirrorrgbreverseblend.comp` | Compiled | Reverse mirror channel blend |
| 142 | MirrorBitwiseXor | `MirrorBitwiseXor` | bitwise | `compute/mirrorbitwisexor.comp` | Compiled | Rotated-bit mirror XOR |
| 143 | AlphaBlendMirror | `AlphaBlendMirror` | mirror | `compute/alphablendmirror.comp` | Compiled | Dual-mirror alpha blend |
| 144 | TwistedMirror | `TwistedMirror` | mirror | `compute/twistedmirror.comp` | Compiled | Polar twisted mirror |
| 145 | FlipAlphaBlend | `FlipAlphaBlend` | blend | `compute/flipalphablend.comp` | Compiled | Animated axis-flip blend |
| 146 | MirrorMedian | `MirrorMedian` | mirror | `compute/mirrormedian.comp` | Compiled | Mirror and horizontal-neighbor median |
| 147 | MirrorAlphaBlend | `MirrorAlphaBlend` | mirror | `compute/mirroralphablend.comp` | Compiled | Source and dual-mirror blend |
| 148 | MirrorEachSecond | `MirrorEachSecond` | mirror | `compute/mirroreachsecond.comp` | Compiled | Timeline-selected mirror mode |
| 149 | Mirror_Xor_Combined | `Mirror_Xor_Combined` | bitwise | `compute/mirror_xor_combined.comp` | Compiled | Combined mirror average XOR |
| 150 | MirrorVerticalAndHorizontal | `MirrorVerticalAndHorizontal` | mirror | `compute/mirrorverticalandhorizontal.comp` | Compiled | Four-way mirror average |
| 151 | Tri | `Tri` | geometry | `compute/tri.comp` | Compiled | Animated triangular color geometry |
| 152 | Distort | `Distort` | distort | `compute/distort.comp` | Compiled | Two-axis sine distortion |
| 153 | CosSinMultiply | `cossinMultiply` | color | `compute/cossinmultiply.comp` | Compiled | Cosine and sine color modulation |
| 154 | Pixel Scale | `pixelScale` | pixelate | `compute/pixel_scale.comp` | Compiled | Animated pixel-block scaling |
| 155 | Boxes | `Boxes` | grid | `compute/boxes.comp` | Compiled | Adjustable box grid |
| 156 | Boxes Fade | `BoxesFade` | grid | `compute/boxes_fade.comp` | Compiled | Animated fading box grid |
| 157 | WhitePixel | `WhitePixel` | pixelate | `compute/whitepixel.comp` | Compiled | Sparse animated white pixels |
| 158 | FourSquare | `FourSquare` | geometry | `compute/foursquare.comp` | Compiled | Four-way tiled reflection |
| 159 | EightSquare | `EightSquare` | geometry | `compute/eightsquare.comp` | Compiled | Eight-way tiled reflection |
| 160 | DiagonalSquare | `DiagonalSquare` | geometry | `compute/diagonalsquare.comp` | Compiled | Diagonal square displacement |
| 161 | DiagonalSquareRandom | `DiagonalSquareRandom` | geometry | `compute/diagonalsquarerandom.comp` | Compiled | Random diagonal square displacement |
| 162 | SquareStretchDown | `SquareStretchDown` | distort | `compute/squarestretchdown.comp` | Compiled | Downward square-band stretch |
| 163 | SquareStretchRight | `SquareStretchRight` | distort | `compute/squarestretchright.comp` | Compiled | Rightward square-band stretch |
| 164 | SquareStretchUp | `SquareStretchUp` | distort | `compute/squarestretchup.comp` | Compiled | Upward square-band stretch |
| 165 | SquareStretchLeft | `SquareStretchLeft` | distort | `compute/squarestretchleft.comp` | Compiled | Leftward square-band stretch |
| 166 | RandomQuads | `RandomQuads` | geometry | `compute/randomquads.comp` | Compiled | Seeded quadrant transforms |
| 167 | GridRandom | `GridRandom` | grid | `compute/gridrandom.comp` | Compiled | Seeded grid-cell displacement |
| 168 | GridRandomPixel | `GridRandomPixel` | grid | `compute/gridrandompixel.comp` | Compiled | Seeded grid pixel replacement |
| 169 | Curtain | `Curtain` | distort | `compute/curtain.comp` | Compiled | Horizontal curtain folds |
| 170 | RandomCurtain | `RandomCurtain` | distort | `compute/randomcurtain.comp` | Compiled | Random horizontal curtain folds |
| 171 | CurtainVertical | `CurtainVertical` | distort | `compute/curtainvertical.comp` | Compiled | Vertical curtain folds |
| 172 | RandomCurtainVertical | `RandomCurtainVertical` | distort | `compute/randomcurtainvertical.comp` | Compiled | Random vertical curtain folds |
| 173 | SlideFilter | `SlideFilter` | distort | `compute/slidefilter.comp` | Compiled | Alternating horizontal slides |
| 174 | SlideFilterXor | `SlideFilterXor` | bitwise | `compute/slidefilterxor.comp` | Compiled | Horizontal slide byte XOR |
| 175 | RandomSlideFilter | `RandomSlideFilter` | distort | `compute/randomslidefilter.comp` | Compiled | Seeded horizontal slides |
| 176 | SlideUpDown | `SlideUpDown` | distort | `compute/slideupdown.comp` | Compiled | Alternating vertical slides |
| 177 | SlideUpDownXor | `SlideUpDownXor` | bitwise | `compute/slideupdownxor.comp` | Compiled | Vertical slide byte XOR |
| 178 | SlideUpDownRandom | `SlideUpDownRandom` | distort | `compute/slideupdownrandom.comp` | Compiled | Seeded vertical slides |
| 179 | StretchOutward | `StretchOutward` | distort | `compute/stretchoutward.comp` | Compiled | Animated outward stretch |
| 180 | ExpandFrame | `ExpandFrame` | distort | `compute/expandframe.comp` | Compiled | Animated frame expansion |
| 181 | RotateFrame | `RotateFrame` | geometry | `compute/rotateframe.comp` | Compiled | Continuous frame rotation |
| 182 | RotateFrameReverse | `RotateFrameReverse` | geometry | `compute/rotateframereverse.comp` | Compiled | Reverse frame rotation |
| 183 | RotateSet | `RotateSet` | geometry | `compute/rotateset.comp` | Compiled | Stepped frame rotation |
| 184 | RotateSetReverse | `RotateSetReverse` | geometry | `compute/rotatesetreverse.comp` | Compiled | Reverse stepped rotation |
| 185 | PixelateExpandDistort | `PixelateExpandDistort` | pixelate | `compute/pixelateexpanddistort.comp` | Compiled | Pixelated radial expansion |
| 186 | PixelateExpandDistortX | `PixelateExpandDistortX` | pixelate | `compute/pixelateexpanddistortx.comp` | Compiled | Pixelated horizontal expansion |
| 187 | PixelateExpandDistortY | `PixelateExpandDistortY` | pixelate | `compute/pixelateexpanddistorty.comp` | Compiled | Pixelated vertical expansion |
| 188 | PixelateExpandDistortExtra | `PixelateExpandDistortExtra` | pixelate | `compute/pixelateexpanddistortextra.comp` | Compiled | Layered pixel expansion distortion |
| 189 | DistortPixelate | `DistortPixelate` | pixelate | `compute/distortpixelate.comp` | Compiled | Wave-distorted pixelation |
| 190 | PixelateSquares | `PixelateSquares` | pixelate | `compute/pixelatesquares.comp` | Compiled | Checker-scaled square pixelation |
| 191 | DiagPixel | `DiagPixel` | distort | `compute/diagpixel.comp` | Compiled | Diagonal pixel displacement |
| 192 | DiagPixelY | `DiagPixelY` | distort | `compute/diagpixely.comp` | Compiled | Vertical diagonal displacement |
| 193 | DiagPixelY2 | `DiagPixelY2` | distort | `compute/diagpixely2.comp` | Compiled | Alternating vertical diagonal displacement |
| 194 | DiagPixelY3 | `DiagPixelY3` | distort | `compute/diagpixely3.comp` | Compiled | Layered vertical diagonal displacement |
| 195 | DiagPixelY4 | `DiagPixelY4` | distort | `compute/diagpixely4.comp` | Compiled | RGB vertical diagonal displacement |
| 196 | DiagSquare | `DiagSquare` | geometry | `compute/diagsquare.comp` | Compiled | Diagonal square-band sampling |
| 197 | DiagSquareLarge | `DiagSquareLarge` | geometry | `compute/diagsquarelarge.comp` | Compiled | Large diagonal square-band sampling |
| 198 | ExpandLeftRight | `ExpandLeftRight` | distort | `compute/expandleftright.comp` | Compiled | Horizontal center expansion |
| 199 | ShiftPixelsRGB | `ShiftPixelsRGB` | channel | `compute/shiftpixelsrgb.comp` | Compiled | Independent RGB pixel shifts |
| 200 | JaggedLine | `JaggedLine` | distort | `compute/jaggedline.comp` | Compiled | Seeded jagged line displacement |
| 201 | ScratchyTrails | `ScratchyTrails` | trail | `compute/scratchytrails.comp` | Compiled | Scratch-like offset color trails |
| 202 | ExpandPixelate | `ExpandPixelate` | pixelate | `compute/expandpixelate.comp` | Compiled | Expanding pixel blocks |
| 203 | DiagSquare8 | `DiagSquare8` | geometry | `compute/diagsquare8.comp` | Compiled | Eight-pixel diagonal squares |
| 204 | DiagSquareRandom | `DiagSquareRandom` | geometry | `compute/diagsquarerandom.comp` | Compiled | Seeded diagonal square shifts |
| 205 | DiagSquareX | `DiagSquareX` | geometry | `compute/diagsquarex.comp` | Compiled | Crossed diagonal square shifts |
| 206 | SquareShiftDirRGB | `SquareShiftDirRGB` | channel | `compute/squareshiftdirrgb.comp` | Compiled | Directional square RGB shifts |
| 207 | StretchLineRowIncRGB | `StretchLineRowIncRGB` | channel | `compute/stretchlinerowincrgb.comp` | Compiled | Increasing row RGB stretch |
| 208 | StretchLineColIncRGB | `StretchLineColIncRGB` | channel | `compute/stretchlinecolincrgb.comp` | Compiled | Increasing column RGB stretch |
| 209 | StretchLineRowIncSource | `StretchLineRowIncSource` | distort | `compute/stretchlinerowincsource.comp` | Compiled | Increasing source row stretch |
| 210 | StretchLineColIncSource | `StretchLineColIncSource` | distort | `compute/stretchlinecolincsource.comp` | Compiled | Increasing source column stretch |
| 211 | AlternateAlpha | `AlternateAlpha` | blend | `compute/alternatealpha.comp` | Compiled | Alternating source alpha modulation |
| 212 | Square_Block_Resize_Vertical_RGB | `Square_Block_Resize_Vertical_RGB` | channel | `compute/square_block_resize_vertical_rgb.comp` | Compiled | Vertical block RGB resize |
| 213 | DiagSquareRGB | `DiagSquareRGB` | channel | `compute/diagsquarergb.comp` | Compiled | Diagonal square RGB separation |
| 214 | Square_Block_Resize_RGB | `Square_Block_Resize_RGB` | channel | `compute/square_block_resize_rgb.comp` | Compiled | Square block RGB resize |
| 215 | VariableLinesY_RGB | `VariableLinesY_RGB` | channel | `compute/variablelinesy_rgb.comp` | Compiled | Variable vertical RGB lines |
| 216 | SquareShiftDirGradient | `SquareShiftDirGradient` | gradient | `compute/squareshiftdirgradient.comp` | Compiled | Directional square gradient shifts |
| 217 | BlendWithSourcePercent | `BlendWithSourcePercent` | blend | `compute/blendwithsourcepercent.comp` | Compiled | Animated source percentage blend |
| 218 | ReverseRandom | `ReverseRandom` | geometry | `compute/reverserandom.comp` | Compiled | Seeded random reversal |
| 219 | SquareBlockGlitch | `SquareBlockGlitch` | glitch | `compute/squareblockglitch.comp` | Compiled | Seeded square block glitch |
| 220 | SquareStretchRows | `SquareStretchRows` | distort | `compute/squarestretchrows.comp` | Compiled | Alternating stretched rows |
| 221 | SquareStretchRowsDelay | `SquareStretchRowsDelay` | distort | `compute/squarestretchrowsdelay.comp` | Compiled | Delayed stretched rows |
| 222 | SquareStretchEven | `SquareStretchEven` | distort | `compute/squarestretcheven.comp` | Compiled | Even-band square stretch |
| 223 | SketchFilter | `SketchFilter` | edge | `compute/sketchfilter.comp` | Compiled | Monochrome sketch edges |
| 224 | SquareStretchEven32 | `SquareStretchEven32` | distort | `compute/squarestretcheven32.comp` | Compiled | Wide even-band square stretch |
| 225 | RGBLineFuzz | `RGBLineFuzz` | channel | `compute/rgblinefuzz.comp` | Compiled | Vertical RGB line fuzz |
| 226 | RGBLineFuzzX | `RGBLineFuzzX` | channel | `compute/rgblinefuzzx.comp` | Compiled | Horizontal RGB line fuzz |
| 227 | LinesAcrossX | `LinesAcrossX` | line | `compute/linesacrossx.comp` | Compiled | Animated lines across rows |
| 228 | XorLineX | `XorLineX` | bitwise | `compute/xorlinex.comp` | Compiled | Row line byte XOR |
| 229 | AlphaComponentIncrease | `AlphaComponentIncrease` | color | `compute/alphacomponentincrease.comp` | Compiled | Animated component amplification |
| 230 | ExpandContract | `ExpandContract` | distort | `compute/expandcontract.comp` | Compiled | Alternating expansion and contraction |
| 231 | MoveInThenMoveOut | `MoveInThenMoveOut` | distort | `compute/moveinthenmoveout.comp` | Compiled | Slow inward and outward motion |
| 232 | MoveInThenMoveOutFast | `MoveInThenMoveOutFast` | distort | `compute/moveinthenmoveoutfast.comp` | Compiled | Fast inward and outward motion |
| 233 | DistortionFuzz | `DistortionFuzz` | glitch | `compute/distortionfuzz.comp` | Compiled | Seeded two-axis distortion fuzz |
| 234 | DistortionByRow | `DistortionByRow` | distort | `compute/distortionbyrow.comp` | Compiled | Progressive row distortion |
| 235 | DistortionByRowRev | `DistortionByRowRev` | distort | `compute/distortionbyrowrev.comp` | Compiled | Reverse progressive row distortion |
| 236 | DistortionByRowVar | `DistortionByRowVar` | distort | `compute/distortionbyrowvar.comp` | Compiled | Oscillating row distortion |
| 237 | DistortionByRowRand | `DistortionByRowRand` | distort | `compute/distortionbyrowrand.comp` | Compiled | Seeded row distortion |
| 238 | DistortionByCol | `DistortionByCol` | distort | `compute/distortionbycol.comp` | Compiled | Progressive column distortion |
| 239 | DistortionByColRand | `DistortionByColRand` | distort | `compute/distortionbycolrand.comp` | Compiled | Seeded column distortion |
| 240 | DistortionByColVar | `DistortionByColVar` | distort | `compute/distortionbycolvar.comp` | Compiled | Oscillating column distortion |
| 241 | LongLines | `LongLines` | line | `compute/longlines.comp` | Compiled | Long displaced horizontal lines |
| 242 | TearRight | `TearRight` | glitch | `compute/tearright.comp` | Compiled | Rightward image tearing |
| 243 | TearDown | `TearDown` | glitch | `compute/teardown.comp` | Compiled | Downward image tearing |
| 244 | TearUp | `TearUp` | glitch | `compute/tearup.comp` | Compiled | Upward image tearing |
| 245 | TearLeft | `TearLeft` | glitch | `compute/tearleft.comp` | Compiled | Leftward image tearing |
| 246 | DistortStretch | `DistortStretch` | distort | `compute/distortstretch.comp` | Compiled | Layered stretch distortion |
| 247 | FadeOnOff | `FadeOnOff` | strobe | `compute/fadeonoff.comp` | Compiled | Smooth fade on and off |
| 248 | Stereo | `Stereo` | channel | `compute/stereo.comp` | Compiled | Stereo red-cyan separation |
| 249 | ShiftLinesDown | `ShiftLinesDown` | distort | `compute/shiftlinesdown.comp` | Compiled | Downward shifted line bands |
| 250 | VisualSnow | `VisualSnow` | noise | `compute/visualsnow.comp` | Compiled | Animated monochrome visual snow |
| 251 | VisualSnowX2 | `VisualSnowX2` | noise | `compute/visualsnowx2.comp` | Compiled | Dense animated color snow |
| 252 | LineGlitch | `LineGlitch` | glitch | `compute/lineglitch.comp` | Compiled | Seeded horizontal line glitch |
| 253 | SlitReverse64 | `SlitReverse64` | geometry | `compute/slitreverse64.comp` | Compiled | Reversed sixty-four-pixel slits |
| 254 | SlitReverse64_Increase | `SlitReverse64_Increase` | geometry | `compute/slitreverse64_increase.comp` | Compiled | Expanding reversed slits |
| 255 | SlitStretch | `SlitStretch` | distort | `compute/slitstretch.comp` | Compiled | Animated slit stretching |
| 256 | LineLeftRight | `LineLeftRight` | distort | `compute/lineleftright.comp` | Compiled | Alternating left-right lines |
| 257 | LineLeftRightResize | `LineLeftRightResize` | distort | `compute/lineleftrightresize.comp` | Compiled | Resized alternating line shifts |
| 258 | RGBLineTrails | `RGBLineTrails` | trail | `compute/rgblinetrails.comp` | Compiled | Separated RGB line trails |
| 259 | RGBCollectionBlend | `RGBCollectionBlend` | trail | `compute/rgbcollectionblend.comp` | Compiled | Offset RGB trail blend |
| 260 | RGBCollectionIncrease | `RGBCollectionIncrease` | trail | `compute/rgbcollectionincrease.comp` | Compiled | Increasing RGB trail separation |
| 261 | RGBCollectionEx | `RGBCollectionEx` | trail | `compute/rgbcollectionex.comp` | Compiled | Extended RGB trail blend |
| 262 | RGBLongTrails | `RGBLongTrails` | trail | `compute/rgblongtrails.comp` | Compiled | Long RGB displacement trails |
| 263 | FadeRGB_Speed | `FadeRGB_Speed` | color | `compute/fadergb_speed.comp` | Compiled | Speed-controlled RGB fading |
| 264 | RGBStrobeTrails | `RGBStrobeTrails` | trail | `compute/rgbstrobetrails.comp` | Compiled | Strobing RGB trails |
| 265 | FadeRGB_Variable | `FadeRGB_Variable` | color | `compute/fadergb_variable.comp` | Compiled | Variable RGB channel fading |
| 266 | BoxGlitch | `BoxGlitch` | glitch | `compute/boxglitch.comp` | Compiled | Seeded box displacement glitch |
| 267 | VerticalPictureDistort | `VerticalPictureDistort` | distort | `compute/verticalpicturedistort.comp` | Compiled | Vertical picture distortion |
| 268 | ShortTrail | `ShortTrail` | trail | `compute/shorttrail.comp` | Compiled | Short directional trail |
| 269 | DiagInward | `DiagInward` | geometry | `compute/diaginward.comp` | Compiled | Diagonal inward sampling |
| 270 | DiagSquareInward | `DiagSquareInward` | geometry | `compute/diagsquareinward.comp` | Compiled | Inward diagonal squares |
| 271 | DiagSquareInwardResize | `DiagSquareInwardResize` | geometry | `compute/diagsquareinwardresize.comp` | Compiled | Resized inward diagonal squares |
| 272 | DiagSquareInwardResizeXY | `DiagSquareInwardResizeXY` | geometry | `compute/diagsquareinwardresizexy.comp` | Compiled | Two-axis resized inward squares |
| 273 | ParticleSlide | `ParticleSlide` | glitch | `compute/particleslide.comp` | Compiled | Particle-like sliding blocks |
| 274 | DiagPixelated | `DiagPixelated` | pixelate | `compute/diagpixelated.comp` | Compiled | Diagonal pixelation |
| 275 | DiagPixelatedResize | `DiagPixelatedResize` | pixelate | `compute/diagpixelatedresize.comp` | Compiled | Resized diagonal pixelation |
| 276 | DiagPixelRGB_Collection | `DiagPixelRGB_Collection` | channel | `compute/diagpixelrgb_collection.comp` | Compiled | Diagonal RGB pixel trails |
| 277 | RGBShiftTrails | `RGBShiftTrails` | trail | `compute/rgbshifttrails.comp` | Compiled | Animated RGB shift trails |
| 278 | PictureShiftDown | `PictureShiftDown` | distort | `compute/pictureshiftdown.comp` | Compiled | Downward picture shift |
| 279 | PictureShiftRight | `PictureShiftRight` | distort | `compute/pictureshiftright.comp` | Compiled | Rightward picture shift |
| 280 | PictureShiftDownRight | `PictureShiftDownRight` | distort | `compute/pictureshiftdownright.comp` | Compiled | Diagonal picture shift |
| 281 | FlipPictureShift | `FlipPictureShift` | geometry | `compute/flippictureshift.comp` | Compiled | Flipped picture shifting |
| 282 | FlipPictureRandomMirror | `FlipPictureRandomMirror` | geometry | `compute/flippicturerandommirror.comp` | Compiled | Random flipped mirror |
| 283 | PictureShiftVariable | `PictureShiftVariable` | distort | `compute/pictureshiftvariable.comp` | Compiled | Variable picture shifting |
| 284 | RGBWideTrails | `RGBWideTrails` | trail | `compute/rgbwidetrails.comp` | Compiled | Wide RGB displacement trails |
| 285 | StretchR_Right | `StretchR_Right` | channel | `compute/stretchr_right.comp` | Compiled | Rightward red stretch |
| 286 | StretchG_Right | `StretchG_Right` | channel | `compute/stretchg_right.comp` | Compiled | Rightward green stretch |
| 287 | StretchB_Right | `StretchB_Right` | channel | `compute/stretchb_right.comp` | Compiled | Rightward blue stretch |
| 288 | StretchR_Down | `StretchR_Down` | channel | `compute/stretchr_down.comp` | Compiled | Downward red stretch |
| 289 | StretchG_Down | `StretchG_Down` | channel | `compute/stretchg_down.comp` | Compiled | Downward green stretch |
| 290 | StretchB_Down | `StretchB_Down` | channel | `compute/stretchb_down.comp` | Compiled | Downward blue stretch |
| 291 | Distorted_LinesY | `Distorted_LinesY` | line | `compute/distorted_linesy.comp` | Compiled | Distorted vertical lines |
| 292 | Distorted_LinesX | `Distorted_LinesX` | line | `compute/distorted_linesx.comp` | Compiled | Distorted horizontal lines |
| 293 | TripHSV | `TripHSV` | color | `compute/triphsv.comp` | Compiled | Animated HSV color trip |
| 294 | Diag_Line_InOut | `Diag_Line_InOut` | distort | `compute/diag_line_inout.comp` | Compiled | Diagonal line expansion and contraction |
| 295 | Histogram | `Histogram` | color | `compute/histogram.comp` | Compiled | Histogram-style tonal mapping |
| 296 | XorSumStrobe | `XorSumStrobe` | bitwise | `compute/xorsumstrobe.comp` | Compiled | Summed-channel XOR strobe |
| 297 | DetectEdges | `DetectEdges` | edge | `compute/detectedges.comp` | Compiled | Luma edge detection |
| 298 | SobelNorm | `SobelNorm` | edge | `compute/sobelnorm.comp` | Compiled | Normalized Sobel edges |
| 299 | SobelThreshold | `SobelThreshold` | edge | `compute/sobelthreshold.comp` | Compiled | Thresholded Sobel edges |
| 300 | MedianBlurHigherLevel | `MedianBlurHigherLevel` | blur | `compute/medianblurhigherlevel.comp` | Compiled | High-radius median-like blur |

## Validation policy

Each batch must compile through ACMXVK's source-library builder before its
status is changed to `Compiled`. Batches 1 through 6 compiled all 300 sources
with zero failures using the ACMXVK builder. Visual equivalence is tracked separately from
compiler validation because some CPU filters depend on mutable static values
whose GPU equivalents use the normalized library controls and ACMXVK shader
timeline.
