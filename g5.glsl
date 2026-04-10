#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

void main(void) {
    // Normalize coordinates to center and adjust for aspect ratio
    vec2 uv = tc - 0.5;
    uv.x *= iResolution.x / iResolution.y;
    
    // Create spiral effect
    float radius = length(uv) * 2.0;
    float angle = atan(uv.y, uv.x) + time_f * 0.5;
    
    // Add underwater wobble distortion
    float wobble = sin(time_f * 2.0 + radius * 5.0) * 0.01;
    
    // Create ice-like refraction with multiple distortion layers
    vec2 spiralUV = vec2(
        cos(angle) * radius + sin(time_f + uv.y * 10.0) * 0.02 + wobble,
        sin(angle) * radius + cos(time_f + uv.x * 10.0) * 0.02 + wobble
    );
    
    // Add chromatic aberration (ice refraction effect)
    float chromaOffset = 0.005;
    vec4 texColor;
    texColor.r = texture(samp, spiralUV + chromaOffset).r;
    texColor.g = texture(samp, spiralUV).g;
    texColor.b = texture(samp, spiralUV - chromaOffset).b;
    texColor.a = 1.0;
    
    // Add water tint and lighting effects
    vec3 waterColor = vec3(0.2, 0.4, 0.6);
    float depthEffect = clamp(radius * 0.8, 0.0, 1.0);
    vec3 tinted = mix(texColor.rgb, waterColor, 0.3 * depthEffect);
    
    // Add caustic-like light patterns (simulating light through water)
    float lightPattern = sin(uv.x * 20.0 + time_f * 1.5) * 
                         sin(uv.y * 15.0 + time_f) * 0.1 + 0.9;
    
    // Final color with all effects
    color = vec4(tinted * lightPattern, 1.0);
}