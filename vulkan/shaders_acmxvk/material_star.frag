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
#define alpha ext.u0.x
#define iResolution ext.u0.zw

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

in vec2 iResolution_;
in float timeval;
layout(set = 0, binding = 0) uniform sampler2D samp;
uniform sampler2D mat_samp;


void main() {
    float time = timeval;
    vec2 resolution = iResolution_;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    float angleRotation = time;
    float cosA = cos(angleRotation);
    float sinA = sin(angleRotation);
    mat2 rotationMat = mat2(cosA, -sinA, sinA, cosA);
    uv = rotationMat * uv;
    float radius = length(uv);
    float angle = atan(uv.y, uv.x);
    angle = mod(angle, 2.0 * 3.14159 / 5.0);
    float sharpness = 0.5;
    bool inStar = radius < (cos(sharpness) / cos(angle - sharpness));
    
    if (inStar) {
        color = texture(samp, tc);
        vec4 color2 = texture(mat_samp, tc);
        color = (0.6 * color) + (0.6 * color2);
    } else {
        color = texture(samp, tc);
    }
}

