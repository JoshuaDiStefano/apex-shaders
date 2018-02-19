vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
#ifdef WAVING_CAMERA
    position.xy += vec2(0.01 * sin(frameTimeCounter * 2.0), 0.01 * cos(frameTimeCounter * 3.0));
#endif

gl_Position = gl_ProjectionMatrix * gbufferModelView * position;