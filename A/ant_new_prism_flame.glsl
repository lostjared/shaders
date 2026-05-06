#version 330 core
// ant_new_prism_flame
// Mix of ant_gem_prism_vortex + ant_spectrum_kaleido_flame:
// prism radial bands interleaved with layered flame echo tongues.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 prism(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x),
               mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

vec2 kaleido(vec2 p, float seg) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = 2.0 * PI / seg;
    ang = abs(mod(ang, s) - s * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

vec2 mirror(vec2 u) {
    vec2 m = mod(u, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0) * 2.0;

    float dist = length(uv);
    float seg = floor(6.0 + bass * 6.0);

    // Primary kaleidoscope sample
    vec2 k = kaleido(uv, seg);
    k = abs(k);
    if (k.y > k.x)
        k = k.yx;
    vec2 baseUV = mirror(k * 0.6 + 0.5);
    vec3 base = texture(samp, baseUV).rgb;

    // Flame echo tongues drifting upward
    vec3 echo = vec3(0.0);
    for (float e = 1.0; e < 5.0; e++) {
        float en = noise(uv * (3.0 + e) + vec2(0.0, -iTime * (1.5 + e * 0.5)));
        vec2 ef = uv;
        ef.x += (en - 0.5) * 0.1 * e;
        ef.y -= e * 0.02;
        vec2 ek = kaleido(ef, seg);
        ek = abs(ek);
        if (ek.y > ek.x)
            ek = ek.yx;
        vec3 s = texture(samp, mirror(ek * 0.6 + 0.5)).rgb;
        s *= prism(e * 0.15 + (uv.y * 0.5 + 0.5) + iTime * 0.2 + mid);
        echo += s * (0.3 / e);
    }

    vec3 col = base + echo;

    // Prism hue cycling keyed to radius
    vec3 hue = prism(dist * 2.0 - iTime * 0.4 + bass * 0.5);
    col = mix(col, col * hue, 0.35 + hiMid * 0.25);

    // Radial prism bands
    col *= 0.85 + 0.15 * sin(dist * (20.0 + hiMid * 15.0) - iTime * 3.0);

    // Flame shimmer sparks
    float shim = pow(noise(uv * 8.0 + iTime * 2.0), 3.0);
    col += shim * prism(iTime * 0.5 + treble) * 0.25;

    // Vignette opening with bass
    col *= smoothstep(1.6, 0.3 + bass * 0.3, dist);

    col = mix(col, col.gbr, air * 0.3);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
