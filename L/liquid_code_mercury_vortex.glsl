#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise21(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float weight = 0.5;
    mat2 turn = mat2(0.8, -0.6, 0.6, 0.8);
    for (int i = 0; i < 6; ++i) {
        value += noise21(p) * weight;
        p = turn * p * 2.03 + vec2(2.71, -1.93);
        weight *= 0.5;
    }
    return value;
}

vec2 rotate2(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c) * p;
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 spectrum(float x) {
    return 0.52 + 0.48 * cos(TAU * (x + vec3(0.02, 0.35, 0.67)));
}

float vortexHeight(vec2 p) {
    float t = time_f;
    float radius = max(length(p), 0.025);
    float angle = atan(p.y, p.x);
    float spiral = angle + log(radius) * (5.1 + amp_mid * 0.8) - t * 1.35;
    vec2 q = rotate2(p, 0.7 * sin(radius * 5.0 - t * 0.55));
    q += vec2(fbm(q * 3.1 + t * 0.11), fbm(q * 3.1 - t * 0.09 + 8.4)) * 0.16;

    float arms = sin(spiral * 3.0 + radius * 25.0);
    float ripples = sin(radius * 52.0 - t * 5.2 + fbm(q * 7.0) * 5.0);
    float folds = sin(q.x * 15.0 + fbm(q * 4.0 + t * 0.08) * 8.0);
    float turbulence = fbm(q * 6.2 + vec2(t * 0.13, -t * 0.17));
    float core = exp(-radius * 7.5);
    return arms * 0.34 + ripples * 0.11 + folds * 0.09 + turbulence * 0.62 + core * 0.5;
}

vec3 surfaceNormal(vec2 p, float e) {
    float hx0 = vortexHeight(p - vec2(e, 0.0));
    float hx1 = vortexHeight(p + vec2(e, 0.0));
    float hy0 = vortexHeight(p - vec2(0.0, e));
    float hy1 = vortexHeight(p + vec2(0.0, e));
    vec2 gradient = vec2(hx1 - hx0, hy1 - hy0) / (2.0 * e);
    return normalize(vec3(-gradient * 0.105, 1.0));
}

vec3 sampleVortexTexture(vec2 uv, vec2 direction, float split) {
    vec2 tangent = vec2(-direction.y, direction.x);
    vec2 u0 = mirrorUV(uv - tangent * 0.006);
    vec2 u1 = mirrorUV(uv + tangent * 0.006);
    vec3 soft = texture(samp, mirrorUV(uv)).rgb * 0.5;
    soft += texture(samp, u0).rgb * 0.25;
    soft += texture(samp, u1).rgb * 0.25;
    return vec3(texture(samp, mirrorUV(uv + direction * split)).r,
                soft.g,
                texture(samp, mirrorUV(uv - direction * split)).b);
}

float distributionGGX(float nh, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float d = nh * nh * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, 0.0001);
}

vec3 shadeMercury(vec3 base, vec3 n, vec2 p, float height, float roughness) {
    vec3 v = normalize(vec3(-p * 0.15, 1.35));
    vec3 lights[3] = vec3[3](normalize(vec3(-0.55, 0.45, 0.78)),
                              normalize(vec3(0.72, 0.35, 0.58)),
                              normalize(vec3(-0.12, -0.82, 0.55)));
    vec3 lightColors[3] = vec3[3](vec3(1.0, 0.72, 0.48),
                                   vec3(0.25, 0.58, 1.0),
                                   vec3(0.62, 0.22, 1.0));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.72), base, 0.48);
    vec3 result = base * 0.035;

    for (int i = 0; i < 3; ++i) {
        vec3 h = normalize(v + lights[i]);
        float nl = max(dot(n, lights[i]), 0.0);
        float nh = max(dot(n, h), 0.0);
        float vh = max(dot(v, h), 0.0);
        vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - vh, 5.0);
        result += lightColors[i] * nl *
                  (base * 0.055 + fresnel * distributionGGX(nh, roughness) * 0.18);
    }

    vec3 reflected = reflect(-v, n);
    vec3 environment = mix(vec3(0.018, 0.027, 0.055),
                           spectrum(reflected.x * 0.11 + reflected.y * 0.18 +
                                    height * 0.035 + time_f * 0.018),
                           smoothstep(-0.55, 0.85, reflected.z));
    vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    return result + environment * fresnel * 1.35;
}

vec3 toneMap(vec3 x) {
    x = max(x, 0.0);
    return 1.0 - exp(-x * (1.08 + x * 0.12));
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float pixel = 1.5 / max(max(iResolution.x, iResolution.y), 320.0);
    float height = vortexHeight(p);
    vec3 n = surfaceNormal(p, pixel);

    float radius = max(length(p), 0.02);
    vec2 radial = p / radius;
    vec2 tangent = vec2(-radial.y, radial.x);
    float pull = exp(-radius * 2.6);
    vec2 flow = tangent * (0.025 + 0.055 * pull + amp_low * 0.025);
    flow += n.xy * (0.018 + amp_smooth * 0.018);
    flow += radial * sin(radius * 34.0 - time_f * 4.0) * 0.006;
    vec2 uv = mirrorUV(tc + flow / vec2(aspect, 1.0));

    float split = 0.0018 + amp_high * 0.006 + pull * 0.002;
    vec3 source = sampleVortexTexture(uv, normalize(n.xy + tangent * 0.25 + vec2(0.0001)), split);
    float luminance = dot(source, vec3(0.299, 0.587, 0.114));
    vec3 metalBase = mix(vec3(luminance) * vec3(0.76, 0.84, 0.96), source, 0.34);
    float roughness = mix(0.075, 0.28, fbm(p * 5.0 + time_f * 0.04));
    vec3 result = shadeMercury(metalBase, n, p, height, roughness);

    float crest = pow(0.5 + 0.5 * sin(height * 10.0 - time_f * 2.2), 14.0);
    result += spectrum(height * 0.16 + time_f * 0.021) * crest * (0.3 + amp_peak * 1.3);
    result = mix(result, result * source * 1.45, 0.18);
    float alpha = texture(samp, uv).a;
    color = vec4(toneMap(result * (1.0 + amp_smooth * 0.25)), alpha);
}
