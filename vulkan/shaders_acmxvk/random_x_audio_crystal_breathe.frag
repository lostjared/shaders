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
    vec2 center = vec2(iResolution.x * 0.5, iResolution.y * 0.5);
    vec2 texCoord = tc * iResolution;
    vec2 delta = texCoord - center;
    float dist = length(delta);
    float maxRadius = min(iResolution.x, iResolution.y) * 0.5;

    // Bass makes the crystal ball breathe/pulse
    float breathe = 1.0 + amp_low * 0.3 * sin(time_f * 3.0);
    float radius = maxRadius * (0.5 + amp_smooth * 0.3) * breathe;

    vec2 newTexCoord = texCoord;
    if (dist < radius) {
        // Smooth amplitude controls distortion strength
        float strength = 1.0 - sqrt(dist / radius);
        strength *= 0.8 + amp_rms * 0.6;
        newTexCoord = center + delta * (1.0 - strength);
    }

    newTexCoord = clamp(newTexCoord / iResolution, 0.0, 1.0);

    // Mids rotate hue
    float hueRot = amp_mid * 0.2;
    vec4 tex = texture(samp, newTexCoord);
    tex.r += hueRot * sin(time_f);
    tex.g += hueRot * cos(time_f * 1.3);
    tex.b -= hueRot * sin(time_f * 0.7);

    // Treble edge glow
    float edgeDist = abs(dist - radius) / maxRadius;
    float glow = smoothstep(0.05, 0.0, edgeDist) * amp_high * 0.5;
    tex.rgb += glow;

    // Peak brightness boost
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
