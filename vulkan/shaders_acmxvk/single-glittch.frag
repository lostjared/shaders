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
#define alpha_r ext.custom_uniforms[0].z
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc; // Texture coordinates passed from vertex shader
layout(set = 0, binding = 0) uniform sampler2D samp; // Single texture unit for all mappings and manipulations




const float PI = 3.1415926535897932384626433832795;

// Function to generate a detailed noise pattern based on simplex noise method
float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float a = dot(sin(ip), vec2(1.0, 17.0));
    float b = dot(cos(ip), vec2(1.0, 17.0));
    float n_x = mix(mix(a, b, fp.x), mix(sin(a), cos(b), fp.x), fp.y);
    return n_x;
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main() {
    vec2 uv = tc;
    int OCTAVES = int(alpha_r * pingPong(time_f*PI, 10.0));
    float detailNoise = 0.0;
    for (int i = 0; i < OCTAVES; ++i) {
        float freq = pow(2.0, float(i));
        float amp = pow(0.5, float(OCTAVES - i));
        detailNoise += noise(uv * freq) * freq * sin(amp * time_f);
    }
    uv += vec2(detailNoise) * 0.1;
    color = texture(samp, uv);
}
