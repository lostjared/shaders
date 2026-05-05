#version 330 core
// ant_gem_rainbow_fracture
// Rainbow spectrum wash with kaleidoscope fracture and bass-driven break lines

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

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Bass-driven fracture: sudden spatial breaks
    float breakStr = bass * 0.15;
    p.x += breakStr * step(0.5, fract(p.y * 8.0 + iTime));
    p.y += breakStr * step(0.5, fract(p.x * 8.0 - iTime * 0.7));

    // Mid-driven rotation
    p = rot(iTime * 0.25 + mid * 1.5) * p;

    // Kaleidoscope fracture
    float segments = 5.0 + floor(hiMid * 10.0);
    float angle = atan(p.y, p.x);
    float radius = length(p);
    float step_val = 2.0 * PI / segments;
    angle = mod(angle, step_val);
    angle = abs(angle - step_val * 0.5);

    // Fracture: additional sharp abs-fold breaks
    vec2 fractured = vec2(cos(angle), sin(angle)) * radius;
    fractured = abs(fractured) - 0.2 + bass * 0.08;
    fractured = rot(iTime * 0.15) * fractured;
    fractured = abs(fractured) - 0.15;

    // Map to texture
    vec2 sampUV = fractured;
    sampUV.x /= aspect;
    sampUV = fract(sampUV + 0.5);

    // Chromatic fracture split
    float chroma = (treble + air) * 0.05;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, chroma * 0.5)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma * 0.5, chroma)).b;

    // Rainbow spectrum wash
    float dist = length(tc - 0.5);
    vec3 rainbow = 0.5 + 0.5 * cos(6.28318 * (radius * 2.0 - iTime * 0.4 + bass * 0.5 + vec3(0.0, 0.33, 0.67)));
    col = mix(col, col * rainbow, 0.4 + mid * 0.25);

    // Break line glow: neon edges along fracture boundaries
    float breakEdge = pow(0.005 / max(min(abs(fractured.x), abs(fractured.y)), 0.001), 0.7);
    col += rainbow * breakEdge * 0.12 * (1.0 + treble);

    // Color cycling shift
    col = mix(col, col.brg, smoothstep(0.3, 0.7, sin(iTime * 0.4)));

    col *= 0.85 + amp_smooth * 0.35;
    col *= 1.0 + bass * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
