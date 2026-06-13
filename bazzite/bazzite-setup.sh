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
    org.gnome.design.Lorem
    com.authormore.penpotdesktop
    com.github.taiko2k.avvie
    io.github.josephmawa.SpellingBee
    io.github.wartybix.Constrict
    org.gnome.design.Lorem
    io.gitlab.theevilskeleton.Upscaler
    org.gnome.Calculator
    com.spotify.Client
    com.heroicgameslauncher.hgl
    org.onlyoffice.desktopeditors
    org.localsend.localsend_app
    org.prismlauncher.PrismLauncher
    org.kde.kcolorchooser
    org.kde.kdenlive
    org.gimp.GIMP
    org.kde.krita
    com.usebottles.bottles
    io.github.plrigaux.sysd-manager
    io.github.shonebinu.Brief
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
    info.febvre.Komikku
    io.github.shiftey.Desktop
    com.feaneron.Boatswain
  )

  info "Installing Flatpaks..."

   flatpak remote-add --if-not-exists --system flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
   flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

   flatpak install --system -y flathub "${flatpaks[@]}"

  #if ! flatpak list --app | grep -q "^com.stremio.Stremio"; then
  #  flatpak install -y flathub-beta --user com.stremio.Stremio
  #fi

  success "Flatpaks installed."
}

apply_konsave() {
  local knsv="bazzite.knsv"

  brew install pipx
  pipx install konsave

  if [[ ! -f "$knsv" ]]; then
    warn "Konsave file '$knsv' not found. Skipping."
    return
  fi

  info "Applying konsave profile..."
  quiet konsave -i "$knsv"
  quiet konsave -a bazzite
  success "KDE profile applied."
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

main() {
  install_flatpaks
  apply_konsave
  setup_mangohud_config
  success "All done! Reboot recommended."
}

main
