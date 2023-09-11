//
//  utils.m
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/30.
//

#import <Foundation/Foundation.h>
#import <dirent.h>
#import <sys/statvfs.h>
#import <sys/stat.h>
#import "proc.h"
#import "vnode.h"
#import "krw.h"
#import "helpers.h"
#include "offsets.h"
#import "thanks_opa334dev_htrowii.h"
#import <errno.h>
#import "utils.h"

uint64_t createFolderAndRedirect(uint64_t vnode, NSString *mntPath) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:mntPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    uint64_t orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
    return orig_to_v_data;
}

uint64_t UnRedirectAndRemoveFolder(uint64_t orig_to_v_data, NSString *mntPath) {
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    return 0;
}

int setResolution(NSString *path, NSInteger height, NSInteger width) {
    NSDictionary *dictionary = @{
        @"canvas_height": @(height),
        @"canvas_width": @(width)
    };
    
    BOOL success = [dictionary writeToFile:path atomically:YES];
    if (!success) {
        printf("[-] Failed createPlistAtPath.\n");
        return -1;
    }
    
    return 0;
}

int ResSet16(NSInteger height, NSInteger width) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    //1. Create /var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist
    uint64_t var_tmp_vnode = getVnodeAtPathByChdir("/var/tmp");
    printf("[i] /var/tmp vnode: 0x%llx\n", var_tmp_vnode);
    
    uint64_t orig_to_v_data = createFolderAndRedirect(var_tmp_vnode, mntPath);
    
    
    //iPhone 14 Pro Max Resolution
    setResolution([mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"], height, width);
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    
    //2. Create symbolic link /var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist -> /var/mobile/Library/Preferences/com.apple.iokit.IOMobileGraphicsFamily.plist
    uint64_t preferences_vnode = getVnodePreferences();
    orig_to_v_data = createFolderAndRedirect(preferences_vnode, mntPath);

    remove([mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"].UTF8String);
    printf("symlink ret: %d\n", symlink("/var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist", [mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"].UTF8String));
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    //3. xpc restart
//    do_kclose();
//    sleep(1);
//    xpc_crasher("com.apple.cfprefsd.daemon");
//    xpc_crasher("com.apple.backboard.TouchDeliveryPolicyServer");
    
    return 0;
}

int removeSMSCache(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    uint64_t library_vnode = getVnodeLibrary();
    uint64_t sms_vnode = getVnodeAtPathByChdir("/var/mobile/Library/SMS");
    printf("[i] /var/mobile/Library/SMS vnode: 0x%llx\n", sms_vnode);
    
    uint64_t orig_to_v_data = createFolderAndRedirect(sms_vnode, mntPath);

    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/SMS directory list: %@", dirs);

    remove([mntPath stringByAppendingString:@"/com.apple.messages.geometrycache_v7.plist"].UTF8String);

    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/SMS directory list: %@", dirs);

    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

int VarMobileWriteTest(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    uint64_t var_mobile_vnode = getVnodeVarMobile();
    
    uint64_t orig_to_v_data = createFolderAndRedirect(var_mobile_vnode, mntPath);
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    //create
    [@"PLZ_GIVE_ME_GIRLFRIENDS!@#" writeToFile:[mntPath stringByAppendingString:@"/can_i_remove_file"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

int VarMobileRemoveTest(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    uint64_t var_mobile_vnode = getVnodeVarMobile();
    
    uint64_t orig_to_v_data = createFolderAndRedirect(var_mobile_vnode, mntPath);
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    //remove
    int ret = remove([mntPath stringByAppendingString:@"/can_i_remove_file"].UTF8String);
    printf("remove ret: %d\n", ret);
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile directory list: %@", dirs);
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

int setSuperviseMode(BOOL enable) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    // /var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/CloudConfigurationDetails.plist
    
    uint64_t systemgroup_vnode = getVnodeSystemGroup();
    
    //must enter 3 subdirectories
    uint64_t configurationprofiles_vnode = findChildVnodeByVnode(systemgroup_vnode, "systemgroup.com.apple.configurationprofiles");
    while(1) {
        if(configurationprofiles_vnode != 0)
            break;
        configurationprofiles_vnode = findChildVnodeByVnode(systemgroup_vnode, "systemgroup.com.apple.configurationprofiles");
    }
    printf("[i] /var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles vnode: 0x%llx\n", configurationprofiles_vnode);
    
    configurationprofiles_vnode = findChildVnodeByVnode(configurationprofiles_vnode, "Library");
    while(1) {
        if(configurationprofiles_vnode != 0)
            break;
        configurationprofiles_vnode = findChildVnodeByVnode(configurationprofiles_vnode, "Library");
    }
    printf("[i] /var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library vnode: 0x%llx\n", configurationprofiles_vnode);
    
    configurationprofiles_vnode = findChildVnodeByVnode(configurationprofiles_vnode, "ConfigurationProfiles");
    while(1) {
        if(configurationprofiles_vnode != 0)
            break;
        configurationprofiles_vnode = findChildVnodeByVnode(configurationprofiles_vnode, "ConfigurationProfiles");
    }
    printf("[i] /var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles vnode: 0x%llx\n", configurationprofiles_vnode);
    
    uint64_t orig_to_v_data = createFolderAndRedirect(configurationprofiles_vnode, mntPath);
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles directory list:\n %@", dirs);
    
    //set value of "IsSupervised" key
    NSString *plistPath = [mntPath stringByAppendingString:@"/CloudConfigurationDetails.plist"];
    
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
        
    if (plist) {
        // Set the value of "IsSupervised" key to true
        [plist setObject:@(enable) forKey:@"IsSupervised"];
        
        // Save the updated plist back to the file
        if ([plist writeToFile:plistPath atomically:YES]) {
            printf("[+] Successfully set IsSupervised in the plist.");
        } else {
            printf("[-] Failed to write the updated plist to file.");
        }
    } else {
        printf("[-] Failed to load the plist file.");
    }
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

int removeKeyboardCache(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    uint64_t vnode = getVnodeAtPath("/var/mobile/Library/Caches/com.apple.keyboards/images");
    if(vnode == -1) return 0;
    
    uint64_t orig_to_v_data = createFolderAndRedirect(vnode, mntPath);
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/Caches/com.apple.keyboards/images directory list:\n %@", dirs);
    
    for(NSString *dir in dirs) {
        NSString *path = [NSString stringWithFormat:@"%@/%@", mntPath, dir];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/Caches/com.apple.keyboards/images directory list:\n %@", dirs);
    
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    return 0;
}

#define COUNTRY_KEY @"h63QSdBCiT/z0WU6rdQv6Q"
#define REGION_KEY @"zHeENZu+wbg7PUprwNwBWg"
int regionChanger(NSString *country_value, NSString *region_value) {
    NSString *plistPath = @"/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist";
    NSString *rewrittenPlistPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/com.apple.MobileGestalt.plist"];
    
    remove(rewrittenPlistPath.UTF8String);
    
    NSDictionary *dict1 = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSMutableDictionary *mdict1 = dict1 ? [dict1 mutableCopy] : [NSMutableDictionary dictionary];
    NSDictionary *dict2 = dict1[@"CacheExtra"];
    
    NSMutableDictionary *mdict2 = dict2 ? [dict2 mutableCopy] : [NSMutableDictionary dictionary];
    mdict2[COUNTRY_KEY] = country_value;
    mdict2[REGION_KEY] = region_value;
    [mdict1 setObject:mdict2 forKey:@"CacheExtra"];
    
    NSData *binaryData = [NSPropertyListSerialization dataWithPropertyList:mdict1 format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    [binaryData writeToFile:rewrittenPlistPath atomically:YES];
    
    funVnodeOverwriteFile(plistPath.UTF8String, rewrittenPlistPath.UTF8String);
    
    return 0;
}

int themePasscodes(void) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    uint64_t var_tmp_vnode = getVnodeAtPathByChdir("/var/tmp");
    
//    for(NSString *dir in dirs) {
//        NSString *path = [NSString stringWithFormat:@"%@/%@", mntPath, dir];
//        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
//    }
    
    printf("[i] /var/tmp vnode: 0x%llx\n", var_tmp_vnode);
    // symlink documents folder to /var/tmp, then copy all our images there
    uint64_t orig_to_v_data = createFolderAndRedirect(var_tmp_vnode, mntPath);
    
    NSError *error;
    
    // create a file picker and let users choose the image, add them to your documents or whatever, then do this.
    
    // the topath name can be anything but i'm making them the same for easy copy paste
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/feet.png"] toPath:[mntPath stringByAppendingString:@"/en-0---white.png"] error:&error];
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/Lear.png"] toPath:[mntPath stringByAppendingString:@"/en-1---white.png"] error:&error];
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/Leye.png"] toPath:[mntPath stringByAppendingString:@"/en-2-A B C--white.png"] error:&error];
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/Reye.png"] toPath:[mntPath stringByAppendingString:@"/en-3-D E F--white.png"] error:&error];
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/Side.png"] toPath:[mntPath stringByAppendingString:@"/en-4-G H I--white.png"] error:&error];
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/mouth.png"] toPath:[mntPath stringByAppendingString:@"/en-5-J K L--white.png"] error:&error];
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/nose.png"] toPath:[mntPath stringByAppendingString:@"/en-6-M N O--white.png"] error:&error];
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/back.png"] toPath:[mntPath stringByAppendingString:@"/en-7-P Q R S--white.png"] error:&error];
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/stomach.png"] toPath:[mntPath stringByAppendingString:@"/en-8-T U V--white.png"] error:&error];
    
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@%@", NSBundle.mainBundle.bundlePath, @"/nothing.png"] toPath:[mntPath stringByAppendingString:@"/en-9-W X Y Z--white.png"] error:&error];

    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/tmp directory list:\n %@", dirs);
    printf("unredirecting from tmp\n");
    sleep(2);
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    
    uint64_t telephonyui_vnode = getVnodeAtPathByChdir("/var/mobile/Library/Caches/TelephonyUI-9");
    printf("[i] /var/mobile/Library/Caches/TelephonyUI-9 vnode: 0x%llx\n", telephonyui_vnode);
    
    //2. Create symbolic link /var/tmp/image.png -> /var/mobile/Library/Caches/TelephonyUI-9/en-number-letters--white.png, loop through then done. Technically just add our known image paths in /var/tmp (they can be anything, just 1.png also works) into an array then loop through both that array and this directory to automate it
    sleep(2);
    orig_to_v_data = createFolderAndRedirect(telephonyui_vnode, mntPath);
    sleep(2);
    // Remove and symlink for "en-0---white.png"
    printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/en-0---white.png"] error:nil]);
    printf("symlink ret: %d, errno: %d\n", symlink("/var/tmp/en-0---white.png", [mntPath stringByAppendingString:@"/en-0---white.png"].UTF8String), errno);
    // Remove and symlink for "en-1---white.png"
    printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/en-1---white.png"] error:nil]);
    printf("symlink ret: %d, errno: %d\n", symlink("/var/tmp/en-1---white.png", [mntPath stringByAppendingString:@"/en-1---white.png"].UTF8String), errno);
    // Remove and symlink for "en-2-A B C--white.png"
    printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/en-2-A B C--white.png"] error:nil]);
    printf("symlink ret: %d, errno: %d\n", symlink("/var/tmp/en-2-A B C--white.png", [mntPath stringByAppendingString:@"/en-2-A B C--white.png"].UTF8String), errno);
    // Remove and symlink for "en-3-D E F--white.png"
    printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/en-3-D E F--white.png"] error:nil]);
    printf("symlink ret: %d, errno: %d\n", symlink("/var/tmp/en-3-D E F--white.png", [mntPath stringByAppendingString:@"/en-3-D E F--white.png"].UTF8String), errno);
    // Remove and symlink for "en-4-G H I--white.png"
    printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/en-4-G H I--white.png"] error:nil]);
    printf("symlink ret: %d, errno: %d\n", symlink("/var/tmp/en-4-G H I--white.png", [mntPath stringByAppendingString:@"/en-4-G H I--white.png"].UTF8String), errno);
    // Remove and symlink for "en-5-J K L--white.png"
    printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/en-5-J K L--white.png"] error:nil]);
    printf("symlink ret: %d, errno: %d\n", symlink("/var/tmp/en-5-J K L--white.png", [mntPath stringByAppendingString:@"/en-5-J K L--white.png"].UTF8String), errno);
    // Remove and symlink for "en-6-M N O--white.png"
    printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/en-6-M N O--white.png"] error:nil]);
    printf("symlink ret: %d, errno: %d\n", symlink("/var/tmp/en-6-M N O--white.png", [mntPath stringByAppendingString:@"/en-6-M N O--white.png"].UTF8String), errno);
    // Remove and symlink for "en-7-P Q R S--white.png"
    printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/en-7-P Q R S--white.png"] error:nil]);
    printf("symlink ret: %d, errno: %d\n", symlink("/var/tmp/en-7-P Q R S--white.png", [mntPath stringByAppendingString:@"/en-7-P Q R S--white.png"].UTF8String), errno);
    // Remove and symlink for "en-8-T U V--white.png"
    printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/en-8-T U V--white.png"] error:nil]);
    printf("symlink ret: %d, errno: %d\n", symlink("/var/tmp/en-8-T U V--white.png", [mntPath stringByAppendingString:@"/en-8-T U V--white.png"].UTF8String), errno);
    // Remove and symlink for "en-9-W X Y Z--white.png"
    printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingString:@"/en-9-W X Y Z--white.png"] error:nil]);
    printf("symlink ret: %d, errno: %d\n", symlink("/var/tmp/en-9-W X Y Z--white.png", [mntPath stringByAppendingString:@"/en-9-W X Y Z--white.png"].UTF8String), errno);
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/Caches/TelephonyUI-9 directory list:\n %@", dirs);

    sleep(2);
    printf("cleaning up\n");
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
    return 0;
}
