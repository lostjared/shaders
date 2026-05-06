#version 330 core
// ant_new_liquid_helix
// Mix of ant_gem_liquid_mirror + ant_light_color_plasma_helix:
// liquid glass mirror warp with twin neon helix strands swimming
// through the refraction.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
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

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.82).r;

    vec2 uv = tc;
    vec2 centered = uv - 0.5;

    // Bass-wobble mirror fold
    centered.x += bass * sin(centered.y * PI + iTime * 2.0);
    centered.x = abs(centered.x);
    uv = centered + 0.5;

    // Plasma noise drift
    float scale = 5.0 + mid * 4.0;
    vec2 off = vec2(noise(uv * scale + iTime * 0.4),
                    noise(uv * scale - iTime * 0.4 + 100.0));
    uv += (off - 0.5) * 0.12 * (1.0 + bass * 0.5);

    // Glass normals
    float d = 0.008;
    float h = dot(texture(samp, uv).rgb, vec3(0.33));
    float h1 = dot(texture(samp, uv + vec2(d, 0)).rgb, vec3(0.33));
    float h2 = dot(texture(samp, uv + vec2(0, d)).rgb, vec3(0.33));
    vec2 n = vec2(h1 - h, h2 - h);
    uv += n * (0.05 + mid * 0.07);

    // Chromatic refraction
    float chroma = smoothstep(0.2, 0.8, treble) * 0.05;
    vec3 col;
    col.r = texture(samp, uv + vec2(chroma, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(chroma, 0.0)).b;

    // Helix strands in screen space, riding the liquid refraction
    float aspect = iResolution.x / iResolution.y;
    vec2 sp = (tc - 0.5) * vec2(aspect, 1.0);
    sp += n * 0.2; // strands bend through the glass
    float hA = sin(sp.y * 14.0 + iTime * 3.0 + bass * 5.0) * (0.2 + mid * 0.12);
    float hB = sin(sp.y * 14.0 + iTime * 3.0 + bass * 5.0 + PI) * (0.2 + mid * 0.12);
    float sA = smoothstep(0.05, 0.0, abs(sp.x - hA));
    float sB = smoothstep(0.05, 0.0, abs(sp.x - hB));
    col += rainbow(iTime * 0.3 + sp.y) * sA * (1.8 + air * 4.0);
    col += rainbow(iTime * 0.3 + sp.y + 0.5) * sB * (1.8 + air * 4.0);

    // Glass specular + frequency wash
    col += vec3(1.0) * pow(max(0.0, 1.0 - length(n * 16.0)), 8.0) * 0.3;
    col += vec3(bass, mid, treble) * 0.12;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
