//
//  bootstrap.h
//  kfd
//
//  Created by user on 11/09/2023.
//

#ifndef bootstrap_h
#define bootstrap_h

#include "stdbool.h"

char* getBootManifestHash(void);
bool bootstrapInstalled(void);
void reinstallBootstrap(void);
void prepareBootstrap(void);
void extractBootstrap(void);
void dpkg(char* pathName);
char* mountVarJbUnsandboxed(void);

#endif /* bootstrap_h */
