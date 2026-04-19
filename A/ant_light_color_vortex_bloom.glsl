#version 330 core
// ant_light_color_vortex_bloom
// Blooming vortex with flower-petal UV warp and spectrum light halos

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 bloom(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.15, 0.45)));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(p);
    float angle = atan(p.y, p.x);

    // Flower petal warp
    float petals = 5.0 + floor(bass * 4.0);
    float petal = cos(angle * petals + iTime * 0.8) * 0.3;
    float bloom_r = r + petal * (0.2 + mid * 0.2);

    // Vortex twist
    float twist = (4.0 + bass * 8.0) * exp(-bloom_r * 2.0);
    float vAngle = angle + twist + iTime * 0.6;

    vec2 vUV = vec2(cos(vAngle), sin(vAngle)) * bloom_r;
    vUV.x /= aspect;
    vec2 sampUV = vUV + 0.5;

    float chroma = (treble + air) * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Light halos at petal peaks
    float halo = pow(max(cos(angle * petals + iTime * 0.8), 0.0), 8.0);
    halo *= exp(-r * 2.0);
    col += bloom(angle / TAU + r + iTime * 0.2) * halo * (2.0 + mid * 3.0);

    // Spiral arm coloring
    float spiral = sin(vAngle * 3.0 + log(r + 0.01) * 5.0);
    spiral = max(spiral, 0.0);
    col += bloom(r + iTime * 0.15) * spiral * 0.2 * (1.0 + air);

    // Center bloom glow
    float center = exp(-r * (3.5 - bass * 2.5));
    col += bloom(iTime * 0.3) * center * (1.5 + amp_peak * 3.0);

    col *= smoothstep(1.6, 0.3, r);
    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
