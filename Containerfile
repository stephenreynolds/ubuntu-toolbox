# Base toolbox image
FROM docker.io/library/ubuntu:24.04 AS ubuntu-toolbox

# Remove apt configuration optimized for containers
# Remove docker-gzip-indexes to help with "command-not-found"
RUN rm /etc/apt/apt.conf.d/docker-gzip-indexes /etc/apt/apt.conf.d/docker-no-languages

# Enable myhostname nss plugin for clean hostname resolution without patching
# hosts (at least for sudo), add it right after 'files' entry. We expect that
# this entry is not present yet. Do this early so that package postinst (which
# adds it too late in the order) skips this step
RUN sed -Ei 's/^(hosts:.*)(\<files\>)\s*(.*)/\1\2 myhostname \3/' /etc/nsswitch.conf

# Restore documentation but do not upgrade all packages
# Install ubuntu-minimal & ubuntu-standard
# Install extra packages as well as libnss-myhostname
COPY toolbox/packages /
RUN sed -Ei '/apt-get (update|upgrade)/s/^/#/' /usr/local/sbin/unminimize && \
    apt-get update && \
    yes | /usr/local/sbin/unminimize && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    ubuntu-minimal ubuntu-standard \
    libnss-myhostname \
    flatpak-xdg-utils \
    $(cat packages | xargs) && \
    rm -rd /var/lib/apt/lists/*
RUN rm /packages

# Fix empty bind-mount to clear selinuxfs (see #337)
RUN mkdir /usr/share/empty

# Add flatpak-spawn to /usr/bin
RUN ln -s /usr/libexec/flatpak-xdg-utils/flatpak-spawn /usr/bin/

# Disable APT ESM hook which tries to enable some systemd services on each apt invocation
RUN rm /etc/apt/apt.conf.d/20apt-esm-hook.conf

# Distrobox image
FROM ubuntu-toolbox AS ubuntu-distrobox

COPY distrobox/packages /
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    $(cat packages | xargs) && \
    rm -rd /var/lib/apt/lists/*
RUN rm /packages

RUN ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/docker && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak && \ 
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree

RUN echo "ALL            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

# WSL image
FROM ubuntu-toolbox AS ubuntu-wsl

# Create wsl.conf
# See https://learn.microsoft.com/en-us/windows/wsl/wsl-config
COPY wsl/wsl.conf /etc/wsl.conf

# Install useful packages for WSL
COPY wsl/packages /
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    $(cat packages | xargs) && \
    rm -rd /var/lib/apt/lists/*
RUN rm /packages
