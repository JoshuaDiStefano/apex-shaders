#ifdef DOF
            vec2 res = vec2(viewWidth, viewHeight);

            float midSample = min(getCameraDepthBuffer(vec2(0.5)) / dofStrength, 1.0);
            float fragSample = min(getCameraDepthBuffer(texcoord.st) / dofStrength, 1.0);
            float aspectratio = res.x / res.y;
            float factor = getDofFactor(midSample, fragSample);

            vec2 aspectcorrect = vec2(1.0, aspectratio);
            vec2 dofBlur = vec2(clamp(factor * aperture, -blurclamp, blurclamp));
            vec2 temp;

            vec3 col = vec3(0.0);

            float tempSample;
            float tempFactor;
            float sampleCount = 0;

            col += texture2D(gcolor, texcoord.st).rgb;
            sampleCount++;

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