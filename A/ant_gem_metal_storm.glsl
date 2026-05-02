#version 330 core
// ant_gem_metal_storm
// Electric metallic storm with lightning bolts and spectrum-driven intensity

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 metalSpectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float lightning(vec2 uv, float seed) {
    // Jagged line from top to bottom
    float x = 0.0;
    float intensity = 0.0;
    float y = uv.y;
    for (float i = 0.0; i < 8.0; i++) {
        x += (hash(vec2(i, seed + floor(time_f * 4.0))) - 0.5) * 0.15;
        float segY = -1.0 + i * 0.25;
        float nextY = -1.0 + (i + 1.0) * 0.25;
        if (y > segY && y < nextY) {
            float t = (y - segY) / (nextY - segY);
            float boltX = x * t + (x + (hash(vec2(i + 1.0, seed + floor(time_f * 4.0))) - 0.5) * 0.15) * (1.0 - t);
            float d = abs(uv.x - boltX);
            intensity = max(intensity, exp(-d * 60.0));
        }
    }
    return intensity;
}

void main(void) {
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Storm cloud noise
    float cloud = noise(uv * 3.0 + time_f * 0.5) * 0.5;
    cloud += noise(uv * 6.0 - time_f * 0.3) * 0.3;
    cloud += noise(uv * 12.0 + time_f * 0.7) * 0.2;
    cloud *= 0.8 + bass * 0.5;

    // Lightning bolts triggered by peak amplitude
    float bolt1 = lightning(uv * vec2(1.0, 0.8) + vec2(0.2, 0.0), 1.0);
    float bolt2 = lightning(uv * vec2(1.0, 0.8) - vec2(0.3, 0.0), 7.0);
    float bolt3 = lightning(uv * vec2(1.0, 0.8) + vec2(-0.1, 0.0), 13.0);
    float bolts = max(bolt1, max(bolt2, bolt3));
    bolts *= smoothstep(0.4, 0.8, amp_peak); // only flash on peaks

    // Texture warp from storm
    vec2 stormWarp = vec2(cloud - 0.5) * (0.02 + mid * 0.03);
    vec2 sampUV = tc + stormWarp;

    // Chromatic split
    float chroma = 0.01 + treble * 0.025 + bolts * 0.02;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Dark storm atmosphere
    float darkness = 0.7 + cloud * 0.3;
    baseTex *= darkness;

    // Lightning color: electric blue-white metallic
    vec3 boltColor = mix(vec3(0.5, 0.7, 1.0), vec3(1.0), bolts);
    baseTex += boltColor * bolts * (3.0 + hiMid * 4.0);

    // Metallic storm coloring
    vec3 stormColor = metalSpectrum(cloud + time_f * 0.15 + r) * vec3(0.6, 0.7, 1.0);
    float stormMask = smoothstep(0.4, 0.7, cloud);
    vec3 finalColor = mix(baseTex, baseTex * stormColor, stormMask * (0.3 + mid * 0.3));

    // Flash brightness on peak
    finalColor *= 1.0 + amp_peak * bolts * 2.0;

    // Central glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    finalColor += vec3(0.7, 0.8, 1.0) * center * (1.5 + amp_peak * 2.0);

    color = vec4(finalColor, 1.0);
}
