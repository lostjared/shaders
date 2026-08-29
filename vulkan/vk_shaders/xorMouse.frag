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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;




vec3 hueShift(vec3 color, float hue) {
    vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(hue);
    return color * cosAngle + cross(k, color) * sin(hue) + k * dot(k, color) * (1.0 - cosAngle);
}

void main() {
    vec4 baseColor = texture(samp, tc);
    vec2 mouseNorm = iMouse.xy / iResolution.xy;
    vec2 clickNorm = iMouse.zw / iResolution.xy;
    
    // Calculate drag vector and strength
    vec2 dragVec = mouseNorm - clickNorm;
    float dragStrength = smoothstep(0.0, 0.5, length(dragVec));
    vec2 dragDir = normalize(dragVec + vec2(0.0001));
    
    // Calculate color shift parameters
    float hueAngle = atan(dragDir.y, dragDir.x);
    float shiftAmount = dragStrength * 2.0;
    
    // Animate return when released
    float returnSpeed = 2.0;
    float timeDecay = exp(-time_f * returnSpeed * (1.0 - step(0.5, iMouse.z)));
    shiftAmount *= mix(timeDecay, 1.0, step(0.5, iMouse.z));
    
    // Apply directional hue shift
    vec3 shiftedColor = hueShift(baseColor.rgb, hueAngle * shiftAmount);
    
    // Add chromatic aberration
    vec2 redOffset = dragDir * shiftAmount * 0.02;
    vec2 greenOffset = dragDir * shiftAmount * 0.01;
    vec3 finalColor = vec3(
        texture(samp, tc - redOffset).r,
        texture(samp, tc - greenOffset).g,
        texture(samp, tc).b
    );
    
    // Blend between original and shifted colors
    finalColor = mix(finalColor, shiftedColor, dragStrength);
    
    color = vec4(finalColor, baseColor.a);
}