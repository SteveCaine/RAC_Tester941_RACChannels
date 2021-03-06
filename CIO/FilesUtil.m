//
//	FilesUtil.m
//	FilesUtil
//
//	Created by Steve Caine on 08/16/14.
//
//	This code is distributed under the terms of the MIT license.
//
//	Copyright (c) 2014-2017 Steve Caine.
//

#import "FilesUtil.h"

// --------------------------------------------------
static NSInteger sortFilesByThis(id lhs, id rhs, void *v);
// --------------------------------------------------
static NSString * const TYPE_json  = @"json";
static NSString * const TYPE_plist = @"plist";

// --------------------------------------------------

@interface FilesUtil ()
@end

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------

@implementation FilesUtil

+ (NSError *)errorWithDescription:(NSString *)description {
	return [self errorWithDescription:description domain:nil];
}

+ (NSError *)errorWithDescription:(NSString *)description domain:(NSString *)domain {
	NSError *result = nil;
	
	if (description.length) {
		if (domain.length == 0)
			domain = NSLocalizedString(@"FilesUtilErrorDomain",
									   @"error domain");
		result = [NSError errorWithDomain:domain
									 code:-1
								 userInfo:@{ NSLocalizedDescriptionKey : description }];
	}
	return result;
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------
// TODO: add better validation of paths, identifying file names vs dir names, etc.

+ (double)ageOfFile:(NSString *)filePath error:(NSError **)outError {
	double result = 0.0;
	NSError *error;
	NSDictionary *attribs = [NSFileManager.defaultManager attributesOfItemAtPath:filePath error:&error];
	if (attribs && !error) {
		NSDate *date = [attribs objectForKey:NSFileModificationDate];
		result = -date.timeIntervalSinceNow;
	}
	if (outError) *outError = error;
	return result;
}

+ (unsigned long long)sizeOfFile:(NSString *)filePath error:(NSError **)outError {
	unsigned long long result = 0;
	NSError *error;
	NSDictionary *attribs = [NSFileManager.defaultManager attributesOfItemAtPath:filePath error:&error];
	if (attribs && !error) {
		NSNumber *size = [attribs objectForKey:NSFileSize];
		result = size.unsignedLongLongValue;
	}
	if (outError) *outError = error;
	return result;
}


+ (BOOL)fileExists:(NSString *)path {
	if (path.length) {
		BOOL isDirectory;
		BOOL found = [NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory];
		return (found && !isDirectory);
	}
	return NO;
}

+ (BOOL)clearFile:(NSString *)path error:(NSError **)outError {
	BOOL result = NO;
	
	NSError *error = nil;
	if ([self fileExists:path]) {
		if ([NSFileManager.defaultManager removeItemAtPath:path error:&error])
			result = YES;
		else {
			MyLog(@"Failed to remove file '%@': %@", path, error.localizedDescription);
			result = NO;
		}
	}
	else {
		NSString *dir = [path stringByDeletingLastPathComponent];
		if ([self directoryExists:dir])
			result = YES;
	}
	if (outError) *outError = error;
	return result;
}

// --------------------------------------------------

+ (BOOL)directoryExists:(NSString *)path {
	if (path.length) {
		BOOL isDirectory;
		BOOL found = [NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory];
		return (found && isDirectory);
	}
	return NO;
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------
// these returns PATH if dir exists, else return -nil-

+ (NSString *)documentsDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return paths.firstObject;
}

+ (NSString *)cacheDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	return paths.firstObject;
}

+ (NSString *)cacheSubDirectory:(NSString *)name { // name of subfolder in cache dir
	NSString *result = nil;
	// TODO: check name is valid for a directory
	if (name.length) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString *dir = paths.firstObject;
		if (dir.length)
			result = [dir stringByAppendingPathComponent:name];
	}
	return result;
}

+ (NSString *)tempDirectory {
	return NSTemporaryDirectory();
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------
// DO overwrite existing files
+ (NSUInteger)copyBundleFilesOfType:(NSString *)type toDir:(NSString *)dirPath {
	return [self copyBundleFilesOfType:type toDir:dirPath overwriteExisting:YES];
}

// DON'T overwrite existing files
+ (NSUInteger)mergeBundleFilesOfType:(NSString *)type intoDir:(NSString *)dirPath {
	return [self copyBundleFilesOfType:type toDir:dirPath overwriteExisting:NO];
}

// LOCAL METHOD
+ (NSUInteger)copyBundleFilesOfType:(NSString *)type toDir:(NSString *)dirPath overwriteExisting:(BOOL)overwriteYesNo {
	NSUInteger result = 0;
	
	NSFileManager *defaultManager = NSFileManager.defaultManager;
	
	NSArray *filePaths = [self pathsForBundleFilesType:type sortedBy:0]; //bundleFiles
	for (NSString *srcPath in filePaths) {
		NSString *srcName = srcPath.lastPathComponent;
		NSString *dstPath = [dirPath stringByAppendingPathComponent:srcName];
//		MyLog(@"copy \n'%@'\n to \n'%@'", srcPath, dstPath);
		
		BOOL exists = [defaultManager fileExistsAtPath:dstPath];
		if (exists && overwriteYesNo == NO)
			continue;
		
		NSError *error = nil;
		if (exists) {
			[defaultManager removeItemAtPath:dstPath error:&error];
			if (error) {
				MyLog(@"Failed to delete existing file '%@': %@", srcName, error.localizedDescription);
			}
		}
		if (error == nil)
			[defaultManager copyItemAtPath:srcPath toPath:dstPath error:&error];
		if (error) {
			MyLog(@"Failed to copy file '%@': %@", srcName, error.localizedDescription);
		}
		else
			++result;
	}
	
	return result;
}

// --------------------------------------------------

+ (NSUInteger)countForFilesOfType:(NSString *)type inDir:(NSString *)dirPath filter:(BOOL(^)(NSString *))filter {
//	MyLog(@"%s '%@'", __FUNCTION__, dirPath);
	NSUInteger result = 0;
	
	if (type.length && dirPath.length) {
		BOOL isDir = NO;
		if ([NSFileManager.defaultManager fileExistsAtPath:dirPath isDirectory:&isDir] && isDir) {
			NSError *error = nil;
			NSArray* files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dirPath error:&error];
			
			if (files.count) {
				for (NSString *file in files) {
					if ([file.pathExtension isEqualToString:type] && (filter == nil || filter(file)))
						++result;
				}
			}
			else if (error)
				MyLog(@"Error counting files in '%@': %@", dirPath, error.localizedDescription);
		}
	}
	return result;
}

+ (NSUInteger)clearFilesOfType:(NSString *)type inDir:(NSString *)dirPath filter:(BOOL(^)(NSString *))filter {
	NSUInteger result = 0;
	
	if (type.length && dirPath.length) {
		BOOL isDir = NO;
		if ([NSFileManager.defaultManager fileExistsAtPath:dirPath isDirectory:&isDir] && isDir) {
			NSError *error = nil;
			NSArray* files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dirPath error:&error];
			
			if (files.count) {
				for (NSString *file in files) {
					NSString *path = [NSString pathWithComponents:@[dirPath, file]];
					if ([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
						if ([file.pathExtension isEqualToString:type] && (filter == nil || filter(file))) {
							if ([NSFileManager.defaultManager removeItemAtPath:path error:&error])
								++result;
						}
					}
				}
			}
			else if (error)
				MyLog(@"Error clearing files in '%@': %@", dirPath, error.localizedDescription);
		}
	}
	return result;
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------
// TODO: check 'type' is valid for a filename extension
+ (NSArray *)pathsForFilesType:(NSString *)type inDir:(NSString *)dirPath sortedBy:(FilesUtil_SortFilesBy)sortedBy {
	NSMutableArray * result = nil;
	
	if (type.length && dirPath.length) {
		BOOL isDir = NO;
		if ([NSFileManager.defaultManager fileExistsAtPath:dirPath isDirectory:&isDir] && isDir) {
			NSError *error = nil;
			NSArray* files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dirPath error:&error];
			if (error != nil) {
				MyLog(@"Error counting files: %@", error.localizedDescription);
			}
			else {
//				int index = 0;
				for (NSString *file in files) {
//					MyLog(@"%2i: '%@'", index++, file);
					NSString *path = [NSString pathWithComponents:@[dirPath, file]];
					if ([path.pathExtension isEqualToString:type]) {
						if (result == nil)
							result = [NSMutableArray arrayWithCapacity:1];
						[result addObject:path];
					}
				}
				//MyLog(@"%s result == %@", __FUNCTION__, [FilesUtil namesFromPaths:result stripExtensions:NO]);
				if (result.count > 1 && sortedBy != SortFiles_NO) {
					NSArray *sorted = [result sortedArrayUsingFunction:sortFilesByThis context:&sortedBy];
					result = [NSMutableArray arrayWithArray:sorted];
					//MyLog(@" result => %@", [FilesUtil namesFromPaths:result stripExtensions:NO]);
				}
			}
		}
	}
	return result;
}

// --------------------------------------------------

+ (NSArray *)pathsForBundleFilesType:(NSString *)type sortedBy:(FilesUtil_SortFilesBy)sortedBy {
	NSArray *result = nil;
	
	if (type.length) {
		result = [NSBundle.mainBundle pathsForResourcesOfType:type inDirectory:nil];
		//MyLog(@"%s result == %@", __FUNCTION__, [FilesUtil namesFromPaths:result stripExtensions:NO]);
		if (result.count > 1) {
			result = [result sortedArrayUsingFunction:sortFilesByThis context:&sortedBy];
			//MyLog(@" result => %@", [FilesUtil namesFromPaths:result stripExtensions:NO]);
		}
	}
	return result;
}

// --------------------------------------------------

+ (NSArray *)namesFromPaths:(NSArray *)paths stripExtensions:(BOOL)stripYesNo {
	NSMutableArray * result = nil;
	if (paths.count) {
		// TODO: check that each is a valid file path?
		for (NSString *path in paths) {
			NSString *name = path.lastPathComponent;
			if (stripYesNo)
				name = [name stringByDeletingPathExtension];
			if (result == nil)
				result = [NSMutableArray arrayWithCapacity:1];
			[result addObject:name];
		}
	}
	return result;
}

// --------------------------------------------------
// TODO: check that dirPath is valid?

+ (NSArray *)pathsForNames:(NSArray *)names inDir:(NSString *)dirPath {
	NSMutableArray *result = @[].mutableCopy;
	if (names.count && dirPath.length) {
		for (NSString *name in names) {
			NSString *path = [dirPath stringByAppendingPathComponent:name];
			// TODO: check that files exist?
			[result addObject:path];
		}
	}
	return (result.count ? result.copy : nil);
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------

+ (NSArray *)arrayFromBundle_plist:(NSString *)name error:(NSError **)outError {
	NSArray *result = nil;
	
	NSError *error = nil;
	if (name.length) {
		NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:TYPE_plist];
		if (path.length)
			result = [NSArray arrayWithContentsOfFile:path]; // nil if it's not an array
		else error = [self errorWithDescription:NSLocalizedString(@"Failed to read file.", @"error message")];
	}
	else error = [self errorWithDescription:NSLocalizedString(@"Empty file name.", @"error message")];
	if (outError) *outError = error;
	
	return result;
}

+ (NSDictionary *)dictionaryFromBundle_plist:(NSString *)name error:(NSError **)outError {
	NSDictionary *result = nil;
	
	NSError *error = nil;
	if (name.length) {
		NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:TYPE_plist];
		if (path.length)
			result = [NSDictionary dictionaryWithContentsOfFile:path]; // nil if it's not a dictionary
		else error = [self errorWithDescription:NSLocalizedString(@"Failed to read file.", @"error message")];
	}
	else error = [self errorWithDescription:NSLocalizedString(@"Empty file name.", @"error message")];
	if (outError) *outError = error;
	
	return result;
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------

+ (NSArray *)arrayFromBundle_json:(NSString *)name error:(NSError **)outError {
	id obj = [self.class objFromBundle_json:name error:outError];
	if ([obj isKindOfClass:NSArray.class])
		return obj;
	else if (obj)
		NSCAssert(NO, @"Not an array: %@", NSStringFromClass([obj class]));
	// else error explains nil obj to caller
	return nil;
}

+ (NSDictionary *)dictionaryFromBundle_json:(NSString *)name error:(NSError **)outError {
	id obj = [self.class objFromBundle_json:name error:outError];
	if ([obj isKindOfClass:NSDictionary.class])
		return obj;
	else if (obj)
		NSCAssert(NO, @"Not a dictionary: %@", NSStringFromClass([obj class]));
	// else error explains nil obj to caller
	return nil;
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------

+ (NSArray *)arrayFromFilePath_json:(NSString *)path error:(NSError **)outError {
	id obj = [self.class objectFromFilePath_json:path error:outError];
	if ([obj isKindOfClass:NSArray.class])
		return obj;
	return nil;
}

+ (NSDictionary *)dictionaryFromFilePath_json:(NSString *)path error:(NSError **)outError {
	id obj = [self.class objectFromFilePath_json:path error:outError];
	if ([obj isKindOfClass:NSDictionary.class])
		return obj;
	return nil;
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------

+ (NSArray *)arrayFromFileURL_json:(NSURL *)fileURL error:(NSError **)outError {
	id obj = [self.class objectFromFileURL_json:fileURL error:outError];
	if ([obj isKindOfClass:NSArray.class])
		return obj;
	return nil;
}
+ (NSDictionary *)dictionaryFromFileURL_json:(NSURL *)fileURL error:(NSError **)outError {
	id obj = [self.class objectFromFileURL_json:fileURL error:outError];
	if ([obj isKindOfClass:NSDictionary.class])
		return obj;
	return nil;
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------

+ (id)objFromBundle_json:(NSString *)name error:(NSError **)outError {
	id obj = nil;
	
	NSError *error = nil;
	if (name.length) {
		NSString *path = [NSBundle.mainBundle pathForResource:name ofType:TYPE_json];
		obj = [self objectFromFilePath_json:path error:&error];
	}
	else error = [self errorWithDescription:NSLocalizedString(@"No resource name provided.", @"error message")];
	if (outError) *outError = error;
	return obj;
}

+ (id)objectFromFilePath_json:(NSString *)path error:(NSError **)outError {
	id obj = nil;
	
	NSError *error = nil;
	if (path.length) {
		NSURL *fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
		if (fileURL == nil)
			MyLog(@" nil URL for file '%@'", fileURL.path.lastPathComponent);
		obj = [self objectFromFileURL_json:fileURL error:&error];
	}
	else error = [self errorWithDescription:NSLocalizedString(@"Empty file path.", @"error message")];
	if (outError) *outError = error;
	return obj;
}

+ (id)objectFromFileURL_json:(NSURL *)fileURL error:(NSError **)outError {
	id obj = nil;
	
	NSError *error = nil;
	if (fileURL) {
		NSData *data = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
		if (data.length) {
			@try {
				obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
			} @catch (NSException *exception) {
				if (error == nil) error = [self errorWithDescription:exception.reason];
			}
		}
		else if (error == nil)
			error = [self errorWithDescription:NSLocalizedString(@"Failed to read file.", @"error message")];
	}
	else error = [self errorWithDescription:NSLocalizedString(@"No file link provided.", @"error message")];
	if (outError) *outError = error;
	return obj;
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------

+ (BOOL)writeJson:(id)obj toFile:(NSString *)fileName inDir:(NSString *)dirPath error:(NSError **)outError {
	BOOL result = NO;
	
	NSError *error = nil;
	if (fileName.length && dirPath.length && obj != nil) {
		if ([NSJSONSerialization isValidJSONObject:obj]) {
			NSJSONWritingOptions options = 0;
#if DEBUG
			options = NSJSONWritingPrettyPrinted;
#endif
			NSData *json = [NSJSONSerialization dataWithJSONObject:obj options:options error:&error];
			if (json.length) {
				NSString *path = [dirPath stringByAppendingPathComponent:fileName];
				path = [path stringByAppendingPathExtension:TYPE_json];
				result = [json writeToFile:path options:0 error:&error];
//				NSLog(@"wrote JSON = %s", result ? "YES" : "NO");
			}
		}
		else error = [self errorWithDescription:NSLocalizedString(@"data object not valid for export to JSON.", @"error message")];
	}
	else error = [self errorWithDescription:NSLocalizedString(@"No file/dir/object provided.", @"error message")];
	if (outError) *outError = error;
	
	return result;
}
+ (BOOL)writeJson:(id)obj toDocFile:(NSString *)fileName error:(NSError **)outError {
	return [self writeJson:obj toFile:fileName inDir:self.documentsDirectory error:outError];
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------

+ (BOOL)writePlist:(id)obj toFile:(NSString *)fileName inDir:(NSString *)dirPath error:(NSError **)outError {
	BOOL result = NO;
	
	NSError *error = nil;
	
	if (fileName.length && dirPath.length && obj != nil) {
		if ([self directoryExists:dirPath]) {
			NSString *path = [dirPath stringByAppendingPathComponent:fileName];
			path = [path stringByAppendingPathExtension:TYPE_plist];
			
			// unnecessary? - writeToFile: apparently always overwrites existing files (iff file permissions allow)
			if ([self clearFile:path error:&error]) {
				if ([obj isKindOfClass:NSDictionary.class])
					result = [((NSDictionary *)obj) writeToFile:path atomically:YES];
				else if ([obj isKindOfClass:NSArray.class])
					result = [((NSArray *)obj) writeToFile:path atomically:YES];
				else
					error = [self errorWithDescription:NSLocalizedString(@"This code can only write dictionaries and arrays to files.", @"error message")];
			}
			else
				error = [self errorWithDescription:NSLocalizedString(@"Invalid file path.", @"error message")];
		}
		else
			error = [self errorWithDescription:NSLocalizedString(@"Invalid directory path.", @"error message")];
	}
	else error = [self errorWithDescription:NSLocalizedString(@"No data object provided.", @"error message")];
	if (outError) *outError = error;
	
	return result;
}
+ (BOOL)writePlist:(id)obj toDocFile:(NSString *)fileName error:(NSError **)outError {
	return [self writePlist:obj toFile:fileName inDir:self.documentsDirectory error:outError];
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------
// write -data- to (overwriting) new file and return its path

+ (NSString *)writeData:(NSData *)data toFile:(NSString *)name inFolder:(NSString *)path {
	NSString *result = nil;
	
	if (data.length && name.length && path.length) {
		NSString *dst_path = [path stringByAppendingPathComponent:name];
		BOOL exists = [NSFileManager.defaultManager fileExistsAtPath:dst_path];
		NSError *error = nil;
		if (exists) {
			(void) [NSFileManager.defaultManager removeItemAtPath:dst_path error:&error];
		}
		if (error)
			NSLog(@"Error clearing older file '%@': %@", name, error);
		
		else {
			BOOL wrote = [NSFileManager.defaultManager createFileAtPath:dst_path contents:data attributes:nil];
			if (!wrote)
				NSLog(@"Failed to write file '%@'", name);
			else
				result = dst_path;
		}
	}
	return result;
}

+ (NSString *)writeData:(NSData *)data toDocFile:(NSString *)name {
	NSString *docsDir = [self documentsDirectory];
	return [FilesUtil writeData:data toFile:name inFolder:docsDir];
}

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------
// write -str- to (overwriting) new file and return its path
+ (NSString *)writeString:(NSString *)str toFile:(NSString *)name inFolder:(NSString *)path {
	NSString *result = nil;
	if (str.length && name.length && path.length) {
		NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
		result = [self writeData:data toFile:name inFolder:path];
	}
	return result;
}

+ (NSString *)writeString:(NSString *)str toDocFile:(NSString *)name {
	NSString *docsDir = [self documentsDirectory];
	return [FilesUtil writeString:str toFile:name inFolder:docsDir];
}

+ (NSString *)writeString:(NSString *)str toDocFile:(NSString *)name withDate:(NSDate *)date {
	if (date) {
		NSString *prefix = [self.date2name_Formatter stringFromDate:date];
		NSString *date_name = [NSString stringWithFormat:@"%@ %@", prefix, name];
		return [self writeString:str toDocFile:date_name];
	}
	return nil;
}

/* TK
+ (NSString *)appendString:(NSString *)str toFile:(NSString *)name inFolder:(NSString *)path {
	return nil;
}

+ (NSString *)appendString:(NSString *)str toDocFile:(NSString *)name {
	return nil;
}
*/

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------

+ (NSDateFormatter *)date2name_Formatter {
	static NSDateFormatter *formatter;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		formatter = [[NSDateFormatter alloc] init];
		// ex. "31 Jan 21.09.35 <name>"
		formatter.dateFormat = @"dd MMM HH.mm.ss"; // no colons in file names
	});
	
	return formatter;
}

@end

// --------------------------------------------------
#pragma mark -
// --------------------------------------------------

static NSInteger sortFilesByThis(id lhs, id rhs, void *v) {
	
	FilesUtil_SortFilesBy sortFilesBy = SortFiles_alphabeticalAscending; // default
	if (v)
		sortFilesBy = *(FilesUtil_SortFilesBy *)v;
	
	NSString *lhsPath = (NSString *)lhs;
	NSString *rhsPath = (NSString *)rhs;
	
	NSError *lhsError = nil;
	NSError *rhsError = nil;
	
	if (sortFilesBy == SortFiles_alphabeticalAscending ||
		sortFilesBy == SortFiles_alphabeticalDescending) {
		
		NSString *lhsName = lhsPath.lastPathComponent;
		NSString *rhsName = rhsPath.lastPathComponent;
		NSInteger result = [lhsName caseInsensitiveCompare:rhsName];
		
		if (sortFilesBy == SortFiles_alphabeticalAscending)
			return result;
		else if (sortFilesBy == SortFiles_alphabeticalDescending)
			return -result;
	}
	
	else if (sortFilesBy == SortFiles_newestFirst ||
			 sortFilesBy == SortFiles_oldestFirst) {
		// TODO: handle errors
		double lhsAge = [FilesUtil ageOfFile:lhsPath error:&lhsError];
		double rhsAge = [FilesUtil ageOfFile:rhsPath error:&rhsError];
		
		if (lhsAge < rhsAge)
			return (sortFilesBy == SortFiles_newestFirst) ? -1 : +1;
		else
			if (rhsAge < lhsAge)
				return (sortFilesBy == SortFiles_newestFirst) ? +1 : -1;
	}
	else if (sortFilesBy == SortFiles_largestFirst ||
			 sortFilesBy == SortFiles_smallestFirst) {
		// TODO: handle errors
		unsigned long long lhsSize = [FilesUtil sizeOfFile:lhsPath error:&lhsError];
		unsigned long long rhsSize = [FilesUtil sizeOfFile:rhsPath error:&rhsError];
		
		if (lhsSize < rhsSize)
			return (sortFilesBy == SortFiles_smallestFirst) ? -1 : +1;
		else
			if (rhsSize < lhsSize)
				return (sortFilesBy == SortFiles_smallestFirst) ? +1 : -1;
	}
	
	return 0;
}

// --------------------------------------------------
