#version 120

#include "/lib/framebuffer.glsl"
#include "/lib/gaussian.glsl"

uniform   sampler2D     colortex0;
uniform   sampler2D     colortex1;

uniform   float         viewHeight;
uniform   float         viewWidth;

varying   vec4          texcoord;

/* DRAWBUFFERS:01 */

void main() {
    FragData0 = vec4(texture2D(colortex0, texcoord.st).rgb, 1.0);
    FragData1 = gaussian(colortex1, vec2(viewWidth, viewHeight), vec2(1.0, 0.0), texcoord.st, BLOOM_STRENGTH);
}
