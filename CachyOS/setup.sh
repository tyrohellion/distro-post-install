#!/bin/bash
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
    echo -e "\033[0;31m✘ Please do NOT run setup.sh with sudo — run it as your normal user.\033[0m"
    exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()    { echo -e "${CYAN}==> $*${RESET}"; }
success() { echo -e "${GREEN}✔ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $*${RESET}"; }
error()   { echo -e "${RED}✘ $*${RESET}"; }

quiet() { "$@" >/dev/null 2>&1; }

alacritty_config="$HOME/.config/alacritty/alacritty.toml"
env_file="/etc/environment"

sudo pacman -Syu --needed --noconfirm yay

install_packages() {
  local packages=(
    base-devel
    steam
    pfetch
    fastfetch
    ffmpeg
    alacritty
    ttf-noto-sans-cjk-vf
    ttf-jetbrains-mono-nerd
    inter-font
    github-desktop
    xdg-desktop-portal-kde
    xorg-xlsclients
    papirus-icon-theme
    ffmpegthumbs
    openssh
    firefox
    drawy-git
    r2modman-bin
    gamepadla-polling
    konsave
    mangohud
    flatpak
    proton-ge-custom-bin
    fwupd
    tesseract-data-eng
    tesseract
    helium-browser-bin
    syncthing
    cachyos/vscodium
  )
  info "Installing packages..."
  yay -Syu --needed --noconfirm "${packages[@]}"
  success "Packages installed."
}

install_flatpaks() {
  local flatpaks=(
    io.github.kolunmi.Bazaar
    com.dec05eba.gpu_screen_recorder
    com.discordapp.Discord
    io.gitlab.adhami3310.Converter
    io.github.nokse22.asciidraw
    org.gnome.gitlab.YaLTeR.VideoTrimmer
    com.github.unrud.VideoDownloader
    com.github.tenderowl.frog
    org.gnome.design.Lorem
    com.authormore.penpotdesktop
    com.github.taiko2k.avvie
    com.github.tchx84.Flatseal
    io.github.flattool.Warehouse
    io.github.josephmawa.SpellingBee
    io.github.wartybix.Constrict
    org.gnome.Decibels
    org.gnome.design.Lorem
    io.gitlab.theevilskeleton.Upscaler
    org.kde.haruna
    org.gnome.Calculator
    com.spotify.Client
    com.heroicgameslauncher.hgl
    org.onlyoffice.desktopeditors
    com.modrinth.ModrinthApp
    com.vysp3r.ProtonPlus
    org.localsend.localsend_app
    org.kde.kcolorchooser
    org.kde.kdenlive
    org.gimp.GIMP
    org.kde.krita
    org.kde.gwenview
    org.kde.okular
    com.usebottles.bottles
    io.github.plrigaux.sysd-manager
    io.github.shonebinu.Brief
    io.github.seadve.Mousai
    io.github.sitraorg.sitra
    io.github.swordpuffin.hunt
    io.missioncenter.MissionCenter
    org.gnome.Snapshot
  )

  info "Installing Flatpaks..."

  if ! flatpak remote-list | grep -q "^flathub-beta"; then
    flatpak remote-add --if-not-exists --system flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
  fi

  flatpak install -y --noninteractive --system flathub "${flatpaks[@]}"

  if ! flatpak list --app | grep -q "^com.stremio.Stremio"; then
    flatpak install -y flathub-beta --system com.stremio.Stremio
  fi

  success "Flatpaks installed."
}

apply_konsave() {
  local knsv="cachy.knsv"

  if [[ ! -f "$knsv" ]]; then
    warn "Konsave file '$knsv' not found. Skipping."
    return
  fi

  info "Applying konsave profile..."
  quiet konsave -i "$knsv"
  quiet konsave -a cachy
  success "KDE profile applied."
}

set_limine_cmdline() {
  info "Adding custom kernel parameters to Limine..."

  local limine_conf="/etc/default/limine"
  local params=(
    "usbhid.mousepoll=1"
    "xpad.poll_interval=1"
  )

  for param in "${params[@]}"; do
    if ! grep -q "$param" "$limine_conf"; then
      quiet sudo sed -i \
        "s|^\(KERNEL_CMDLINE\[default\]+=\".*\)\"|\1 $param\"|" \
        "$limine_conf"
    fi
  done

  success "Limine kernel parameters updated."
}

setup_fish_config() {
  info "Creating fish config..."
  sudo tee /usr/share/cachyos-fish-config/cachyos-config.fish > /dev/null <<'EOF'
## Source from conf.d before our fish config
source /usr/share/cachyos-fish-config/conf.d/done.fish


## Set values
## Run fastfetch as welcome message
function fish_greeting
    pfetch
end

# Format man pages
set -x MANROFFOPT "-c"
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Set settings for https://github.com/franciscolourenco/done
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low

## Environment setup
# Apply .profile: use this to put fish compatible .profile stuff in
if test -f ~/.fish_profile
  source ~/.fish_profile
end

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        set -p PATH ~/Applications/depot_tools
    end
end


## Functions
# Functions needed for !! and !$ https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ];
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end

# Fish command history
function history
    builtin history --show-time='%F %T '
end

function backup --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

## Useful aliases
# Replace ls with eza
alias ls='eza -al --color=always --group-directories-first --icons' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.="eza -a | grep -e '^\.'"                                     # show only dotfiles

# Common use
alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias hw='hwinfo --short'                                   # Hardware Info
alias big="expac -H M '%m\t%n' | sort -h | nl"              # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'          # List amount of -git packages
alias update='sudo pacman -Syu'

# Get fastest mirrors
alias mirror="sudo cachyos-rate-mirrors"

# Help people new to Arch
alias apt='man pacman'
alias apt-get='man pacman'
alias please='sudo'
alias tb='nc termbin.com 9999'

# Cleanup orphaned packages
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'

# Get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# Recent installed packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

alias fish-config="kate /usr/share/cachyos-fish-config/cachyos-config.fish"

alias up="flatpak update && yay -Syu"
alias xwayland-list="xlsclients -l"
alias firmware-update="sudo fwupdmgr refresh && sudo fwupdmgr get-updates && sudo fwupdmgr update"
alias polling="gamepadla-polling"
alias rl-launch="echo BAKKES=1 PROMPTLESS=1 PROTON_ENABLE_WAYLAND=1 mangohud %command%"
function bakkes-update
    if pacman -Qs bakkesmod-steam > /dev/null
        yay -Rns bakkesmod-steam
        yay -Sy bakkesmod-steam --rebuild --noconfirm




    else
        yay -Sy bakkesmod-steam --rebuild --noconfirm
    end
end
EOF
  success "fish config written."
}

setup_mangohud_config() {
  info "Creating MangoHud config..."
  mkdir -p "$HOME/.config/MangoHud"
  cat > "$HOME/.config/MangoHud/MangoHud.conf" <<'EOF'
  legacy_layout=false
  horizontal
  horizontal_stretch=0
  blacklist=protonplus,lsfg-vk-ui,bazzar,gnome-calculator,pamac-manager,lact,ghb,bitwig-studio,ptyxis,yumex
  gpu_stats
  gpu_load_change
  cpu_stats
  cpu_load_change
  #fps_limit=237
  fps
  fps_color_change
  fps_metrics=avg,0.01
  wine
  #frame_timing
  round_corners=4
  resolution
  display_server
  engine_short_names
  present_mode
  winesync
  toggle_logging=Shift_L+F2
  toggle_hud_position=Shift_R+F11
  output_folder=$HOME/
  fps_limit_method=late
  toggle_fps_limit=Shift_L+F1
  vsync=1
  cellpadding_y=0.25
  background_alpha=0.6
  position=top-left
  toggle_hud=Shift_R+F12
  font_size=18
  gpu_text=GPU
  gpu_color=2e9762
  cpu_text=CPU
  cpu_color=2e97cb
  fps_value=30,60
  fps_color=b22222,fdfd09,39f900
  gpu_load_value=50,90
  gpu_load_color=ffffff,ffaa7f,cc0000
  cpu_load_value=50,90
  cpu_load_color=ffffff,ffaa7f,cc0000
  background_color=000000
  frametime_color=fa8000
  vram_color=ad64c1
  ram_color=c26693
  wine_color=eb5b5b
  engine_color=eb5b5b
  text_color=ffffff
  media_player_color=ffffff
  network_color=e07b85
  battery_color=92e79a
  media_player_format={title};{artist};{album}
EOF
  success "MangoHud config written."
}

customize_alacritty_config() {
  info "Writing Alacritty config..."
  mkdir -p "$(dirname "$alacritty_config")"
  cat > "$alacritty_config" <<'EOF'
[env]
TERM = "xterm-256color"
WINIT_X11_SCALE_FACTOR = "1"

[window]
padding = { x = 16, y = 8 }
dynamic_padding = false
decorations = "full"
title = "alacritty"
opacity = 0.99
decorations_theme_variant = "Dark"

[window.dimensions]
columns = 140
lines = 35

[window.class]
instance = "Alacritty"
general = "Alacritty"

[scrolling]
history = 10000
multiplier = 3

[colors]
draw_bold_text_with_bright_colors = true

[colors.primary]
background = "0x15181e"
foreground = "0xD8DEE9"

[colors.normal]
black = "0x3B4252"
red = "0xBF616A"
green = "0xA3BE8C"
yellow = "0xEBCB8B"
blue = "0x81A1C1"
magenta = "0xB48EAD"
cyan = "0x88C0D0"
white = "0xE5E9F0"

[colors.bright]
black = "0x4C566A"
red = "0xBF616A"
green = "0xA3BE8C"
yellow = "0xEBCB8B"
blue = "0x81A1C1"
magenta = "0xB48EAD"
cyan = "0x8FBCBB"
white = "0xECEFF4"

[font]
size = 12

[font.normal]
family = "JetBrainsMono Nerd Font"
style = "Regular"

[font.bold]
family = "JetBrainsMono Nerd Font"
style = "Bold"

[font.italic]
family = "JetBrainsMono Nerd Font"
style = "Italic"

[font.bold_italic]
family = "JetBrainsMono Nerd Font"
style = "Bold Italic"

[selection]
semantic_escape_chars = ",│`|:\"' ()[]{}<>\t"
save_to_clipboard = true

[cursor]
style = "Underline"
vi_mode_style = "None"
unfocused_hollow = true
thickness = 0.15

[mouse]
hide_when_typing = true

[[mouse.bindings]]
mouse = "Middle"
action = "PasteSelection"

[keyboard]
[[keyboard.bindings]]
key = "Paste"
action = "Paste"

[[keyboard.bindings]]
key = "Copy"
action = "Copy"

[[keyboard.bindings]]
key = "L"
mods = "Control"
action = "ClearLogNotice"

[[keyboard.bindings]]
key = "L"
mods = "Control"
mode = "~Vi"
chars = "\f"

[[keyboard.bindings]]
key = "PageUp"
mods = "Shift"
mode = "~Alt"
action = "ScrollPageUp"

[[keyboard.bindings]]
key = "PageDown"
mods = "Shift"
mode = "~Alt"
action = "ScrollPageDown"

[[keyboard.bindings]]
key = "Home"
mods = "Shift"
mode = "~Alt"
action = "ScrollToTop"

[[keyboard.bindings]]
key = "End"
mods = "Shift"
mode = "~Alt"
action = "ScrollToBottom"

[[keyboard.bindings]]
key = "V"
mods = "Control|Shift"
action = "Paste"

[[keyboard.bindings]]
key = "C"
mods = "Control|Shift"
action = "Copy"

[[keyboard.bindings]]
key = "F"
mods = "Control|Shift"
action = "SearchForward"

[[keyboard.bindings]]
key = "B"
mods = "Control|Shift"
action = "SearchBackward"

[[keyboard.bindings]]
key = "C"
mods = "Control|Shift"
mode = "Vi"
action = "ClearSelection"

[[keyboard.bindings]]
key = "Key0"
mods = "Control"
action = "ResetFontSize"

[general]
live_config_reload = true
working_directory = "None"
EOF

  success "Alacritty config written to $alacritty_config"
}

customize_firefox() {
  info "Customizing Firefox..."
  local firefox_dir="$HOME/.config/mozilla/firefox"
  local tmp=$(mktemp -d)

  quiet git clone --depth=1 https://github.com/tyrohellion/arcadia "$tmp"

  local profile
  profile=$(find "$firefox_dir" -maxdepth 1 -type d -name "*default-release" | head -n 1)

  if [[ -d "$profile" ]]; then
    quiet cp -r "$tmp/chrome" "$profile/"
    quiet cp "$tmp/user.js" "$profile/"
    success "Firefox theme applied."
  else
    warn "Firefox profile not found. Skipping."
  fi

  quiet rm -rf "$tmp"
}

main() {
  install_packages
  install_flatpaks
  apply_konsave
  set_limine_cmdline
  setup_fish_config
  setup_mangohud_config
  customize_alacritty_config
  customize_firefox
  success "All done! Reboot recommended."
}

main
