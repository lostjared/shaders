#version 330 core
// ant_gem_mercury_bloom
// Glass warp with metal sheen and mercury fluid motion bloom

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

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

vec3 mercury(float t) {
    return vec3(0.7 + 0.3 * cos(6.28318 * (t + vec3(0.0, 0.05, 0.1))));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc;

    // Mercury fluid flow distortion
    float flowScale = 5.0 + mid * 4.0;
    float n1 = noise(uv * flowScale + iTime * 0.6 + bass * 2.0);
    float n2 = noise(uv * flowScale * 1.3 - iTime * 0.4 + 50.0);
    vec2 flowOff = vec2(n1, n2) * 0.06 * (1.0 + bass * 0.8);
    uv += flowOff;

    // Glass surface normals
    float delta = 0.007;
    float h = dot(texture(samp, uv).rgb, vec3(0.33));
    float h1 = dot(texture(samp, uv + vec2(delta, 0.0)).rgb, vec3(0.33));
    float h2 = dot(texture(samp, uv + vec2(0.0, delta)).rgb, vec3(0.33));
    vec2 normal = vec2(h1 - h, h2 - h);

    // Refract through mercury surface
    uv += normal * (0.06 + mid * 0.07 + bass * 0.04);

    // Chromatic split along normals
    float refractSplit = (treble + air) * 0.035;
    vec3 col;
    col.r = texture(samp, uv + normal * refractSplit).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - normal * refractSplit).b;

    // Mercury metallic sheen
    vec3 mercCol = mercury(h + iTime * 0.15 + bass);
    float sheen = smoothstep(0.3, 0.7, n1);
    col = mix(col, col * mercCol, sheen * 0.4);

    // Metal zigzag ripples (from metal shader)
    float aspect = iResolution.x / iResolution.y;
    vec2 centered = (tc * 2.0 - 1.0) * vec2(aspect, 1.0);
    float r = length(centered);
    float angle = atan(centered.y, centered.x);
    float ripple = sin(angle * 12.0 + iTime + mid * 3.0) * 0.03;
    float wave = sin(r * 20.0 - iTime * 3.0 + ripple * 10.0);
    col += wave * ripple * (2.0 + amp_smooth * 6.0);

    // Bloom: bright areas spread
    float bright = dot(col, vec3(0.299, 0.587, 0.114));
    float bloomMask = smoothstep(0.5, 1.0, bright + hiMid * 0.3);
    col += col * bloomMask * 0.3 * (1.0 + bass);

    // Specular glass highlights
    float spec = pow(max(0.0, 1.0 - length(normal * 18.0)), 9.0);
    col += vec3(1.0, 0.98, 0.95) * spec * 0.35;

    // Saturation pump
    float grey = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(grey), col, 1.0 + amp_smooth * 0.8);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
