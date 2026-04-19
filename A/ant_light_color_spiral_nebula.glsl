#version 330 core
// ant_light_color_spiral_nebula
// Spiraling nebula clouds with color-shifting gas layers and star particles

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 nebula(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.25, 0.55)));
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

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Spiral arm warp
    float spiral = angle + log(r + 0.01) * (3.0 + bass * 4.0) - iTime * 0.8;
    float armDensity = sin(spiral * (3.0 + mid * 2.0)) * 0.5 + 0.5;
    armDensity = pow(armDensity, 1.5);

    // Nebula cloud layers
    float cloud = fbm(uv * 4.0 + iTime * 0.2 + bass * 0.5);
    cloud = mix(cloud, armDensity, 0.5 + mid * 0.3);

    // Texture warp through spiral
    vec2 spiralUV = vec2(cos(spiral * 0.3), sin(spiral * 0.3)) * r * 0.6 + 0.5;
    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, spiralUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, spiralUV).g;
    col.b = texture(samp, spiralUV - vec2(chroma, 0.0)).b;

    // Nebula gas overlay
    vec3 gasColor = nebula(cloud + iTime * 0.1 + bass);
    col = mix(col, col * gasColor * 2.0, cloud * (0.4 + mid * 0.3));

    // Star particles
    float stars = step(0.98, hash(floor(uv * 50.0)));
    float twinkle = sin(iTime * 10.0 + hash(floor(uv * 50.0)) * 100.0) * 0.5 + 0.5;
    col += nebula(hash(floor(uv * 50.0)) + iTime) * stars * twinkle * (2.0 + air * 3.0);

    // Core glow
    col += nebula(iTime * 0.15) * exp(-r * (3.0 - bass * 2.0)) * (1.0 + amp_peak * 2.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
