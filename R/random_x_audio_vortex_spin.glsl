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
