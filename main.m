/*
 *
 *	Copyright (C) 2012 Filippo Bigarella <filippo@filippobiga.com>
 *
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Inspired by Laurin Brandner's LBYouTubeView: https://github.com/larcus94/LBYouTubeView

#import <Foundation/Foundation.h>

// Use iPad User-Agent: makes it easier to extract the source and we get up to 720p
static NSString * const kUserAgent = @"Mozilla/5.0 (iPad; CPU OS 5_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B176 Safari/7534.48.3";
static NSString * const kJSONStartMark = @"\")]}'";
static NSString * const kJSONEndMark = @"\");";

NSString *unescapeUnicodeString(NSString *string);

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        printf("Usage: %s youtube-url\n", argv[0]);
        return 1;
    }
    
    @autoreleasepool
    {
        NSURL *youtubeURL = nil;
        NSMutableURLRequest *request = nil;
        NSError *error = nil;
        NSData *buffer = nil;
        NSString *html = nil;
        
        NSUInteger startLoc = 0;
        NSUInteger endLoc = 0;
        NSRange jsonRange;
        NSString *jsonString = nil;
        NSDictionary *parsedJSON = nil;
        NSArray *stream_map = nil;
        
        NSString *videoURLString = nil;
        
        
        youtubeURL = [NSURL URLWithString:[NSString stringWithUTF8String:argv[1]]];
        
        request = [NSMutableURLRequest requestWithURL:youtubeURL];
        [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
        
        buffer = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
        
        if (![buffer length])
        {
            NSLog(@"Error receiving data!");
            
            if (error)
            {
                NSLog(@"%@", error);
            }
            
            return -1;
        }
        
        
        html = [[[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding] autorelease];
        if (![html length])
        {
            NSLog(@"Couldn't encode data! (%@)", buffer);
            
            return -2;
        }
        
        
        startLoc = [html rangeOfString:kJSONStartMark].location;
        endLoc = [html rangeOfString:kJSONEndMark].location;
        if (startLoc == NSNotFound || endLoc == NSNotFound)
        {
            NSLog(@"Couldn't find JSON data! (%d, %d)", (int)startLoc, (int)endLoc);
            
            return -3;
        }
        
        
        startLoc += [kJSONStartMark length];
        jsonRange = NSMakeRange(startLoc, (endLoc - startLoc));
        
        jsonString = unescapeUnicodeString([html substringWithRange:jsonRange]);
        
        if (!jsonString)
        {
            NSLog(@"Couldn't unescape string!");
            
            return -4;
        }
        
        
        parsedJSON = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                     options:NSJSONReadingAllowFragments
                                                       error:&error];
        
        if (!parsedJSON)
        {
            NSLog(@"Error serializing JSON!");
            if (error)
            {
                NSLog(@"%@", error);
            }
            
            return -5;
        }
        
        
        stream_map = [[[parsedJSON objectForKey:@"content"] objectForKey:@"video"] objectForKey:@"fmt_stream_map"];
        videoURLString = [[stream_map objectAtIndex:0] objectForKey:@"url"];
        
        printf("%s\n", [videoURLString UTF8String]);
    }
    
    return 0;
}

NSString *unescapeUnicodeString(NSString *string)
{
    NSString *escaped = [string stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\\\\\"" withString:@"\\\""];
    
    NSString *quoted = [NSString stringWithFormat:@"\"%@\"", escaped];
    
    NSString *unescaped = [NSPropertyListSerialization propertyListFromData:[quoted dataUsingEncoding:NSUTF8StringEncoding]
                                                           mutabilityOption:NSPropertyListImmutable
                                                                     format:NULL
                                                           errorDescription:NULL];
    
    if (![unescaped isKindOfClass:[NSString class]])
    {
        return nil;
    }
    
    return [unescaped stringByReplacingOccurrencesOfString:@"\\U" withString:@"\\u"];
}
