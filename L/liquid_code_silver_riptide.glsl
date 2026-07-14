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
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
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
    float amplitude = 0.5;
    mat2 rotation = mat2(0.76, -0.65, 0.65, 0.76);
    for (int i = 0; i < 7; ++i) {
        value += noise21(p) * amplitude;
        p = rotation * p * 2.01 + vec2(-2.2, 3.4);
        amplitude *= 0.49;
    }
    return value;
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 steelSpectrum(float x) {
    return 0.5 + 0.5 * cos(TAU * (x + vec3(0.06, 0.36, 0.67)));
}

float streamPotential(vec2 p) {
    float t = time_f;
    vec2 warp = vec2(fbm(p * 2.7 + vec2(t * 0.09, -t * 0.07)),
                     fbm(p * 2.7 + vec2(-t * 0.08, t * 0.11) + 7.3));
    vec2 q = p + (warp - 0.5) * 0.34;
    float radius = max(length(q), 0.025);
    float angle = atan(q.y, q.x);
    float spiral = sin(angle * 5.0 + log(radius) * 9.0 - t * 1.5);
    float current = sin(q.x * 6.0 + q.y * 4.0 + fbm(q * 3.2) * 5.0 - t * 0.8);
    return fbm(q * 4.5 + t * 0.04) * 0.68 + spiral * 0.2 + current * 0.12;
}

vec2 curlVelocity(vec2 p, float e) {
    float left = streamPotential(p - vec2(e, 0.0));
    float right = streamPotential(p + vec2(e, 0.0));
    float down = streamPotential(p - vec2(0.0, e));
    float up = streamPotential(p + vec2(0.0, e));
    vec2 gradient = vec2(right - left, up - down) / (2.0 * e);
    vec2 curl = vec2(gradient.y, -gradient.x);
    return curl / (1.0 + length(curl) * 0.65);
}

float riptideHeight(vec2 p) {
    float t = time_f;
    float radius = max(length(p), 0.025);
    float angle = atan(p.y, p.x);
    vec2 velocity = curlVelocity(p, 0.0045);
    vec2 q = p + velocity * 0.055;
    float flow = streamPotential(q);
    float wake = sin(dot(q, normalize(vec2(0.82, 0.57))) * 31.0 - t * 4.7 + flow * 8.0);
    float spiralWake = sin(angle * (6.0 + amp_mid) + radius * 38.0 - t * 3.4 + flow * 4.0);
    float capillary = sin(q.x * 64.0 - q.y * 41.0 + t * 5.3) *
                      sin(q.y * 37.0 + t * 3.1);
    return flow * 0.62 + wake * 0.1 + spiralWake * 0.16 + capillary * 0.045;
}

vec3 waterNormal(vec2 p, float e) {
    float h = riptideHeight(p);
    float hx = riptideHeight(p + vec2(e, 0.0));
    float hy = riptideHeight(p + vec2(0.0, e));
    vec2 gradient = vec2(hx - h, hy - h) / e;
    return normalize(vec3(-gradient * 0.11, 1.0));
}

vec3 filteredTexture(vec2 uv, vec2 flow, vec2 normalFlow, float split) {
    vec2 direction = normalize(flow + normalFlow + vec2(0.0001));
    vec2 across = vec2(-direction.y, direction.x);
    vec3 source = texture(samp, mirrorUV(uv)).rgb * 0.34;
    source += texture(samp, mirrorUV(uv + direction * 0.0035)).rgb * 0.22;
    source += texture(samp, mirrorUV(uv - direction * 0.0035)).rgb * 0.22;
    source += texture(samp, mirrorUV(uv + direction * 0.007)).rgb * 0.11;
    source += texture(samp, mirrorUV(uv - direction * 0.007)).rgb * 0.11;
    return vec3(texture(samp, mirrorUV(uv + across * split)).r,
                source.g,
                texture(samp, mirrorUV(uv - across * split)).b);
}

float ggx(float nh, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float d = nh * nh * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, 0.0001);
}

vec3 shadeSilver(vec3 base, vec3 n, vec2 p, float flowPhase, float roughness) {
    vec3 view = normalize(vec3(-p * 0.1, 1.5));
    vec3 lights[3] = vec3[3](normalize(vec3(-0.66, 0.54, 0.66)),
                              normalize(vec3(0.75, 0.27, 0.61)),
                              normalize(vec3(0.03, -0.81, 0.59)));
    vec3 colors[3] = vec3[3](vec3(1.0, 0.78, 0.56),
                              vec3(0.26, 0.58, 1.0),
                              vec3(0.54, 0.28, 1.0));
    vec3 f0 = mix(vec3(0.74), base, 0.45);
    vec3 result = base * 0.036;

    for (int i = 0; i < 3; ++i) {
        vec3 halfVector = normalize(view + lights[i]);
        float nl = max(dot(n, lights[i]), 0.0);
        float nh = max(dot(n, halfVector), 0.0);
        float vh = max(dot(view, halfVector), 0.0);
        vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - vh, 5.0);
        result += colors[i] * nl *
                  (base * 0.052 + fresnel * ggx(nh, roughness) * 0.2);
    }

    float nv = max(dot(n, view), 0.0);
    vec3 reflection = reflect(-view, n);
    vec3 environment = mix(vec3(0.018, 0.029, 0.058),
                           steelSpectrum(reflection.x * 0.13 + reflection.y * 0.19 +
                                         flowPhase * 0.04 + time_f * 0.015),
                           smoothstep(-0.6, 0.82, reflection.z));
    vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    return result + environment * fresnel * 1.4;
}

vec3 toneMap(vec3 value) {
    value = max(value, 0.0);
    return value / (0.82 + value);
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 1.7 / max(max(iResolution.x, iResolution.y), 320.0);
    float height = riptideHeight(p);
    vec3 n = waterNormal(p, e);
    vec2 velocity = curlVelocity(p, 0.0045);

    float radius = max(length(p), 0.02);
    vec2 tangent = vec2(-p.y, p.x) / radius;
    velocity += tangent * exp(-radius * 3.0) * (0.55 + amp_low * 0.45);
    velocity = velocity / (1.0 + length(velocity));
    vec2 flow = velocity * (0.032 + amp_low * 0.018);
    vec2 normalFlow = n.xy * (0.018 + amp_smooth * 0.017);
    vec2 uv = mirrorUV(tc + (flow + normalFlow) / vec2(aspect, 1.0));

    float split = 0.0016 + amp_high * 0.006;
    vec3 source = filteredTexture(uv, flow, normalFlow, split);
    float luminance = dot(source, vec3(0.299, 0.587, 0.114));
    vec3 silver = mix(vec3(luminance) * vec3(0.81, 0.88, 0.98), source, 0.36);
    float roughness = mix(0.065, 0.27, fbm(p * 4.2 + time_f * 0.035));
    vec3 result = shadeSilver(silver, n, p, height, roughness);

    float caustic = pow(0.5 + 0.5 * sin(height * 13.0 - time_f * 2.4), 16.0);
    result += steelSpectrum(height * 0.12 + time_f * 0.019) * caustic *
              (0.34 + amp_peak * 1.3);
    result = mix(result, result * (0.62 + source), 0.22);
    color = vec4(toneMap(result * (1.0 + amp_smooth * 0.28)), texture(samp, uv).a);
}
