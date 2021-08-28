ENTRY(_boot)

KERNEL_PMA = 0x0000000000100000;
KERNEL_VMA = 0xffffffff80100000;

SECTIONS
{
    . = KERNEL_PMA;

    .text.boot :
    {
        *(.multiboot)
        *(.text.boot)
        *(.rodata.boot)
    }

    . += KERNEL_VMA - KERNEL_PMA;

    .text : AT(ADDR(.text) - KERNEL_VMA + KERNEL_PMA)
    {
        *(.text)
        *(.text.*)
    }

    .rodata : AT(ADDR(.rodata) - KERNEL_VMA + KERNEL_PMA)
    {
        *(.rodata)
        *(.rodata.*)
    }

    . = ALIGN(4K);

    .data : AT(ADDR(.data) - KERNEL_VMA + KERNEL_PMA)
    {
        *(.data)
        *(.data.*)
    }

    .bss : AT(ADDR(.bss) - KERNEL_VMA + KERNEL_PMA)
    {
        *(COMMON)
        *(.bss)
        *(.bss.*)
    }

    . -= KERNEL_VMA - KERNEL_PMA;

    /* Boot-only BSS located at the end so it can be reclaimed */
    .bss.boot :
    {
        *(.boot.bss)
    }

    /DISCARD/ : { *.* }
}
