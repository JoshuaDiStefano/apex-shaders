#version 120

#include "/lib/framebuffer.glsl"

uniform   sampler2D     texture;

uniform   float         rainStrength;

varying   vec4          texcoord;

/* DRAWBUFFERS:7 */

void main() {
    vec4 sunColor = texture2D(texture, texcoord.st);

    FragData0 = vec4(sunColor.rgb, sunColor.a * (1.0 - rainStrength) * dot(sunColor.rgb, vec3(0.299, 0.587, 0.114)));
}