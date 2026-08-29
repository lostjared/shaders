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
#define iTime ext.u0.y

layout(location = 0) in vec2 tc; // Texture Coordinates from your vertex shader
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;    // Your input grayscale video frame/texture


// 1. Function to map brightness to a dynamic rainbow gradient
// Based on IQ's color palette function: iquilezles.org/articles/palettes/
vec3 getShiftingGradientColor(float t) {
    // These constants define the rainbow pattern and its speed/offset
    vec3 a = vec3(0.5, 0.5, 0.5); // Brightness base
    vec3 b = vec3(0.5, 0.5, 0.5); // Contrast range
    vec3 c = vec3(1.0, 1.0, 1.0); // Frequency (1 full rainbow loop)
    
    // Phase shifts (d) for each color channel.
    // By animating 'iTime' inside 'd', the gradient spectrum shifts.
    vec3 d = vec3(0.0 + iTime*0.5, 0.33, 0.67); 

    // Standard cosine palette formula
    return a + b * cos( 6.28318 * (c * t + d) );
}

void main(void) {
    // 2. Sample the input texture (assumed grayscale or using only Red channel)
    vec4 texColor = texture(samp, tc);
    
    // We only need the brightness (luminance). If it's grayscale, R=G=B.
    // If it's a true grayscale texture, just use texColor.r.
    float brightness = texColor.r; 

    // 3. Map the brightness to the color spectrum
    // 0.0 (Black) maps to the 'start' of the dynamic gradient
    // 1.0 (White) maps to the 'end' of the dynamic gradient
    vec3 mappedColor = getShiftingGradientColor(brightness);

    // 4. Output the final color, maintaining original alpha
    color = vec4(mappedColor, texColor.a);
}