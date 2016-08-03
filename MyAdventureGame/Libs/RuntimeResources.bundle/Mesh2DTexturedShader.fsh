//
//  Mesh2DTexturedShader
//  Codea
//
//  Created by John Millard on 7/01/12.
//  Copyright 2012 Two Lives Left. All rights reserved.
//

varying lowp vec4 vColor;
varying highp vec2 vTexCoord;

uniform lowp sampler2D texture;

void main()
{
    gl_FragColor = texture2D( texture, vTexCoord ) * vColor;
}
