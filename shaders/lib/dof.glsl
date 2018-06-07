#ifdef DOF
            const vec2[60] offsets = vec2[60] (
                vec2( 0.0000, 0.2500 ),
                vec2( -0.2165, 0.1250 ),
                vec2( -0.2165, -0.1250 ),
                vec2( -0.0000, -0.2500 ),
                vec2( 0.2165, -0.1250 ),
                vec2( 0.2165, 0.1250 ),
                vec2( 0.0000, 0.5000 ),
                vec2( -0.2500, 0.4330 ),
                vec2( -0.4330, 0.2500 ),
                vec2( -0.5000, 0.0000 ),
                vec2( -0.4330, -0.2500 ),
                vec2( -0.2500, -0.4330 ),
                vec2( -0.0000, -0.5000 ),
                vec2( 0.2500, -0.4330 ),
                vec2( 0.4330, -0.2500 ),
                vec2( 0.5000, -0.0000 ),
                vec2( 0.4330, 0.2500 ),
                vec2( 0.2500, 0.4330 ),
                vec2( 0.0000, 0.7500 ),
                vec2( -0.2565, 0.7048 ),
                vec2( -0.4821, 0.5745 ),
                vec2( -0.6495, 0.3750 ),
                vec2( -0.7386, 0.1302 ),
                vec2( -0.7386, -0.1302 ),
                vec2( -0.6495, -0.3750 ),
                vec2( -0.4821, -0.5745 ),
                vec2( -0.2565, -0.7048 ),
                vec2( -0.0000, -0.7500 ),
                vec2( 0.2565, -0.7048 ),
                vec2( 0.4821, -0.5745 ),
                vec2( 0.6495, -0.3750 ),
                vec2( 0.7386, -0.1302 ),
                vec2( 0.7386, 0.1302 ),
                vec2( 0.6495, 0.3750 ),
                vec2( 0.4821, 0.5745 ),
                vec2( 0.2565, 0.7048 ),
                vec2( 0.0000, 1.0000 ),
                vec2( -0.2588, 0.9659 ),
                vec2( -0.5000, 0.8660 ),
                vec2( -0.7071, 0.7071 ),
                vec2( -0.8660, 0.5000 ),
                vec2( -0.9659, 0.2588 ),
                vec2( -1.0000, 0.0000 ),
                vec2( -0.9659, -0.2588 ),
                vec2( -0.8660, -0.5000 ),
                vec2( -0.7071, -0.7071 ),
                vec2( -0.5000, -0.8660 ),
                vec2( -0.2588, -0.9659 ),
                vec2( -0.0000, -1.0000 ),
                vec2( 0.2588, -0.9659 ),
                vec2( 0.5000, -0.8660 ),
                vec2( 0.7071, -0.7071 ),
                vec2( 0.8660, -0.5000 ),
                vec2( 0.9659, -0.2588 ),
                vec2( 1.0000, -0.0000 ),
                vec2( 0.9659, 0.2588 ),
                vec2( 0.8660, 0.5000 ),
                vec2( 0.7071, 0.7071 ),
                vec2( 0.5000, 0.8660 ),
                vec2( 0.2588, 0.9659 )
            );

            vec2 res = vec2(viewWidth, viewHeight);

            vec3 pos = vec3(0.5, 0.5, centerDepthSmooth);
            vec4 v = gbufferProjectionInverse * vec4(pos * 2.0 - 1.0, 1.0);
            float midSample = length(pos) / v.w;

            //float midSample = min(getCameraDepthBuffer(vec2(0.5)) / dofStrength, 1.0);
            float fragSample = min(texture2D(depthtex1, texcoord.st).r / dofStrength, 1.0);
            float aspectratio = res.x / res.y;
            float factor = getDofFactor(fragSample, centerDepthSmooth / dofStrength);

            vec2 aspectcorrect = vec2(1.0, aspectratio);
            #ifdef TILT_SHIFT
                vec2 dofBlur = vec2(clamp(factor / aperture * 3.25, -blurclamp, blurclamp));
            #else
                vec2 dofBlur = vec2(clamp(factor * aperture, -blurclamp, blurclamp));
            #endif
            vec2 temp;

            vec3 col = vec3(0.0);

            float tempSample;
            float tempFactor;
            float sampleCount = 0;

            col += texture2D(colortex0, texcoord.st).rgb;
            sampleCount++;

            /*for(int i = 0; i < 1; ++i) {
                col += texture2D(colortex0, texcoord.st + (vec2(offsets[i]) * aspectcorrect) * dofBlur).rgb;
                sampleCount++;
                //weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            }*/

            temp = texcoord.st + (vec2(  0.0,    0.4  ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.15,   0.37 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.29,   0.29 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2( -0.37,   0.15 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.4,    0.0  ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.37,  -0.15 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.29,  -0.29 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2( -0.15,  -0.37 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.0,   -0.4  ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2( -0.15,   0.37 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2( -0.29,   0.29 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.37,   0.15 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2( -0.4,    0.0  ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2( -0.37,  -0.15 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2( -0.29,  -0.29 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.15,  -0.37 ) * aspectcorrect) * dofBlur;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            

            temp = texcoord.st + (vec2(  0.15,   0.37 ) * aspectcorrect) * dofBlur * 0.9;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2( -0.37,   0.15 ) * aspectcorrect) * dofBlur * 0.9;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.37,  -0.15 ) * aspectcorrect) * dofBlur * 0.9;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2( -0.15,  -0.37 ) * aspectcorrect) * dofBlur * 0.9;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2( -0.15,   0.37 ) * aspectcorrect) * dofBlur * 0.9;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.37,   0.15 ) * aspectcorrect) * dofBlur * 0.9;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2( -0.37,  -0.15 ) * aspectcorrect) * dofBlur * 0.9;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

            temp = texcoord.st + (vec2(  0.15,  -0.37 ) * aspectcorrect) * dofBlur * 0.9;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);

        
            temp = texcoord.st + (vec2(  0.29,   0.29 ) * aspectcorrect) * dofBlur * 0.7;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2(  0.4,    0.0  ) * aspectcorrect) * dofBlur * 0.7;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2(  0.29,  -0.29 ) * aspectcorrect) * dofBlur * 0.7;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2(  0.0,   -0.4  ) * aspectcorrect) * dofBlur * 0.7;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2( -0.29,   0.29 ) * aspectcorrect) * dofBlur * 0.7;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2( -0.4,    0.0  ) * aspectcorrect) * dofBlur * 0.7;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2( -0.29,  -0.29 ) * aspectcorrect) * dofBlur * 0.7;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2(  0.0,    0.4  ) * aspectcorrect) * dofBlur * 0.7;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            
            temp = texcoord.st + (vec2(  0.29,   0.29 ) * aspectcorrect) * dofBlur * 0.4;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2(  0.4,    0.0  ) * aspectcorrect) * dofBlur * 0.4;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2(  0.29,  -0.29 ) * aspectcorrect) * dofBlur * 0.4;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2(  0.0,   -0.4  ) * aspectcorrect) * dofBlur * 0.4;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2( -0.29,   0.29 ) * aspectcorrect) * dofBlur * 0.4;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2( -0.4,    0.0  ) * aspectcorrect) * dofBlur * 0.4;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2( -0.29,  -0.29 ) * aspectcorrect) * dofBlur * 0.4;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            temp = texcoord.st + (vec2(  0.0,    0.4  ) * aspectcorrect) * dofBlur * 0.4;
            weightSample(tempSample, tempFactor, sampleCount, col, temp, fragSample);
            
            color = col / sampleCount;
        #endif
