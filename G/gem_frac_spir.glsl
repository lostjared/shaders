#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

// Your original XOR logic
vec4 xor_RGB(vec4 icolor, vec4 source) {
    ivec3 int_color;
    ivec4 isource = ivec4(source * 255);
    for(int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] = int_color[i]^isource[i];
        if(int_color[i] > 255)
            int_color[i] = int_color[i]%255;
        icolor[i] = float(int_color[i])/255;
    }
    icolor.a = 1.0;
    return icolor;
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

// Optimization: Using textureLod or a smaller kernel for performance if needed, 
// but keeping your specific blur logic here.
vec4 blur(sampler2D image, vec2 uv, vec2 resolution) {
    vec2 texelSize = 1.0 / resolution;
    vec4 result = vec4(0.0);
    float kernelVals[100] = float[](0.5, 1.0, 1.5, 2.0, 2.5, 2.5, 2.0, 1.5, 1.0, 0.5,
                                    1.0, 2.0, 2.5, 3.0, 3.5, 3.5, 3.0, 2.5, 2.0, 1.0,
                                    1.5, 2.5, 3.0, 3.5, 4.0, 4.0, 3.5, 3.0, 2.5, 1.5,
                                    2.0, 3.0, 3.5, 4.0, 4.5, 4.5, 4.0, 3.5, 3.0, 2.0,
                                    2.5, 3.5, 4.0, 4.5, 5.0, 5.0, 4.5, 4.0, 3.5, 2.5,
                                    2.5, 3.5, 4.0, 4.5, 5.0, 5.0, 4.5, 4.0, 3.5, 2.5,
                                    2.0, 3.0, 3.5, 4.0, 4.5, 4.5, 4.0, 3.5, 3.0, 2.0,
                                    1.5, 2.5, 3.0, 3.5, 4.0, 4.0, 3.5, 3.0, 2.5, 1.5,
                                    1.0, 2.0, 2.5, 3.0, 3.5, 3.5, 3.0, 2.5, 2.0, 1.0,
                                    0.5, 1.0, 1.5, 2.0, 2.5, 2.5, 2.0, 1.5, 1.0, 0.5);
    float kernelSum = 842.0;
    for (int x = -5; x <= 4; ++x) {
        for (int y = -5; y <= 4; ++y) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            result += texture(image, uv + offset) * kernelVals[(y + 5) * 10 + (x + 5)];
        }
    }
    return result / kernelSum;
}

mat2 rotate2d(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void) {
    // 1. Fractal & Spiral Coordinates
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float t_spiral = pingPong(time_f * 0.5, 5.0);
    float t_zoom = 1.0 + 0.5 * sin(time_f * 0.3);
    
    // Iterative Fractal folding
    for(int i = 0; i < 4; i++) {
        uv = abs(uv) - 0.5; // Mirror fold
        uv *= rotate2d(t_spiral * 0.2 + float(i)); // Rotate each fold
        uv *= t_zoom; // Iterative zoom
    }

    // Convert to spiral polar coordinates
    float r = length(uv);
    float angle = atan(uv.y, uv.x);
    float spiral = angle + log(r + 0.1) * t_spiral;

    // 2. Texture Sampling & Blur
    // We use the distorted 'fractal' UVs to sample the texture
    vec2 fractalTC = fract(uv * 0.5 + 0.5);
    vec4 tcolor = blur(samp, fractalTC, iResolution);

    // 3. Color Logic
    float time_t = pingPong(time_f, 10.0) + 2.0;
    
    // Cycle rainbow through the spiral
    vec3 rainbow_color = 0.5 + 0.5 * cos(6.28318 * (spiral + time_f * 0.5 + vec3(0,2,4)/3.0));
    vec3 blended_color = mix(tcolor.rgb, rainbow_color, 0.6);

    // 4. XOR Post-Processing
    // Applying your XOR logic to the fractalized rainbow colors
    vec4 xorColor = xor_RGB(
        vec4(sin(blended_color * time_t), 1.0), 
        vec4(cos(blended_color * time_t), 1.0)
    );

    // Adding a subtle vignette based on original distance
    float vign = smoothstep(1.5, 0.2, length(tc * 2.0 - 1.0));
    color = vec4(xorColor.rgb * vign, tcolor.a);
}