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
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), f.x), f.y);
}

float ridgedFbm(vec2 p) {
    float sum = 0.0;
    float amplitude = 0.52;
    mat2 basis = mat2(0.707, -0.707, 0.707, 0.707);
    for (int i = 0; i < 6; ++i) {
        float ridge = 1.0 - abs(valueNoise(p) * 2.0 - 1.0);
        sum += ridge * ridge * amplitude;
        p = basis * p * 2.08 + vec2(-3.7, 1.9);
        amplitude *= 0.48;
    }
    return sum;
}

vec2 rotate2(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c) * p;
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 thinFilm(float phase) {
    vec3 wave = vec3(1.0, 0.79, 0.58);
    return 0.5 + 0.5 * cos(TAU * (phase * wave + vec3(0.00, 0.17, 0.39)));
}

float shellHeight(vec2 p) {
    float t = time_f;
    float r = max(length(p), 0.018);
    float a = atan(p.y, p.x);
    float logarithmic = log(r + 0.045);
    float chamberPhase = a * 7.0 - logarithmic * 15.0 - t * 1.75;
    chamberPhase += sin(a * 2.0 + t * 0.35) * amp_mid * 0.85;
    float ribs = cos(chamberPhase) * exp(-r * 0.34);

    // Keep angular domain warping periodic across atan's -PI/PI branch cut.
    float angularCurl = sin(a * 3.0 - t * 0.18) * 0.22;
    vec2 curled = rotate2(p, angularCurl - logarithmic * 0.7 + t * 0.07);
    float liquid = ridgedFbm(curled * 4.8 + vec2(t * 0.11, -t * 0.08));
    float rings = sin(r * 69.0 - a * 2.0 - t * 4.4 + liquid * 3.0);
    float membrane = cos(a * 2.0 + r * 18.0 + sin(a * 5.0 - t) * 1.4);
    float centralPool = exp(-r * 8.0) * sin(a * 4.0 - t * 3.0);
    return ribs * 0.32 + rings * 0.08 + membrane * 0.11 + liquid * 0.58 + centralPool * 0.32;
}

vec3 shellNormal(vec2 p, float e) {
    float center = shellHeight(p);
    float right = shellHeight(p + vec2(e, 0.0));
    float up = shellHeight(p + vec2(0.0, e));
    vec2 gradient = vec2(right - center, up - center) / e;
    return normalize(vec3(-gradient * 0.12, 1.0));
}

vec3 textureAlongShell(vec2 uv, vec2 curl, vec2 normalFlow, float dispersion) {
    vec2 axis = normalize(curl + normalFlow * 0.5 + vec2(0.0001));
    vec2 across = vec2(-axis.y, axis.x);
    vec2 center = mirrorUV(uv);
    vec3 axialBlur = texture(samp, center).rgb * 0.42;
    axialBlur += texture(samp, mirrorUV(uv + axis * 0.0045)).rgb * 0.2;
    axialBlur += texture(samp, mirrorUV(uv - axis * 0.0045)).rgb * 0.2;
    axialBlur += texture(samp, mirrorUV(uv + across * 0.003)).rgb * 0.09;
    axialBlur += texture(samp, mirrorUV(uv - across * 0.003)).rgb * 0.09;
    return vec3(texture(samp, mirrorUV(uv + across * dispersion)).r,
                axialBlur.g,
                texture(samp, mirrorUV(uv - across * dispersion)).b);
}

float ggx(float nh, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float denominator = nh * nh * (a2 - 1.0) + 1.0;
    return a2 / max(PI * denominator * denominator, 0.0001);
}

vec3 chromeLighting(vec3 base, vec3 n, vec2 p, float phase, float roughness) {
    vec3 view = normalize(vec3(-p * 0.12, 1.45));
    vec3 light0 = normalize(vec3(-0.72, 0.38, 0.68));
    vec3 light1 = normalize(vec3(0.56, 0.66, 0.51));
    vec3 light2 = normalize(vec3(0.25, -0.72, 0.65));
    vec3 lights[3] = vec3[3](light0, light1, light2);
    vec3 colors[3] = vec3[3](vec3(1.0, 0.58, 0.28),
                              vec3(0.30, 0.62, 1.0),
                              vec3(0.72, 0.25, 1.0));
    vec3 f0 = mix(vec3(0.68), base, 0.52);
    vec3 result = base * 0.04;

    for (int i = 0; i < 3; ++i) {
        vec3 halfVector = normalize(view + lights[i]);
        float nl = max(dot(n, lights[i]), 0.0);
        float nh = max(dot(n, halfVector), 0.0);
        float vh = max(dot(view, halfVector), 0.0);
        vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - vh, 5.0);
        result += colors[i] * nl *
                  (base * 0.065 + fresnel * ggx(nh, roughness) * 0.2);
    }

    float nv = max(dot(n, view), 0.0);
    vec3 reflection = reflect(-view, n);
    vec3 environment = mix(vec3(0.025, 0.035, 0.065),
                           thinFilm(sin(phase) * 0.18 + reflection.y * 0.14 + time_f * 0.013),
                           smoothstep(-0.65, 0.75, reflection.z));
    vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    return result + environment * fresnel * 1.5;
}

vec3 toneMap(vec3 value) {
    value = max(value, 0.0);
    return value / (1.0 + value * 0.72);
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 1.6 / max(max(iResolution.x, iResolution.y), 320.0);
    float radius = max(length(p), 0.018);
    float angle = atan(p.y, p.x);
    float phase = angle * 7.0 - log(radius + 0.045) * 15.0 - time_f * 1.75;
    float height = shellHeight(p);
    vec3 n = shellNormal(p, e);

    vec2 radial = p / radius;
    vec2 tangent = vec2(-radial.y, radial.x);
    float curlStrength = 0.018 + 0.045 * exp(-radius * 2.2) + amp_low * 0.022;
    vec2 curl = tangent * curlStrength;
    curl += radial * sin(phase + height * 2.0) * 0.009;
    vec2 normalFlow = n.xy * (0.018 + amp_smooth * 0.014);
    vec2 uv = mirrorUV(tc + (curl + normalFlow) / vec2(aspect, 1.0));

    float dispersion = 0.0015 + amp_high * 0.006 + abs(sin(phase)) * 0.0015;
    vec3 source = textureAlongShell(uv, curl, normalFlow, dispersion);
    float luminance = dot(source, vec3(0.299, 0.587, 0.114));
    vec3 chrome = mix(vec3(luminance) * vec3(0.83, 0.89, 1.0), source, 0.38);
    float roughness = mix(0.07, 0.3, ridgedFbm(p * 3.6 + time_f * 0.035));
    vec3 result = chromeLighting(chrome, n, p, phase + height, roughness);

    float ribHighlight = pow(0.5 + 0.5 * cos(phase), 18.0);
    result += thinFilm(sin(phase) * 0.15 + height * 0.09) * ribHighlight *
              (0.35 + amp_peak * 1.25);
    result = mix(result, result * (0.55 + source * 1.1), 0.2);
    color = vec4(toneMap(result * (1.0 + amp_smooth * 0.3)), texture(samp, uv).a);
}
