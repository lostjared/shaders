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

    float speedFactor = sin(time_f * 0.5) * 0.5 + 0.5;
    float angle1 = time_f * (0.2 + speedFactor * 0.8);
    float angle2 = time_f * (0.2 + (1.0 - speedFactor) * 0.8);

    if (centeredUV.x >= 0.0) {
        mat2 rotation1 = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
        centeredUV = rotation1 * centeredUV;
    } else {
        mat2 rotation2 = mat2(cos(angle2), -sin(angle2), sin(angle2), cos(angle2));
        centeredUV = rotation2 * centeredUV;
    }

    centeredUV = abs(centeredUV);
    vec2 mirroredUV = mod(centeredUV, 1.0);
    vec4 texColor = texture(samp, mirroredUV);

    float pulse = 0.5 + 0.5 * sin(time_f * 3.0);
    vec3 pulsatingColor = vec3(
        0.5 + 0.5 * sin(time_f + uv.x * 10.0),
        0.5 + 0.5 * cos(time_f + uv.y * 10.0),
        0.5 + 0.5 * sin(time_f + (uv.x + uv.y) * 10.0)
    ) * pulse;

    color = vec4(texColor.rgb * 0.7 + pulsatingColor * 0.3, texColor.a);
    
    color = vec4(sin(color.rgb * time_f), texColor.a);
}

