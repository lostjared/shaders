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
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void)
{
    // Convert normalized coordinates [0,1] to [-1,1] space
    vec2 uv = (tc * 2.0) - 1.0;

    // Dynamic zooming to ensure the fractal remains visible
    float zoom = pow(0.8, time_f * 0.5);  // Slower exponential zoom
    uv *= zoom;

    // Adjust center dynamically based on zoom level to keep fractal visible
    vec2 center = vec2(-0.75, 0.0);  // Initial center of the Mandelbrot set
    center += vec2(-0.3, -0.4) * (1.0 - zoom);  // Adjust position over zoom
    
    vec2 z = vec2(0.0);
    vec2 c = uv + center;  // Shift UV to the current center

    const int MAX_ITER = 400;  
    int i;

    for(i = 0; i < MAX_ITER; i++)
    {
        z = vec2(z.x * z.x - z.y * z.y + c.x,
                 2.0 * z.x * z.y + c.y);
        if(dot(z, z) > 4.0)
            break;
    }

    float normalized = float(i) / float(MAX_ITER);
    vec3 rainbow = 0.5 + 0.5 * cos(6.28318 * (vec3(0.5, 0.3, 0.1) + normalized * 3.0));
    vec3 texColor = texture(samp, tc).rgb;
    color = vec4(mix(texColor, rainbow, 0.8), 1.0);
}
