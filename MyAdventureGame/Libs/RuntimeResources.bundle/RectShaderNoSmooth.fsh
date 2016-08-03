//
//  RectShaderNoSmooth.fsh
//  Codea
//
//  Created by Simeon Saint-Saëns on 17/05/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

varying highp vec2 vTexCoord;

uniform lowp vec4 FillColor;
uniform lowp vec4 StrokeColor;

uniform mediump vec2 Size;
uniform mediump float StrokeWidth;

void main()
{
    mediump vec2 nTexCoord = vec2( vTexCoord.x + 1.0, vTexCoord.y + 1.0 ) * 0.5;
    mediump vec2 xyInset = vec2( nTexCoord.x * Size.x, nTexCoord.y * Size.y );
    mediump float closestDist = min( min( xyInset.x, Size.x - xyInset.x ), min( xyInset.y, Size.y - xyInset.y ) );
    
    //Premult
    gl_FragColor = mix( StrokeColor, FillColor, step(StrokeWidth, closestDist) );
}

