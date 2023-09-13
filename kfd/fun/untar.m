#import "untar.h"
#import "../libarchive/archive.h"
#import "../libarchive/archive_entry.h"
#import "Foundation/Foundation.h"

static void errmsg(const char *);
static void fail(const char *, const char *, int);
static int copy_data(struct archive *, struct archive *);
static void msg(const char *);
static void usage(void);
static void warn(const char *, const char *);

int untar(char* pathName, char* destination, int dpkgMode) {
    int verbose = 1;
    int do_extract = 1;

    @autoreleasepool {
        NSString *filePath = [NSString stringWithUTF8String:pathName];
        NSString *destinationDirectory = [NSString stringWithUTF8String:destination];

        struct archive *a;
        struct archive *ext;
        struct archive_entry *entry;
        int r;

        a = archive_read_new();
        ext = archive_write_disk_new();

        /*
         * Note: archive_write_disk_set_standard_lookup() is useful
         * here, but it requires library routines that can add 500k or
         * more to a static executable.
         */
        
        archive_read_support_filter_all(a);
        archive_read_support_format_all(a);

        if (filePath.UTF8String != NULL && strcmp(filePath.UTF8String, "-") == 0)
            filePath = NULL;
        if ((r = archive_read_open_filename(a, filePath.UTF8String, 10240)))
            fail("archive_read_open_filename()",
                 archive_error_string(a), r);
        for (;;) {
            r = archive_read_next_header(a, &entry);
            if (r == ARCHIVE_EOF)
                break;
            if (r != ARCHIVE_OK)
                fail("archive_read_next_header()",
                     archive_error_string(a), 1);
            
            const char* currentFile = archive_entry_pathname(entry);
            NSString* prefixedPathName = [NSString stringWithFormat:@"%@/%s", destinationDirectory, currentFile];
            archive_entry_set_pathname(entry, (dpkgMode ? [prefixedPathName stringByReplacingOccurrencesOfString:@"/var/jb" withString:@""] : prefixedPathName).UTF8String);
            
            if (verbose || !do_extract)
                msg(archive_entry_pathname(entry));
            if (do_extract) {
                r = archive_write_header(ext, entry);
                if (r != ARCHIVE_OK)
                    warn("archive_write_header()",
                         archive_error_string(ext));
                else {
                    copy_data(a, ext);
                    r = archive_write_finish_entry(ext);
                    if (r != ARCHIVE_OK)
                        fail("archive_write_finish_entry()",
                             archive_error_string(ext), 1);
                }

            }
            if (verbose || !do_extract)
                msg("\n");
        }
        archive_read_close(a);
        archive_read_free(a);

        archive_write_close(ext);
        archive_write_free(ext);
    }
    return 0;
}

static int copy_data(struct archive *ar, struct archive *aw) {
    int r;
    const void *buff;
    size_t size;
#if ARCHIVE_VERSION_NUMBER >= 3000000
    int64_t offset;
#else
    off_t offset;
#endif

    for (;;) {
        r = archive_read_data_block(ar, &buff, &size, &offset);
        if (r == ARCHIVE_EOF)
            return (ARCHIVE_OK);
        if (r != ARCHIVE_OK)
            return (r);
        r = archive_write_data_block(aw, buff, size, offset);
        if (r != ARCHIVE_OK) {
            warn("archive_write_data_block()",
                 archive_error_string(aw));
            return (r);
        }
    }
}

static void msg(const char *m) {
    write(1, m, strlen(m));
}

static void errmsg(const char *m) {
    write(2, m, strlen(m));
}

static void warn(const char *f, const char *m) {
    errmsg(f);
    errmsg(" failed: ");
    errmsg(m);
    errmsg("\n");
}

static void fail(const char *f, const char *m, int r) {
    warn(f, m);
    exit(r);
}

static void usage(void) {
    const char *m = "Usage: untar [-tvx] [-f file] [file]\n";
    errmsg(m);
    exit(1);
}
