//
//  FillColorTransform.vsh
//
//  Created by John Millard on 6/01/12.
//  Copyright 2012 Two Lives Left. All rights reserved.
//

uniform mat4 modelViewProjection;

attribute vec4 position;

void main()
{
    gl_Position = modelViewProjection * position;
}
