vec3 getSky(vec2 coord, in float fac, in vec3 worldpos, in vec3 up, in vec3 lightPos) {
    vec3 view = worldpos;
    float atmosphere = pow(sqrt(1.0 - view.y), 4.0);
    vec3 skyColor = vec3(0.2, 0.4, 0.8);
    vec3 nightColor = vec3(0.0, 0.005, 0.0075);

    if (isNight > 0.9) {
        skyColor = mix(skyColor, nightColor, fac);
    }

    float timeFactor = dot(lightVector, up);
    
    float scatter = timeFactor / 0.5;
    scatter = 1.0 - clamp(scatter, 0.0, 1.0);

    vec3 scatterColor = mix(vec3(1.0), vec3(1.0, 0.2, 0.0) * 5.0, scatter);
    
    if (isNight > 0.9) {
        scatterColor = mix(scatterColor, nightColor * 2.0, fac);
    }

    return mix(mix(skyColor, scatterColor, clamp(atmosphere, 0.0, 1.0)), vec3(0.0), min(rainStrength, 0.95)) + texture2D(noisetex, gl_FragCoord.st * (1.0 / noiseTextureResolution)).rgb * 0.000390625;
}

vec3 getSun(vec2 coord, in float fac, in vec3 pos) {
    vec3 view = normalize(getCameraSpacePositionSky(coord).xyz);
    float sunInfluence = max(dot(view, normalize(pos)), 0.0);

	float sun = sunInfluence;
    sun = clamp(sun, 0.0, 1.0);
    
    float glow = sun;
    glow = clamp(glow, 0.0, 1.0);
    
    sun = pow(sun, 500.0);
    sun *= 5.0;
    sun = clamp(sun, 0.0, 1.0);
    
    glow = pow(glow, 150.0) * 1.0;
    glow = pow(glow, (coord.y * 1.5));
    glow = clamp(glow, 0.0, 1.0);
    
    sun *= pow(dot(coord.y, coord.y), 1.0 / 1.65);
    
    glow *= pow(dot(coord.y, coord.y), 1.0 / 2.0);
    
    sun += glow;
    
    #ifdef VANILLA_SUN
        vec3 sunColor = texture2D(colortex7, texcoord.st).rgb * texture2D(colortex7, texcoord.st).a * 2.0 * sunInfluence;
    #else
        vec3 sunColor = vec3(1.0, 0.6, 0.05) * sun * 2.0;
    #endif
    
    if (isNight > 0.9) {
        sunColor = mix(sunColor, vec3(0.0), fac);
    }
    
    return mix(sunColor, vec3(0.0), rainStrength) + texture2D(noisetex, gl_FragCoord.st * (1.0 / noiseTextureResolution)).rgb * 0.000390625;
}

vec3 getMoon(vec2 coord, in float fac, in vec3 pos) {
    vec3 view = normalize(getCameraSpacePositionSky(coord).xyz);
    float sunInfluence = max(dot(view, normalize(-pos)), 0.0);

	float sun = sunInfluence;
    sun = clamp(sun, 0.0, 1.0);
    
    float glow = sun;
    glow = clamp(glow, 0.0, 1.0);
    
    sun = pow(sun, 1000.0);
    sun *= 5.0;
    sun = clamp(sun, 0.0, 1.0);
    
    glow = pow(glow, 1000.0);
    //glow = pow(glow, (coord.y));
    glow = clamp(glow, 0.0, 1.0);
    
    //sun *= pow(dot(coord.y, coord.y), 1.0 / 1.65);
    
    //glow *= pow(dot(coord.y, coord.y), 1.0 / 5.0);
    
    sun += glow;
    
    #ifdef VANILLA_MOON
        vec3 sunColor = texture2D(colortex7, texcoord.st).rgb * texture2D(colortex7, texcoord.st).a * 3.0 * sunInfluence;
    #else
        vec3 sunColor = vec3(sun);
    #endif
    
    return mix(sunColor, vec3(0.0), rainStrength) + texture2D(noisetex, gl_FragCoord.st * (1.0 / noiseTextureResolution)).rgb * 0.000390625;
}