#version 120

const     float      	centerDepthHalflife       = 2.0f;  // [0.0f 0.2f 0.4f 0.6f 0.8f 1.0f 1.2f 1.4f 1.6f 1.8f 2.0f] Transition speed for focus.

const     int           shadowMapResolution       = 2048;  // [1024 2048 4096]
const     int           noiseTextureResolution    = 512;

#include "/lib/framebuffer.glsl"
#include "/lib/math.glsl"
#include "/lib/poisson.glsl"

#define   TRANSPARENT_SHADOWS
#define   ROUGHNESS                                 0.0
#define   SPECULAR_FALLOFF                          750

uniform   mat4          gbufferModelViewInverse;
uniform   mat4          gbufferProjectionInverse;

uniform   mat4          shadowModelView;
uniform   mat4          shadowProjection;

uniform   sampler2D     colortex0;
uniform   sampler2D     colortex1;
uniform   sampler2D     colortex2;
uniform   sampler2D     colortex3;
uniform   sampler2D     colortex4;
uniform   sampler2D     colortex5;
uniform   sampler2D     colortex6;
uniform   sampler2D     colortex7;
uniform   sampler2D     noisetex;
uniform   sampler2D     depthtex0;
uniform   sampler2D     depthtex1;
uniform   sampler2D     gdepthtex;
uniform   sampler2D     shadow;
uniform   sampler2D     watershadow;
uniform   sampler2D     shadowtex0;
uniform   sampler2D     shadowtex1;
uniform   sampler2D     shadowcolor0;

uniform   vec3          upPosition;
uniform   vec3          cameraPosition;
uniform   vec3          sunPosition;
uniform   vec3          fogColor;

uniform   float         viewHeight;
uniform   float         viewWidth;
uniform   float         rainStrength;
uniform   float         far;
uniform   float         near;
uniform   float         fogDensity;
uniform   float         frameTimeCounter;
uniform   float         sunAngle;
uniform   float         nightVision;

uniform   int           isEyeInWater;
uniform   int           worldTime;

varying   vec4          texcoord;

varying   vec3          lightVector;
varying   vec3          lightColor;
varying   vec3          skyColor;
varying   vec3          cameraVector;

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

vec4 getCameraSpacePositionSky(in vec2 coord) {
    float depth = getDepth(coord).r;
    vec4 positionNdcSpace = vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);
    vec4 positionCameraSpace = normalize(gbufferProjectionInverse * positionNdcSpace);
  
    return positionCameraSpace / positionCameraSpace.w;
}

vec4 getWorldSpacePositionSky(in vec2 coord) {
    vec4 tmp = gbufferProjectionInverse * vec4(coord * 2.0 - 1.0, 1.0, 1.0);
    vec3 viewPos = tmp.xyz / tmp.w;
    vec4 positionCameraSpace = vec4(viewPos, 1.0);
    vec4 positionWorldSpace = gbufferModelViewInverse * vec4(positionCameraSpace);
    //positionWorldSpace.xyz *= cameraPosition.xyz;

    return positionWorldSpace;
}

float getCameraDepthBuffer(in vec2 coord) {
    vec3 pos = vec3(coord, texture2D(depthtex0, coord).r);
    vec4 v = gbufferProjectionInverse * vec4(pos * 2.0 - 1.0, 1.0);
    return length(pos) / v.w;
}

#include "/lib/sky.glsl"

vec3 calcSky(in vec2 coord) {
    return texture2D(colortex6, coord).rgb;
}

vec4 getCameraSpacePositionShadow(in vec2 coord) {
    float depth = getDepth(coord).r;
    vec4 positionNdcSpace = vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);
    vec4 positionCameraSpace = gbufferProjectionInverse * positionNdcSpace;

    return positionCameraSpace / positionCameraSpace.w;
}

vec4 getWorldSpacePositionShadow(in vec2 coord) {
    vec4 positionCameraSpace = getCameraSpacePositionShadow(coord);
    vec4 positionWorldSpace = gbufferModelViewInverse * positionCameraSpace;
    positionWorldSpace.xyz += cameraPosition.xyz;

    return positionWorldSpace;
}

vec3 getShadowSpacePosition(in vec2 coord, inout float fac) {
    vec4 positionWorldSpace = getWorldSpacePositionShadow(coord);

    positionWorldSpace.xyz -= cameraPosition;
    vec4 positionShadowSpace = shadowModelView * positionWorldSpace;
    positionShadowSpace = shadowProjection * positionShadowSpace;
    positionShadowSpace /= positionShadowSpace.w;

    float dist = sqrt(positionShadowSpace.x * positionShadowSpace.x + positionShadowSpace.y * positionShadowSpace.y);
    float distortFactor = (1.0f - 0.85) + dist * 0.85;

    positionShadowSpace.xy *= 1.0f / distortFactor;
    fac = 1.0f / distortFactor;

    return positionShadowSpace.xyz * 0.5 + 0.5;
}

mat2 getRotationMatrix(in vec2 coord) {
    float angle = texture2D(
        noisetex,
        coord * vec2(
            viewWidth / noiseTextureResolution,
            viewHeight / noiseTextureResolution
        )
    ).r * (2.0 * 3.1415);

    vec2 sc = vec2(sin(angle), cos(angle));
    return mat2(
        sc.y, -sc.x,
        sc.x, sc.y
    );
}

float getPenumbraWidth(in vec3 shadowCoord, in float factor, in sampler2D shadowTexture) {
    float dFragment = shadowCoord.z; //distance from pixel to light
    float dBlocker = 0.0; //distance from blocker to light
    float penumbra = 0.0;
    
    float shadowMapSample; //duh
    float numBlockers = 0.0;

    float searchSize = LIGHT_SIZE / dFragment;

    for (int x = -PCSS_SAMPLE_COUNT; x < PCSS_SAMPLE_COUNT; x++) {
        for (int y = -PCSS_SAMPLE_COUNT; y < PCSS_SAMPLE_COUNT; y++) {
            vec2 sampleCoord = shadowCoord.st + (vec2(x, y) * searchSize / (shadowMapResolution * 25 * PCSS_SAMPLE_COUNT));
            shadowMapSample = texture2D(shadowTexture, sampleCoord, 2.0).r;

            dBlocker += shadowMapSample;
            numBlockers += 1.0;
        }
    }

    if(numBlockers > 0.0) {
		dBlocker /= numBlockers;
		penumbra = (dFragment - dBlocker) * LIGHT_SIZE / dFragment;
	}

    return clamp(max(penumbra, MIN_PENUMBRA_SIZE), 0.0, searchSize / 50);
}

vec3 getShadowColor(in vec2 coord) {
    float factor;

    vec3 shadowCoord = getShadowSpacePosition(coord, factor);
    vec3 shadowColor = vec3(0.0);

    #ifdef PCSS
        float penumbraSize1 = getPenumbraWidth(shadowCoord, factor, shadowtex1);
        float penumbraSize2 = getPenumbraWidth(shadowCoord, factor, watershadow);
    #else
        float penumbraSize1 = 1.0;
        float penumbraSize2 = 1.0;
    #endif
    
    int numSamples = 64;

    float shadowMapBias1;
    float shadowMapBias2;

    mat2 rotationMatrix = getRotationMatrix(coord);

    if (!(shadowCoord.x > 0.0 && shadowCoord.x < 1.0 && shadowCoord.y > 0.0 && shadowCoord.y < 1.0)) {
        return vec3(0.111);
    }

    for (int i = 0; i < numSamples; i++) {
        vec2 offset1 = disc64[i] / shadowMapResolution;
        vec2 offset2 = offset1;
        offset1 *= penumbraSize1;
        offset2 *= penumbraSize2;
        #ifdef RANDOM_ROTATION
            offset1 = rotationMatrix * offset1;
            offset2 = rotationMatrix * offset2;
        #endif

        shadowMapBias1 = 0.0005 * (length(offset1) + 0.75);
        shadowMapBias2 = 0.0005 * (length(offset2) + 0.75);

        vec2 adjustedShadowCoord1 = shadowCoord.st + offset1;
        vec2 adjustedShadowCoord2 = shadowCoord.st + offset2;
        
        float shadowMapSample = texture2D(shadowtex1, adjustedShadowCoord1).r;
        float visibility = step(shadowCoord.z - shadowMapSample, shadowMapBias1);
        
        float shadowMapSampleTransparent = texture2D(watershadow, adjustedShadowCoord2).r;
        float transparentVisibility = step(shadowCoord.z - shadowMapSampleTransparent, shadowMapBias2);

        vec3 colorSample = texture2D(shadowcolor0, adjustedShadowCoord2).rgb;

        colorSample = mix(colorSample, vec3(1.0), transparentVisibility);
        colorSample = mix(vec3(0.0), colorSample, visibility);

        shadowColor += colorSample;
    }

    shadowColor /= numSamples;

    return shadowColor * 0.111;
}

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

    lightmap.torchLightStrength = lp.TorchLightStrength * 0.5;
    lightmap.skyLightStrength = lp.SkyLightStrength;

    return lightmap;
}

float ctorspec(vec3 ppos, vec3 lvector, vec3 normal) {
    //half vector
	vec3 pos = -normalize(ppos);
    vec3 cHalf = normalize(lvector + pos);
	
    // beckman's distribution function D
    float normalDotHalf = dot(normal, cHalf);
    float normalDotHalf2 = normalDotHalf * normalDotHalf;

    float roughness2 = 0.05;
    float exponent = -(1.0 - normalDotHalf2) / (normalDotHalf2 * roughness2);
    float e = 2.71828182846;
    float D = pow(e, exponent) / (roughness2 * normalDotHalf2 * normalDotHalf2);
	//D *= texture2D(gaux1, texcoord.st).a;
	
    // fresnel term F
	float normalDotEye = dot(normal, pos);
    float F = pow(1.0 - normalDotEye, 5.0);

    // self shadowing term G
    float normalDotLight = dot(normal, lvector);
    float X = 2.0 * normalDotHalf / dot(pos, cHalf);
    float G = min(1.0, min(X * normalDotLight, X * normalDotEye));
    float pi = 3.1415927;
    float CookTorrance = (D*F*G)/(pi*normalDotEye);
	
    return max(CookTorrance/pi,0.0);
}

float getNoHSquared(float radiusTan, float NoL, float NoV, float VoL) { // From https://www.guerrilla-games.com/read/decima-engine-advances-in-lighting-and-aa
    float radiusCos = inversesqrt(1.0 + radiusTan * radiusTan);

    float RoL = 2.0 * NoL * NoV - VoL;
    if (RoL >= radiusCos)
        return 1.0;

    float rOverLengthT = radiusCos * radiusTan * inversesqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    float triple = sqrt(clamp(1.0 - NoL * NoL - NoV - VoL * VoL + 2.0 * NoL * NoV * VoL, 0.0, 1.0));

    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * q + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr +
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    VoTr = cosTheta * VoTr + sinTheta * VoBr;

    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;
    return max(0.0, NoH * NoH / HoH);
}

float GGX (vec3 n, vec3 v, vec3 l, float r, float F0) {
  r*=r;r*=r;
  
  vec3 h = l + v;
  float hn = inversesqrt(dot(h, h));

  float dotLH = clamp(dot(h,l)*hn,0.,1.);
  float dotNL = clamp(dot(n,l),0.,1.);
  float dotNH = getNoHSquared(tan(radians(5.5)), dotNL, dot(n,v), dot(v,l));
  
  float denom = (dotNH * r - dotNH) * dotNH + 1.;
  float D = r / (3.141592653589793 * denom * denom);
  float F = F0 + (1. - F0) * exp2((-5.55473*dotLH-6.98316)*dotLH);
  float k2 = .25 * r;

  return dotNL * D * F / (dotLH*dotLH*(1.0-k2)+k2);
}

float OrenNayar(vec3 v, vec3 l, vec3 n, float r) {
    r *= r;
    
    float NdotL = dot(n,l);
    float NdotV = dot(n,v);
    
    float t = max(NdotL,NdotV);
    float g = max(.0, dot(v - n * NdotV, l - n * NdotL));
    float c = g/t - g*t;
    
    float a = .285 / (r+.57) + .5;
    float b = .45 * r / (r+.09);

    return max(0., NdotL) * ( b * c + a);
}

float diffuseorennayar(vec3 pos, vec3 lvector, vec3 normal, float spec, float roughness) {
	
    vec3 v=normalize(pos);
	vec3 l=normalize(lvector);
	vec3 n=normalize(normal);

	float vdotn=dot(v,n);
	float ldotn=dot(l,n);
	float cos_theta_r=vdotn; 
	float cos_theta_i=ldotn; 
	float cos_phi_diff=dot(normalize(v-n*vdotn),normalize(l-n*ldotn));
	float cos_alpha=min(cos_theta_i,cos_theta_r); // alpha=max(theta_i,theta_r);
	float cos_beta=max(cos_theta_i,cos_theta_r); // beta=min(theta_i,theta_r)

	float r2=roughness*roughness;
	float a=1.0-0.5*r2/(r2+0.33);
	float b_term;
	
	if(cos_phi_diff>=0.0) {
		float b=0.45*r2/(r2+0.09);
		//b_term=b*sqrt((1.0-cos_alpha*cos_alpha)*(1.0-cos_beta*cos_beta))/cos_beta*cos_phi_diff;
		b_term = b*sin(cos_alpha)*tan(cos_beta)*cos_phi_diff;
	}
	else b_term=0.0;

	return clamp(cos_theta_i*(a+b_term*spec),0.0,1.0);
}

vec4 calculateLighting(in Fragment frag, in Lightmap lm, in vec2 coord, inout vec3 spec) {
    float notNdotL = OrenNayar(-normalize(getCameraSpacePositionShadow(texcoord.st).xyz), lightVector, frag.normal, 0.001);

    vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * getDepth(texcoord.st).r - 1.0f, 1.0f);
	fragposition /= fragposition.w;

    float specularIntensity = GGX(frag.normal, -normalize(fragposition.xyz), lightVector, clamp(texture2D(colortex5, texcoord.st).g, 0.1, 1.0), 0.0) * float(frag.albedo.a > 0.01);
    //specularIntensity = ctorspec(fragposition.xyz, lightVector, normalize(frag.normal)) * texture2D(colortex3, texcoord.st).r;
    vec3 specularColor = clamp(specularIntensity, 0.0, 1.0) * lightColor;

    float directLightStrength = max(0.0, notNdotL);
    vec3 directLight = directLightStrength * lightColor;

    vec3 torchColor = vec3(0.85, 0.5, 0.15) * 5.0;
    vec3 torchLight = torchColor * lm.torchLightStrength;

    vec3 skyLight = skyColor * lm.skyLightStrength;

    vec3 nonDirectLight = max(skyLight, 0.025) + torchLight;
    vec3 shadowColor;

    #ifdef TRANSPARENT_SHADOWS
        if (frag.albedo.a > 0.01) {
            shadowColor = getShadowColor(coord);
        } else {
            shadowColor = vec3(0.2);
        }
    #else
        shadowColor = vec3(0.2);
    #endif

    spec = specularColor * shadowColor + texture2D(noisetex, gl_FragCoord.st * (1.0 / noiseTextureResolution)).rgb * 0.00390625;
    vec3 litColor = frag.albedo.rgb * (directLight * shadowColor + nonDirectLight) + spec;

    return vec4(litColor, frag.albedo.a);
}

void desat(inout vec3 color, in float strength) {
	float amount = 0.8f;
	vec3 cyan = vec3(0.12f, 0.45f, 1.0f);
	float gray = dot(color, vec3(1.0f));

	color = mix(color, vec3(gray) * cyan, strength * amount);
    color *= 0.5;
}

float linearDepth(float depth) {
    if (isEyeInWater == 0) {
        return (2.0 * near - FOG_DENSITY + rainStrength * 0.15) / (FAR + near - FOG_DENSITY + rainStrength * 0.15 - depth * (FAR - near - FOG_DENSITY + rainStrength * 0.15));
    } else if (isEyeInWater == 1) {
        return (2.0 * near) / (FAR + near - depth * (FAR - near));
    }
}

vec3 fog(in vec3 colorOut, in vec3 sky) {
    if (isEyeInWater == 0) {
        colorOut = mix(colorOut, sky, clamp(pow(linearDepth(getDepth(texcoord.st).r) * 1.5, 1.5) * 0.8, 0.0, 0.75));
    } else if (isEyeInWater == 1) {
        colorOut = mix(colorOut, vec3(0.025) * WATER_COLOR, clamp(pow(linearDepth(getDepth(texcoord.st).r), 1.5) * 1.5, 0.0, 0.95) * (1.0 - nightVision));        
    }

    return colorOut;
}

/* DRAWBUFFERS:3567 */

void main() {
    //vec4 worldPos = normalize(getWorldSpacePositionSky(texcoord.st));

    Fragment frag = getFragment(texcoord.st);
    Lightmap lm = getLightmapSample(texcoord.st);

    vec3 spec;
    
    vec4 finalColor = calculateLighting(frag, lm, texcoord.st, spec);
    //finalColor = texture2D(colortex4, texcoord.st).rgb;

    if (bool(isNight)) {
        desat(finalColor.rgb, pow((1.0 - lm.torchLightStrength), 256.0));
    }

    vec3 sky = calcSky(texcoord.st);

    #ifdef FOG
        finalColor.rgb = fog(finalColor.rgb, sky);
    #endif

    vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * getDepth(texcoord.st).r - 1.0f, 1.0f);
	fragposition /= fragposition.w;

    //FragData0 = vec4(vec3(fract(worldPos.xz / worldPos.y), 0.0), 1.0);
    //FragData0 = vec4(texture2D(gdepthtex, texcoord.st).rgb, 1.0);
    //FragData0 = vec4(vec3((getCameraDepthBuffer(texcoord.st)) / 50.0), 1.0);
    FragData0 = vec4(finalColor.rgb, 1.0);
    FragData1 = fragposition;//vec4(ctorspec(fragposition.xyz, lightVector, normalize(frag.normal)));
    FragData2 = vec4(vec3(finalColor.a), 1.0);
    FragData3 = vec4(spec, 1.0);
}
