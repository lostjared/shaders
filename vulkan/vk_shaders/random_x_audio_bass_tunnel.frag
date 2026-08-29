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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Bass drives tunnel zoom speed
    float speed = 2.0 + amp_low * 8.0;
    float tunnel = 1.0 / (dist + 0.1) + time_f * speed;
    float twist = angle / 3.14159 + amp_mid * sin(time_f * 1.5);

    vec2 tunnelUV = fract(vec2(tunnel, twist));

    // Treble adds chromatic split
    float chroma = amp_high * 0.03;
    float r = texture(samp, clamp(tunnelUV + vec2(chroma, 0.0), 0.0, 1.0)).r;
    float g = texture(samp, clamp(tunnelUV, 0.0, 1.0)).g;
    float b = texture(samp, clamp(tunnelUV - vec2(chroma, 0.0), 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Vignette pulses with peaks
    float vignette = smoothstep(1.5, 0.3 + amp_peak * 0.5, dist);
    col *= vignette;

    // Peak brightness flash
    col += smoothstep(0.7, 1.0, amp_peak) * 0.25;

    color = vec4(col, 1.0);
}
