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
    vec2 center = vec2(0.5);
    vec2 dir = tc - center;

    // Peak triggers zoom strobe - snap between zoom in/out
    float zoomBase = 1.0;
    float zoomStrobe = amp_peak * 0.3 * sin(time_f * 15.0);
    float zoom = zoomBase + zoomStrobe;

    // Bass adds smooth zoom breathing
    zoom += amp_low * 0.15 * sin(time_f * 2.0);

    vec2 uv = center + dir * zoom;
    uv = clamp(uv, 0.0, 1.0);

    // Mids add rotation during zoom
    float angle = amp_mid * 0.3 * sin(time_f * 3.0);
    vec2 rotDir = dir;
    float c = cos(angle), s = sin(angle);
    rotDir = vec2(c * dir.x - s * dir.y, s * dir.x + c * dir.y);
    vec2 uv2 = center + rotDir * zoom;
    uv2 = clamp(uv2, 0.0, 1.0);

    // Blend between normal and rotated zoom
    vec3 col1 = texture(samp, uv).rgb;
    vec3 col2 = texture(samp, uv2).rgb;
    vec3 col = mix(col1, col2, 0.5);

    // Treble adds afterimage trail
    vec2 trailUV = center + dir * (zoom * 0.95);
    trailUV = clamp(trailUV, 0.0, 1.0);
    vec3 trail = texture(samp, trailUV).rgb;
    col = mix(col, trail, amp_high * 0.3);

    // Peak white flash
    col += smoothstep(0.7, 1.0, amp_peak) * 0.3;

    // Smooth global brightness
    col *= 1.0 + amp_smooth * 0.15;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
