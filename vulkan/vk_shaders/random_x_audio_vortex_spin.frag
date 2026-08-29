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
    vec2 centered = (tc - 0.5) * vec2(aspect, 1.0);
    float dist = length(centered);
    float angle = atan(centered.y, centered.x);

    // Mids drive spin speed, bass drives tightness
    float spinSpeed = 3.0 + amp_mid * 12.0;
    float tightness = 8.0 + amp_low * 15.0;
    angle += (1.0 / (dist + 0.1)) * sin(time_f * 0.5) * 0.3;
    angle += (1.0 - smoothstep(0.0, 1.5, dist)) * time_f * spinSpeed;

    // Bass pulses the radial stretch
    float stretch = 1.0 + amp_low * 0.25 * sin(dist * tightness - time_f * 4.0);
    dist *= stretch;

    vec2 vortexUV = vec2(cos(angle), sin(angle)) * dist;
    vortexUV.x /= aspect;
    vortexUV += 0.5;

    // Wrap UVs
    vortexUV = abs(mod(vortexUV, 2.0) - 1.0);

    vec4 tex = texture(samp, clamp(vortexUV, 0.0, 1.0));

    // Treble chromatic ring
    float ring = smoothstep(0.02, 0.0, abs(dist - 0.5 - amp_high * 0.3));
    tex.rgb += ring * vec3(0.3, 0.1, 0.5) * amp_high;

    // Peak flash
    tex.rgb *= 1.0 + smoothstep(0.5, 1.0, amp_peak) * 0.4;

    color = tex;
}
