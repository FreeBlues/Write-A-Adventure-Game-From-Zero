//
//  Shader.fsh
//  Codea
//
//  Created by Simeon Saint-Saëns on 17/05/11.
//  Copyright 2011 Two Lives Left. All rights reserved.
//

varying highp vec2 vTexCoord;

uniform lowp vec4 FillColor;
uniform lowp vec4 StrokeColor;

uniform highp vec2 Radius;
uniform highp float StrokeWidth;

void main()
{
    //WORKING BETTER THAN OTHERS
    /*
    mediump vec2 aTexCoord = abs( vTexCoord );
    mediump float angle = atan( aTexCoord.y, aTexCoord.x );
    
    mediump float ryCosTheta = (Radius.y * cos(angle));
    mediump float rxSinTheta = (Radius.x * sin(angle));
    mediump float scaledRadius = (Radius.x * Radius.y) / sqrt( (ryCosTheta * ryCosTheta + rxSinTheta * rxSinTheta ) ); 
    
    mediump float length = length( aTexCoord );
    //mediump float scaledRadius = mix( Radius.x, Radius.y, angle / (3.14159265 * 0.5) );
    mediump float pixelLength = length * scaledRadius;    

    gl_FragColor = mix( mix( FillColor, StrokeColor, step(scaledRadius - StrokeWidth, pixelLength) ),
                        vec4(0,0,0,0), step(scaledRadius, pixelLength) );    
    */
    
    //USING SUBTRACTION
    highp vec2 RadiusAA = vec2(Radius.x - 4.0, Radius.y - 4.0);
    
    highp vec2 scaledPointSq = vec2( (vTexCoord.x * Radius.x) * (vTexCoord.x * Radius.x), (vTexCoord.y * Radius.y) * (vTexCoord.y * Radius.y) );
    
    highp float c = (scaledPointSq.x / (Radius.x*Radius.x)) + (scaledPointSq.y / (Radius.y*Radius.y));
    highp float cAA = (scaledPointSq.x / (RadiusAA.x*RadiusAA.x)) + (scaledPointSq.y / (RadiusAA.y*RadiusAA.y));        
    
    highp vec2 innerRadius = vec2( Radius.x - StrokeWidth * 2.0, Radius.y - StrokeWidth * 2.0 );
    highp vec2 innerRadiusAA = vec2( Radius.x - StrokeWidth * 2.0 - 4.0, Radius.y - StrokeWidth * 2.0 - 4.0 );    
    highp float cInner = (scaledPointSq.x / (innerRadius.x*innerRadius.x)) + (scaledPointSq.y / (innerRadius.y*innerRadius.y));    
    highp float cInnerAA = (scaledPointSq.x / (innerRadiusAA.x*innerRadiusAA.x)) + (scaledPointSq.y / (innerRadiusAA.y*innerRadiusAA.y));        

    //Regular
    //lowp vec4 fragCol = mix( FillColor, StrokeColor, smoothstep( cInner / cInnerAA, 1.0, cInner ) );    
    
    //Premult
    lowp vec4 fragCol = mix( FillColor, StrokeColor, smoothstep( cInner / cInnerAA, 1.0, cInner ) );

    //Regular alpha
    //gl_FragColor = mix( fragCol, vec4(fragCol.rgb,0), smoothstep( c / cAA, 1.0, c ) );
    
    //Premult
    gl_FragColor = mix( fragCol, vec4(0,0,0,0), smoothstep( c / cAA, 1.0, c ) );    
}

