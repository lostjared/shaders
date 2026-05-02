#version 330 core
// Phantom Drift — Ghost trails that smear outward from center
// Each cache layer is sampled with increasing radial offset, creating
// an expanding phantom aura around moving objects.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

uniform vec2 iResolution;
uniform float time_f;

vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0)
        return texture(samp1, uv);
    if (idx == 1)
        return texture(samp2, uv);
    if (idx == 2)
        return texture(samp3, uv);
    if (idx == 3)
        return texture(samp4, uv);
    if (idx == 4)
        return texture(samp5, uv);
    if (idx == 5)
        return texture(samp6, uv);
    if (idx == 6)
        return texture(samp7, uv);
    return texture(samp8, uv);
}

void main(void) {
    vec2 center = vec2(0.5);
    vec2 dir = tc - center;
    float dist = length(dir);
    vec2 normDir = normalize(dir + 0.0001);

    vec4 current = texture(samp, tc);

    // Each older frame is sampled further outward along the radial direction
    // creating a "soul leaving the body" drift effect
    vec3 ghostAccum = vec3(0.0);
    float totalWeight = 0.0;

    for (int i = 0; i < 8; i++) {
        float age = float(i + 1) / 8.0;
        float weight = 1.0 - age * 0.85;

        // Radial expansion: older frames drift further out
        float expansion = age * 0.04 * (1.0 + 0.5 * sin(time_f * 1.2 + float(i)));

        // Also add a slow rotation per layer
        float rotAngle = age * 0.15 * sin(time_f * 0.3);
        float cs = cos(rotAngle), sn = sin(rotAngle);
        vec2 rotDir = vec2(normDir.x * cs - normDir.y * sn,
                           normDir.x * sn + normDir.y * cs);

        vec2 offsetUV = tc + rotDir * expansion;
        vec4 cached = sampleCache(i, offsetUV);

        // Hue shift the ghost based on age — warm to cool
        vec3 tinted = cached.rgb;
        tinted.r *= 1.0 - age * 0.3;
        tinted.b *= 1.0 + age * 0.4;

        ghostAccum += tinted * weight;
        totalWeight += weight;
    }

    ghostAccum /= totalWeight;

    // Lighten blend: take the brighter of current or ghost
    vec3 result = max(current.rgb, ghostAccum * 0.85);

    // Add ethereal glow at edges where ghosts are strongest
    float edgeGlow = smoothstep(0.1, 0.5, dist) * 0.2;
    result += ghostAccum * edgeGlow;

    color = vec4(result, 1.0);
}
