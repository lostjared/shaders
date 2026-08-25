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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;


layout(set = 0, binding = 0) uniform sampler2D samp;








float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 screenToComplex(vec2 screenPos, vec2 center, float zoom) {
    vec2 scale = vec2(zoom * (iResolution.x / iResolution.y), zoom);
    return center + (screenPos - iResolution * 0.5) * scale;
}

const int maxIterations = 300;

int mandelbrot(vec2 c) {
    vec2 z = vec2(0.0);
    int n = 0;
    for (int i = 0; i < maxIterations; i++) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if (dot(z, z) > 4.0) break;
        n++;
    }
    return n;
}

vec4 xor_RGB(vec4 icolor, vec4 isourcex) {
    ivec4 isource = ivec4(isourcex * 255.0);
    ivec3 int_color;
    for (int i = 0; i < 3; ++i) {
        int_color[i] = int(255.0 * icolor[i]);
        int_color[i] ^= isource[i];
        if (int_color[i] > 255)
            int_color[i] %= 255;
        icolor[i] = float(int_color[i]) / 255.0;
    }
    icolor.a = 1.0;
return icolor;
}

void main() {
    float zoomCycleSpeed = (0.1 + amp_low * 0.2);
    float zoomIntensity = (20.0 + amp_low * 5.0);
    float zoom = exp(-abs(sin(time_f * zoomCycleSpeed)) * zoomIntensity);

    vec2 center = vec2(-0.745, 0.113);
    vec2 c = screenToComplex(gl_FragCoord.xy, center, zoom * iResolution.y / iResolution.x);
    int n = mandelbrot(c);

    float colorIndex = rand(vec2(n, time_f));
    vec3 col = 0.5 + 0.5 * cos(6.28318 * (vec3(colorIndex) + vec3(0.0, 0.33, 0.67)));

    vec4 mandelbrotColor = n == maxIterations ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(col, 1.0);
    
    vec4 textureColor = texture(samp, tc);

    color = xor_RGB(mandelbrotColor, textureColor);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    color.rgb *= 1.0 + _ab * 0.6;
    color.rgb = mix(color.rgb, color.rgb * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

}
