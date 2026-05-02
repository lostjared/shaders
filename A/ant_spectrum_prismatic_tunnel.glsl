#version 330 core
// ant_spectrum_prismatic_tunnel
// Log-polar tunnel with prismatic mirror walls and rainbow depth bands

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

vec2 kaleidoscope(vec2 p, float seg) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = 2.0 * PI / seg;
    ang = mod(ang, s);
    ang = abs(ang - s * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass = texture(spectrum, 0.04).r;
    float lowMid = texture(spectrum, 0.12).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.60).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Kaleidoscope before tunnel
    float seg = floor(6.0 + bass * 4.0);
    vec2 kUV = kaleidoscope(uv, seg);

    float r = length(kUV);
    float angle = atan(kUV.y, kUV.x);

    // Tunnel mapping
    float speed = 0.4 + bass * 1.2;
    vec2 tunnelUV;
    tunnelUV.x = angle / PI;
    tunnelUV.y = 1.0 / (r + 0.01) + iTime * speed;

    // Mirror wrap for seamless walls
    vec2 texUV = mirror(tunnelUV * 0.5);

    // Prismatic split per channel
    float spread = 0.01 + treble * 0.04;
    vec3 result;
    result.r = texture(samp, mirror(texUV + vec2(spread, 0.0))).r;
    result.g = texture(samp, texUV).g;
    result.b = texture(samp, mirror(texUV - vec2(spread, 0.0))).b;

    // Echo depth rings
    for (float e = 1.0; e < 5.0; e++) {
        float depthOff = e * 0.2;
        vec2 echoTunnel = vec2(tunnelUV.x, tunnelUV.y + depthOff);
        vec3 echoCol = texture(samp, mirror(echoTunnel * 0.5)).rgb;
        echoCol *= rainbow(e * 0.2 + tunnelUV.y * 0.3 + iTime * 0.2);
        result += echoCol * (0.2 / e);
    }

    // Rainbow depth bands
    vec3 depthColor = rainbow(tunnelUV.y * 0.5 + iTime * 0.3 + mid);
    result = mix(result, result * depthColor * 1.3, 0.3 + lowMid * 0.2);

    // Color shift
    result = mix(result, result.gbr, hiMid * 0.5);

    // Center glow
    float glow = exp(-r * (3.0 - bass * 1.5));
    result += glow * rainbow(iTime * 0.5) * 0.25;

    // Vignette
    result *= smoothstep(0.0, 0.15, r) * smoothstep(2.0, 0.5, r);

    result = mix(result, vec3(1.0) - result, smoothstep(0.92, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
