//
//  Shader.fsh
//  Codea
//
//  Created by Simeon Saint-Saëns on 17/05/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

varying highp vec2 vTexCoord;

uniform highp float Radius;

uniform lowp vec4 StrokeColor;

void main()
{
    highp float RadiusAA = max( Radius-0.5, 0.0 );
    
    //RadiusAA = RadiusAA * step( 1.0, RadiusAA );
    
    //highp vec2 scaledPointSq = vec2( (vTexCoord.x * Radius) * (vTexCoord.x * Radius), (vTexCoord.y * Radius) * (vTexCoord.y * Radius) );
    
    highp vec2 pos = vTexCoord*Radius;
    highp float dist = sqrt(dot(pos, pos));
    
    //Regular blend
    //gl_FragColor = mix( vec4(StrokeColor.rgb,0), StrokeColor, smoothstep(Radius*Radius,RadiusAA*RadiusAA,dist_squared));
    
    //Premult
    gl_FragColor = mix( vec4(0,0,0,0), StrokeColor, smoothstep(Radius,RadiusAA,dist));    
}

