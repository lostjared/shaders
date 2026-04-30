#version 330 core
// ant_new_ocean_kaleido
// Mix of ant_gem_fractal_ocean + ant_spectrum_mirror_infinity:
// fractal ocean depth-field viewed through a layered kaleidoscope
// mirror stack.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 ocean(float t) {
    return vec3(0.1, 0.3, 0.5) + vec3(0.3, 0.4, 0.5)
         * cos(6.28318 * (vec3(1.0, 1.2, 1.0) * t + vec3(0.0, 0.25, 0.5)));
}

mat2 rot(float a) { float s = sin(a), c = cos(a); return mat2(c, -s, s, c); }

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
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0) * 2.0;

    // Run fractal once on base uv
    vec2 fp = uv * (0.8 + 0.3 * mid);
    float iters = 0.0;
    const float maxI = 40.0;
    for (float i = 0.0; i < maxI; i++) {
        fp = abs(fp) / dot(fp, fp) - vec2(0.78 + hiMid * 0.25, 0.5 + 0.1 * sin(iTime * 0.3));
        if (length(fp) > 20.0) break;
        iters++;
    }
    float ni = iters / maxI;

    // Layered kaleidoscope mirror stack (infinity-style, 4 layers)
    vec3 stack = vec3(0.0);
    float totalW = 0.0;
    float seg = floor(6.0 + bass * 6.0);
    for (float d = 0.0; d < 4.0; d++) {
        float zoom = pow(1.2 + mid * 0.1, d);
        vec2 p = uv * zoom * rot(d * 0.15 + iTime * 0.06);
        // Couple the kaleidoscope to the fractal output
        p += fp * 0.02 * (d + 1.0);
        vec2 kUV = kaleido(p, seg);
        kUV = abs(kUV);
        if (kUV.y > kUV.x) kUV = kUV.yx;
        vec2 texUV = mirror(kUV * 0.55 + 0.5);

        float co = d * 0.003 * (1.0 + treble);
        vec3 s;
        s.r = texture(samp, mirror(texUV + vec2(co, 0.0))).r;
        s.g = texture(samp, texUV).g;
        s.b = texture(samp, mirror(texUV - vec2(co, 0.0))).b;
        s *= ocean(ni * 2.0 + d * 0.2 + iTime * 0.15 + bass);

        float w = 1.0 / (1.0 + d * 0.55);
        stack += s * w;
        totalW += w;
    }
    stack /= totalW;

    vec3 col = stack;

    // Deep glow rings from fractal depth
    float rings = pow(0.01 / max(abs(sin(ni * 8.0 + iTime)), 0.001), 0.8);
    col += ocean(ni * 2.0 + iTime * 0.2) * rings * 0.15 * (1.0 + air);

    // Center glow pulses on bass
    col += exp(-length(uv * 0.5) * 4.0) * ocean(iTime * 0.3 + bass) * (0.15 + bass * 0.3);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
