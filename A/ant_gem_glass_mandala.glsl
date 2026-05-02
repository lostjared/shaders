#version 330 core
// ant_gem_glass_mandala
// Glass surface normals with mandala kaleidoscope and treble jitter distortion

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

vec2 kaleidoscope(vec2 p, float seg) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = 2.0 * PI / seg;
    ang = mod(ang, s);
    ang = abs(ang - s * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Bass-driven mandala breathing
    p *= 1.0 - bass * 0.3;

    // Mandala kaleidoscope segments
    float seg = floor(8.0 + mid * 8.0);
    p = kaleidoscope(p, seg);

    // Diamond fold for extra facets
    p = abs(p);
    if (p.y > p.x)
        p = p.yx;

    // Treble jitter: high-frequency noise displacement
    float jitter = treble * 0.04;
    float noise = fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
    p += jitter * vec2(sin(noise * 100.0 + iTime * 15.0), cos(noise * 80.0 + iTime * 12.0));

    // Map to texture coords
    vec2 sampUV = p;
    sampUV.x /= aspect;
    sampUV = sampUV + 0.5;
    sampUV = clamp(sampUV, 0.0, 1.0);

    // Glass warp normals
    float delta = 0.007;
    float h = dot(texture(samp, sampUV).rgb, vec3(0.33));
    float h1 = dot(texture(samp, sampUV + vec2(delta, 0.0)).rgb, vec3(0.33));
    float h2 = dot(texture(samp, sampUV + vec2(0.0, delta)).rgb, vec3(0.33));
    vec2 normal = vec2(h1 - h, h2 - h);

    // Refracted sampling
    vec2 refractUV = sampUV + normal * (0.05 + mid * 0.05);

    // Chromatic aberration through glass
    float refract_split = (air + treble) * 0.03;
    vec3 col;
    col.r = texture(samp, refractUV + normal * refract_split).r;
    col.g = texture(samp, refractUV).g;
    col.b = texture(samp, refractUV - normal * refract_split).b;

    // Specular highlights
    float spec = pow(max(0.0, 1.0 - length(normal * 20.0)), 10.0);
    col += vec3(1.0, 0.95, 0.9) * spec * 0.4;

    // Mandala ring glow
    float rad = length((tc - 0.5) * vec2(aspect, 1.0));
    float ringGlow = sin(rad * (15.0 + hiMid * 10.0) - iTime * 2.0) * 0.5 + 0.5;
    vec3 mandalaCol = 0.5 + 0.5 * cos(6.28318 * (rad + iTime * 0.2 + vec3(0.0, 0.33, 0.67)));
    col = mix(col, col * mandalaCol, ringGlow * 0.25);

    col *= 0.85 + amp_smooth * 0.3;
    col *= 1.0 + bass * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
