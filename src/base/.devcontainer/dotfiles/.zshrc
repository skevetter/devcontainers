if [ -f "$HOME/.config/starship/starship.toml" ]; then
    export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
fi

if [ ! -d "$HOME/.local/bin" ]; then
    mkdir -p "$HOME/.local/bin"
fi

if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$HOME/.local/bin/" --yes
fi

eval "$(starship init "$(basename "${SHELL}")")"
