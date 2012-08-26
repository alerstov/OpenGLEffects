//
//  OpenGLHelper.m
//  OpenGLTest1
//
//  Created by Lion User on 26.08.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OpenGLHelper.h"


typedef struct {
    float pos[3];
    float coord[2];
} Vertex;

static const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0}},
    {{1, 1, 0}, {1, 1}},
    {{-1, 1, 0}, {0, 1}},
    {{-1, -1, 0}, {0, 0}}
};

static const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};


@implementation OpenGLHelper
{
    EAGLContext* _context;
    
    GLuint _colorRenderBuffer;

    GLuint _inputTexture;
    GLuint _tempTexture;

    GLuint _positionSlot;
    GLuint _inputTextureCoordinate;
}
@synthesize delegate = _delegate;

+(id)sharedOpenGLHelper
{
    static OpenGLHelper* helper = nil;
    if (helper == nil){
        helper = [[OpenGLHelper alloc] init];
    }
    return helper;
}

-(id)init
{
    if (self = [super init])
    {
        [self setupContext];
        [self setupFrameBuffer];
        [self setupRenderBuffer];
        [self setupVBO];
        [self setupTextures];
    }
    return self;
}

- (void)dealloc
{
    [_context release];
    _context = nil;
    [super dealloc];
}


#pragma mark - setup

-(void)setupContext 
{   
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

-(void)setupFrameBuffer
{    
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);        
}

-(void)setupRenderBuffer
{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);        
}

-(void)renderbufferStorage:(id<EAGLDrawable>)eaglLayer
{
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer]; 
}

-(void)setupVBO
{
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}


#pragma mark - shaders

-(NSString*)loadShader:(NSString*)shaderName
{
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName 
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath 
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    return shaderString;
}

-(GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType 
{    
    GLuint shaderHandle = glCreateShader(shaderType);    
    const char * shaderStringUTF8 = [shaderString UTF8String];    
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;    
}

-(GLuint)compileShaders:(NSString*)vsString :(NSString*)fsString
{
    GLuint vs = [self compileShader:vsString withType:GL_VERTEX_SHADER];
    GLuint fs = [self compileShader:fsString withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vs);
    glAttachShader(programHandle, fs);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "position");
    _inputTextureCoordinate = glGetAttribLocation(programHandle, "inputTextureCoordinate");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_inputTextureCoordinate);

    return programHandle;
}

-(void)useShaderProgram:(GLuint)program
{
    glUseProgram(program);
}

-(GLuint)getShaderAttrib:(GLuint)program :(const char*)name
{
    GLuint slot = glGetAttribLocation(program, name);
    glEnableVertexAttribArray(slot);
    return slot;
}
                                      
-(GLuint)getShaderUniform:(GLuint)program :(const char*)name
{
    return glGetUniformLocation(program, name);    
}
       
-(void)setUniformInt:(GLuint)location :(GLint)value
{
    glUniform1i(location, value);    
}

-(void)setUniformFloat:(GLuint)location :(GLfloat)value
{
    glUniform1f(location, value);    
}

#pragma mark - textures

-(GLuint)setupTexture
{    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    return texName;    
}

-(void)setupTextures
{
    _inputTexture = [self setupTexture];
    _tempTexture = [self setupTexture];
}

-(void)fillInputTexture:(CGSize)size :(GLubyte*)data
{
    glBindTexture(GL_TEXTURE_2D, _tempTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size.width, size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);        
    glBindTexture(GL_TEXTURE_2D, _inputTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size.width, size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);    
}

-(void)readTempTexture:(CGSize)size :(GLubyte*)data
{
    glBindTexture(GL_TEXTURE_2D, _tempTexture);
    glReadPixels(0, 0, size.width, size.height, GL_RGBA, GL_UNSIGNED_BYTE, data);    
}

#pragma mark - render

-(void)renderToTempTexture:(CGSize)size
{
    glViewport(0, 0, size.width, size.height);
    glActiveTexture(GL_TEXTURE0); 
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _tempTexture, 0);    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,  sizeof(Vertex), 0);
    glVertexAttribPointer(_inputTextureCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));    
    
    glBindTexture(GL_TEXTURE_2D, _inputTexture);        
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);    
}


-(void)renderToScreen:(CGSize)size
{
    glViewport(0, 0, size.width, size.height);
    glActiveTexture(GL_TEXTURE0); 
    
    // first pass
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _tempTexture, 0);    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,  sizeof(Vertex), 0);
    glVertexAttribPointer(_inputTextureCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));    

    [self.delegate firstPass];
    
    glBindTexture(GL_TEXTURE_2D, _inputTexture);        
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
            
    // second pass
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);    
    
    [self.delegate secondPass];
 
    glBindTexture(GL_TEXTURE_2D, _tempTexture);        
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
        
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
