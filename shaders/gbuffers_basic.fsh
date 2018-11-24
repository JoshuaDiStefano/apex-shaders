#version 120

#include "/lib/framebuffer.glsl"

varying   vec4          color;

/* DRAWBUFFERS:04 */

void main() {
    FragData0 = color;
    FragData1 = vec4(0.0);
}
