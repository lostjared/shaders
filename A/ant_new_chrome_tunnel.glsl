#version 330 core
// ant_new_chrome_tunnel
// Mix of ant_gem_liquid_mirror + ant_gem_prism_vortex:
// glass-normal chrome refraction sampled through a prism polar tunnel.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 prism(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.60).r;
    float air = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // Polar tunnel coords
    float dist = length(uv);
    float ang = atan(uv.y, uv.x);
    float tunSpeed = iTime * (0.4 + bass * 0.8);
    vec2 tunnel = vec2(ang / PI + iTime * 0.05,
                       1.0 / (dist + 0.01) + tunSpeed);

    // Kaleidoscope prism petals
    float segments = 5.0 + floor(mid * 10.0);
    float k = 2.0 * PI / segments;
    float kAng = abs(mod(ang, k) - k * 0.5);
    vec2 petal = vec2(cos(kAng), sin(kAng)) * dist;
    petal.x /= aspect;

    vec2 sampUV = mix(
        abs(fract(tunnel * 0.5) * 2.0 - 1.0),
        fract(petal + 0.5),
        0.5 + hiMid * 0.3);

    // Glass normals from luminance gradient (liquid_mirror trick)
    float delta = 0.009;
    float h = dot(texture(samp, sampUV).rgb, vec3(0.33));
    float h1 = dot(texture(samp, sampUV + vec2(delta, 0.0)).rgb, vec3(0.33));
    float h2 = dot(texture(samp, sampUV + vec2(0.0, delta)).rgb, vec3(0.33));
    vec2 normal = vec2(h1 - h, h2 - h);

    sampUV += normal * (0.05 + mid * 0.08);

    // Chromatic split along tangential direction
    float chroma = (treble + air) * 0.045;
    vec2 splitDir = rot(ang) * vec2(chroma, 0.0);
    vec3 col;
    col.r = texture(samp, sampUV + splitDir).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - splitDir).b;

    // Prism hue cycling
    vec3 hue = prism(dist * 2.0 - iTime * 0.4 + bass * 0.5);
    col = mix(col, col * hue, 0.35 + mid * 0.25);

    // Chrome specular highlight
    float spec = pow(max(0.0, 1.0 - length(normal * 14.0)), 8.0);
    col += vec3(1.0) * spec * 0.35;

    // Radial bands
    col *= 0.85 + 0.15 * sin(dist * (20.0 + hiMid * 15.0) - iTime * 3.0);

    // Tunnel vignette
    col *= smoothstep(1.6, 0.3 + bass * 0.3, dist);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
