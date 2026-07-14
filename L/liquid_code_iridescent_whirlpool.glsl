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
    return fract(sin(dot(p, vec2(269.5, 183.3))) * 43758.5453);
}

float noise21(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), u.x), u.y);
}

float turbulentFbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.52;
    mat2 rotation = mat2(0.58, -0.82, 0.82, 0.58);
    for (int i = 0; i < 6; ++i) {
        value += abs(noise21(p) * 2.0 - 1.0) * amplitude;
        p = rotation * p * 2.07 + vec2(3.13, -2.41);
        amplitude *= 0.48;
    }
    return value;
}

vec2 rotate2(vec2 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * p;
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 interference(float phase, float thickness) {
    vec3 wavelengths = vec3(1.0, 0.78, 0.58);
    vec3 bands = 0.5 + 0.5 * cos(TAU * (phase + thickness * wavelengths) +
                                  vec3(0.0, 0.9, 1.7));
    return pow(bands, vec3(1.15));
}

float whirlpoolHeight(vec2 p) {
    float t = time_f;
    float radius = max(length(p), 0.018);
    float angle = atan(p.y, p.x);
    float tightening = log(radius + 0.035) * (7.8 + amp_mid * 0.9);
    float phase = angle * 6.0 + tightening - t * 1.8;

    vec2 q = rotate2(p, -log(radius + 0.05) * 0.55 + t * 0.08);
    vec2 warp = vec2(turbulentFbm(q * 3.2 + vec2(t * 0.1, 0.0)),
                     turbulentFbm(q * 3.2 + vec2(0.0, -t * 0.12) + 5.8));
    q += (warp - 0.48) * 0.19;
    float filaments = turbulentFbm(q * 7.3 + vec2(t * 0.14, -t * 0.09));
    float arms = sin(phase + filaments * 5.5) * 0.31;
    float wake = sin(radius * 58.0 - angle * 3.0 - t * 5.1 + warp.x * 4.0) * 0.1;
    float cross = cos(q.x * 36.0 + q.y * 19.0 + t * 3.8) * 0.055;
    float funnel = -exp(-radius * 6.5) * 0.62;
    return arms + wake + cross + filaments * 0.56 + funnel;
}

vec3 whirlpoolNormal(vec2 p, float e) {
    float left = whirlpoolHeight(p - vec2(e, 0.0));
    float right = whirlpoolHeight(p + vec2(e, 0.0));
    float down = whirlpoolHeight(p - vec2(0.0, e));
    float up = whirlpoolHeight(p + vec2(0.0, e));
    vec2 gradient = vec2(right - left, up - down) / (2.0 * e);
    return normalize(vec3(-gradient * 0.105, 1.0));
}

vec3 refractedTexture(vec2 uv, vec2 tangent, vec2 normalFlow, float split) {
    vec2 direction = normalize(tangent + normalFlow * 0.7 + vec2(0.0001));
    vec2 across = vec2(-direction.y, direction.x);
    vec3 source = texture(samp, mirrorUV(uv)).rgb * 0.38;
    source += texture(samp, mirrorUV(uv + direction * 0.003)).rgb * 0.2;
    source += texture(samp, mirrorUV(uv - direction * 0.003)).rgb * 0.2;
    source += texture(samp, mirrorUV(uv + across * 0.0045)).rgb * 0.11;
    source += texture(samp, mirrorUV(uv - across * 0.0045)).rgb * 0.11;
    return vec3(texture(samp, mirrorUV(uv + normalFlow * split + across * split)).r,
                source.g,
                texture(samp, mirrorUV(uv - normalFlow * split - across * split)).b);
}

float anisotropicSpecular(vec3 n, vec3 v, vec3 l, vec3 tangent, float roughness) {
    vec3 halfVector = normalize(v + l);
    vec3 bitangent = normalize(cross(n, tangent));
    float th = dot(tangent, halfVector) / max(roughness, 0.04);
    float bh = dot(bitangent, halfVector) / max(roughness * 2.4, 0.04);
    float nh = max(dot(n, halfVector), 0.0);
    return exp(-(th * th + bh * bh) / max(nh * nh, 0.015)) /
           max(4.0 * PI * roughness * roughness, 0.01);
}

vec3 iridescentMetal(vec3 base, vec3 n, vec2 p, float thickness, float roughness) {
    vec3 view = normalize(vec3(-p * 0.13, 1.45));
    vec3 light0 = normalize(vec3(-0.63, 0.51, 0.69));
    vec3 light1 = normalize(vec3(0.72, 0.24, 0.65));
    vec3 light2 = normalize(vec3(0.04, -0.76, 0.65));
    vec3 tangent = normalize(vec3(-n.y, n.x, 0.08));
    float nv = max(dot(n, view), 0.0);
    vec3 f0 = mix(vec3(0.67), base, 0.5);
    vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    vec3 film = interference((1.0 - nv) * 0.72 + time_f * 0.012, thickness);

    vec3 result = base * 0.04;
    result += base * max(dot(n, light0), 0.0) * 0.07;
    result += anisotropicSpecular(n, view, light0, tangent, roughness) *
              vec3(1.0, 0.74, 0.5) * 0.72;
    result += anisotropicSpecular(n, view, light1, tangent, roughness * 1.25) *
              vec3(0.28, 0.58, 1.0) * 0.62;
    result += anisotropicSpecular(n, view, light2, tangent, roughness * 1.7) *
              vec3(0.74, 0.24, 1.0) * 0.38;

    vec3 reflected = reflect(-view, n);
    vec3 environment = mix(vec3(0.02, 0.03, 0.062), film,
                           smoothstep(-0.6, 0.82, reflected.z));
    return result + environment * fresnel * 1.45;
}

vec3 toneMap(vec3 value) {
    value = max(value, 0.0);
    return 1.0 - exp(-value * (1.06 + value * 0.11));
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 1.5 / max(max(iResolution.x, iResolution.y), 320.0);
    float radius = max(length(p), 0.018);
    float angle = atan(p.y, p.x);
    float phase = angle * 6.0 + log(radius + 0.035) * 7.8 - time_f * 1.8;
    float height = whirlpoolHeight(p);
    vec3 n = whirlpoolNormal(p, e);

    vec2 radial = p / radius;
    vec2 tangent = vec2(-radial.y, radial.x);
    float core = exp(-radius * 3.2);
    vec2 spiralFlow = tangent * (0.022 + core * 0.058 + amp_low * 0.024);
    spiralFlow -= radial * (0.006 + core * 0.018);
    spiralFlow += n.xy * (0.017 + amp_smooth * 0.017);
    vec2 uv = mirrorUV(tc + spiralFlow / vec2(aspect, 1.0));

    float split = 0.0018 + amp_high * 0.0065 + core * 0.0015;
    vec3 source = refractedTexture(uv, tangent, n.xy, split);
    float luminance = dot(source, vec3(0.299, 0.587, 0.114));
    vec3 alloy = mix(vec3(luminance) * vec3(0.78, 0.86, 0.98), source, 0.4);
    float thickness = turbulentFbm(p * 5.1 + time_f * 0.035) + height * 0.12;
    float roughness = mix(0.08, 0.26, turbulentFbm(p * 3.8 - time_f * 0.025));
    vec3 result = iridescentMetal(alloy, n, p, thickness, roughness);

    float filament = pow(0.5 + 0.5 * sin(phase + height * 8.0), 15.0);
    result += interference(height * 0.08 + time_f * 0.018, thickness) * filament *
              (0.38 + amp_peak * 1.35);
    result = mix(result, result * (0.58 + source * 1.08), 0.22);
    color = vec4(toneMap(result * (1.0 + amp_smooth * 0.3)), texture(samp, uv).a);
}
