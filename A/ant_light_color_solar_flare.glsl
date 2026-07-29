#version 330 core
// ant_light_color_solar_flare
// Solar surface with magnetic flare arcs and corona light bloom

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 solar(float t) {
    vec3 a = vec3(0.6, 0.3, 0.05);
    vec3 b = vec3(0.4, 0.3, 0.15);
    vec3 c = vec3(1.5, 1.0, 0.5);
    vec3 d = vec3(0.0, 0.1, 0.2);
    return a + b * cos(TAU * (c * t + d));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Solar surface turbulence
    float surface = fbm(uv * 5.0 + iTime * 0.3 + bass);
    surface += fbm(uv * 10.0 - iTime * 0.5) * 0.5;

    // Flare arcs: parabolic arcs from surface
    float flareArc = 0.0;
    for (float i = 0.0; i < 4.0; i++) {
        float arcAngle = i * 1.57 + iTime * 0.2 + bass * i;
        vec2 arcCenter = vec2(cos(arcAngle), sin(arcAngle)) * 0.3;
        float arcDist = length(uv - arcCenter);
        float arc = smoothstep(0.02, 0.0, abs(arcDist - 0.2 - mid * 0.1));
        arc *= step(0.0, dot(normalize(uv - arcCenter), normalize(arcCenter)));
        flareArc += arc;
    }

    // Texture through solar distortion
    vec2 distort = uv + normalize(uv + 0.001) * surface * 0.04;
    vec2 sampUV = distort * 0.5 + 0.5;

    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Solar color overlay
    col *= solar(surface + iTime * 0.05);

    // Flare glow
    col += solar(iTime * 0.3 + r) * flareArc * (3.0 + air * 4.0);

    // Corona bloom
    float corona = exp(-r * (2.0 - bass * 1.5)) * (1.0 + surface * 0.5);
    col += solar(iTime * 0.1) * corona * (1.0 + amp_peak * 3.0);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
