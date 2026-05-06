#version 330 core
// ant_gem_prism_vortex
// Polar tunnel with kaleidoscope prism and spectrum-driven hue cycling

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
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // Polar conversion
    float dist = length(uv);
    float angle = atan(uv.y, uv.x) / PI;

    // Bass-driven tunnel zoom speed
    float tunnelSpeed = iTime * (0.4 + bass * 0.8);

    // Tunnel coordinates
    vec2 tunnelUV;
    tunnelUV.x = angle + iTime * 0.05;
    tunnelUV.y = (1.0 / (dist + 0.01)) + tunnelSpeed;

    // Kaleidoscope prism splitting
    float segments = 5.0 + floor(mid * 10.0);
    float kAngle = atan(uv.y, uv.x);
    float step_val = 2.0 * PI / segments;
    kAngle = mod(kAngle, step_val);
    kAngle = abs(kAngle - step_val * 0.5);
    vec2 prismP = vec2(cos(kAngle), sin(kAngle)) * dist;
    prismP.x /= aspect;

    // Blend tunnel and prism UVs
    vec2 sampUV = mix(
        abs(fract(tunnelUV * 0.5) * 2.0 - 1.0),
        fract(prismP + 0.5),
        0.5 + hiMid * 0.3);

    // Chromatic prism split
    float chroma = (treble + air) * 0.04;
    vec2 splitDir = rot(angle * PI) * vec2(chroma, 0.0);
    vec3 col;
    col.r = texture(samp, sampUV + splitDir).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - splitDir).b;

    // Spectrum hue cycling overlay
    vec3 hue = prism(dist * 2.0 - iTime * 0.4 + bass * 0.5);
    col = mix(col, col * hue, 0.35 + mid * 0.25);

    // Radial light bands
    float bands = sin(dist * (20.0 + hiMid * 15.0) - iTime * 3.0);
    col *= 0.85 + 0.15 * bands;

    // Vignette opening with bass
    float vignette = smoothstep(1.5, 0.3 + bass * 0.3, dist);
    col *= vignette;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
