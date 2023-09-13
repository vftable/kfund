//
//  fun.c
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/25.
//

#include "krw.h"
#include "offsets.h"
#include <sys/stat.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/mount.h>
#include <sys/stat.h>
#include <sys/attr.h>
#include <sys/snapshot.h>
#include <sys/mman.h>
#include <mach/mach.h>
#include "proc.h"
#include "vnode.h"
#include "utils.h"
#include "grant_full_disk_access.h"
#include "thanks_opa334dev_htrowii.h"
#include "IOKit.h"
#include "bootstrap.h"


int funUcred(uint64_t proc) {
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    uint64_t ucreds = kread64(proc_ro + off_p_ro_p_ucred);
    
    uint64_t cr_label_pac = kread64(ucreds + off_u_cr_label);
    uint64_t cr_label = cr_label_pac | 0xffffff8000000000;
    printf("[i] self ucred->cr_label: 0x%llx\n", cr_label);
//
//    printf("[i] self ucred->cr_label+0x8+0x0: 0x%llx\n", kread64(kread64(cr_label+0x8)));
//    printf("[i] self ucred->cr_label+0x8+0x0+0x0: 0x%llx\n", kread64(kread64(kread64(cr_label+0x8))));
//    printf("[i] self ucred->cr_label+0x10: 0x%llx\n", kread64(cr_label+0x10));
//    uint64_t OSEntitlements = kread64(cr_label+0x10);
//    printf("OSEntitlements: 0x%llx\n", OSEntitlements);
//    uint64_t CEQueryContext = OSEntitlements + 0x28;
//    uint64_t der_start = kread64(CEQueryContext + 0x20);
//    uint64_t der_end = kread64(CEQueryContext + 0x28);
//    for(int i = 0; i < 100; i++) {
//        printf("OSEntitlements+0x%x: 0x%llx\n", i*8, kread64(OSEntitlements + i * 8));
//    }
//    kwrite64(kread64(OSEntitlements), 0);
//    kwrite64(kread64(OSEntitlements + 8), 0);
//    kwrite64(kread64(OSEntitlements + 0x10), 0);
//    kwrite64(kread64(OSEntitlements + 0x20), 0);
    
    uint64_t cr_posix_p = ucreds + off_u_cr_posix;
    printf("[i] self ucred->posix_cred->cr_uid: %u\n", kread32(cr_posix_p + off_cr_uid));
    printf("[i] self ucred->posix_cred->cr_ruid: %u\n", kread32(cr_posix_p + off_cr_ruid));
    printf("[i] self ucred->posix_cred->cr_svuid: %u\n", kread32(cr_posix_p + off_cr_svuid));
    printf("[i] self ucred->posix_cred->cr_ngroups: %u\n", kread32(cr_posix_p + off_cr_ngroups));
    printf("[i] self ucred->posix_cred->cr_groups: %u\n", kread32(cr_posix_p + off_cr_groups));
    printf("[i] self ucred->posix_cred->cr_rgid: %u\n", kread32(cr_posix_p + off_cr_rgid));
    printf("[i] self ucred->posix_cred->cr_svgid: %u\n", kread32(cr_posix_p + off_cr_svgid));
    printf("[i] self ucred->posix_cred->cr_gmuid: %u\n", kread32(cr_posix_p + off_cr_gmuid));
    printf("[i] self ucred->posix_cred->cr_flags: %u\n", kread32(cr_posix_p + off_cr_flags));

    return 0;
}


int funCSFlags(char* process) {
    uint64_t pid = getPidByName(process);
    uint64_t proc = getProc(pid);
    
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    uint32_t csflags = kread32(proc_ro + off_p_ro_p_csflags);
    printf("[i] %s proc->proc_ro->p_csflags: 0x%x\n", process, csflags);
    
#define TF_PLATFORM 0x400

#define CS_GET_TASK_ALLOW    0x0000004    /* has get-task-allow entitlement */
#define CS_INSTALLER        0x0000008    /* has installer entitlement */

#define    CS_HARD            0x0000100    /* don't load invalid pages */
#define    CS_KILL            0x0000200    /* kill process if it becomes invalid */
#define CS_RESTRICT        0x0000800    /* tell dyld to treat restricted */

#define CS_PLATFORM_BINARY    0x4000000    /* this is a platform binary */

#define CS_DEBUGGED         0x10000000  /* process is currently or has previously been debugged and allowed to run with invalid pages */
    
//    csflags = (csflags | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW | CS_DEBUGGED) & ~(CS_RESTRICT | CS_HARD | CS_KILL);
//    sleep(3);
//    kwrite32(proc_ro + off_p_ro_p_csflags, csflags);
    
    return 0;
}

int funTask(char* process) {
    uint64_t pid = getPidByName(process);
    uint64_t proc = getProc(pid);
    printf("[i] %s proc: 0x%llx\n", process, proc);
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    
    uint64_t pr_proc = kread64(proc_ro + off_p_ro_pr_proc);
    printf("[i] %s proc->proc_ro->pr_proc: 0x%llx\n", process, pr_proc);
    
    uint64_t pr_task = kread64(proc_ro + off_p_ro_pr_task);
    printf("[i] %s proc->proc_ro->pr_task: 0x%llx\n", process, pr_task);
    
    //proc_is64bit_data+0x18: LDR             W8, [X8,#0x3D0]
    uint32_t t_flags = kread32(pr_task + off_task_t_flags);
    printf("[i] %s task->t_flags: 0x%x\n", process, t_flags);
    
    
    /*
     * RO-protected flags:
     */
    #define TFRO_PLATFORM                   0x00000400                      /* task is a platform binary */
    #define TFRO_FILTER_MSG                 0x00004000                      /* task calls into message filter callback before sending a message */
    #define TFRO_PAC_EXC_FATAL              0x00010000                      /* task is marked a corpse if a PAC exception occurs */
    #define TFRO_PAC_ENFORCE_USER_STATE     0x01000000                      /* Enforce user and kernel signed thread state */
    
    uint32_t t_flags_ro = kread64(proc_ro + off_p_ro_t_flags_ro);
    printf("[i] %s proc->proc_ro->t_flags_ro: 0x%x\n", process, t_flags_ro);
    
    return 0;
}

uint64_t fun_ipc_entry_lookup(mach_port_name_t port_name) {
    uint64_t proc = getProc(getpid());
    uint64_t proc_ro = kread64(proc + off_p_proc_ro);
    
    uint64_t pr_proc = kread64(proc_ro + off_p_ro_pr_proc);
    printf("[i] self proc->proc_ro->pr_proc: 0x%llx\n", pr_proc);
    
    uint64_t pr_task = kread64(proc_ro + off_p_ro_pr_task);
    printf("[i] self proc->proc_ro->pr_task: 0x%llx\n", pr_task);
    
    uint64_t itk_space_pac = kread64(pr_task + 0x300);
    uint64_t itk_space = itk_space_pac | 0xffffff8000000000;
    printf("[i] self task->itk_space: 0x%llx\n", itk_space);
    //NEED TO FIGURE OUT SMR POINTER!!!
    
//    uint32_t table_size = kread32(itk_space + 0x14);
//    printf("[i] self task->itk_space table_size: 0x%x\n", table_size);
//    uint32_t port_index = MACH_PORT_INDEX(port_name);
//    if (port_index >= table_size) {
//        printf("[!] invalid port name: 0x%x", port_name);
//        return -1;
//    }
//
//    uint64_t is_table_pac = kread64(itk_space + 0x20);
//    uint64_t is_table = is_table_pac | 0xffffff8000000000;
//    printf("[i] self task->itk_space->is_table: 0x%llx\n", is_table);
//    printf("[i] self task->itk_space->is_table read: 0x%llx\n", kread64(is_table));
//
//    const int sizeof_ipc_entry_t = 0x18;
//    uint64_t ipc_entry = is_table + sizeof_ipc_entry_t * port_index;
//    printf("[i] self task->itk_space->is_table->ipc_entry: 0x%llx\n", ipc_entry);
//
//    uint64_t ie_object = kread64(ipc_entry + 0x0);
//    printf("[i] self task->itk_space->is_table->ipc_entry->ie_object: 0x%llx\n", ie_object);
//
//    sleep(1);
    
    
    
    return 0;
}

char* mountVnode(uint64_t vnode, char* pathname) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@%s/.mnt", NSHomeDirectory(), @"/Documents/mount", pathname];
    NSLog(@"[i] pathname: %s", pathname);
    createFolderAndRedirect(vnode, mntPath);
    return mntPath.UTF8String;
}

uint64_t getChildVnode(uint64_t vnode, char* childname) {
    uint64_t target_vnode = 0;
    int trycount = 0;
    
    while(1) {
        if (target_vnode != 0)
            break;
        
        target_vnode = findChildVnodeByVnode(vnode, childname);
        trycount++;
    }
    
    return target_vnode;
}

uint64_t getVnodePrivate(void) {
    
    //path: /private/var/mobile/Library/Preferences/.GlobalPreferences.plist
    //5 upward, /private
    const char* path = "/private/var/mobile/Library/Preferences/.GlobalPreferences.plist";
    
    uint64_t vnode = getVnodeAtPath(path);
    if(vnode == -1) {
        printf("[-] Unable to get vnode, path: %s\n", path);
        return -1;
    }

    uint64_t parent_vnode = vnode;
    for(int i = 0; i < 4; i++) {
        parent_vnode = kread64(parent_vnode + off_vnode_v_parent) | 0xffffff8000000000;
    }

    return parent_vnode;
}

int do_fun(void) {
    
    _offsets_init();
    
    uint64_t kslide = get_kslide();
    uint64_t kbase = 0xfffffff007004000 + kslide;
    printf("[i] Kernel base: 0x%llx\n", kbase);
    printf("[i] Kernel slide: 0x%llx\n", kslide);
    uint64_t kheader64 = kread64(kbase);
    printf("[i] Kernel base kread64 ret: 0x%llx\n", kheader64);
    
    pid_t myPid = getpid();
    uint64_t selfProc = getProc(myPid);
    printf("[i] self proc: 0x%llx\n", selfProc);
    
    funUcred(selfProc);
    funProc(selfProc);
    
    grant_full_disk_access(^(NSError* _Nullable error) {
        if (error) {
            NSLog(@"[!] error: %@", error);
        } else {
            NSLog(@"[+] successfully ran grant_full_disk_access");
        }
    });
    
    /*
    
    uint64_t target_vnode = getChildVnode(getVnodeVar(), "root");
    char* target_mount = mountVnode(target_vnode, "/var/root");
    
    NSLog(@"[i] directory listing of /var/root: %@", [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithUTF8String:target_mount] error:NULL]);
     
     */
    
    NSLog(@"[i] /private vnode: 0x%llx", getVnodePrivate());
    NSLog(@"[i] boot manifest hash: %s", getBootManifestHash());
    
    uint64_t target_vnode = getVnodeAtPathByChdir("/var/mobile");
    char* target_mount = mountVnode(target_vnode, "/var/mobile");
    
    NSLog(@"[i] directory listing of /var/mobile: %@", [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithUTF8String:target_mount] error:NULL]);
    
    /*
    if (!bootstrapInstalled()) {
        prepareBootstrap();
        extractBootstrap();
    }
     */
    
    // VarMobileWriteTest();
    
    return 0;
}

void do_fun2(char** enabledTweaks, int numTweaks) {
    // i apologize greatly, this function is one of the worst attrocities known to man with how bad it is written 💀
    _offsets_init();
    
    uint64_t kslide = get_kslide();
    uint64_t kbase = 0xfffffff007004000 + kslide;
    printf("[i] Kernel base: 0x%llx\n", kbase);
    printf("[i] Kernel slide: 0x%llx\n", kslide);
    uint64_t kheader64 = kread64(kbase);
    printf("[i] Kernel base kread64 ret: 0x%llx\n", kheader64);
    
    pid_t myPid = getpid();
    uint64_t selfProc = getProc(myPid);
    printf("[i] self proc: 0x%llx\n", selfProc);
    
    funUcred(selfProc);
    funProc(selfProc);
    
    // passcode key stuff
    // forgive the code below for it is horrendous, i suck at obj c
    // largely copied from sacrosanct
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    uint64_t var_tmp_vnode = getVnodeAtPathByChdir("/var/tmp");
    printf("[i] /var/tmp vnode: 0x%llx\n", var_tmp_vnode);
    
    // symlink documents folder to /var/tmp, then copy all our images there
    uint64_t orig_to_v_data = createFolderAndRedirect(var_tmp_vnode, mntPath);
    
    NSError *error;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *folderPath = [documentsDirectory stringByAppendingPathComponent:@"ChangingPasscodeKeys"];
    
    // This was an attempt to clean up the horrible code below
    // Unfortunately, it does not work and I cannot figure out why
    NSDictionary *keyMapping = @{
        @"0": @"",
        @"1": @"",
        @"2": @"A B C",
        @"3": @"D E F",
        @"4": @"G H I",
        @"5": @"J K L",
        @"6": @"M N O",
        @"7": @"P Q R S",
        @"8": @"T U V",
        @"9": @"W X Y Z"
    };

    for (int i = 0; i < numTweaks; i++) {
        char *tweak = enabledTweaks[i];
        NSString *letters = keyMapping[@(tweak)];

        if (letters) {
            NSString *filePath = [folderPath stringByAppendingFormat:@"/PasscodeKey-%s.png", tweak];

            [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@", filePath] toPath:[mntPath stringByAppendingFormat:@"/en-%s-%@--white.png", tweak, letters] error:&error];
        }
    }

    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/tmp directory list:\n %@", dirs);
    printf("unredirecting from tmp\n");
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);

    uint64_t telephonyui_vnode = getVnodeAtPathByChdir("/var/mobile/Library/Caches/TelephonyUI-9");
    printf("[i] /var/mobile/Library/Caches/TelephonyUI-9 vnode: 0x%llx\n", telephonyui_vnode);

    //2. Create symbolic link /var/tmp/image.png -> /var/mobile/Library/Caches/TelephonyUI-9/en-number-letters--white.png, loop through then done. Technically just add our known image paths in /var/tmp (they can be anything, just 1.png also works) into an array then loop through both that array and this directory to automate it
    orig_to_v_data = createFolderAndRedirect(telephonyui_vnode, mntPath);
    for (int i = 0; i < numTweaks; i++) {
        char *tweak = enabledTweaks[i];
        NSString *letters = keyMapping[@(tweak)];
        if (letters) {
            // Remove symlink
            NSString *tmpPath = [NSString stringWithFormat:@"/var/tmp/en-%s-%@--white.png", tweak, letters];
            unlink(tmpPath.UTF8String);
            // Remove and symlink
            printf("remove ret: %d\n", [[NSFileManager defaultManager] removeItemAtPath:[mntPath stringByAppendingFormat:@"/en-%s-%@--white.png", tweak, letters] error:nil]);
            printf("symlink ret: %d, errno: %d\n", symlink(tmpPath.UTF8String, [mntPath stringByAppendingFormat:@"/en-%s-%@--white.png", tweak, letters].UTF8String), errno);
        }
    }
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/Caches/TelephonyUI-9 directory list:\n %@", dirs);

    printf("cleaning up\n");
    UnRedirectAndRemoveFolder(orig_to_v_data, mntPath);
}
