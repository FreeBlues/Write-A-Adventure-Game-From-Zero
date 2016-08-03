//
//  RectShaderNoStroke.fsh
//  Codea
//
//  Created by Simeon Saint-Saëns on 17/05/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

varying highp vec2 vTexCoord;

uniform lowp vec4 FillColor;

uniform highp vec2 Size;

void main()
{
    highp vec2 nTexCoord = vec2( vTexCoord.x + 1.0, vTexCoord.y + 1.0 ) * 0.5;
    highp vec2 xyInset = vec2( nTexCoord.x * Size.x, nTexCoord.y * Size.y );
    highp float closestDist = min( min( xyInset.x, Size.x - xyInset.x ), min( xyInset.y, Size.y - xyInset.y ) );
    
    //Premult
    gl_FragColor = mix( vec4(0,0,0,0), FillColor, smoothstep(0.0, 1.0, closestDist) );
}

