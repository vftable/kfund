//
//  bootstrap.m
//  kfd
//
//  Created by user on 11/09/2023.
//

#include "bootstrap.h"
#include "vnode.h"
#include "fun.h"
#include <Foundation/Foundation.h>

bool bootstrapInstalled() {
    char* var_jb_mount = mountVarJbUnsandboxed();
    NSString* var_jb_path = [NSString stringWithUTF8String:var_jb_mount];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:var_jb_path];
}

void prepareBootstrap() {
    char* var_jb_mount = mountVarJbUnsandboxed();
    NSString* var_jb_path = [NSString stringWithUTF8String:var_jb_mount];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:var_jb_path withIntermediateDirectories:TRUE attributes:NULL error:NULL];
    NSLog(@"[i] prepared bootstrap for installation");
}

char* mountVarJbUnsandboxed() {
    uint64_t target_vnode = getVnodeAtPathByChdir("/var/mobile");
    char* target_mount = mountVnode(target_vnode, "/var/mobile");
    
    NSString* var_jb_path = [NSString stringWithFormat:@"%s%s", target_mount, "/jb"];
    return var_jb_path.UTF8String;
}
