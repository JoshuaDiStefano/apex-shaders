#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     texture;

varying   vec3          tintColor;
varying   vec3          normal;

varying   vec4          texcoord;
varying   vec4          lmcoord;

/* DRAWBUFFERS:0124 */

void main() {
    vec4 eyeColor = texture2D(texture, texcoord.st);
    eyeColor.rgb *= tintColor;

    #ifdef CLAY
        eyeColor.rgb = tintColor;
    #endif

    FragData0 = vec4(eyeColor.rgb / 50.0, 1.0);
    FragData1 = vec4(0.0);
    FragData2 = vec4(normal * 0.5 + 0.5, 1.0);
    FragData3 = vec4(0.0);
}