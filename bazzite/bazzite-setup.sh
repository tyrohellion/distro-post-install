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
    app.zen_browser.zen
    com.brave.Browser
    com.vscodium.codium
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
    page.tesk.Refine
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
  #237 cap for vrr on gnome
  fps_limit = 237
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

setup_mic_volume_script() {
  local mic_script="$HOME/.local/bin/mic-volume-set.sh"

  mkdir -p "$(dirname "$mic_script")"

  cat > "$mic_script" <<'EOF'
#!/usr/bin/env bash

# Retry a few times in case PipeWire isn't ready yet
for i in {1..5}; do
  wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 1.4 && exit 0
  sleep 1
done

exit 1
EOF

  chmod +x "$mic_script"
  success "Mic volume script created at $mic_script"
}

setup_mic_systemd_service() {
  local service_dir="$HOME/.config/systemd/user"
  local service_file="$service_dir/mic-volume.service"

  mkdir -p "$service_dir"

  cat > "$service_file" <<EOF
[Unit]
Description=Set Mic Volume (User)
After=pipewire.service wireplumber.service

[Service]
Type=oneshot
ExecStart=%h/.local/bin/mic-volume-set.sh

[Install]
WantedBy=default.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now mic-volume.service

  success "Mic volume systemd service enabled"
}

main() {
  install_flatpaks
  setup_mangohud_config
  #customize_firefox
  setup_mic_volume_script
  setup_mic_systemd_service
  success "All done! Reboot recommended."
}

main