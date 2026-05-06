#version 330 core
// ant_spectrum_echo_spiral
// Mirrored spiral arms with echo trailing and rainbow gradient coloring

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.60).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Spiral twist with mirror
    float spiralTwist = log(r + 0.001) * (3.0 + bass * 4.0) - iTime * (1.0 + mid);
    angle += spiralTwist;

    // Kaleidoscopic mirror in polar
    float seg = 6.0;
    float segAngle = 2.0 * PI / seg;
    angle = mod(angle, segAngle);
    angle = abs(angle - segAngle * 0.5);

    // Echo spiral: multiple offset samples
    vec3 result = vec3(0.0);
    for (float e = 0.0; e < 6.0; e++) {
        float echoR = r + e * 0.02 * (1.0 + hiMid);
        float echoAngle = angle + e * 0.05;
        vec2 spiralUV = vec2(cos(echoAngle), sin(echoAngle)) * echoR * 0.5 + 0.5;
        vec3 s = texture(samp, mirror(spiralUV)).rgb;

        // Rainbow per echo
        s *= rainbow(e * 0.16 + r * 2.0 + iTime * 0.25);
        result += s * (1.0 / (1.0 + e * 0.35));
    }
    result /= 2.8;

    // Spiral arm glow
    float arms = 4.0 + mid * 3.0;
    float armPattern = sin(angle * arms + spiralTwist * 0.5);
    vec3 armColor = rainbow(r + iTime * 0.3 + bass);
    result += smoothstep(0.0, 0.6, armPattern) * armColor * 0.2;

    // Color shift
    result = mix(result, result.gbr, treble * 0.4);

    // Gradient
    result *= mix(vec3(1.0), rainbow(r * 2.5 + iTime * 0.3), 0.25);

    result *= smoothstep(2.0, 0.4, r);
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
