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
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


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

vec4 randomColor(ivec2 cell_coord) {
    int n = cell_coord.x + cell_coord.y * 10 + int(time_f);
    n = (n << 13) ^ n;
    n = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return vec4(float((n & 0xFF0000) >> 16) / 255.0,
                float((n & 0x00FF00) >> 8) / 255.0,
                float(n & 0x0000FF) / 255.0,
                1.0);
}

void main(void) {
    int grid_size = 10;
    float cell_size = 1.0 / float(grid_size);
    ivec2 cell_coord = ivec2(floor(tc.x * float(grid_size)), floor(tc.y * float(grid_size)));
    vec2 cell_center = (vec2(cell_coord) + 0.5) * cell_size;
    vec2 offset = tc - cell_center;
    float border = 0.05 * cell_size;
    if (abs(offset.x) < border || abs(offset.y) < border) {
        color = vec4(0, 0, 0, 1);
    } else {
        vec4 rand_color = sin(randomColor(cell_coord) * time_f);
        color = xor_RGB(texture(samp, tc), rand_color);
    }
}
