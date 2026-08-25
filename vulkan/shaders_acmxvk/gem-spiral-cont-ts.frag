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
#define alpha ext.u0.x
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define time_speed ext.custom_uniforms[3].y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;






void main(void) {
    vec2 uv = (tc * 2.0 - 1.0);
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;
    float d = length(uv);
    float lensStrength = 1.5; 
    vec3 normal = normalize(vec3(uv, 1.0 / lensStrength));
    float fisheyeRadius = atan(d, 1.0); 
    vec2 distortedUV = normalize(uv + 1e-6) * fisheyeRadius;
    float t = time_f * (amp_smooth * time_speed); 
    float r_dist = length(distortedUV);
    float angle = atan(distortedUV.y, distortedUV.x);
    float spiral = angle + (log(r_dist + 0.1) * 3.0) - t * 1.5;
    float r = sin(spiral * 3.0 + t);
    float g = sin(spiral * 3.0 + t + 2.094);
    float b = sin(spiral * 3.0 + t + 4.188);
    vec3 spiralCol = vec3(r, g, b) * 0.5 + 0.5;
    vec3 lightDir = normalize(vec3(sin(time_f), cos(time_f), 1.0));
    float diff = max(dot(normal, lightDir), 0.0);
    float spec = pow(max(dot(reflect(-lightDir, normal), vec3(0,0,1)), 0.0), 16.0);
    vec3 texColor = texture(samp, tc).rgb;
    vec3 finalCol = mix(texColor, spiralCol * (diff + 0.5) + spec, 0.7);
    finalCol *= smoothstep(2.0, 0.5, d);
    color = vec4(finalCol, alpha);
}