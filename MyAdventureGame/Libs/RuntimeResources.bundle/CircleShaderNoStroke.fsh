//
//  Shader.fsh
//  Codea
//
//  Created by Simeon Saint-Saëns on 17/05/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

varying highp vec2 vTexCoord;

uniform highp vec2 Radius;

uniform lowp vec4 FillColor;

void main()
{            
//    highp float RadiusAA = Radius-2.5;    
    //highp vec2 scaledPointSq = vec2( (vTexCoord.x * Radius) * (vTexCoord.x * Radius), (vTexCoord.y * Radius) * (vTexCoord.y * Radius) );
    
//    highp vec2 pos = vTexCoord*Radius;
//    highp float dist_squared = dot(pos, pos);
    
    highp vec2 RadiusAA = vec2(Radius.x - 4.0, Radius.y - 4.0);
    
    highp vec2 scaledPointSq = vec2( (vTexCoord.x * Radius.x) * (vTexCoord.x * Radius.x), (vTexCoord.y * Radius.y) * (vTexCoord.y * Radius.y) );
    
    highp float c = (scaledPointSq.x / (Radius.x*Radius.x)) + (scaledPointSq.y / (Radius.y*Radius.y));    
    highp float cAA = (scaledPointSq.x / (RadiusAA.x*RadiusAA.x)) + (scaledPointSq.y / (RadiusAA.y*RadiusAA.y));            
    
    //gl_FragColor = mix( FillColor, vec4(0,0,0,0), smoothstep(Radius*Radius,RadiusAA*RadiusAA,dist_squared));    
    
    gl_FragColor = mix( FillColor, vec4(0,0,0,0), smoothstep( c / cAA, 1.0, c ) );        
}

