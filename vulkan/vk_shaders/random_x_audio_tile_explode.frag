#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










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
