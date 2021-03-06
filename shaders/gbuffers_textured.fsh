#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     texture;

varying   vec3          tintColor;
varying   vec3          normal;

varying   vec4          texcoord;
varying   vec4          lmcoord;

/* DRAWBUFFERS:0124 */

void main() {
    vec4 color = texture2D(texture, texcoord.st);
    color.rgb *= tintColor;

    #ifdef CLAY
        color.rgb = tintColor;
    #endif

    FragData0 = color;
    FragData1 = vec4(clamp(lmcoord.st / 256.0, vec2(0.0), vec2(1.0)), 0.0, 1.0);
    FragData2 = vec4(clamp(normal * 0.5 + 0.5, vec3(0.0), vec3(1.0)), 1.0);
    FragData3 = vec4(0.0);
}
