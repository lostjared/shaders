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
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iTime ext.u0.y

// pure_texture_tunnel
// Rotating tunnel stretching a texture with audio-reactive depth and chroma
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




layout(set = 0, binding = 3) uniform sampler1D spectrum;

const float PI = 3.14159265;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    
    // Rotate the UV space to spin the tunnel
    vec2 rotatedUV = rot(iTime * 0.2 + mid * 0.5) * uv;
    float angle = atan(rotatedUV.y, rotatedUV.x);

    // Tunnel mapping: polar to rectangular
    float tunnelDepth = 1.0 / (r + 0.1);
    float tunnelAngle = angle / PI;

    // Depth scroll to pull the texture toward the camera
    tunnelDepth += iTime * (1.0 + bass * 2.0);

    // Texture mapped through the tunnel
    // tunnelAngle wraps it radially, tunnelDepth stretches it longitudinally
    vec2 sampUV = vec2(tunnelAngle * 0.5 + 0.5, fract(tunnelDepth * 0.2));
    
    // Retained the chromatic aberration for the texture sampling
    float chroma = treble * 0.04 / (r + 0.1);
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Tunnel depth fade so it blends to black in the center
    float depthLight = exp(-r * (1.5 - bass));
    col *= depthLight * (0.5 + amp_peak * 1.0);

    // Outer vignette and audio-reactive flashes
    col *= smoothstep(2.0, 0.3, r);
    col *= 0.85 + amp_smooth * 0.35;
    
    // Invert colors on heavy audio peaks
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}