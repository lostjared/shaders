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

layout(set = 0, binding = 0) uniform sampler2D samp;


layout(location = 0) out vec4 color;

void main() {
    vec2 uv = gl_FragCoord.xy / iResolution;
    vec2 centeredUV = uv * 2.0 - 1.0;
    float angle = atan(centeredUV.y, centeredUV.x);
    float radius = length(centeredUV);
    float spin = time_f * 0.5;
    angle += floor(mod(angle + 3.14159, 3.14159 / 4.0)) * spin;
    vec2 rotatedUV = vec2(cos(angle), sin(angle)) * radius;
    rotatedUV = abs(mod(rotatedUV, 2.0) - 1.0);
    vec4 texColor = texture(samp, rotatedUV * 0.5 + 0.5);
    vec3 gradientEffect = vec3(
        0.5 + 0.5 * sin(time_f + uv.x * 15.0),
        0.5 + 0.5 * cos(time_f + uv.y * 15.0),
        0.5 + 0.5 * sin(time_f + (uv.x + uv.y) * 15.0)
    );
    vec3 finalColor = mix(texColor.rgb, gradientEffect, 0.3);
    color = vec4(finalColor, texColor.a);
}

