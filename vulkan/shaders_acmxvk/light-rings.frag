#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 0.0;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(st);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    vec2 uv = tc;
    vec2 center = iResolution * 0.5;
    vec2 pos = uv * iResolution - center;
    float dist = length(pos);
    float angle = atan(pos.y, pos.x);
    float lightning = smoothstep(0.1, 0.12, fbm(vec2(angle * 8.0, time_f * 0.5) + vec2(dist * 0.1)));
    float brightness = lightning * (1.0 - dist / (iResolution.x * 0.5));
    float time_z = pingPong(time_f, 5.0) + 2.0;
    brightness = sin(brightness * time_z);
    vec4 texColor = texture(samp, uv);
    
    float time_t = pingPong(time_f, 10.0) + 2.0;
    
    color = texColor + sin(vec4(vec3(brightness), 1.0) * time_t);
    color.a = 1.0;
}
