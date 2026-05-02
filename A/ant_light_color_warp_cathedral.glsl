#version 330 core
// ant_light_color_warp_cathedral
// Gothic rose window warp with stained glass light rays and organ bass

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;
const float PI = 3.14159265;

vec3 stainedGlass(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 0.7, 0.4);
    vec3 d = vec3(0.0, 0.15, 0.2);
    return a + b * cos(TAU * (c * t + d));
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

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(p);
    float angle = atan(p.y, p.x);

    // Rose window segments
    float petals = 8.0 + floor(bass * 4.0);
    float petal = cos(angle * petals + iTime * 0.5) * 0.5 + 0.5;

    // Warp: radial breathing with bass
    float warpR = r * (1.0 + petal * 0.3 * mid);
    warpR *= 1.0 - bass * 0.25;

    // Stained glass angular bands
    float band = floor(angle * petals / TAU + 0.5);
    float bandHue = band / petals + iTime * 0.05;

    vec2 warpUV = vec2(cos(angle + petal * 0.2), sin(angle + petal * 0.2)) * warpR;
    warpUV = rot(iTime * 0.1) * warpUV;
    warpUV.x /= aspect;
    vec2 sampUV = warpUV + 0.5;

    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Stained glass tinting
    col *= stainedGlass(bandHue + bass * 0.3);

    // Light rays from center
    float rays = pow(max(cos(angle * petals + iTime), 0.0), 12.0);
    float rayFade = exp(-r * (2.0 - bass));
    col += stainedGlass(angle / TAU + iTime * 0.15) * rays * rayFade * (1.5 + air * 3.0);

    // Rose outline glow
    float roseLine = abs(petal - 0.5);
    roseLine = smoothstep(0.02, 0.0, roseLine * r);
    col += stainedGlass(iTime * 0.2 + r) * roseLine * 0.8;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
