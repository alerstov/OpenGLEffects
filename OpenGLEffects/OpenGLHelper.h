//
//  OpenGLHelper.h
//  OpenGLTest1
//
//  Created by Lion User on 26.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>


#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)


@protocol OpenGLHelperDelegate <NSObject>
@optional
-(void)firstPass;
-(void)secondPass;
@end


@interface OpenGLHelper : NSObject

@property (nonatomic, assign) id<OpenGLHelperDelegate> delegate;

+(id)sharedOpenGLHelper;

-(void)renderbufferStorage:(id<EAGLDrawable>)eaglLayer;

-(GLuint)compileShaders:(NSString*)vsString :(NSString*)fsString;
-(GLuint)getShaderUniform:(GLuint)program :(const char*)name;
-(void)useShaderProgram:(GLuint)program;
-(void)setUniformInt:(GLuint)location :(GLint)value;
-(void)setUniformFloat:(GLuint)location :(GLfloat)value;

-(void)fillInputTexture:(CGSize)size :(GLubyte*)data;
-(void)readTempTexture:(CGSize)size :(GLubyte*)data;

-(void)renderToTempTexture:(CGSize)size;
-(void)renderToScreen:(CGSize)size;

@end
