#version 120

#include "/lib/positionVars.glsl"
#include "/lib/math.glsl"

#define WAVING_CAMERA

#define diagonal3(mat) vec3((mat)[0].x, (mat)[1].y, mat[2].z)

#define transMAD(mat, v) (     mat3(mat) * (v) + (mat)[3].xyz)
#define  projMAD(mat, v) (diagonal3(mat) * (v) + (mat)[3].xyz)

attribute vec4 mc_Entity;
attribute vec4 at_tangent;

uniform   mat4          gbufferProjection;

uniform   vec3          cameraPosition;

varying   mat3          tbn;

varying   vec3          tintColor;
varying   vec3          normal;
varying   vec3          nnormal;
varying   vec3          binormal;
varying   vec3          tangent;
varying   vec3          headPosition;
varying   vec3          bump;
varying   vec3          viewVector;
varying   vec3          vertPosition;
varying   vec3          worldpos;

varying   vec4          texcoord;
varying   vec4          lmcoord;

varying   float         isWater;
varying   float         isGlass;
varying   float         isTransparent;

vec3 getHeadPosition() {
    vec3 temp = (gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;
    temp.y -= 1.62;
    return temp;
}

void main() {
    if (mc_Entity.x == 13000) {
        isWater = 1.0;
        isGlass = 0.0;
    } else if (mc_Entity.x == 13011) {
        isGlass = 1.0;
        isWater = 0.0;
    } else {
        isWater = 0.0;
        isGlass = 0.0;
    }

    isTransparent = float(mc_Entity.x == 13010);

    float displacement;

    vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    
    if (isWater > 0.9) {
        worldpos = position.xyz + cameraPosition;

        float fy = fract(worldpos.y + 0.001);
        
        if (fy > 0.002) {
            float wave = 0.05 * sin(2 * pi * (frameTimeCounter * 0.75 + worldpos.x /  7.0 + worldpos.z / 13.0))
                       + 0.05 * sin(2 * pi * (frameTimeCounter * 0.6 + worldpos.x / 11.0 + worldpos.z /  5.0));
            displacement = clamp(wave, -fy, 1.0 - fy);
            position.y += displacement;
        }
    }

    #ifdef WAVING_CAMERA
        position.xy += vec2(0.01 * sin(frameTimeCounter * 2.0), 0.01 * cos(frameTimeCounter * 3.0));
    #endif

    gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

    vertPosition = gl_Position.xyz;

    headPosition = getHeadPosition();

    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;

    tangent = vec3(0.0);
	binormal = vec3(0.0);
	normal = normalize(gl_NormalMatrix * normalize(gl_Normal));

	if (gl_Normal.x > 0.5) {
		//  1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0, -1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.x < -0.5) {
		// -1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.y > 0.5) {
		//  0.0,  1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	}
	
	else if (gl_Normal.y < -0.5) {
		//  0.0, -1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	}
	
	else if (gl_Normal.z > 0.5) {
		//  0.0,  0.0,  1.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.z < -0.5) {
		//  0.0,  0.0, -1.0
		tangent  = normalize(gl_NormalMatrix * vec3(-1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  tangent.y, binormal.y, normal.y,
						  tangent.z, binormal.z, normal.z);

    nnormal = vec3(sin(displacement * pi), 1.0 - cos(displacement * pi), displacement);

    bump = nnormal;
		
    float bumpmult = 0.05;
	
	bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);

    nnormal = bump * tbnMatrix;

    viewVector = (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewVector = normalize(tbnMatrix * viewVector);

    normal = normalize(gl_NormalMatrix * gl_Normal);
	
	tbn = mat3(normalize(gl_NormalMatrix * at_tangent.xyz),
			   normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * sign(at_tangent.w)),
			   normal);
}
