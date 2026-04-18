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
