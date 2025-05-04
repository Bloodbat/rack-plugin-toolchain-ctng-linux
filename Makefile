# Installation path for executables
LOCAL_DIR := $(PWD)/local
# Local programs should have higher path priority than system-installed programs
export PATH := $(LOCAL_DIR)/bin:$(PATH)

# Allow specifying the number of jobs for toolchain build for systems that need it.
# Due to different build systems used in the toolchain build, just `make -j` won't work here.
# Note: Plugin build uses `$(MAKE)` to inherit `-j` argument from command line.
ifdef JOBS
export JOBS := $(JOBS)
# Define number of jobs for crosstool-ng (uses different argument format)
export JOBS_CT_NG := .$(JOBS)
else
# If `JOBS` is not specified, default to max number of jobs.
export JOBS :=
export JOBS_CT_NG :=
endif

WGET := wget -c
UNTAR := tar -x -f
UNZIP := unzip

SHA256 := sha256check() { echo "$$2  $$1" | sha256sum -c; }; sha256check

# Toolchain build

crosstool-ng := $(LOCAL_DIR)/bin/ct-ng
$(crosstool-ng):
	git clone "https://github.com/crosstool-ng/crosstool-ng.git" crosstool-ng
	cd crosstool-ng && git checkout b49e4c689c4dc8e9c8da5b8f56d7ddf59e485d3b
	cd crosstool-ng && ./bootstrap
	cd crosstool-ng && ./configure --prefix="$(LOCAL_DIR)"
	cd crosstool-ng && make -j $(JOBS)
	cd crosstool-ng && make install
	rm -rf crosstool-ng

toolchain-lin := $(LOCAL_DIR)/x86_64-ubuntu16.04-linux-gnu
toolchain-lin: $(toolchain-lin)
$(toolchain-lin): $(crosstool-ng)
	$(WGET) "https://ftp.gnu.org/gnu/texinfo/texinfo-7.2.tar.gz"
	$(SHA256) texinfo-7.2.tar.gz e86de7dfef6b352aa1bf647de3a6213d1567c70129eccbf8977706d9c91919c8
	$(UNTAR) texinfo-7.2.tar.gz
	rm texinfo-7.2.tar.gz
	cd texinfo-7.2 && ./configure --prefix="$(LOCAL_DIR)"
	cd texinfo-7.2 && make -j $(JOBS)
	cd texinfo-7.2 && make install -j $(JOBS)
	rm -rf texinfo-7.2

	ct-ng x86_64-ubuntu16.04-linux-gnu
	CT_PREFIX="$(LOCAL_DIR)" ct-ng build$(JOBS_CT_NG)
	rm -rf .build .config build.log
	# HACK Copy GL and related include dirs to toolchain sysroot
	chmod +w $(toolchain-lin)/x86_64-ubuntu16.04-linux-gnu/sysroot/usr/include
	cp -r /usr/include/GL $(toolchain-lin)/x86_64-ubuntu16.04-linux-gnu/sysroot/usr/include/
	cp -r /usr/include/KHR $(toolchain-lin)/x86_64-ubuntu16.04-linux-gnu/sysroot/usr/include/
	cp -r /usr/include/X11 $(toolchain-lin)/x86_64-ubuntu16.04-linux-gnu/sysroot/usr/include/
	chmod -w $(toolchain-lin)/x86_64-ubuntu16.04-linux-gnu/sysroot/usr/include

# Docker helpers

dep-ubuntu:
	sudo apt-get install --no-install-recommends \
		ca-certificates \
		git \
		build-essential \
		autoconf \
		automake \
		bison \
		flex \
		gawk \
		libtool-bin \
		libncurses5-dev \
		unzip \
		zip \
		jq \
		libgl-dev \
		libglu-dev \
		git \
		wget \
		curl \
		cmake \
		nasm \
		xz-utils \
		file \
		python3 \
		libxml2-dev \
		libssl-dev \
		texinfo \
		help2man \
		libz-dev \
		rsync \
		xxd \
		perl \
		coreutils \
		zstd \
		markdown \
		libarchive-tools \
		gettext \
		libgmp-dev \
		libmpfr-dev

.NOTPARALLEL: