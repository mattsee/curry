//
//  NSURLSession+TKProgressDataTask.m
//  Created by Devin Ross on 5/2/17.
//
/*
 
 curry || https://github.com/devinross/curry
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */


#import "NSURLSession+TKProgressDataTask.h"


@interface TKProgressDataTask ()

- (instancetype) initWithDataTaskWithURL:(NSURL*)url progressHandler:(void (^)(double loadedDataSize, double expectedDataSize))progressHandler completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

@property (nonatomic,strong) NSURLSessionDataTask *task;
@property (nonatomic,strong) NSURLSession *session;
@property (nonatomic,strong) NSMutableData *data;


@end


@implementation NSURLSession (TKProgressDataTask)

+ (TKProgressDataTask* _Nonnull) progressDataTaskWithURL:(NSURL* _Nonnull)url
										 progressHandler:(void (^ __nullable)(double loadedDataSize, double expectedDataSize))progressHandler
									   completionHandler:(void (^ __nullable)(NSData * _Nullable data, NSURLResponse  * _Nullable response, NSError * _Nullable error))completionHandler{
	
	TKProgressDataTask *task = [TKProgressDataTask progressDataTaskWithURL:url progressHandler:progressHandler completionHandler:completionHandler];
	return task;
}

@end

@implementation TKProgressDataTask


+ (instancetype _Nonnull) progressDataTaskWithURL:(NSURL* _Nonnull)url
								  progressHandler:(void (^ __nullable)(double loadedDataSize, double expectedDataSize))progressHandler
								completionHandler:(void (^ __nullable)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError  * _Nullable error))completionHandler{
	TKProgressDataTask *task = [[TKProgressDataTask alloc] initWithDataTaskWithURL:url progressHandler:progressHandler completionHandler:completionHandler];
	return task;
}


- (instancetype) initWithDataTaskWithURL:(NSURL*)url progressHandler:(void (^)(double loadedDataSize, double expectedDataSize))progressHandler completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler{
	if(!(self=[super init])) return nil;
	
	self.data = [[NSMutableData alloc] init];

	self.progressHandler = progressHandler;
	self.completionHandler = completionHandler;
	
	NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession *gifSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];
	self.session = gifSession;
	self.task = [gifSession dataTaskWithURL:url];
	
	return self;
}


#pragma mark GIF Loading
- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
	dispatch_async(dispatch_get_main_queue(), ^{
		if(self.progressHandler)
			self.progressHandler((double)totalBytesSent, (double)totalBytesExpectedToSend);
	});
}
- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
	completionHandler(NSURLSessionResponseAllow);
	self.expectedData = response.expectedContentLength;
	dispatch_async(dispatch_get_main_queue(), ^{
		self.progressHandler(0, (double)self.expectedData);
	});
}
- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
	[self.data appendData:data];
	dispatch_async(dispatch_get_main_queue(), ^{
		self.progressHandler(self.data.length, (double)self.expectedData);
	});
}
- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
	dispatch_async(dispatch_get_main_queue(), ^{
		if(self.completionHandler)
			self.completionHandler(self.data, task.response, error);
	});
}


- (void) resume{
	[self.task resume];
}
- (void) suspend{
	[self.task suspend];
}
- (void) cancel{
	[self.task cancel];
	self.data = nil;
}


@end
