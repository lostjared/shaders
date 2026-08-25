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
    vec4 texColor = texture(samp, uv);

    float pulse = 0.5 + 0.5 * sin(time_f * 4.0);
    
    vec2 trailOffset1 = vec2(0.02, 0.03) * sin(time_f * 3.0 + length(uv - 0.5) * 15.0) * pulse;
    vec2 trailOffset2 = vec2(-0.03, 0.02) * cos(time_f * 2.0 + length(uv - 0.5) * 20.0) * pulse;
    vec2 trailOffset3 = vec2(0.01, -0.01) * sin(time_f * 5.0) * (1.0 - pulse);

    vec3 trail1 = texture(samp, uv + trailOffset1).rgb * 0.7;
    vec3 trail2 = texture(samp, uv + trailOffset2).rgb * 0.5;
    vec3 trail3 = texture(samp, uv + trailOffset3).rgb * 0.3;

    vec3 energyGlow = vec3(
        0.5 + 0.5 * sin(time_f + uv.x * 25.0),
        0.5 + 0.5 * cos(time_f * 1.2 + uv.y * 25.0),
        0.5 + 0.5 * sin(time_f * 0.8 + uv.x * uv.y * 25.0)
    );

    vec3 finalColor = mix(trail1 + trail2 + trail3, energyGlow, 0.6);
    finalColor *= 0.8 + 0.2 * sin(time_f * 6.0 + length(uv - 0.5) * 10.0);

    color = vec4(finalColor, texColor.a);
}

