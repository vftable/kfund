//
//  bootstrap.m
//  kfd
//
//  Created by user on 11/09/2023.
//

#include "bootstrap.h"
#include "vnode.h"
#include "fun.h"
#include "IOKit.h"
#include "untar.h"
#include <Foundation/Foundation.h>

char* getBootManifestHash() {
    io_registry_entry_t registryEntry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/chosen");
    if (registryEntry == IO_OBJECT_NULL) {
        return NULL;
    }
    CFDataRef bootManifestHash = IORegistryEntryCreateCFProperty(registryEntry, CFSTR("boot-manifest-hash"), kCFAllocatorDefault, kNilOptions);
    if(!bootManifestHash) {
        return NULL;
    }
    
    IOObjectRelease(registryEntry);
    
    CFIndex length = CFDataGetLength(bootManifestHash) * 2 + 1;
    char *manifestHash = (char*)calloc(length, sizeof(char));
    
    int i = 0;
    for (i = 0; i<(int)CFDataGetLength(bootManifestHash); i++) {
        sprintf(manifestHash+i*2, "%02X", CFDataGetBytePtr(bootManifestHash)[i]);
    }
    manifestHash[i*2] = 0;
    
    CFRelease(bootManifestHash);
    
    return manifestHash;
}

bool bootstrapInstalled() {
    char* var_jb_mount = mountVarJbUnsandboxed();
    NSString* var_jb_path = [NSString stringWithUTF8String:var_jb_mount];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/.procursus_strapped", var_jb_path]];
}

void reinstallBootstrap() {
    char* var_jb_mount = mountVarJbUnsandboxed();
    NSString* var_jb_path = [NSString stringWithUTF8String:var_jb_mount];
    
    [[NSFileManager defaultManager] removeItemAtPath:var_jb_path error:NULL];
    
    prepareBootstrap();
    extractBootstrap();
}

void prepareBootstrap() {
    char* var_jb_mount = mountVarJbUnsandboxed();
    NSString* var_jb_path = [NSString stringWithUTF8String:var_jb_mount];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:var_jb_path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:var_jb_path withIntermediateDirectories:TRUE attributes:NULL error:NULL];
    }
    
    NSLog(@"[i] prepared bootstrap for installation");
}

void extractBootstrap() {
    char* var_jb_mount = mountVarJbUnsandboxed();
    NSString* var_jb_path = [NSString stringWithUTF8String:var_jb_mount];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:var_jb_path]) {
        prepareBootstrap();
    }
    
    if (untar([NSString stringWithFormat:@"%@/bootstrap.tar", NSBundle.mainBundle.bundlePath].UTF8String, var_jb_path.UTF8String, 0) != 0) {
        NSLog(@"[!] error extracting bootstrap");
        return;
    }
    
    NSLog(@"[+] extracted bootstrap!");
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/basebin", var_jb_path] withIntermediateDirectories:TRUE attributes:NULL error:NULL];
    
    if (untar([NSString stringWithFormat:@"%@/basebin.tar", NSBundle.mainBundle.bundlePath].UTF8String, var_jb_path.UTF8String, 0) != 0) {
        NSLog(@"[!] error extracting basebin");
        return;
    }
    
    NSLog(@"[+] extracted basebin!");
    
    NSLog(@"[i] directory listing of /var/jb: %@", [[NSFileManager defaultManager] contentsOfDirectoryAtPath:var_jb_path error:NULL]);
}

void dpkg(char* pathName) {
    char* var_jb_mount = mountVarJbUnsandboxed();
    NSString* var_jb_path = [NSString stringWithUTF8String:var_jb_mount];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:var_jb_path]) {
        NSLog(@"[!] bootstrap not installed");
        return;
    }
    
    if (untar(pathName, [NSString stringWithFormat:@"%@/tmp", var_jb_path].UTF8String, 0) != 0) {
        NSLog(@"[!] error extracting %s", pathName);
        return;
    }
    
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/tmp", var_jb_path] error:NULL];
    NSString* stringToSearch = @"data.tar";
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", stringToSearch];
    NSArray* results = [contents filteredArrayUsingPredicate:predicate];
    
    if (results.count != 1) {
        NSLog(@"[!] no data in .deb archive");
        return;
    }
    
    char* dataTar = [NSString stringWithFormat:@"%@/tmp/%@", var_jb_path, (NSString *)results[0]].UTF8String;
    
    if (untar(dataTar, var_jb_path.UTF8String, 1) != 0) {
        NSLog(@"[!] error extracting %s", dataTar);
        return;
    }
    
    NSLog(@"[+] installed %s", pathName);
    NSLog(@"[i] directory listing of /var/jb: %@", [[NSFileManager defaultManager] contentsOfDirectoryAtPath:var_jb_path error:NULL]);
}


char* mountVarJbUnsandboxed() {
    uint64_t target_vnode = getVnodeAtPathByChdir("/var/mobile");
    char* target_mount = mountVnode(target_vnode, "/var/mobile");
    
    NSString* var_jb_path = [NSString stringWithFormat:@"%s/jb", target_mount];
    return var_jb_path.UTF8String;
}
