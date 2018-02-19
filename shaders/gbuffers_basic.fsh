#version 120

#include "/lib/framebuffer.glsl"

varying   vec4          color;

/* DRAWBUFFERS:0 */

void main() {
    FragData0 = color;
}