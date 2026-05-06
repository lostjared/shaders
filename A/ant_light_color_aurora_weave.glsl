#version 330 core
// ant_light_color_aurora_weave
// Woven aurora ribbons with cross-hatch light and bass-reactive sway

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 aurora(float t) {
    vec3 green = vec3(0.1, 1.0, 0.4);
    vec3 blue = vec3(0.2, 0.4, 1.0);
    vec3 pink = vec3(1.0, 0.2, 0.6);
    float p = fract(t);
    vec3 c = mix(green, blue, smoothstep(0.0, 0.5, p));
    return mix(c, pink, smoothstep(0.5, 1.0, p));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc;

    // Weave distortion: horizontal ribbons
    float hRibbon = 0.0;
    for (float i = 0.0; i < 6.0; i++) {
        float y = (i + 0.5) / 6.0;
        float sway = noise(vec2(uv.x * 3.0 + iTime * (0.3 + i * 0.1), i)) * 0.08 * (1.0 + bass);
        float band = smoothstep(0.02, 0.0, abs(uv.y - y - sway));
        hRibbon += band * aurora(i * 0.15 + iTime * 0.1).r;
    }

    // Vertical ribbons
    float vRibbon = 0.0;
    for (float i = 0.0; i < 6.0; i++) {
        float x = (i + 0.5) / 6.0;
        float sway = noise(vec2(i, uv.y * 3.0 + iTime * (0.2 + i * 0.08))) * 0.06 * (1.0 + mid);
        float band = smoothstep(0.02, 0.0, abs(uv.x - x - sway));
        vRibbon += band * aurora(i * 0.15 + 0.5 + iTime * 0.1).g;
    }

    float weave = max(hRibbon, vRibbon);
    float crossHatch = hRibbon * vRibbon;

    // Texture sample
    float chroma = treble * 0.03 * weave;
    vec3 col;
    col.r = texture(samp, uv + vec2(chroma, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(chroma, 0.0)).b;

    // Aurora ribbon glow
    col += aurora(uv.y + iTime * 0.15) * hRibbon * (0.5 + air * 1.5);
    col += aurora(uv.x + iTime * 0.15 + 0.33) * vRibbon * (0.5 + air * 1.5);

    // Cross-hatch bright spots
    col += aurora(iTime * 0.2 + crossHatch * 3.0) * crossHatch * (3.0 + bass * 4.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
