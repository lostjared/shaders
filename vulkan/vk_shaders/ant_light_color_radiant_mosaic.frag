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
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iTime ext.u0.y

// ant_light_color_radiant_mosaic
// Voronoi mosaic tiles radiating light with spectrum-driven tile color and glow edges
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




layout(set = 0, binding = 3) uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
    return vec2(hash(p), hash(p + 31.0));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = tc;

    // Voronoi mosaic
    float scale = 8.0 + bass * 4.0;
    vec2 p = uv * scale;
    vec2 ip = floor(p);
    vec2 fp = fract(p);

    float minDist = 10.0;
    float secondDist = 10.0;
    vec2 closestCell = vec2(0.0);

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = hash2(ip + neighbor);
            point = 0.5 + 0.4 * sin(iTime * 0.5 + TAU * point);
            float d = length(neighbor + point - fp);
            if (d < minDist) {
                secondDist = minDist;
                minDist = d;
                closestCell = ip + neighbor;
            } else if (d < secondDist) {
                secondDist = d;
            }
        }
    }

    float edge = secondDist - minDist;
    float edgeLine = smoothstep(0.0, 0.08, edge);

    // Texture per tile with offset
    float cellHash = hash(closestCell);
    vec2 tileOffset = (hash2(closestCell) - 0.5) * 0.02 * (1.0 + bass);
    vec2 sampUV = uv + tileOffset;

    float chroma = treble * 0.03 * (1.0 - edgeLine);
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Tile color tinting
    col *= mix(vec3(1.0), rainbow(cellHash + iTime * 0.1), 0.2 + mid * 0.3);

    // Radiant edge glow
    col += rainbow(cellHash * 2.0 + iTime * 0.2) * (1.0 - edgeLine) * (1.5 + air * 3.0);

    // Tile brightness pulse
    float pulse = sin(iTime * 3.0 + cellHash * TAU) * 0.5 + 0.5;
    col *= 0.8 + pulse * 0.4 * bass;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
