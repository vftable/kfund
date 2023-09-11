//
//  trustcache.h
//  kfd
//
//  Created by user on 10/09/2023.
//

// i just took this from xnu lmao

#ifndef trustcache_h
#define trustcache_h

#include <stdint.h>

#define kTCEntryHashSize 20
#define kUUIDSize 16

enum {
    kTCVersion0 = 0x0,
    kTCVersion1 = 0x1,
    kTCVersion2 = 0x2,
    
    kTCVersionTotal,
};

enum {
    kTCFlagAMFID = 0x01,
    kTCFlagANEModel = 0x02,
};

typedef struct _TrustCacheModuleBase {
    uint32_t version;
} __attribute__((packed)) TrustCacheModuleBase_t;

#pragma mark Trust Cache Version 0

typedef uint8_t TrustCacheEntry0_t[kTCEntryHashSize];

typedef struct _TrustCacheModule0 {
    uint32_t version;
    uint8_t uuid[kUUIDSize];
    uint32_t numEntries;
    TrustCacheEntry0_t entries[0];
} __attribute__((packed)) TrustCacheModule0_t;

#pragma mark Trust Cache Version 1

typedef struct _TrustCacheEntry1 {
    uint8_t CDHash[kTCEntryHashSize];
    uint8_t hashType;
    uint8_t flags;
} __attribute__((packed)) TrustCacheEntry1_t;

typedef struct _TrustCacheModule1 {
    uint32_t version;
    uint8_t uuid[kUUIDSize];
    uint32_t numEntries;
    TrustCacheEntry1_t entries[0];
} __attribute__((packed)) TrustCacheModule1_t;

#pragma mark Trust Cache Version 2

typedef struct _TrustCacheEntry2 {
    uint8_t CDHash[kTCEntryHashSize];
    uint8_t hashType;
    uint8_t flags;
    uint8_t constraintCategory;
    uint8_t reserved0;
} __attribute__((packed)) TrustCacheEntry2_t;

typedef struct _TrustCacheModule2 {
    uint32_t version;
    uint8_t uuid[kUUIDSize];
    uint32_t numEntries;
    TrustCacheEntry2_t entries[0];
} __attribute__((packed)) TrustCacheModule2_t;

typedef uint8_t TCType_t;
enum {
    kTCTypeStatic = 0x00,
    kTCTypeEngineering = 0x01,
    kTCTypeLegacy = 0x02,
    kTCTypeDTRS = 0x03,
    kTCTypeLTRS = 0x04,
    kTCTypePersonalizedDiskImage = 0x05,
    kTCTypeDeveloperDiskImage = 0x06,
    kTCTypeLTRSWithDDINonce = 0x07,
    kTCTypeCryptex = 0x08,
    kTCTypeEphemeralCryptex = 0x09,
    kTCTypeUpdateBrain = 0x0A,
    kTCTypeInstallAssistant = 0x0B,
    kTCTypeBootabilityBrain = 0x0C,
    kTCTypeCryptex1BootOS = 0x0D,
    kTCTypeCryptex1BootApp = 0x0E,
    kTCTypeCryptex1PreBootApp = 0x0F,
    kTCTypeGlobalDiskImage = 0x10,
    kTCTypeMobileAssetBrain = 0x11,
    kTCTypeSafariDownlevel = 0x12,
    kTCTypeCryptex1PreBootOS = 0x13,
    kTCTypeSupplementalPersistent = 0x14,
    kTCTypeSupplementalEphemeral = 0x15,
    kTCTypeCryptex1Generic = 0x16,
    kTCTypeCryptex1GenericSupplemental = 0x17,
    
    kTCTypeTotal,
    kTCTypeInvalid = 0xFF,
};

#define kLibTrustCacheHasCryptex1BootOS 1
#define kLibTrustCacheHasCryptex1BootApp 1
#define kLibTrustCacheHasCryptex1PreBootApp 1
#define kLibTrustCacheHasMobileAssetBrain 1
#define kLibTrustCacheHasSafariDownlevel 1
#define kLibTrustCacheHasCryptex1PreBootOS 1
#define kLibTrustCacheHasSupplementalPersistent 1
#define kLibTrustCacheHasSupplementalEphemeral 1
#define kLibTrustCacheHasCryptex1Generic 1
#define kLibTrustCacheHasCryptex1GenericSupplemental 1

typedef struct TrustCache {
    uint64_t next; // TrustCache*
    uint64_t prev; // TrustCache*
    TCType_t type;
    size_t moduleSize;
    uint64_t module; // TrustCacheModuleBase*
} TrustCache_t;

typedef uint8_t TCQueryType_t;
enum {
    kTCQueryTypeAll = 0x00,
    kTCQueryTypeStatic = 0x01,
    kTCQueryTypeLoadable = 0x02,
    
    kTCQueryTypeTotal,
};

typedef uint64_t TCCapabilities_t;
enum {
    kTCCapabilityNone = 0,
    kTCCapabilityHashType = (1 << 0),
    kTCCapabilityFlags = (1 << 1),
    kTCCapabilityConstraintsCategory = (1 << 2),
};

typedef struct _TrustCacheQueryToken {
    uint64_t trustCache; // TrustCache*
    uint64_t trustCacheEntry; // void*
} TrustCacheQueryToken_t;

typedef struct _TrustCacheMutableRuntime {
    uint64_t loadableTCHead; // TrustCache*
} TrustCacheMutableRuntime_t;

typedef struct _TrustCacheRuntime {
    uint64_t image4RT; // img4_runtime_t*
    bool allowSecondStaticTC;
    bool allowEngineeringTC;
    bool allowLegacyTC;
    uint64_t staticTCHead; // TrustCache*
    uint64_t engineeringTCHead; // TrustCache*
    uint64_t mutableRT; // TrustCacheMutableRuntime*
} TrustCacheRuntime_t;

#endif /* trustcache_h */
