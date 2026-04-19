#version 330 core
// ant_light_color_stardust_spiral
// Particle stardust flowing in spiral paths with trail persistence and color evolution

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 stardust(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.05, 0.3, 0.6)));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    p = rot(iTime * 0.1) * p;

    float r = length(p);
    float angle = atan(p.y, p.x);

    // Spiral path for texture
    float spiralWarp = angle + log(r + 0.01) * (4.0 + bass * 3.0) - iTime * 1.5;
    vec2 spiralUV = vec2(cos(spiralWarp * 0.5), sin(spiralWarp * 0.5)) * r * 0.5 + 0.5;

    float chroma = treble * 0.03;
    vec3 col;
    col.r = texture(samp, spiralUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, spiralUV).g;
    col.b = texture(samp, spiralUV - vec2(chroma, 0.0)).b;

    // Stardust particle field
    vec3 dust = vec3(0.0);
    for (float i = 0.0; i < 12.0; i++) {
        float t = iTime * (0.3 + hash(vec2(i, 0.0)) * 0.5) + hash(vec2(i, 1.0)) * TAU;
        float pr = 0.1 + hash(vec2(i, 2.0)) * 0.5;
        pr += sin(t * 0.5) * 0.05;
        float pa = t * (1.0 + hash(vec2(i, 3.0)));
        vec2 particlePos = vec2(cos(pa), sin(pa)) * pr;

        float d = length(p - particlePos);
        float glow = 0.002 / (d * d + 0.0005);

        // Trail persistence
        float trail = 0.001 / (abs(length(p) - pr) + 0.01);
        trail *= smoothstep(0.3, 0.0, abs(atan(p.y - particlePos.y, p.x - particlePos.x)));

        vec3 dustColor = stardust(i * 0.08 + iTime * 0.1 + pr);
        dust += dustColor * (glow + trail * 0.3) * (0.1 + bass * 0.2);
    }

    col += dust;

    // Color evolution based on radius
    col *= stardust(r * 3.0 - iTime * 0.15 + bass) * 0.5 + 0.7;

    // Center glow
    float center = exp(-r * (4.0 - bass * 2.0));
    col += stardust(iTime * 0.25) * center * (1.0 + amp_peak * 2.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
