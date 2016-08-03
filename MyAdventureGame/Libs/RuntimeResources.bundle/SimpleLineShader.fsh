//
//  LineShader.fsh
//  Codea
//
//  Created by Dylan Sale on 24/09/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

uniform lowp vec4 StrokeColor;

void main()
{
    gl_FragColor = StrokeColor;
}

