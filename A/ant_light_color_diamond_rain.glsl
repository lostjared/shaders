#version 330 core
// ant_light_color_diamond_rain
// Falling diamond shards with prismatic refraction and bass-driven scatter

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc;
    float aspect = iResolution.x / iResolution.y;

    // Diamond grid with falling motion
    float gridSize = 8.0 + floor(mid * 6.0);
    vec2 cell = floor(uv * gridSize);
    vec2 f = fract(uv * gridSize) - 0.5;

    // Each cell falls at different speed
    float fallSpeed = 0.5 + hash(vec2(cell.x, 0.0)) * 2.0;
    float fall = fract(iTime * fallSpeed * 0.3 + hash(cell.xx) * 10.0);
    cell.y += floor(iTime * fallSpeed * 0.3 + hash(cell.xx) * 10.0);

    // Diamond shape
    float diamond = abs(f.x) + abs(f.y);
    float edge = smoothstep(0.5, 0.45, diamond);
    float outline = smoothstep(0.45, 0.42, diamond) - smoothstep(0.42, 0.39, diamond);

    // Refracted texture per shard
    float angle = hash(cell) * TAU;
    vec2 refract_offset = vec2(cos(angle), sin(angle)) * 0.02 * (1.0 + bass);
    vec2 shardUV = uv + refract_offset * edge;

    float chroma = treble * 0.04 * edge;
    vec3 col;
    col.r = texture(samp, shardUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, shardUV).g;
    col.b = texture(samp, shardUV - vec2(chroma, 0.0)).b;

    // Prismatic edge glow
    vec3 prismColor = rainbow(hash(cell) + iTime * 0.3 + diamond * 2.0);
    col += prismColor * outline * (2.0 + air * 3.0);

    // Shard brightness variation
    float brightness = hash(cell + 0.5) * 0.5 + 0.5;
    col *= mix(1.0, brightness * 1.5, edge);

    // Falling sparkle trail
    float trail = exp(-fall * 5.0) * edge;
    col += rainbow(fall + hash(cell)) * trail * bass * 2.0;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
