#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(41.23, 289.17))) * 45758.5453);
}

void main(void) {
    vec2 uv = tc;
    float frame = floor(time_f * 29.97);
    float line = floor(uv.y * max(iResolution.y, 1.0));
    float switchTop = 0.075 + 0.012 * sin(time_f * 2.0);
    float switchZone = 1.0 - smoothstep(switchTop, switchTop + 0.045, uv.y);
    float saw = fract(uv.y * 95.0 + time_f * 5.0) - 0.5;

    uv.x += switchZone * (saw * 0.035 + (hash21(vec2(line, frame)) - 0.5) * 0.09);
    uv.x += sin(uv.y * 160.0 + time_f * 4.0) * 0.0015;
    uv = clamp(uv, 0.001, 0.999);

    vec3 image;
    image.r = texture(samp, uv + vec2(0.002 + switchZone * 0.006, 0.0)).r;
    image.g = texture(samp, uv).g;
    image.b = texture(samp, uv - vec2(0.003 + switchZone * 0.008, 0.0)).b;

    float noise = hash21(gl_FragCoord.xy + frame * 31.0) - 0.5;
    float whiteTear = step(0.93, hash21(vec2(line, frame + 7.0))) * switchZone;
    image += noise * (0.025 + switchZone * 0.38);
    image = mix(image, vec3(0.78 + noise), whiteTear * 0.55);
    image *= 0.95 + 0.05 * sin(uv.y * iResolution.y * 3.14159265);

    color = vec4(clamp(image, 0.0, 1.0), 1.0);
}
