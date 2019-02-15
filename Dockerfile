FROM archlinux/base:latest as builder
MAINTAINER François LAROCHE "fl@make.org"

# Let's run stuff
RUN \
  # First, update everything (start by keyring and pacman)
  pacman -Sy && \
  # Install what is needed to build xmr-stak
  pacman -S gcc fakeroot git sudo vim tree iproute2 inetutils --noconfirm --needed && \
  # Generate and set locale en_US.UTF-8
  echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8

RUN \
  # Create an user
  useradd -m -G wheel -s /bin/bash user && \
  # Install sudo and configure it
  pacman -S sudo --noconfirm && \
  echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER user
WORKDIR /home/user
RUN \
  # Get xmr-stak from AUR
  git clone https://aur.archlinux.org/google-chrome.git && \
  cd google-chrome  && makepkg -s --noconfirm && ls -l && cd .. && \
  git clone https://aur.archlinux.org/chromedriver.git && \
  cd chromedriver && makepkg -s --noconfirm && ls -l

FROM makeorg/docker-sbt-coursier:latest

COPY --from=builder \
/home/user/google-chrome/google-chrome-*-x86_64.pkg.tar.xz /tmp/.

COPY --from=builder \
/home/user/chromedriver/chromedriver-*-x86_64.pkg.tar.xz /tmp/.

RUN \
  ls -l /tmp/ && pacman -Sy && \
  # Install it with its dependency
  pacman -U /tmp/google-chrome-*-x86_64.pkg.tar.xz --noconfirm && \
  pacman -U /tmp/chromedriver-*-x86_64.pkg.tar.xz --noconfirm && \
  # Clean cache
  pacman -Scc --noconfirm

