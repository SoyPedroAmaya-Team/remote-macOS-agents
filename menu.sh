#!/bin/bash
# =============================================================================
# Remote macOS Agents - Interactive Menu
# =============================================================================
# Simple menu to run common setup tasks without remembering flags
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# Colores simples
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# Menu
# =============================================================================

show_menu() {
    clear
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║       Remote macOS Agents - Setup Menu                     ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Herramientas${NC}"
    echo "  ─────────────────────────────────────────"
    echo -e "  ${GREEN}1)${NC}  Instalar tools de Homebrew"
    echo -e "  ${GREEN}2)${NC}  Aplicar dotfiles (chezmoi)"
    echo -e "  ${GREEN}3)${NC}  Full setup (tools + dotfiles)"
    echo ""
    echo -e "  ${BOLD}Verificaciones${NC}"
    echo "  ─────────────────────────────────────────"
    echo -e "  ${GREEN}4)${NC}  Ver estado de tools instaladas"
    echo -e "  ${GREEN}5)${NC}  Verificar conectividad de red"
    echo ""
    echo -e "  ${BOLD}Utilidades${NC}"
    echo "  ─────────────────────────────────────────"
    echo -e "  ${GREEN}6)${NC}  Ver ayuda de setup.sh"
    echo ""
    echo -e "  ${RED}0)${NC}  Salir"
    echo ""
    echo -n "  Seleccioná una opcion: "
}

# =============================================================================
# Acciones
# =============================================================================

install_tools() {
    echo ""
    echo -e "${BOLD}═══ Instalando Tools ═══${NC}"
    echo ""
    "${SCRIPT_DIR}/setup.sh" --yes --install-tools
}

apply_dotfiles() {
    echo ""
    echo -e "${BOLD}═══ Aplicando Dotfiles ═══${NC}"
    echo ""
    "${SCRIPT_DIR}/setup.sh" --yes --apply-dotfiles
}

full_setup() {
    echo ""
    echo -e "${BOLD}═══ Full Setup ═══${NC}"
    echo ""
    "${SCRIPT_DIR}/setup.sh" --yes --full-setup
}

check_tools() {
    echo ""
    echo -e "${BOLD}═══ Verificando Tools ═══${NC}"
    echo ""

    local tools=(
        "starship:Shell prompt"
        "chezmoi:Dotfiles manager"
        "nvim:Editor"
        "mise:Runtime manager"
        "pnpm:Node packages"
        "gh:GitHub CLI"
        "rg:ripgrep"
        "eza:ls moderno"
        "jq:JSON processor"
        "bat:cat con colores"
        "fd:find mejorado"
        "lazygit:Git UI"
        "shellcheck:Linter bash"
        "go:Go language"
        "ffmpeg:Video/audio"
        "tree:Directory tree"
    )

    for item in "${tools[@]}"; do
        tool="${item%%:*}"
        desc="${item##*:}"
        if command -v "$tool" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool - $desc"
        else
            echo -e "  ${RED}✗${NC} $tool - $desc"
        fi
    done

    echo ""
    echo -n "Presiona Enter para continuar..."
    read
}

check_network() {
    echo ""
    echo -e "${BOLD}═══ Verificando Red ═══${NC}"
    echo ""

    # Tailscale
    echo -n "  Tailscale: "
    if command -v tailscale &>/dev/null; then
        local status=$(tailscale status 2>/dev/null | head -1)
        if [[ -n "$status" ]]; then
            echo -e "${GREEN}✓ Conectado${NC}"
        else
            echo -e "${YELLOW}⚠ No conectado${NC}"
        fi
    else
        echo -e "${RED}✗ No instalado${NC}"
    fi

    # Git
    echo -n "  Git: "
    if command -v git &>/dev/null; then
        echo -e "${GREEN}✓ $(git --version)${NC}"
    else
        echo -e "${RED}✗ No instalado${NC}"
    fi

    # Homebrew
    echo -n "  Homebrew: "
    if command -v brew &>/dev/null; then
        echo -e "${GREEN}✓ $(brew --version | head -1)${NC}"
    else
        echo -e "${RED}✗ No instalado${NC}"
    fi

    echo ""
    echo -n "Presiona Enter para continuar..."
    read
}

show_help() {
    echo ""
    echo -e "${BOLD}═══ Ayuda de setup.sh ═══${NC}"
    echo ""
    "${SCRIPT_DIR}/setup.sh" --help
    echo ""
    echo -n "Presiona Enter para continuar..."
    read
}

# =============================================================================
# Main
# =============================================================================

main() {
    while true; do
        show_menu
        read choice
        echo ""

        case "$choice" in
            1) install_tools ;;
            2) apply_dotfiles ;;
            3) full_setup ;;
            4) check_tools ;;
            5) check_network ;;
            6) show_help ;;
            0|q|Q) echo "¡Chau!"; exit 0 ;;
            *) echo -e "${RED}Opción inválida${NC}" ;;
        esac

        if [[ "$choice" != "4" && "$choice" != "5" && "$choice" != "6" ]]; then
            echo ""
            echo -n "Presiona Enter para continuar..."
            read
        fi
    done
}

main
