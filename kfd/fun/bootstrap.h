//
//  bootstrap.h
//  kfd
//
//  Created by user on 11/09/2023.
//

#ifndef bootstrap_h
#define bootstrap_h

#include "stdbool.h"

bool bootstrapInstalled(void);
void prepareBootstrap(void);
char* mountVarJbUnsandboxed(void);

#endif /* bootstrap_h */
