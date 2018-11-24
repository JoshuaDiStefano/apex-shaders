#version 120

#include "/lib/framebuffer.glsl"

uniform   mat4          gbufferProjection;
uniform   mat4          gbufferProjectionInverse;
uniform   mat4          gbufferModelViewInverse;

uniform   sampler2D     colortex0;
uniform   sampler2D     colortex1;
uniform   sampler2D     colortex2;
uniform   sampler2D     colortex3;
uniform   sampler2D     colortex4;
uniform   sampler2D     colortex5;
uniform   sampler2D     colortex6;
uniform   sampler2D     colortex7;
uniform   sampler2D     depthtex0;

uniform   vec3          upPosition;

uniform   float         isEyeInWater;
uniform   float         rainStrength;

varying   vec4          texcoord;

vec3 getNormal(in vec2 coord) {
    return normalize(texture2D(colortex2, coord).rgb * 2.0 - 1.0);
}

vec3 getCameraSpacePosition(in vec2 coord) {
    vec4 tmp = gbufferProjectionInverse * vec4(vec3(coord, texture2D(depthtex0, coord).r) * 2.0 - 1.0, 1.0);
    return tmp.xyz / tmp.w;
}

float getDepth(in vec2 coord) {
  return texture2D(depthtex0, coord).r;
}

const int maxf = 50;				//number of refinements
const float stp = 1.2;			//size of one step for raytracing algorithm
const float ref = 0.1;			//refinement multiplier
const float inc = 1.8;			//increasement factor at each step

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.s - 0.5),abs(coord.t - 0.5)) * 2.0;
}

vec4 raytrace(vec3 fragpos, vec3 normal) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i = 0; i < 30; i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
		float depth = getDepth(pos.st);
        vec3 spos = vec3(pos.st, depth);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = length(fragpos.xyz-spos.xyz);
        if(err < pow(length(vector) * pow(length(tvector), 0.11), 1.1) * 1.1){
                sr++;
                if(sr >= maxf) {
                    float border = clamp(1.0 - pow(cdist(pos.st), 5.0), 0.0, 1.0);

                    color = texture2D(colortex0, pos.st);
					color.a = 1.0;
					#ifdef SCREEN_EDGE_MASK
                    	color.a *= border;
					#endif
                    break;
                }

				tvector -=vector;
                vector *=ref;
		}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}

/*
vec4 raytrace(vec3 fragpos, vec3 normal) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
	float border = 0.0;
	vec3 pos = vec3(0.0);
    for(int i = 0; i < 40; i++){
        pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
		float depth = getDepth(pos.st);
		vec3 spos = vec3(pos.st, depth);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = abs(length(fragpos-spos.xyz));
		if(err < pow(length(vector) * pow(length(tvector), 0.11), 1.1) * 1.1){
                sr++;
                if(sr >= maxf){
                    border = clamp(1.0 - pow(cdist(pos.st), 120.0), 0.0, 1.0);
                    break;
                }
				tvector -=vector;
                vector *=ref;
		}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
	
	color.rgb = texture2D(colortex0, pos.st).rgb;
	color.a = border;
	
    return color;
}*/

/* DRAWBUFFERS:012 */

void main() {
    vec3 fragpos = vec3(texcoord.st, getDepth(texcoord.st));
	fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));
    fragpos = texture2D(colortex5, texcoord.st).rgb;
    
    //vec3 transparentLighting = texture2D(colortex5, texcoord.st).rgb;

    vec4 transparents = vec4(texture2D(colortex3, texcoord.st).rgb, texture2D(colortex6, texcoord.st).r);

    vec3 colorOut = vec3(mix(texture2D(colortex0, texcoord.st).rgb, transparents.rgb, transparents.a));
	vec3 normal = getNormal(texcoord.st);

	vec4 reflection = raytrace(fragpos, normalize(upPosition));
	
	float normalDotEye = dot(normal, normalize(fragpos));
	float fresnel = clamp(pow(1.0 + normalDotEye, 5.0), 0.0, 1.0);
    
	reflection.rgb = mix(gl_Fog.color.rgb, reflection.rgb, reflection.a); //fake sky reflection, avoid empty spaces
	reflection.a = min(reflection.a + 0.75, 1.0);
	//colorOut.rgb = mix(colorOut.rgb, reflection.rgb, float(transparents.a > 0.01));
	//colorOut.rgb += texture2D(colortex5, texcoord.st).a * (1.0-rainStrength) * 3.0;
    colorOut += texture2D(colortex7, texcoord.st).rgb;

    float brightness = dot(clamp(colorOut, 0.0, 1.0), vec3(0.299, 0.587, 0.114));
    //float brightness = colorOut.r + colorOut.g + colorOut.g;
    //brightness /= 3.0;

    FragData0 = vec4(colorOut, 1.0);
    FragData1 = mix(vec4(vec3(0.0), 1.0), vec4(colorOut, 1.0), brightness);
    FragData2 = vec4(vec3(brightness), 1.0);
}
