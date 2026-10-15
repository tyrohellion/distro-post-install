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

install_flatpaks() {
  local flatpaks=(
    io.github.kolunmi.Bazaar
    com.dec05eba.gpu_screen_recorder
    com.discordapp.Discord
    io.gitlab.adhami3310.Converter
    io.github.nokse22.asciidraw
    org.gnome.gitlab.YaLTeR.VideoTrimmer
    com.github.unrud.VideoDownloader
    org.gnome.design.Lorem
    com.authormore.penpotdesktop
    com.github.taiko2k.avvie
    io.github.josephmawa.SpellingBee
    io.github.wartybix.Constrict
    io.gitlab.theevilskeleton.Upscaler
    com.spotify.Client
    com.heroicgameslauncher.hgl
    org.localsend.localsend_app
    org.prismlauncher.PrismLauncher
    org.kde.kdenlive
    org.gimp.GIMP
    org.kde.krita
    com.usebottles.bottles
    io.github.plrigaux.sysd-manager
    io.github.seadve.Mousai
    io.github.swordpuffin.hunt
    com.stremio.Stremio
    org.videolan.VLC
    com.github.zocker_160.SyncThingy
    org.kde.drawy
    it.mijorus.gearlever
    org.fedoraproject.MediaWriter
    io.github.sitraorg.sitra
    io.github.shonebinu.Defuse
    io.github.anil_e.Codd
    io.github.seadve.Mousai
    io.github.Faugus.faugus-launcher
    io.github.shiftey.Desktop
    com.feaneron.Boatswain
  )

  info "Installing Flatpaks..."
   flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
   flatpak install --system -y flathub "${flatpaks[@]}"

  #if ! flatpak list --app | grep -q "^com.stremio.Stremio"; then
  #  flatpak install -y flathub-beta --user com.stremio.Stremio
  #fi

  success "Flatpaks installed."
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
  fps_limit=497
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

apply_konsave() {
  local knsv="solus.knsv"

  if [[ ! -f "$knsv" ]]; then
    warn "Konsave file '$knsv' not found. Skipping."
    return
  fi

  info "Applying konsave profile..."
  quiet konsave -i "$knsv"
  quiet konsave -a solus
  success "KDE profile applied."
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
family = "JetBrains Mono"
style = "Regular"

[font.bold]
family = "JetBrains Mono"
style = "Bold"

[font.italic]
family = "JetBrains Mono"
style = "Italic"

[font.bold_italic]
family = "JetBrains Mono"
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


main() {
  install_flatpaks
  setup_mangohud_config
  apply_konsave
  customize_alacritty_config
  success "All done! Reboot recommended."
}

main
