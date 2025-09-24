load_profile() {
    if [ -f "$HOME/.profile" ]; then
        source "$HOME/.profile"
    fi
}

omz_plugin_install() {
    local plugin
    local url
    local plugins_dir

    plugin=$(basename "$1")
    url="https://github.com/$1"
    plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    if [ -d "${plugins_dir}/${plugin}" ]; then
        return
    fi

    mkdir -p "${plugins_dir}/${plugin}"

    if command -v git-lfs &>/dev/null; then
        git clone --depth=1 "$url" "${plugins_dir}/${plugin}"
    else
        archive="${url}/archive/master.tar.gz"
        curl -sSfL "$archive" | tar -xz -C "${plugins_dir}/${plugin}" --strip-components=1
    fi
}

load_oh_my_zsh() {
    local omz

    omz="${ZSH:-$HOME/.oh-my-zsh}"
    if [ ! -d "${omz}" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    omz_plugin_install marlonrichert/zsh-autocomplete
    omz_plugin_install qoomon/zsh-lazyload
    omz_plugin_install zsh-users/zsh-autosuggestions
    omz_plugin_install zsh-users/zsh-history-substring-search
    omz_plugin_install zsh-users/zsh-syntax-highlighting

    ZSH_THEME=""

    plugins=(
        git
        docker
        zsh-autocomplete
        zsh-autosuggestions
        zsh-history-substring-search
        zsh-lazyload
        zsh-syntax-highlighting
    )

    if [ -e "${omz}/oh-my-zsh.sh" ]; then
        zstyle ':omz:update' mode disabled
        source "${omz}/oh-my-zsh.sh"
    fi
}

main() {
    load_profile
    load_oh_my_zsh

    zstyle ':completion:\*' menu select

    if [ -f "${ZSH}/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]; then
        source "${ZSH}/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
    else
        autoload bashcompinit && bashcompinit
        autoload -Uz compinit && compinit
    fi


    if command -v mise &>/dev/null; then
        eval "$(mise activate "$(basename "${SHELL}")")"
    fi

    if command -v fzf &>/dev/null; then
        source <(fzf --zsh)
    fi
}

main
