#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle);
    float cosv = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cosv, -s, s, cosv) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float angle = atan(p.y, p.x);
    float radius = length(p);
    float seg = 6.28318530718 / segments;
    angle = mod(angle, seg);
    angle = abs(angle - seg * 0.5);
    vec2 r = vec2(cos(angle), sin(angle)) * radius;
    r.x /= aspect;
    return r + c;
}

vec2 fractalZoom(vec2 uv, float zoom, float t, vec2 c, float aspect) {
    vec2 p = uv;
    for (int i = 0; i < 5; i++) {
        p = abs((p - c) * zoom) - 0.5 + c;
        p = rotateUV(p, t * 0.1, c, aspect);
    }
    return p;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 uv = tc;

    vec4 originalTexture = texture(samp, tc);

    vec2 kaleidoUV = reflectUV(uv, 6.0, m, aspect);
    float zoom = 1.5 + 0.5 * sin(time_f * 0.5);
    kaleidoUV = fractalZoom(kaleidoUV, zoom, time_f, m, aspect);
    kaleidoUV = rotateUV(kaleidoUV, time_f * 0.2, m, aspect);

    vec4 kaleidoColor = texture(samp, kaleidoUV);
    float blendFactor = 0.6;
    vec4 blendedColor = mix(kaleidoColor, originalTexture, blendFactor);

    blendedColor.rgb *= 0.5 + 0.5 * sin(kaleidoUV.xyx + time_f);

    color = sin(blendedColor * pingPong(time_f, 10.0));
    vec4 t = texture(samp, tc);
    color = color * t * 0.8;
    color = sin(color * pingPong(time_f, 15.0));
    color.a = 1.0;
}
