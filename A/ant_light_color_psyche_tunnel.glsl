#version 330 core
// ant_light_color_psyche_tunnel
// Psychedelic tunnel with rotating hexagonal tiles and flowing color bands

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

vec3 psyche(float t) {
    return 0.5 + 0.5 * cos(TAU * (t * 2.0 + vec3(0.0, 0.25, 0.5)));
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
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Tunnel mapping: polar to rectangular
    float tunnelDepth = 1.0 / (r + 0.1);
    float tunnelAngle = angle / PI;

    // Depth scroll with bass
    tunnelDepth += iTime * (1.0 + bass * 2.0);

    // Hexagonal tile pattern
    vec2 hex = vec2(tunnelAngle * 3.0, tunnelDepth * 2.0);
    hex = rot(iTime * 0.2 + mid * 0.5) * hex;
    vec2 hexFrac = fract(hex) - 0.5;
    float hexDist = max(abs(hexFrac.x), abs(hexFrac.y) * 0.866 + abs(hexFrac.x) * 0.5);
    float hexEdge = smoothstep(0.48, 0.45, hexDist);
    float hexLine = 1.0 - hexEdge;

    // Texture through tunnel
    vec2 sampUV = vec2(tunnelAngle * 0.5 + 0.5, fract(tunnelDepth * 0.2));
    float chroma = treble * 0.04 / (r + 0.1);
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Color band flow through tiles
    float band = sin(tunnelDepth * 5.0 + tunnelAngle * 3.0 - iTime * 3.0) * 0.5 + 0.5;
    col *= psyche(band + iTime * 0.15 + bass);

    // Hex edge neon glow
    col += psyche(tunnelDepth * 0.2 + iTime * 0.2) * hexLine * (0.5 + air * 1.5);

    // Tunnel depth fade with light
    float depthLight = exp(-r * (1.5 - bass));
    col += psyche(iTime * 0.3) * depthLight * (0.3 + amp_peak * 1.0);

    col *= smoothstep(2.0, 0.3, r);
    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
