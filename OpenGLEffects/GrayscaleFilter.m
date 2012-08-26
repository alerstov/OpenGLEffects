//
//  GrayscaleFilter.m
//  OpenGLTest1
//
//  Created by Lion User on 26.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GrayscaleFilter.h"
#import "OpenGLHelper.h"

static NSString *const vertShader = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate; 
    varying highp vec2 textureCoordinate;
    void main() 
    {
        gl_Position = position;
        textureCoordinate = inputTextureCoordinate.xy;
    }
);

static NSString *const fragShader = SHADER_STRING
(
    precision highp float; 
    varying vec2 textureCoordinate; 
    uniform sampler2D inputImageTexture;
    const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);
    void main()
    {
        float luminance = dot(texture2D(inputImageTexture, textureCoordinate).rgb, W);     
        //gl_FragColor = vec4(vec3(luminance), texture2D(inputImageTexture, textureCoordinate).a);
        gl_FragColor = vec4(vec3(luminance), 1.0);
    }
);


@implementation GrayscaleFilter
{
    OpenGLHelper* glh;
    GLubyte* spriteData;
    size_t _width;
    size_t _heigth;
    
    GLuint program;
}

-(void)dealloc
{
    if (spriteData) free(spriteData);
    [glh release];
    [super dealloc];
}

-(id)init
{    
    if (self = [super init]){
        glh = [OpenGLHelper sharedOpenGLHelper];  
        program = [glh compileShaders:vertShader :fragShader];
    }
    return self;
}

-(UIImage*)filter:(UIImage*)image
{
    size_t width = image.size.width;
    size_t height = image.size.height;

    if (spriteData){
        if (width != _width || height != _heigth){
            free(spriteData);
            spriteData = NULL;
        }
    }
    
    if (!spriteData){
        spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
        _width = width;
        _heigth = height;
    }
        
    [self fillImageData:image];    
    [glh fillInputTexture:CGSizeMake(_width, _heigth) :spriteData];    
    [glh useShaderProgram:program];    
    [glh renderToTempTexture:CGSizeMake(_width, _heigth)];

    return [self imageFromTempTexture];
}

-(void)fillImageData:(UIImage*)image
{
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();   
    //CGColorSpaceRef cs = CGImageGetColorSpace(image.CGImage);
    
	CGContextRef contextRef = CGBitmapContextCreate(spriteData, _width, _heigth, 8, _width*4, cs, 
                                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, _width, _heigth), image.CGImage);  
    CGContextRelease(contextRef);
    CGColorSpaceRelease(cs);
}

void dataProviderReleaseCallback(void *info, const void *data, size_t size)
{
    free((void *)data);
}

-(UIImage*)imageFromTempTexture
{
    size_t width = _width;
    size_t height = _heigth;    
    size_t totalBytes = width*height*4;
    
    GLubyte* rawImagePixels = (GLubyte *)malloc(totalBytes);  
    
    [glh readTempTexture:CGSizeMake(_width, _heigth) :rawImagePixels];
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels, totalBytes,
                                                                  dataProviderReleaseCallback);
    
    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImageFromBytes = CGImageCreate(width, height, 8, 32, 
                                                4*width, defaultRGBColorSpace,
                                                kCGBitmapByteOrderDefault | kCGImageAlphaLast,
                                                dataProvider, NULL, NO, kCGRenderingIntentDefault);
    
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);
    
    return [UIImage imageWithCGImage:cgImageFromBytes];
}

@end
