#version 330 core
// ant_gem_metal_tessera
// Tessellated mosaic with metallic tile edges and spectrum-driven tile animation

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 metalSpectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main(void) {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Hexagonal tessellation
    float scale = 8.0 + bass * 4.0;
    vec2 hex = uv * scale;
    vec2 hexID;

    // Hex grid conversion
    float q = (2.0 / 3.0 * hex.x);
    float rr = (-1.0 / 3.0 * hex.x + sqrt(3.0) / 3.0 * hex.y);
    float s = -q - rr;
    vec3 cube = vec3(q, rr, s);
    vec3 rcube = floor(cube + 0.5);
    vec3 diff = abs(rcube - cube);
    if (diff.x > diff.y && diff.x > diff.z)
        rcube.x = -rcube.y - rcube.z;
    else if (diff.y > diff.z)
        rcube.y = -rcube.x - rcube.z;
    hexID = rcube.xy;

    // Fractional position within tile
    vec2 tileCenter = hexID;
    vec2 tileLocal = hex - tileCenter;
    float tileDist = length(tileLocal);

    // Tile animation: each tile pulses independently
    float tileHash = hash(hexID);
    float tilePhase = tileHash * 6.28 + time_f * (2.0 + mid * 3.0);
    float tilePulse = sin(tilePhase) * 0.5 + 0.5;

    // Tile edge detection
    float edgeDist = 0.5 - tileDist;
    float edge = smoothstep(0.0, 0.05 + treble * 0.03, edgeDist);
    float edgeGlow = 1.0 - edge;

    // Texture per tile with pulse offset
    vec2 tileOffset = vec2(tileHash, fract(tileHash * 7.0)) * 0.01 * tilePulse;
    vec2 sampUV = tc + tileOffset * (1.0 + hiMid);

    // Chromatic split
    float chroma = 0.008 + air * 0.02;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Metallic edge coloring
    vec3 edgeColor = metalSpectrum(tileHash + time_f * 0.2 + bass * 0.5);
    vec3 finalColor = baseTex * edge;
    finalColor += edgeColor * edgeGlow * (1.5 + hiMid * 2.0);

    // Tile interior metallic tint
    vec3 tileTint = metalSpectrum(tileHash * 3.0 + time_f * 0.1);
    finalColor = mix(finalColor, finalColor * tileTint, tilePulse * 0.3);

    // Central glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    finalColor += vec3(1.0, 0.97, 0.93) * center * (1.5 + amp_peak * 2.0);

    color = vec4(finalColor, 1.0);
}
