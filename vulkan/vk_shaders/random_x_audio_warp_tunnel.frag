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

    // Bass drives tunnel depth zoom
    float tunnelDepth = 1.0 / (dist + 0.05) + time_f * (1.5 + amp_low * 6.0);

    // Mids twist the tunnel walls
    float twist = angle + time_f * (0.2 + amp_mid * 2.0) + amp_mid * sin(tunnelDepth * 0.5) * 1.5;

    vec2 tunnelUV = fract(vec2(tunnelDepth * 0.2, twist / 6.28318));

    // Treble adds radial wave distortion in the tunnel
    tunnelUV.x += amp_high * 0.02 * sin(tunnelUV.y * 20.0 + time_f * 5.0);

    // Wrap UVs
    tunnelUV = abs(mod(tunnelUV, 2.0) - 1.0);

    vec4 tex = texture(samp, clamp(tunnelUV, 0.0, 1.0));

    // Depth fog - closer = brighter, far = darker
    float fog = smoothstep(1.5, 0.1, dist);
    fog = mix(fog, 1.0, amp_smooth * 0.4);
    tex.rgb *= fog;

    // RMS ring glow
    float ringGlow = smoothstep(0.03, 0.0, abs(dist - 0.2 - amp_rms * 0.3));
    tex.rgb += ringGlow * vec3(0.2, 0.6, 1.0) * 0.5;

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = tex;
}
