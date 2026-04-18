#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main(void) {
    // Tile size shrinks on peaks (more tiles = more shattered)
    float tileSize = mix(8.0, 64.0, clamp(amp_peak * 2.0, 0.0, 1.0));
    vec2 tileCoord = floor(tc * iResolution / tileSize);
    vec2 tileFrac = fract(tc * iResolution / tileSize);

    // Each tile explodes outward from center on peaks
    float h = hash(tileCoord);
    float explodeStrength = amp_peak * 0.1 + amp_low * 0.03;
    vec2 tileCenter = (tileCoord + 0.5) * tileSize / iResolution;
    vec2 fromCenter = tileCenter - 0.5;
    vec2 offset = fromCenter * explodeStrength * h;

    // Mids add rotation per tile
    float tileAngle = amp_mid * h * 1.5;
    vec2 tc2 = tileFrac - 0.5;
    float c = cos(tileAngle), s = sin(tileAngle);
    tc2 = vec2(c * tc2.x - s * tc2.y, s * tc2.x + c * tc2.y);
    tc2 += 0.5;

    vec2 uv = (tileCoord + tc2) * tileSize / iResolution + offset;
    uv = clamp(uv, 0.0, 1.0);

    vec4 tex = texture(samp, uv);

    // Tile edge highlight on treble
    float edgeX = smoothstep(0.0, 0.05, tileFrac.x) * smoothstep(1.0, 0.95, tileFrac.x);
    float edgeY = smoothstep(0.0, 0.05, tileFrac.y) * smoothstep(1.0, 0.95, tileFrac.y);
    float edgeMask = 1.0 - edgeX * edgeY;
    tex.rgb += edgeMask * amp_high * 0.4;

    // Peak flash
    tex.rgb += smoothstep(0.7, 1.0, amp_peak) * 0.2;

    color = tex;
}
