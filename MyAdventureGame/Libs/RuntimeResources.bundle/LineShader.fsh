//
//  LineShader.fsh
//  Codea
//
//  Created by Dylan Sale on 24/09/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//
varying highp vec2 vTexCoord;

uniform lowp vec4 StrokeColor;
uniform mediump vec2 Size;

void main()
{
    mediump vec2 nTexCoord = vec2( (vTexCoord.x + 1.0)*Size.x, (vTexCoord.y + 1.0)*Size.y ) * 0.5;
    
    highp float closestDist =  min(min(nTexCoord.x, Size.x - nTexCoord.x), min( nTexCoord.y, Size.y - nTexCoord.y ));
    
    mediump float aa_amount = max( min( Size.y - 0.5, 0.5 ), 0.0 );
    
    //Regular blend
    //gl_FragColor = mix( vec4(StrokeColor.rgb,0), StrokeColor, smoothstep(0.0, 2.5, closestDist) );     
    
    //Premult
    gl_FragColor = mix( vec4(0,0,0,0), StrokeColor, smoothstep(0.0, aa_amount, closestDist) );
}

