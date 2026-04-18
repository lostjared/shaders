#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main(void) {
    vec2 uv = tc;
    vec2 p = (tc - 0.5) * iResolution.xy / iResolution.y;

    // Voronoi crack pattern - peaks drive crack intensity
    float crackScale = 5.0 + amp_peak * 10.0;
    vec2 cell = floor(p * crackScale);
    vec2 frac_ = fract(p * crackScale);

    float minDist = 1.0;
    float minDist2 = 1.0;
    vec2 nearestCell = vec2(0.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = vec2(hash(cell + neighbor), hash((cell + neighbor) * 1.3 + 7.0));
            // Mids animate the cell points
            point += 0.3 * sin(time_f * (0.5 + amp_mid) + 6.28 * point);
            vec2 diff = neighbor + point - frac_;
            float d = length(diff);
            if (d < minDist) {
                minDist2 = minDist;
                minDist = d;
                nearestCell = cell + neighbor;
            } else if (d < minDist2) {
                minDist2 = d;
            }
        }
    }

    // Edge distance = crack lines
    float crackLine = minDist2 - minDist;
    float crack = smoothstep(0.0, 0.05 + amp_peak * 0.03, crackLine);

    // Each cell displaces texture slightly
    float cellHash = hash(nearestCell);
    vec2 cellOffset = (vec2(hash(nearestCell + 13.0), cellHash) - 0.5) * amp_peak * 0.04;
    vec2 sampleUV = clamp(uv + cellOffset, 0.0, 1.0);

    vec4 tex = texture(samp, sampleUV);

    // Crack glow from bass energy
    vec3 crackColor = vec3(1.0, 0.4, 0.1) * amp_low * 2.0;
    tex.rgb = mix(tex.rgb + crackColor, tex.rgb, crack);

    // Treble sparkle on crack edges
    if (crackLine < 0.02 && hash(nearestCell + time_f) < amp_high * 0.5) {
        tex.rgb += amp_high * 0.5;
    }

    // Peak flash
    tex.rgb += smoothstep(0.7, 1.0, amp_peak) * 0.15;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
