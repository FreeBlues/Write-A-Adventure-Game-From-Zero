//
//  SpriteShader.fsh
//  Codea
//
//  Created by Simeon Saint-Saëns on 17/05/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

varying highp vec2 vTexCoord;
uniform lowp sampler2D texture;

void main()
{
    gl_FragColor = texture2D( texture, vTexCoord );
}
