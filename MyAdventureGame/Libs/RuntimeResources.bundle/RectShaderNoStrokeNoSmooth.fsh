//
//  RectShaderNoStrokeNoSmooth.fsh
//  Codea
//
//  Created by Simeon Saint-Saëns on 17/05/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

varying highp vec2 vTexCoord;

uniform lowp vec4 FillColor;

void main()
{
    gl_FragColor = FillColor;
}

