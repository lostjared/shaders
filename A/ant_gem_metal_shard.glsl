#version 330 core
// ant_gem_metal_shard
// Shattered metallic shards with angular fracture and spectrum-driven displacement

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 metalSpectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Angular shatter: divide into radial sectors
    float sectors = 8.0 + bass * 6.0;
    float sectorAngle = 2.0 * PI / sectors;
    float sectorID = floor(angle / sectorAngle + sectors * 0.5);
    float sectorFrac = fract(angle / sectorAngle + sectors * 0.5);

    // Radial rings
    float ringScale = 4.0 + mid * 3.0;
    float ringID = floor(r * ringScale);
    float ringFrac = fract(r * ringScale);

    // Unique shard identity
    float shardHash = hash(vec2(sectorID, ringID));

    // Shard displacement: each shard shifts outward on bass
    float displacement = shardHash * bass * 0.08;
    vec2 shardOffset = vec2(cos(sectorID * sectorAngle), sin(sectorID * sectorAngle)) * displacement;

    // Shard rotation
    float shardRot = (shardHash - 0.5) * mid * 0.3;
    vec2 shardUV = rot(shardRot) * (uv + shardOffset);

    // Map to texture
    vec2 sampUV = shardUV / vec2(aspect, 1.0) + 0.5;

    // Chromatic split
    float chroma = 0.008 + treble * 0.025;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Shard edge detection
    float edgeR = smoothstep(0.0, 0.05, ringFrac) * smoothstep(1.0, 0.95, ringFrac);
    float edgeA = smoothstep(0.0, 0.05, sectorFrac) * smoothstep(1.0, 0.95, sectorFrac);
    float edgeMask = edgeR * edgeA;
    float edgeGlow = 1.0 - edgeMask;

    // Metallic shard tint
    vec3 shardColor = metalSpectrum(shardHash * 3.0 + time_f * 0.15);
    vec3 edgeColor = metalSpectrum(time_f * 0.3 + r + angle * 0.5);

    vec3 finalColor = baseTex * edgeMask;
    finalColor = mix(finalColor, finalColor * shardColor, 0.3 + hiMid * 0.3);
    finalColor += edgeColor * edgeGlow * (1.5 + bass * 2.0);

    // Reflection highlight per shard
    float refl = pow(1.0 - abs(sectorFrac - 0.5) * 2.0, 3.0) * (0.3 + air * 0.5);
    finalColor += shardColor * refl * 0.3;

    // Central glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    finalColor += vec3(1.0, 0.97, 0.93) * center * (1.5 + amp_peak * 2.0);

    color = vec4(finalColor, 1.0);
}
