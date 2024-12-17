# Base toolbox image
FROM quay.io/toolbx/arch-toolbox AS arch-distrobox

# Pacman Initialization
# Create build user
RUN sed -i 's/#Color/Color/g' /etc/pacman.conf && \
    printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" | tee -a /etc/pacman.conf && \
    sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/g' /etc/makepkg.conf && \
    pacman-key --init && pacman-key --populate && \
    pacman -Syu --noconfirm && \
    useradd -m --shell=/bin/bash build && usermod -L build && \
    echo "build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    pacman -S --clean --clean

# Install packages Distrobox adds automatically, this speeds up first launch
RUN pacman -S \
    adw-gtk-theme \
    bash-completion \
    bc \
    curl \
    diffutils \
    findutils \
    glibc \
    gnupg \
    inetutils \
    keyutils \
    less \
    lsof \
    man-db \
    man-pages \
    mlocate \
    mtr \
    ncurses \
    nss-mdns \
    openssh \
    pigz \
    pinentry \
    procps-ng \
    rsync \
    shadow \
    sudo \
    tcpdump \
    time \
    traceroute \
    tree \
    tzdata \
    unzip \
    util-linux \
    util-linux-libs \
    vte-common \
    wget \
    words \
    xorg-xauth \
    zip \
    mesa \
    opengl-driver \
    vulkan-intel \
    vte-common \
    vulkan-radeon \
    --noconfirm && \
    rm -rf /var/cache/pacman/pkg/*

# Add paru and install AUR packages
USER build
WORKDIR /home/build
RUN git clone https://aur.archlinux.org/paru-bin.git --single-branch && \
    cd paru-bin && \
    makepkg -si --noconfirm && \
    cd .. && \
    rm -drf paru-bin
USER root
WORKDIR /
RUN sed -i 's/#BottomUp/BottomUp/g' /etc/paru.conf

# Install packages
RUN paru -S --noconfirm \
    bat \
    btop \
    fd \
    fzf \
    git \
    github-cli \
    jq \
    lazygit \
    lf \
    lsd \
    mtr \
    ncmpcpp \
    neovim \
    ripgrep \
    sad \
    starship \
    systemd \
    tmux \
    trash-cli \
    tree \
    unzip \
    wget \
    zoxide

# Cleanup
RUN sed -i 's@#en_US.UTF-8@en_US.UTF-8@g' /etc/locale.gen && \
    userdel -r build && \
    rm -drf /home/build && \
    sed -i '/build ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
    sed -i '/root ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
    rm -rf /tmp/*
