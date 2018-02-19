#version 120

#include "/lib/framebuffer.glsl"

/* DRAWBUFFERS:01 */

void main() {
    FragData0 = vec4(vec3(0.0), 0.0);
    FragData1 = vec4(vec3(0.0), 1.0);
}