#version 330 core
// ant_new_vortex_helix
// Mix of ant_gem_prism_vortex + ant_light_color_plasma_helix:
// polar vortex tunnel with a helix spiraling along the depth axis
// and prism chromatic split on the tangent.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 prism(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

mat2 rot(float a) { float s = sin(a), c = cos(a); return mat2(c, -s, s, c); }

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.82).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    float dist = length(uv);
    float ang = atan(uv.y, uv.x);

    // Tunnel coords
    float tunSpeed = iTime * (0.4 + bass * 0.8);
    float depth = 1.0 / (dist + 0.01) + tunSpeed;
    vec2 tunnel = vec2(ang / PI + iTime * 0.05, depth);
    vec2 sampUV = abs(fract(tunnel * 0.5) * 2.0 - 1.0);

    // Chromatic split tangent to the tunnel
    float chroma = (treble + air) * 0.045;
    vec2 splitDir = rot(ang) * vec2(chroma, 0.0);
    vec3 col;
    col.r = texture(samp, sampUV + splitDir).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - splitDir).b;

    // Helix wrapped around tunnel: angle vs depth
    float twist = 3.5 + mid * 4.0;
    float hA = ang + depth * twist;
    float hB = ang + depth * twist + PI;
    float strand = 0.2 / max(abs(sin(hA)), 0.001);
    strand += 0.2 / max(abs(sin(hB)), 0.001);
    strand *= smoothstep(1.5, 0.2 + bass * 0.4, dist);  // fade near rim

    // Prism hue cycling
    vec3 hue = prism(dist * 2.0 - iTime * 0.4 + bass * 0.5);
    col = mix(col, col * hue, 0.35 + hiMid * 0.3);

    // Helix neon add
    col += prism(hA * 0.1 + iTime * 0.3) * strand * 0.015 * (1.0 + air * 2.0);

    // Radial bands
    col *= 0.85 + 0.15 * sin(dist * (20.0 + hiMid * 15.0) - iTime * 3.0);

    // Vignette pulsing with bass
    col *= smoothstep(1.6, 0.3 + bass * 0.35, dist);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
