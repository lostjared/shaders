#version 330 core
// ant_light_color_neon_shatter
// Shattered glass panels with neon edge glow and bass-reactive displacement

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 neon(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 voronoi(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 closest = vec2(0.0);
    float minDist = 10.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = vec2(hash(i + neighbor), hash(i + neighbor + 31.0));
            point = 0.5 + 0.5 * sin(iTime * 0.5 + TAU * point);
            float d = length(neighbor + point - f);
            if (d < minDist) {
                minDist = d;
                closest = i + neighbor;
            }
        }
    }
    return vec2(minDist, hash(closest));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = tc;

    // Voronoi shatter field
    float cellScale = 6.0 + bass * 4.0;
    vec2 v = voronoi(uv * cellScale);
    float edge = smoothstep(0.02, 0.08, v.x);

    // Displace each cell based on bass
    vec2 cellOffset = vec2(sin(v.y * 50.0), cos(v.y * 37.0)) * bass * 0.04;
    vec2 sampUV = uv + cellOffset;

    float chroma = treble * 0.04 * (1.0 - edge);
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Neon edge glow
    float neonEdge = 1.0 - edge;
    col += neon(v.y + iTime * 0.3) * neonEdge * (2.0 + mid * 3.0 + air * 2.0);

    // Cell tint from spectrum
    col *= mix(vec3(1.0), neon(v.y * 2.0 + iTime * 0.1), 0.15 + treble * 0.2);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
