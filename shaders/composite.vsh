#version 120

#include "/lib/framebuffer.glsl"

uniform   vec3          shadowLightPosition;
uniform   vec3          sunPosition;
uniform   vec3          cameraPosition;

uniform   float         sunAngle;
uniform   float         rainStrength;

uniform   int           worldTime;

varying   vec4          texcoord;

varying   vec3          lightVector;
varying   vec3          lightColor;
varying   vec3          skyColor;
//varying   vec3          cameraVector;

varying   float         timeSunrise;
varying   float         timeNoon;
varying   float         timeSunset;
varying   float         timeMidnight;
varying   float         isNight;

void main() {
    gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0.0, 1.0);

    texcoord = gl_MultiTexCoord0;

    lightVector = normalize(shadowLightPosition);

    if (sunAngle <= 0.5) {
        lightColor = vec3(vec2(1.0), 0.5) * 15.0 * (1.0 - rainStrength);
        isNight = 0.0;
    } else {
        lightColor = vec3(vec2(0.025), 0.075);
        isNight = 1.0;
    }

    //vec3 position = (gbufferModelView * vec4(cameraPosition, 1.0)).xyz;

    //cameraVector = (inverse(gl_ModelViewMatrix * gbufferModelViewInverse) * vec4(vec3(0.0), 1.0)).xyz - position;
	
	float timefract = float(worldTime);
	timeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0-(clamp(timefract, 0.0, 6000.0)/6000.0));	  
	timeNoon     = ((clamp(timefract, 0.0, 6000.0)) / 6000.0) - ((clamp(timefract, 6000.0, 12000.0) - 6000.0) / 6000.0);  
	timeSunset   = ((clamp(timefract, 6000.0, 12000.0) - 6000.0) / 6000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);	  
	timeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
	
	float sunrise = timeSunrise;
	float noon = timeNoon;
	
	vec3 sunset = vec3(0.95) * timeSunset;
	vec3 midnight =  vec3(0.45, 0.45, 0.7) * timeMidnight - 0.2;

	skyColor = (((sunrise + noon + sunset + midnight) / 4.0) * (1.0 - rainStrength) + 0.05) * (1.0 - SHADOW_STRENGTH);
}
