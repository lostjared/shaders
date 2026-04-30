#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f; // accumulated time value, affected by speed and audio when enabled
uniform float time_speed; // rate of change to time_f
uniform sampler2D samp; // input video frame texture
uniform vec2 iResolution; // viewport resolution in pixels (width, height)
uniform vec4 iMouse; // mouse position: xy = current, zw = click start (drag)
uniform float amp; // audio amplitude scaled by sensitivity
uniform float uamp; // raw audio amplitude before sensitivity scaling
uniform float amp_peak; // peak absolute sample value in current audio buffer
uniform float amp_rms; // RMS energy of current audio buffer
uniform float amp_smooth; // exponentially smoothed amplitude for gradual transitions
uniform float amp_low; // bass energy (below ~300 Hz)
uniform float amp_mid; // mid-range energy (~300-3000 Hz)
uniform float amp_high; // treble energy (above ~3000 Hz)
uniform float iamp; // estimated dominant frequency in Hz via zero-crossing rate

// PAL analog video emulation.
// Models the key visible artifacts of a composite PAL signal:
//   - YUV color space with reduced chroma bandwidth (horizontal color smear)
//   - Phase Alternating Line: chroma U/V averaged across adjacent lines
//   - Luma low-pass + slight ringing (composite bandwidth ~5 MHz)
//   - 625-line scanline structure with mild interlace shimmer at 50 Hz
//   - Subtle hue rotation, saturation lift, gamma -> CRT response
//   - Tape/RF noise modulated by audio amplitude
//   - Soft vignette resembling a CRT phosphor mask

const mat3 RGB_TO_YUV = mat3(
    0.299,    0.587,    0.114,
   -0.14713, -0.28886,  0.436,
    0.615,   -0.51499, -0.10001
);

const mat3 YUV_TO_RGB = mat3(
    1.0,  0.0,      1.13983,
    1.0, -0.39465, -0.58060,
    1.0,  2.03211,  0.0
);

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec3 sampleRGB(vec2 uv) {
    return texture(samp, clamp(uv, vec2(0.0), vec2(1.0))).rgb;
}

vec3 sampleYUV(vec2 uv) {
    return RGB_TO_YUV * sampleRGB(uv);
}

void main(void) {
    vec2 uv = tc;
    vec2 px = 1.0 / iResolution;

    // Quantise vertical sampling onto a 576-line raster (PAL visible lines).
    float lines = 576.0;
    float lineY = floor(uv.y * lines);
    float lineCenter = (lineY + 0.5) / lines;

    // ----- Luma: low-pass horizontally (composite ~5 MHz bandwidth) -----
    float y =
        sampleYUV(uv + vec2(-2.0 * px.x, 0.0)).x * 0.10 +
        sampleYUV(uv + vec2(-1.0 * px.x, 0.0)).x * 0.22 +
        sampleYUV(uv                          ).x * 0.36 +
        sampleYUV(uv + vec2( 1.0 * px.x, 0.0)).x * 0.22 +
        sampleYUV(uv + vec2( 2.0 * px.x, 0.0)).x * 0.10;

    // Slight high-frequency overshoot (composite ringing).
    float yHi = sampleYUV(uv).x - y;
    y += yHi * 0.35;

    // ----- Chroma: heavy horizontal low-pass + PAL line averaging -----
    // Average current and previous scanline so alternating-phase errors
    // cancel, which is the defining feature of PAL.
    vec2 uvCur = vec2(uv.x, lineCenter);
    vec2 uvPrv = vec2(uv.x, lineCenter - 1.0 / lines);

    vec2 chromaCur = vec2(0.0);
    vec2 chromaPrv = vec2(0.0);
    vec2 chromaDly = vec2(0.0);
    const int CHROMA_TAPS = 6;
    float wsum = 0.0;
    for (int i = -CHROMA_TAPS; i <= CHROMA_TAPS; ++i) {
        float fi = float(i);
        float w = exp(-fi * fi / 18.0);
        vec2 off = vec2(fi * px.x, 0.0);
        chromaCur += sampleYUV(uvCur + off).yz * w;
        chromaPrv += sampleYUV(uvPrv + off).yz * w;
        chromaDly += sampleYUV(uvCur + off + vec2(1.5 * px.x, 0.0)).yz * w;
        wsum += w;
    }
    chromaCur /= wsum;
    chromaPrv /= wsum;
    chromaDly /= wsum;
    vec2 uvChroma = 0.5 * (chromaCur + chromaPrv);
    // Chroma is delayed slightly relative to luma in real composite signals.
    uvChroma = mix(uvChroma, chromaDly, 0.35);

    // Faint dot crawl at the chroma subcarrier rate.
    float carrier = sin(uv.x * iResolution.x * 1.6 + lineY * 3.14159 + time_f * 4.0);
    uvChroma += vec2(carrier) * 0.012 * length(uvChroma);

    // Reassemble YUV -> RGB.
    vec3 yuv = vec3(y, uvChroma);
    vec3 rgb = YUV_TO_RGB * yuv;

    // ----- Tone shaping (CRT-ish) -----
    float luma = dot(rgb, vec3(0.299, 0.587, 0.114));
    rgb = mix(vec3(luma), rgb, 1.12);          // saturation lift
    rgb *= vec3(1.03, 1.00, 0.97);             // mild warm tint
    rgb = pow(max(rgb, 0.0), vec3(0.92));      // gamma mismatch

    // ----- Scanlines + 50 Hz interlace shimmer -----
    float scan = 0.85 + 0.15 * cos(uv.y * iResolution.y * 3.14159);
    float field = mod(floor(time_f * 50.0), 2.0);
    float interlace = 1.0 - 0.05 * step(0.5, fract(lineY * 0.5 + field * 0.5));
    rgb *= scan * interlace;

    // ----- Tape / RF noise -----
    float n = hash21(vec2(uv.x * iResolution.x, lineY) + time_f * 60.0);
    float noiseAmt = 0.025 + 0.05 * clamp(amp_smooth + amp_high * 0.5, 0.0, 1.0);
    rgb += (n - 0.5) * noiseAmt;

    // Occasional brief chroma streaks tied to bass energy.
    float streak = step(0.985, hash21(vec2(lineY, floor(time_f * 25.0))));
    rgb.r += streak * 0.08 * amp_low;
    rgb.b -= streak * 0.04 * amp_low;

    // ----- Soft vignette -----
    vec2 vc = uv - 0.5;
    float vig = smoothstep(0.95, 0.35, dot(vc, vc) * 2.2);
    rgb *= mix(0.85, 1.0, vig);

    color = vec4(clamp(rgb, 0.0, 1.0), 1.0);
}


