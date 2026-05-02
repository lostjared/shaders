#version 330 core

in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float iTime;
uniform float amp_peak;

// Our 1D frequency spectrum
uniform sampler1D spectrum;

const float PI = 3.14159265359;

// Helper: Rotation matrix
mat2 rotate2d(float _angle) {
    return mat2(cos(_angle), -sin(_angle),
                sin(_angle), cos(_angle));
}

void main() {
    vec2 uv = tc;
    float aspect = iResolution.x / iResolution.y;

    // 1. Sample the "Dancers" (Frequencies)
    float sBass = texture(spectrum, 0.02).r;   // The "Body"
    float sMid = texture(spectrum, 0.25).r;    // The "Spin"
    float sTreble = texture(spectrum, 0.70).r; // The "Vibration"

    // 2. The Move: Zoom (Bass)
    // Center coordinates and apply a bass-driven scale
    vec2 p = uv - 0.5;
    p.x *= aspect;
    p *= 1.0 - (sBass * 0.4);

    // 3. The Move: Spin (Mids)
    // Rotate based on time + mid-frequency intensity
    float rotation_speed = iTime * 0.5 + (sMid * 2.0);
    p = rotate2d(rotation_speed) * p;

    // 4. The Move: Fracture (Treble)
    // Kaleidoscopic mirroring. Treble adds more "facets" to the mirror.
    float angle = atan(p.y, p.x);
    float radius = length(p);

    // Treble transiently increases the number of segments
    float segments = 4.0 + floor(sTreble * 12.0);
    float step_val = (2.0 * PI) / segments;

    angle = mod(angle, step_val);
    angle = abs(angle - step_val * 0.5);

    // Reconstruct coordinates
    p = vec2(cos(angle), sin(angle)) * radius;
    p.x /= aspect;
    uv = p + 0.5;

    // 5. Final Rendering & Chromatic Jitter
    // Use treble to split the RGB channels for a "shiver" effect
    float chroma = sTreble * 0.05;
    vec3 col;
    col.r = texture(samp, uv + vec4(chroma, 0.0, 0.0, 0.0).xy).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec4(chroma, 0.0, 0.0, 0.0).xy).b;

    // Pulse brightness with the overall energy
    col *= 1.0 + (sBass * 0.5);

    // Invert colors on extreme peaks for a "strobe" dance feel
    if (amp_peak > 0.97)
        col = 1.0 - col;

    color = vec4(col, 1.0);
}