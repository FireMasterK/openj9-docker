FROM quay.io/centos/centos:stream9 AS build

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade -y && \
    dnf install -y epel-release && \
    dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    dnf install -y \
    alsa-lib-devel \
    automake \
    bind-utils \
    bison \
    bzip2 \
    ca-certificates \
    cpio \
    cups-devel \
    curl-devel \
    elfutils-libelf-devel \
    expat-devel \
    file-devel \
    file-libs \
    flex \
    fontconfig \
    fontconfig-devel \
    freetype-devel \
    gettext \
    gettext-devel \
    glibc \
    glibc-common \
    glibc-devel \
    gmp-devel \
    lbzip2 \
    libffi-devel \
    libstdc++-static \
    libX11-devel \
    libXext-devel \
    libXi-devel \
    libXrandr-devel \
    libXrender-devel \
    libXt-devel \
    libXtst-devel \
    make \
    mesa-libGL-devel \
    mpfr-devel \
    numactl-devel \
    openssh-clients \
    openssh-server \
    openssl-devel \
    perl-CPAN \
    perl-DBI \
    perl-devel \
    perl-ExtUtils-MakeMaker \
    perl-GD \
    perl-IPC-Cmd \
    perl-libwww-perl \
    perl-Time-HiRes \
    systemtap-devel \
    texinfo \
    unzip \
    vim \
    wget \
    xorg-x11-server-Xvfb \
    xz \
    zip \
    zlib-devel \
    autoconf \
    ant \
    git \
    nasm \
    cmake \
    python \
    && dnf clean all

# We need an older version of libdwarf for the build
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y https://vault.centos.org/centos/8/PowerTools/x86_64/os/Packages/libdwarf-devel-20180129-4.el8.x86_64.rpm \
    http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/libdwarf-20180129-4.el8.x86_64.rpm \
    && dnf clean all

RUN cd /tmp \
    && wget --progress=dot:mega -O jdk18.tar.gz https://api.adoptopenjdk.net/v3/binary/latest/18/ga/linux/x64/jdk/openj9/normal/adoptopenjdk \
    && mkdir -p /root/bootjdks/jdk18 \
    && tar -xzf jdk18.tar.gz --directory=/root/bootjdks/jdk18/ --strip-components=1 \
    && rm -f jdk*.tar.gz

WORKDIR /jdk/

RUN git clone --depth=1 https://github.com/ibmruntimes/openj9-openjdk-jdk19.git openj9-openjdk-jdk && \
    cd openj9-openjdk-jdk && \
    bash get_source.sh

WORKDIR /jdk/openj9-openjdk-jdk

RUN bash configure --with-boot-jdk=/root/bootjdks/jdk18 && \
    make JOBS=$(nproc) all && \
    find /jdk/openj9-openjdk-jdk/build/ -name "*.debuginfo" -type f -delete

FROM quay.io/centos/centos:stream9

COPY --from=build /jdk/openj9-openjdk-jdk/build/linux-x86_64-server-release/images/jdk /usr/lib/jvm/jdk-19

ENV JAVA_HOME=/usr/lib/jvm/jdk-19 \
    PATH=/usr/lib/jvm/jdk-19/bin:$PATH

RUN dnf install -y \
    binutils \
    util-linux \
    && dnf clean all
