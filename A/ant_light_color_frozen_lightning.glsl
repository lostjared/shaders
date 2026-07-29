#version 330 core
// ant_light_color_frozen_lightning
// Frozen branching lightning bolts with ice-blue glow and bass crack propagation

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 ice(float t) {
    return mix(vec3(0.6, 0.8, 1.0), vec3(0.2, 0.4, 1.0), t) + vec3(0.1, 0.15, 0.3) * sin(t * TAU);
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

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Lightning bolt paths
    float bolt = 0.0;
    for (float i = 0.0; i < 5.0; i++) {
        float startX = (hash(vec2(i, floor(iTime * 0.5))) - 0.5) * aspect;
        float path = startX;
        float y = uv.y;
        float segY = 0.0;
        float branchDist = 10.0;

        for (float j = 0.0; j < 15.0; j++) {
            float segLen = 0.08;
            path += (noise(vec2(j + i * 7.0, floor(iTime * 2.0))) - 0.5) * 0.15 * (1.0 + bass);
            float dy = y - (0.5 - j * segLen);
            float dx = uv.x - path;
            float d = abs(dx) * (10.0 + treble * 20.0) + abs(dy) * 2.0;
            if (abs(dy) < segLen) {
                branchDist = min(branchDist, d);
            }
        }
        float boltLine = 0.05 / (branchDist + 0.05);
        bolt += boltLine;
    }

    // Texture sample
    float chroma = treble * 0.03 + bolt * 0.01;
    vec3 col;
    col.r = texture(samp, tc + vec2(chroma, 0.0)).r;
    col.g = texture(samp, tc).g;
    col.b = texture(samp, tc - vec2(chroma, 0.0)).b;

    // Ice-blue bolt glow
    col += ice(bolt * 0.5 + iTime * 0.1) * bolt * (0.5 + mid * 1.0);

    // Flash on bass hits
    float flash = bass * step(0.7, bass);
    col += ice(0.3) * flash * 1.5;

    // Frost overlay
    float frost = noise(uv * 20.0 + iTime * 0.1);
    frost = pow(frost, 3.0);
    col += ice(frost + iTime * 0.05) * frost * (0.1 + air * 0.3);

    // Frozen shimmer
    float shimmer = sin(uv.x * 80.0 + uv.y * 80.0 + iTime * 5.0) * 0.5 + 0.5;
    shimmer = pow(shimmer, 20.0);
    col += ice(0.5) * shimmer * treble * 0.5;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
