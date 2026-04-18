#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

vec2 mirrorWrap(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Mids drive twist strength
    float twistStrength = 5.0 + amp_mid * 20.0;
    float twistAngle = (1.0 - smoothstep(0.0, 1.0, dist)) * twistStrength * sin(time_f * (0.3 + amp_mid));

    angle += twistAngle;

    // Apply mirror after twist
    vec2 twisted = vec2(cos(angle), sin(angle)) * dist;
    twisted.x /= aspect;
    twisted += 0.5;

    // Bass mirror fold count
    float foldIntensity = 1.0 + amp_low * 3.0;
    vec2 mirrored = mirrorWrap(twisted * foldIntensity);

    // Treble micro distortion
    mirrored.x += amp_high * 0.008 * sin(mirrored.y * 50.0 + time_f * 8.0);
    mirrored.y += amp_high * 0.006 * cos(mirrored.x * 40.0 + time_f * 6.0);

    vec4 tex = texture(samp, clamp(mirrored, 0.0, 1.0));

    // RMS color enhancement
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.2, 0.9, 1.1), amp_rms * 0.4);

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    // Smooth vignette
    float vign = smoothstep(1.2, 0.3 + amp_smooth * 0.3, dist);
    tex.rgb *= vign;

    color = tex;
}
