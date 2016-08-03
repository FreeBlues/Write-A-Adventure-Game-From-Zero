//
//  MeshFillColorShader.fsh
//
//  Created by John Millard on 6/01/12.
//  Copyright 2012 Two Lives Left. All rights reserved.
//

uniform lowp vec4 FillColor;

void main()
{    
    gl_FragColor = FillColor;
}
