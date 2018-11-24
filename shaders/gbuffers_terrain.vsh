#version 120

#include "/lib/positionVars.glsl"
#include "/lib/math.glsl"

#define WAVING_CAMERA

#define   WAVING_LEAVES
//#define   WAVING_VINES
#define   WAVING_GRASS
#define   WAVING_DEADBUSH
#define   WAVING_WHEAT
#define   WAVING_FLOWERS
#define   WAVING_FIRE
#define   WAVING_COBWEB

#define   ENTITY_LEAVES                             11050.0
#define   ENTITY_VINES                              11060.0
#define   ENTITY_TALLGRASS                          11000.0
#define   ENTITY_DEADBUSH                           11010.0
#define   ENTITY_TALLERGRASS                        11030.0
#define   ENTITY_WHEAT                              11020.0
#define   ENTITY_FIRE                               12153.0
#define   ENTITY_COBWEB                             11075.0

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;
attribute vec4 at_tangent;

uniform   sampler2D     normals;

uniform   vec3          cameraPosition;

varying   mat3          tbn;

varying   vec3          tintColor;
varying   vec3          normal;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   float         isEmissive;
varying   float         isFire;
varying   float         isLava;

float pi2wt = pi*2*(frameTimeCounter*24);

vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5) {
    vec3 ret;
    float magnitude,d0,d1,d2,d3;
    magnitude = sin(pi2wt*fm + pos.x*0.5 + pos.z*0.5 + pos.y*0.5) * mm + ma;
    d0 = sin(pi2wt*f0);
    d1 = sin(pi2wt*f1);
    d2 = sin(pi2wt*f2);
    ret.x = sin(pi2wt*f3 + d0 + d1 - pos.x + pos.z + pos.y) * magnitude;
    ret.z = sin(pi2wt*f4 + d1 + d2 + pos.x - pos.z + pos.y) * magnitude;
	ret.y = sin(pi2wt*f5 + d2 + d0 + pos.z + pos.y - pos.y) * magnitude;
    return ret;
}

vec3 calcMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    vec3 move1 = calcWave(pos      , 0.0027, 0.0400, 0.0400, 0.0127, 0.0089, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
    vec3 move2 = calcWave(pos+move1, 0.0348, 0.0400, 0.0400, f0, f1, f2, f3, f4, f5) * amp2;

    if (mc_Entity.x != ENTITY_COBWEB) {    
        return move1 + move2;
    } else {
        return (move1 + move2) * (lmcoord.y / 240);
    }
}

void main() {
    vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

    #ifdef WAVING_CAMERA
        position.xy += vec2(0.01 * sin(frameTimeCounter * 2.0), 0.01 * cos(frameTimeCounter * 3.0));
    #endif

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0);
	vec2 midcoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
    lmcoord = gl_MultiTexCoord1;

    float isTopVertex = 0.0;

    if (mc_Entity.x == ENTITY_TALLERGRASS) {
        if (mc_Entity.z < 8.0) {
            if (gl_MultiTexCoord0.t < mc_midTexCoord.t) isTopVertex = 0.5;
        } else {
            if (gl_MultiTexCoord0.t < mc_midTexCoord.t) {
                isTopVertex = 1.0;
            } else {
                isTopVertex = 0.5;
            }
        }
    } else {
        if (gl_MultiTexCoord0.t < mc_midTexCoord.t) isTopVertex = 1.0;
    }

	vec3 worldpos = position.xyz + cameraPosition;

    #ifdef WAVING_LEAVES
	if (mc_Entity.x == ENTITY_LEAVES) {
		position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,1.0), vec3(0.5,0.1,0.5));
    }
	#endif

	#ifdef WAVING_VINES
	if (mc_Entity.x == ENTITY_VINES)
		position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,1.0), vec3(0.5,0.1,0.5));
	#endif

    #ifdef WAVING_COBWEB
    if (mc_Entity.x == ENTITY_COBWEB)
        position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,1.0), vec3(0.5,0.1,0.5));
    #endif

	if (isTopVertex > 0.9) {
        #ifdef WAVING_GRASS
        if (mc_Entity.x == ENTITY_TALLGRASS) {
            position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
        }
        if (mc_Entity.x == ENTITY_TALLERGRASS) {
            position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
        }
        #endif

        #ifdef WAVING_WHEAT
        if (mc_Entity.x == ENTITY_WHEAT)
            position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
        #endif

        #ifdef WAVING_FIRE
        if (mc_Entity.x == ENTITY_FIRE)
            position.xyz += calcMove(worldpos.xyz, 0.0105, 0.0096, 0.0087, 0.0063, 0.0097, 0.0156, vec3(1.2,0.4,1.2), vec3(0.8,0.8,0.8));
        #endif
        
        #ifdef WAVING_DEADBUSH
        if (mc_Entity.x == ENTITY_DEADBUSH)
            position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
        #endif
	}

    if (isTopVertex == 0.5) {
        if ( mc_Entity.x == ENTITY_TALLERGRASS)
            position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
    }
    
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

    float id = mc_Entity.x;

    isEmissive = float(id == 11000.0 ||
                       id == 11010.0 ||
                       id == 11020.0 ||
                       id == 11030.0 ||
                       id == 11040.0 ||
                       id == 11080.0 ||
                       id == 12153.0
                      );

    isFire = float(mc_Entity.x == ENTITY_FIRE);
    isLava = float(mc_Entity.x == 12152.0);
    
    tintColor = gl_Color.rgb;

    normal = normalize(gl_NormalMatrix * gl_Normal);
	
	tbn = mat3(normalize(gl_NormalMatrix * at_tangent.xyz),
			   normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * sign(at_tangent.w)),
			   normal);
}
