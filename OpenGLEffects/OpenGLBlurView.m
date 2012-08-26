//
//  OpenGLBlurView.m
//  OpenGLTest1
//
//  Created by Lion User on 26.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OpenGLBlurView.h"
#import "OpenGLHelper.h"

static NSString *const vertShader = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 const lowp int GAUSSIAN_SAMPLES = 9; 
 uniform highp float texelWidthOffset; 
 uniform highp float texelHeightOffset;
 uniform highp float blurSize;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];
 
 void main() {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
     
     // Calculate the positions for the blur
     int multiplier = 0;
     highp vec2 blurStep;
     highp vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset) * blurSize;
     
     for (lowp int i = 0; i < GAUSSIAN_SAMPLES; i++) {
         multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2));
         // Blur in x (horizontal)
         blurStep = float(multiplier) * singleStepOffset;
         blurCoordinates[i] = inputTextureCoordinate.xy + blurStep;
     }
 }
);

static NSString *const fragShader = SHADER_STRING
(
    precision lowp float;

    uniform sampler2D inputImageTexture;
    uniform highp float koef;

    const lowp int GAUSSIAN_SAMPLES = 9; 
    varying highp vec2 textureCoordinate;
    varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];

    void main() 
    {
        lowp vec4 sum = vec4(0.0);
        
        sum += texture2D(inputImageTexture, blurCoordinates[0]) * 0.05;
        sum += texture2D(inputImageTexture, blurCoordinates[1]) * 0.09;
        sum += texture2D(inputImageTexture, blurCoordinates[2]) * 0.12;
        sum += texture2D(inputImageTexture, blurCoordinates[3]) * 0.15;
        sum += texture2D(inputImageTexture, blurCoordinates[4]) * 0.18;
        sum += texture2D(inputImageTexture, blurCoordinates[5]) * 0.15;
        sum += texture2D(inputImageTexture, blurCoordinates[6]) * 0.12;
        sum += texture2D(inputImageTexture, blurCoordinates[7]) * 0.09;
        sum += texture2D(inputImageTexture, blurCoordinates[8]) * 0.05;
                
        if (blurCoordinates[0].x == blurCoordinates[1].x)
        {
            vec2 p = textureCoordinate - vec2(0.5, 0.5);
            p.y = p.y*2.0;
            float t = length(p);
            
            // cubic easy in out
            float d = 1.0;
            float c = koef;
            t /= d/2.0;
            
            float x2;
            if (t < 1.0) x2 = c/2.0*t*t*t; else {t-=2.0;x2 = c/2.0*(t*t*t+2.0);}
            
            sum *= (1.0 - x2);
        }
        
        gl_FragColor = sum;
    }
);

@interface OpenGLBlurView()<OpenGLHelperDelegate>
@end

@implementation OpenGLBlurView
{
    OpenGLHelper* glh;
    GLubyte* spriteData;
    CGSize _size;
    
    GLuint _program;

    GLuint _inputImageTexture;
    GLuint _texelWidthOffset;
    GLuint _texelHeightOffset;
    GLuint _blurSize;      
    GLuint _koef;   
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    return [self initWithFrame:self.frame];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        CAEAGLLayer* eaglLayer = (CAEAGLLayer*) self.layer;
        eaglLayer.opaque = YES;    
        
        glh = [OpenGLHelper sharedOpenGLHelper];   
        glh.delegate = self;
        [glh renderbufferStorage:eaglLayer];
        
        _program = [glh compileShaders:vertShader :fragShader];

        _texelWidthOffset = [glh getShaderUniform:_program :"texelWidthOffset"];
        _texelHeightOffset = [glh getShaderUniform:_program :"texelHeightOffset"];
        _blurSize = [glh getShaderUniform:_program :"blurSize"];
        _inputImageTexture = [glh getShaderUniform:_program :"inputImageTexture"];
        _koef = [glh getShaderUniform:_program :"koef"];
    }
    return self;
}

- (void)dealloc
{
    if (spriteData) free(spriteData);
    [super dealloc];
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

-(void)renderLayer:(CALayer*)layer
{
    CGSize size = layer.bounds.size;
    size_t width = size.width;
    size_t height = size.height;
    
    if (spriteData){
        if (width != _size.width || height != _size.height){
            free(spriteData);
            spriteData = NULL;
        }
    }
    
    if (!spriteData){
        spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
        _size = CGSizeMake(width, height);
    }
    
    [self getLayerData:layer :spriteData];
    [glh fillInputTexture:size :spriteData];
    [glh useShaderProgram:_program];
    
    [glh renderToScreen:size];
}

-(void)firstPass
{
    [glh setUniformInt:_inputImageTexture :0];
    [glh setUniformFloat:_texelWidthOffset :1.0/_size.width];
    [glh setUniformFloat:_texelHeightOffset :0.0];
    [glh setUniformFloat:_blurSize :2.0];
}

-(void)secondPass
{
    [glh setUniformFloat:_texelWidthOffset :0.0];
    [glh setUniformFloat:_texelHeightOffset :1.0/_size.height];
    [glh setUniformFloat:_blurSize :2.0];    
    [glh setUniformFloat:_koef :0.6];    
}

-(void)getLayerData:(CALayer*)layer :(GLubyte*)data
{
    size_t width = layer.bounds.size.width;
    size_t height = layer.bounds.size.height;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();    
    CGContextRef spriteContext = CGBitmapContextCreate(data, width, height, 8, width*4, 
                                                       colorSpaceRef, kCGImageAlphaPremultipliedLast);    
    
    [layer renderInContext:spriteContext];
    
    CGColorSpaceRelease(colorSpaceRef);
    CGContextRelease(spriteContext);
}

@end
