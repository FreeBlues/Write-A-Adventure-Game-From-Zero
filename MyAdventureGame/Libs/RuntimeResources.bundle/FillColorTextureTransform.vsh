//
//  FillColorTextureTransform.vsh
//
//  Created by John Millard on 7/01/12.
//  Copyright 2012 Two Lives Left. All rights reserved.
//

uniform mat4 modelViewProjection;
uniform bool SpriteMode;
uniform lowp vec4 FillColor;

attribute vec4 position;
attribute vec2 texCoord;

varying lowp vec4 vColor;
varying highp vec2 vTexCoord;

void main()
{
    gl_Position = modelViewProjection * position;

//    if (SpriteMode)
//    {             
//        vColor = FillColor;
//        vTexCoord = highp vec2(texCoord.s, 1.0-texCoord.t);        
//    }
//    else
//    {
        vColor = FillColor;
        vTexCoord = texCoord;    
//    }
}
