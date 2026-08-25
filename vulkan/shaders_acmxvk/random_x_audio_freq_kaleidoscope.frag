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

    // RMS controls segment count (3 to 12)
    float segments = floor(mix(3.0, 12.0, clamp(amp_rms * 3.0, 0.0, 1.0)));
    float segAngle = 6.28318 / segments;
    angle = mod(angle, segAngle);
    angle = abs(angle - segAngle * 0.5);

    // Mids rotate the kaleidoscope
    float rot = time_f * (0.4 + amp_mid * 3.0);
    angle += rot;

    // Bass pulses the zoom
    float zoom = 1.0 + amp_low * 0.4 * sin(time_f * 2.0);
    dist *= zoom;

    vec2 kaleUV = vec2(cos(angle), sin(angle)) * dist;
    kaleUV.x /= aspect;
    kaleUV += 0.5;

    vec4 tex = texture(samp, clamp(kaleUV, 0.0, 1.0));

    // Treble adds subtle hue shift
    float hueShift = amp_high * 0.15;
    tex.r += hueShift;
    tex.b -= hueShift * 0.5;

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
