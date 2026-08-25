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



float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = tc;

    float lineWidth = 0.01 + 0.005 * sin(time_f * 2.0);
    float splitOffset = 0.05 * sin(time_f * 1.5);
    float linePosition = abs(fract(uv.y * 10.0 + time_f) - 0.5);
    float frameSep = mod(floor(uv.x * 5.0) + floor(uv.y * 5.0), 2.0);

    vec2 displacedUV = uv;
    if (frameSep == 0.0) {
        displacedUV.x += splitOffset;
    } else {
        displacedUV.x -= splitOffset;
    }

    vec4 texColor = texture(samp, displacedUV);

    if (linePosition < lineWidth) {
        texColor.rgb += vec3(1.0, 0.0, 0.0) * abs(sin(time_f)); // Highlight lines in red
    }

    color = texColor;
}

