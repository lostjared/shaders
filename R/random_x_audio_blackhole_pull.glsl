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
    vec2 uv = (tc * 2.0 - 1.0) * vec2(aspect, 1.0);
    float dist = length(uv);

    // Bass controls gravitational pull strength
    float pullStrength = 0.5 + amp_low * 3.0;
    float pullIntensity = pow(dist, 1.0 + pullStrength);
    vec2 pulledUV = uv * pullIntensity;

    // Mids add orbital spin
    float angle = atan(uv.y, uv.x);
    float spin = time_f * (0.3 + amp_mid * 2.0) + amp_mid * 3.0 / (dist + 0.2);
    angle += spin;
    pulledUV = vec2(cos(angle), sin(angle)) * length(pulledUV);

    // Convert back to texture coords
    pulledUV = (pulledUV / vec2(aspect, 1.0)) * 0.5 + 0.5;
    pulledUV = abs(mod(pulledUV, 2.0) - 1.0);

    // Treble chromatic split at event horizon
    float chroma = amp_high * 0.03 / (dist + 0.1);
    vec2 chromaDir = normalize(uv + 0.001);
    float r = texture(samp, clamp(pulledUV + chromaDir * chroma * 0.01, 0.0, 1.0)).r;
    float g = texture(samp, clamp(pulledUV, 0.0, 1.0)).g;
    float b = texture(samp, clamp(pulledUV - chromaDir * chroma * 0.01, 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Dark center vignette (event horizon)
    float horizon = smoothstep(0.05, 0.2 + amp_peak * 0.1, dist);
    col *= horizon;

    // Peak accretion glow
    float ringDist = abs(dist - 0.3 - amp_low * 0.2);
    float ring = smoothstep(0.05, 0.0, ringDist) * (1.0 + amp_peak * 2.0);
    col += ring * vec3(1.0, 0.5, 0.2) * 0.3;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
