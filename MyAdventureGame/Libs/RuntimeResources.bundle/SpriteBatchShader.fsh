//
//  SpriteShader.fsh
//  Codea
//
//  Created by Simeon Saint-Saëns on 17/05/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

varying highp vec2 vTexCoord;
varying lowp vec4 vColor;

uniform lowp sampler2D texture;

void main()
{
    lowp vec4 sample = texture2D( texture, vTexCoord );
    gl_FragColor = vec4( sample.rgb * vColor.rgb, sample.a );
}
