
#include "/lib/framebuffer.glsl"

uniform   sampler2D     colortex0;
uniform   sampler2D     colortex4;

varying   vec4          texcoord;

void main() {
    vec4 transparents = texture2D(colortex4, texcoord.xy);

    FragData0 = vec4(mix(texture2D(colortex0, texcoord.xy).rgb, transparents.rgb, transparents.a), 1.0);
}
