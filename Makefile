all: image

PREFIX =

OUTPUT = build/target/release/norlit-os
IMAGE = image.iso

.PHONY: all image qemu

-include build/dep

$(OUTPUT): src/main.rs
	cargo build --release
	# Replace absolute directory with relative
	sed "s|$(realpath .)/||g" $(OUTPUT).d | sed -E 's#(build/target/release/norlit-os): (.*)#\1: \2\n\2:#g' > build/dep

$(IMAGE): $(OUTPUT) $(shell find image/ -type f)
	# Verify that the file is multiboot-compliant
	grub-file --is-x86-multiboot2 $(OUTPUT)
	mkdir -p build/image/boot
	$(PREFIX)strip $(OUTPUT) -o build/image/boot/kernel
	rsync -a image/ build/image/
	grub-mkrescue -o $@ build/image

image: $(IMAGE)

qemu: $(IMAGE)
	qemu-system-x86_64 -cdrom $(IMAGE)
