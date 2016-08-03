//
//  ColorTextureTransform.vsh
//
//  Created by John Millard on 7/01/12.
//  Copyright 2012 Two Lives Left. All rights reserved.
//

uniform mat4 modelViewProjection;
//uniform bool SpriteMode;

attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

varying lowp vec4 vColor;
varying highp vec2 vTexCoord;

void main()
{
    gl_Position = modelViewProjection * position;
    
//    if (SpriteMode)
//    {
//        vColor.rgb = color.rgb * color.a;
//        vColor.a = color.a;        
//        vTexCoord = highp vec2(texCoord.s, 1.0-texCoord.t);
//    }
//    else
//    {
        vColor.rgb = color.rgb * color.a;
        vColor.a = color.a;
        vTexCoord = texCoord;
//    }
}
