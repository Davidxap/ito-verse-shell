#version 440

// Recolours the shell's pre-drawn art onto the installed theme.
//
// The art is bone linework with crimson where something bleeds. Under a theme both roles move: the bone
// greys take the theme's foreground and the crimson takes its accent. A pixel is told apart by how much
// redder than it is green (bone is neutral, blood is not), and each keeps its own brightness, so the
// hatching, the wear and the antialiasing survive the change intact.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 fg;          // the theme's foreground
    vec4 accent;      // the theme's accent
    vec4 baseFg;      // the bone the art was drawn in
    vec4 baseAccent;  // the crimson the art was drawn in
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    if (c.a < 0.001) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 rgb = c.rgb / c.a;                                  // straight colour from premultiplied
    float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
    float baseLum = dot(baseFg.rgb, vec3(0.299, 0.587, 0.114));
    float red = smoothstep(0.12, 0.42, rgb.r - max(rgb.g, rgb.b));

    vec3 bone = fg.rgb * clamp(lum / baseLum, 0.0, 1.25);
    vec3 blood = accent.rgb * clamp(rgb.r / max(baseAccent.r, 0.05), 0.0, 1.25);
    vec3 outRgb = clamp(mix(bone, blood, red), 0.0, 1.0);
    fragColor = vec4(outRgb * c.a, c.a) * qt_Opacity;
}
