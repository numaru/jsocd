PWD = $(shell pwd)
SRC_DIR = build/native/src
ROOT_DIR = $(PWD)/build/native/usr
DIST_DIR = $(PWD)/build/package
PREFIX = --prefix=$(ROOT_DIR)

ifeq ($(type), debug)
TYPE_FLAGS = -gsource-map -O0
OPENOCD_EMCC_FLAGS += --source-map-base http://localhost:8080/dist/ -fsanitize=address
else
TYPE_FLAGS = -O3
endif

EMCC_CFLAGS = $(TYPE_FLAGS) -pthread
EMMAKE ?= EMCC_CFLAGS="$(EMCC_CFLAGS)" emmake
EMCC ?= CFLAGS="$(EMCC_CFLAGS)" emcc
EMCONFIGURE ?= EM_PKG_CONFIG_PATH="$(ROOT_DIR)/lib/pkgconfig" CFLAGS="$(EMCC_CFLAGS)" emconfigure

OPENOCD_EMCC_FLAGS += --bind
OPENOCD_EMCC_FLAGS += -s ASYNCIFY
OPENOCD_EMCC_FLAGS += -s FORCE_FILESYSTEM=1
OPENOCD_EMCC_FLAGS += -s WASM=1 -s MODULARIZE=1 -s 'EXPORT_NAME="CModule"'
OPENOCD_EMCC_FLAGS += --preload-file $(ROOT_DIR)/share/openocd@/usr/share/openocd

###########
# OPENOCD #
###########
OPENOCD_SRC = $(PWD)/openocd

openocd: $(DIST_DIR)/openocd.js

$(DIST_DIR)/openocd.js: $(ROOT_DIR)/bin/openocd
	mkdir -p $(DIST_DIR); \
	cd $(DIST_DIR); \
	cp $(PWD)/openocd/src/openocd openocd.js; \
	cp $(PWD)/openocd/src/openocd.wasm openocd.wasm; \
	cp $(PWD)/openocd/src/openocd.wasm openocd.data

$(ROOT_DIR)/bin/openocd: $(OPENOCD_SRC)/Makefile
	cd $(OPENOCD_SRC); \
	$(EMMAKE) make install \
	LDFLAGS="$(OPENOCD_EMCC_FLAGS)"

$(OPENOCD_SRC)/Makefile: $(ROOT_DIR)/lib/libjaylink.a $(ROOT_DIR)/lib/libusb-1.0.a $(OPENOCD_SRC)/configure
	cd $(OPENOCD_SRC); \
	$(EMCONFIGURE) ./configure --host=wasm32-emscripten $(PREFIX)

$(OPENOCD_SRC)/configure: $(OPENOCD_SRC)/bootstrap
	cd $(OPENOCD_SRC); \
	./bootstrap

##############
# LIBJAYLINK #
##############
LIBJAYLINK_SRC = $(PWD)/openocd/src/jtag/drivers/libjaylink

libjaylink: $(ROOT_DIR)/lib/libjaylink.a

$(ROOT_DIR)/lib/libjaylink.a: $(LIBJAYLINK_SRC)/Makefile
	cd $(LIBJAYLINK_SRC); \
	$(EMMAKE) make install

$(LIBJAYLINK_SRC)/Makefile: $(LIBJAYLINK_SRC)/configure
	cd $(LIBJAYLINK_SRC); \
	$(EMCONFIGURE) ./configure --host=wasm32-emscripten $(PREFIX)

$(LIBJAYLINK_SRC)/configure: $(LIBJAYLINK_SRC)/autogen.sh
	cd $(LIBJAYLINK_SRC); \
	./autogen.sh

###########
# LIBUSB #
###########
LIBUSB_SRC = $(PWD)/libusb

libusb: $(ROOT_DIR)/lib/libusb-1.0.a

$(ROOT_DIR)/lib/libusb-1.0.a: $(LIBUSB_SRC)/Makefile
	cd $(LIBUSB_SRC); \
	$(EMMAKE) make install

$(LIBUSB_SRC)/Makefile: $(LIBUSB_SRC)/configure
	cd $(LIBUSB_SRC); \
	$(EMCONFIGURE) ./configure --host=wasm32-emscripten $(PREFIX)

$(LIBUSB_SRC)/configure: $(LIBUSB_SRC)/bootstrap.sh
	cd $(LIBUSB_SRC); \
	./bootstrap.sh

.PHONY: openocd libjaylink libusb