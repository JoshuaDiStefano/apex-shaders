#version 120

#include "/lib/framebuffer.glsl"
#include "/lib/math.glsl"

uniform   mat4          gbufferModelViewInverse;
uniform   mat4          gbufferProjectionInverse;

uniform   sampler2D     colortex1;
uniform   sampler2D     colortex2;
uniform   sampler2D     colortex4;
uniform   sampler2D     gdepthtex;

uniform   vec3          upPosition;
uniform   vec3          cameraPosition;

uniform   vec2          viewHeight;
uniform   vec2          viewWidth;

varying   vec4          texcoord;

varying   vec3          lightVector;
varying   vec3          lightColor;
varying   vec3          skyColor;

varying   float         isNight;

vec4 getAlbedo(in vec2 coord) {
    return pow(texture2D(colortex4, coord), vec4(2.2));
}

vec4 getDepth(in vec2 coord) {
  return texture2D(gdepthtex, coord);
}

vec3 getNormal(in vec2 coord) {
    return texture2D(colortex2, coord).rgb * 2.0 - 1.0;
}

struct LightingParams {
    float Emission;
    float TorchLightStrength;
    float SkyLightStrength;
};

LightingParams getLightingParams(in vec2 coord) {
    LightingParams lp;

    vec3 ct1 = texture2D(colortex1, coord).rgb;

    lp.Emission = ct1.b;
    lp.TorchLightStrength = pow(ct1.r, 2.2);
    lp.SkyLightStrength = ct1.g;

    return lp;
}

/* DRAWBUFFERS:1234 */

struct Fragment {
    vec4 albedo;
    vec3 normal;

    float emission;
};

struct Lightmap {
    float torchLightStrength;
    float skyLightStrength;
};

Fragment getFragment(in vec2 coord) {
    Fragment newFragment;

    LightingParams lp = getLightingParams(coord);

    newFragment.albedo = getAlbedo(coord);
    newFragment.normal = getNormal(coord);
    newFragment.emission = lp.Emission;

    return newFragment;
}

Lightmap getLightmapSample(in vec2 coord) {
    Lightmap lightmap;

    LightingParams lp = getLightingParams(coord);

    lightmap.torchLightStrength = lp.TorchLightStrength;
    lightmap.skyLightStrength = lp.SkyLightStrength;

    return lightmap;
}

vec4 calculateLighting(in Fragment frag, in Lightmap lm, in vec2 coord, in float isTransparent) {
    vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * getDepth(coord).r - 1.0f, 1.0f);
	fragposition /= fragposition.w;

    vec3 viewDirection = normalize(-fragposition.xyz);
    vec3 halfAngle = normalize(lightVector + viewDirection);

    float nDotL = dot(frag.normal, lightVector);
    float uDotL = dot(normalize(upPosition), lightVector);
    float nDotH = dot(frag.normal, halfAngle);

    float directLightStrength = mix(0.1, nDotL * 0.2, frag.albedo.a);
    directLightStrength = max(0.0, directLightStrength);
    vec3 directLight = directLightStrength * lightColor;

    vec3 torchColor = vec3(0.02125, 0.005, 0.00125);
    vec3 torchLight = torchColor * lm.torchLightStrength;

    vec3 skyLight = skyColor * lm.skyLightStrength;

    vec3 nonDirectLight = skyLight + torchLight;
    vec3 litColor = frag.albedo.rgb * (directLight + nonDirectLight);

    float a = acos(nDotH);
    float b = normalize(cos(a));
    b *= b;
    float c = b * b;
    float m = 1.0;
    float d = m * m;
    float specular = (exp((1.0 - b) / (b * d)) / (pi * d * c));

    return vec4(litColor * specular, frag.albedo.a);
}

void main() {
    //vec4 worldPos = normalize(getWorldSpacePositionSky(texcoord.st));

    Fragment frag = getFragment(texcoord.st);
    Lightmap lm = getLightmapSample(texcoord.st);

    vec4 finalColor = calculateLighting(frag, lm, texcoord.st, 0.0);
    //finalColor = texture2D(colortex4, texcoord.st).rgb;

    //FragData0 = vec4(vec3(fract(worldPos.xz / worldPos.y), 0.0), 1.0);
    //FragData0 = vec4(texture2D(gdepthtex, texcoord.st).rgb, 1.0);
    //FragData0 = vec4(vec3((getCameraDepthBuffer(texcoord.st)) / 50.0), 1.0);
    FragData3 = finalColor;
}