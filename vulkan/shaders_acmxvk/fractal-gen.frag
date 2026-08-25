#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp ext.u1.y
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iChannelTime ext.custom_uniforms[3].x
#define iFrame int(ext.u2.x)
#define iFrameRate ext.u1.w
#define iMouse ext.mouse
#define iMouseClick ext.mouse.xy
#define iResolution ext.u0.zw
#define iSampleRate ext.u2.z
#define iTime ext.u0.y
#define iTimeDelta ext.u1.x
#define iamp ext.u1.z
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp; // input video frame texture







uniform vec4 iDate;


uniform vec3 iChannelResolution[4]; // resolution of each texture channel










void main(void) {
			 vec2 uv = vec2(tc.x, 1.0 - tc.y);
    float aspect = iResolution.x / iResolution.y;

    // Center and aspect-correct coordinates for fractal space
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    // Audio values are already boosted by acmx2 (sense * 40)
    // Clamp them to sane ranges to prevent fractal divergence
    float lo  = clamp(amp_low,    0.0, 1.5);
    float mid = clamp(amp_mid,    0.0, 1.5);
    float hi  = clamp(amp_high,   0.0, 1.5);
    float pk  = clamp(amp_peak,   0.0, 1.5);
    float rms = clamp(amp_rms,    0.0, 1.5);
    float sm  = clamp(amp_smooth, 0.0, 1.5);

    // =========================================================
    // FRACTAL FOLD — each amp_ uniform drives a different fold
    // =========================================================
    float t = iTime * 0.3;
    const int ITERS = 6;

    for (int i = 0; i < ITERS; i++) {
        // abs fold (box fold) — bass drives fold offset
        p = abs(p) - (0.5 + lo * 0.15);

        // Rotation fold — mids drive rotation angle
        float angle = t + mid * 0.5 + float(i) * 0.5;
        float ca = cos(angle), sa = sin(angle);
        p = mat2(ca, -sa, sa, ca) * p;

        // Inversion fold (circle inversion) — peak drives radius
        float r2 = dot(p, p) + 0.001;
        float invRadius = 0.2 + pk * 0.15;
        if (r2 < invRadius) {
            p /= r2;
        }

        // Scale fold — RMS drives the scaling factor
        float s = 1.2 + rms * 0.15;
        p = p * s - vec2(0.6 + sm * 0.15);

        // Conditional fold — treble flips axes
        if (hi > 0.4) {
            p = vec2(p.y, -p.x) * (1.0 + hi * 0.1);
        }

        // Clamp to prevent divergence
        p = clamp(p, -3.0, 3.0);
    }

    // Map fractal position back to texture UV
    float warpStrength = 0.05 + sm * 0.05;
    vec2 fracUV = uv + p * warpStrength * 0.015;

    // Mirror-tile the UVs so we never go out of bounds
    fracUV = abs(fract(fracUV * 0.5) * 2.0 - 1.0);

    // Chromatic split driven by treble (color separation)
    float chromaShift = 0.002 + hi * 0.008;
    vec2 dir = normalize(p + 1e-6);
    float r = texture(samp, clamp(fracUV - dir * chromaShift, 0.0, 1.0)).r;
    float g = texture(samp, clamp(fracUV, 0.0, 1.0)).g;
    float b = texture(samp, clamp(fracUV + dir * chromaShift, 0.0, 1.0)).b;
    vec3 tex = vec3(r, g, b);

    // Fractal coloring from orbit trap distance
    float trap = length(p);
    vec3 fracColor;
    fracColor.r = 0.5 + 0.5 * sin(trap * 0.3 + t + lo * 1.0);
    fracColor.g = 0.5 + 0.5 * sin(trap * 0.3 + t * 1.3 + mid * 1.0);
    fracColor.b = 0.5 + 0.5 * sin(trap * 0.3 + t * 1.7 + hi * 1.0);

    // Mix fractal color with texture — RMS controls blend
    float blend = 0.15 + rms * 0.1;
    vec3 finalColor = mix(tex, tex * fracColor * 1.5, blend);

    // Brightness pulse from peak — visible flash on transients
    finalColor *= 1.0 + pk * 0.6;

    // Edge glow from smooth — persistent energy adds glow
    float edge = exp(-0.3 * trap);
    finalColor += fracColor * edge * sm * 0.3;

    // Tone map to avoid blowout
    finalColor = finalColor / (1.0 + finalColor * 0.25);

    color = vec4(finalColor, 1.0);
}

