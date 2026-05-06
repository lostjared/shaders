#version 330 core
// ant_new_infinity_plasma
// Mix of ant_spectrum_mirror_infinity + ant_light_color_plasma_helix:
// infinite recursion of plasma-warped kaleidoscope samples fading
// into a rainbow depth well.

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

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
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
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Plasma field pre-warp
    float pl = 0.0;
    pl += sin((uv.x * 5.0 + iTime) * (1.0 + bass));
    pl += sin((uv.y * 5.0 + iTime * 0.7) * (1.0 + mid));
    pl += sin((uv.x + uv.y + iTime) * 3.0);
    pl += cos(length(uv * 10.0 + iTime) * (2.0 + treble * 3.0));
    pl *= 0.25;

    vec3 result = vec3(0.0);
    float totalW = 0.0;
    float seg = floor(6.0 + bass * 6.0);

    for (float d = 0.0; d < 8.0; d++) {
        float zoom = pow(1.18 + mid * 0.1, d);
        vec2 p = uv * zoom;
        // Plasma-coupled rotation per depth
        p *= rot(d * 0.1 + iTime * 0.05 + pl * 0.15);
        p += vec2(pl * 0.06, pl * 0.04);

        vec2 kUV = kaleido(p, seg);
        kUV = abs(kUV);
        if (kUV.y > kUV.x)
            kUV = kUV.yx;
        vec2 texUV = mirror(kUV * 0.5 + 0.5);

        float co = d * 0.002 * (1.0 + treble);
        vec3 s;
        s.r = texture(samp, mirror(texUV + vec2(co, 0.0))).r;
        s.g = texture(samp, texUV).g;
        s.b = texture(samp, mirror(texUV - vec2(co, 0.0))).b;
        s *= rainbow(d * 0.1 + length(kUV) + iTime * 0.15 + hiMid);

        float w = 1.0 / (1.0 + d * 0.5);
        result += s * w;
        totalW += w;
    }
    result /= totalW;

    // Plasma highlight overlay
    result += rainbow(pl + iTime * 0.2) * pow(max(pl, 0.0), 2.0) * (0.2 + air * 0.3);

    // Center glow
    result += exp(-length(uv) * 5.0) * rainbow(iTime * 0.4 + bass) * 0.15;

    result = mix(result, result.gbr, air * 0.3);
    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
