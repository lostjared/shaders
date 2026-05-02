#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec3 compositeEffect(vec2 uv) {
    float offset = 0.01;
    vec3 col;
    col.r = texture(samp, uv + vec2(offset, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(offset, 0.0)).b;
    float noise = fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
    col += noise * 0.05;
    float scanline = sin(uv.y * iResolution.y * 1.5) * 0.1;
    col -= scanline;
    float bleed = sin(uv.y * iResolution.y * 0.2 + time_f * 5.0) * 0.005;
    col.r += bleed * 0.002;
    col.b -= bleed * 0.002;
    return col;
}

vec3 aces(vec3 x) {
    const mat3 a = mat3(0.59719, 0.35458, 0.04823, 0.07600, 0.90834, 0.01566, 0.02840, 0.13383, 0.83777);
    const mat3 b = mat3(1.60475, -0.53108, -0.07367, -0.10208, 1.10813, -0.00605, -0.00327, -0.07276, 1.07602);
    vec3 v = a * x;
    v = (v * (v + 0.0245786) - 0.000090537) * b;
    return clamp(v, 0.0, 1.0);
}

float hash12(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123); }

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 c = vec2(0.5);

    vec2 p = (tc - c) * ar;
    float r2 = dot(p, p);
    float k1 = 0.15;
    float k2 = 0.05;
    vec2 pd = p * (1.0 + k1 * r2 + k2 * r2 * r2);
    vec2 uvd = pd / ar + c;

    vec2 dir = normalize(p + 1e-6);
    float ab = 0.0015 + 0.0015 * sin(time_f * 0.5);
    vec2 uvR = uvd + dir * ab;
    vec2 uvG = uvd;
    vec2 uvB = uvd - dir * ab;

    uvR = clamp(uvR, 0.0, 1.0);
    uvG = clamp(uvG, 0.0, 1.0);
    uvB = clamp(uvB, 0.0, 1.0);

    vec3 cR = compositeEffect(uvR);
    vec3 cG = compositeEffect(uvG);
    vec3 cB = compositeEffect(uvB);
    vec3 col = vec3(cR.r, cG.g, cB.b);

    vec2 ts = 1.0 / iResolution;
    float shAmt = 0.4;
    vec3 bsum = vec3(0.0);
    bsum += compositeEffect(uvd + vec2(1, 1) * ts);
    bsum += compositeEffect(uvd + vec2(-1, 1) * ts);
    bsum += compositeEffect(uvd + vec2(1, -1) * ts);
    bsum += compositeEffect(uvd + vec2(-1, -1) * ts);
    bsum *= 0.25;
    col += (col - bsum) * shAmt;

    float v = smoothstep(0.95, 0.3, length(p));
    col *= v;

    float gAmt = 0.03;
    float g = hash12(gl_FragCoord.xy + time_f * 123.45) - 0.5;
    col += g * gAmt;

    col = aces(col);
    col = pow(col, vec3(1.0 / 2.2));

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
