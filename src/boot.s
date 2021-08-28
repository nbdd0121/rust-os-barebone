.intel_syntax noprefix

.extern KERNEL_PMA
.extern KERNEL_VMA

.section .multiboot

# Multiboot header fields. Refer to Multiboot 1.6 Specifications for details
.set .Lmultiboot_magic, 0xE85250D6
.set .Lmultiboot_x86, 0
.set .Lmultiboot_header_length, .Lmultiboot_end - .Lmultiboot_start
.set .Lmultiboot_checksum, -(.Lmultiboot_magic + .Lmultiboot_x86 + .Lmultiboot_header_length)

.align 8
.Lmultiboot_start:
    .long .Lmultiboot_magic
    .long .Lmultiboot_x86
    .long .Lmultiboot_header_length
    .long .Lmultiboot_checksum

    # MULTIBOOT_TAG_TYPE_END
    .value 0
    .value 0
    .long  8
.Lmultiboot_end:

.section .rodata.boot

# Flat GDTs
.Lgdt_start:
    .quad 0
.Lgdt_code:
    .quad 0x00af9a000000ffff
.Lgdt_data:
    .quad 0x00af92000000ffff
.Lgdt_end:

# GDT pointer
.Lgdt_ptr:
    .value .Lgdt_end - .Lgdt_start
    .long  .Lgdt_start

.set .Lcode_selector, .Lgdt_code - .Lgdt_start
.set .Ldata_selector, .Lgdt_data - .Lgdt_start

.section .boot.bss
.align 4096
stack_bottom:
.skip 16384
stack_top:

pml4: .skip 4096
pdpt: .skip 4096
pd:   .skip 4096

.section .text.boot
.code32
.global _boot
.type _boot, @function
_boot:
    mov esp, offset stack_top

    # EBX contains information from multiboot. Save it because it'll be clobbered later.
    push ebx

    #
    # Check if long mode is available
    #

    # Test if CPUID is supported first by try to flip EFLAGS.ID. This bit can
    # only be flipped if CPUID is supported.
    pushfd
    mov eax, [esp]
    xor dword ptr [esp], (1 << 21)
    popfd
    pushfd
    pop ecx
    cmp eax, ecx
    je .Lerror

    # Run CPUID 0x80000000 to check if extended function 0x80000001 is supported.
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .Lerror

    # Run CPUID 0x80000001 and test 29th bit of EDX, the long mode bit
    mov eax, 0x80000001
    cpuid
    test edx, (1 << 29)
    jz .Lerror

    #
    # Setup identity paging
    #

    # Map lower 512GiB to whole address space
    mov eax, offset pdpt + 0b00000011
    mov ecx, 0
0:
    mov pml4[ecx * 8], eax
    mov dword ptr pml4[ecx * 8 + 4], 0
    add ecx, 1
    cmp ecx, 512
    jne 0b

    # Map lower 1GiB to whole 512GiB
    mov eax, offset pd + 0b00000011
    mov ecx, 0
0:
    mov pdpt[ecx * 8], eax
    mov dword ptr pdpt[ecx * 8 + 4], 0
    add ecx, 1
    cmp ecx, 512
    jne 0b

    # Map lower 1GiB linearly
    mov eax, 0b10000011
    mov ecx, 0
0:
    mov pd[ecx * 8], eax
    mov dword ptr pd[ecx * 8 + 4], 0
    add ecx, 1
    cmp ecx, 512
    jne 0b

    #
    # Setup and enter long mode
    #

    # Load page table
    mov eax, offset pml4
    mov cr3, eax

    # Enable CR4.PSE and CR4.PAE
    mov eax, cr4
    or eax, 0x30
    mov cr4, eax

    # Enable EFER.LME (EFER is MSR 0xC0000080)
    mov ecx, 0xC0000080
    rdmsr
    bts eax, 8
    wrmsr

    # Enable CR4.PG
    mov eax, cr0
    bts eax, 31
    mov cr0, eax

    # When CR4.PG = 1 and EFER.LME = 1
    # EFER.LMA will be set to 1 and we've entered long mode.

    # Restore multiboot information from EBP
    pop edi

    # Load new GDT descriptor
    # And perform a far jump to update code selector.
    lgdt [.Lgdt_ptr]
    jmp .Lcode_selector:.Llong_start

.Lerror:
    cli
    hlt

.code64

.Llong_start:
    # Update data selectors
    mov ax, offset .Ldata_selector
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    # _start would be in KERNEL_VMA, so do a indirect jump.
.extern _start
    movabs rax, offset _start
    jmp rax
