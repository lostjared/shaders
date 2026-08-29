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
