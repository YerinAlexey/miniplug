#!/usr/bin/env zsh

# Miniplug - minimalistic plugin manager for ZSH

# Globals
declare MINIPLUG_HOME="${MINIPLUG_HOME:-$HOME/.miniplug}"
declare MINIPLUG_THEME="${MINIPLUG_THEME:-}"
declare MINIPLUG_PLUGINS=()

# Helper functions {{{

# }}}

# Core functions {{{
# Show help message
function __miniplug_usage() {
  echo "Miniplug - minimalistic plugin manager for ZSH"
  echo "Usage: miniplug <command> [arguments]"
  echo "Commands:"
  echo "  plugin - Register a plugin"
  echo "  theme - Register a theme (can be done only once)"
  echo "  install - Install plugins"
  echo "  help - Show this message"
}

# Register a plugin
function __miniplug_plugin() {
  local plugin_url="$1"

  MINIPLUG_PLUGINS+=("$plugin_url")
}

# Register a theme
function __miniplug_theme() {
  local theme_url="$1"

  # Throw an error if theme is already set but not if MINIPLUG_THEME and new theme match
  if [ -n "$MINIPLUG_THEME" ] && [ "$MINIPLUG_THEME" != "$theme_url" ]; then
    echo "Theme is already set"
    return 1
  fi

  MINIPLUG_PLUGINS+=("$theme_url")
  MINIPLUG_THEME="$theme_url"
}

# Install plugins
function __miniplug_install() {
  local plugin_url plugin_name clone_url clone_dest

  # Make sure MINIPLUG_HOME exists
  mkdir -p "$MINIPLUG_HOME"

  for plugin_url in ${MINIPLUG_PLUGINS[*]}; do
    # Get plugin name (last two URL segments)
    plugin_name="$(echo "$plugin_url" | awk -F '/' '{ print $(NF - 1) "/" $NF }')"

    # Get URL for git clone
    clone_url="$(echo "$plugin_url" | awk -F '/' '{
      if (match($0, /^https:\/\//)) {
        print $0
      } else {
        print "https://github.com/" $0
      }
    }')"

    # Where to clone this plugin
    clone_dest="$MINIPLUG_HOME/$plugin_name"

    # Check if plugin is already installed
    if [ -d "$clone_dest" ]; then
      echo "$plugin_url is already installed, skipping"
      continue
    fi

    # Clone
    echo "Installing $plugin_url ..."
    git clone "$clone_url" "$clone_dest" -q || (
      echo "Failed to install $plugin_url, exiting"
      return 1
    )
  done
}
# }}}

# Wrapper command for core functions
function miniplug() {
  case "$1" in
    plugin) __miniplug_plugin "$2" ;;
    theme) __miniplug_theme "$2" ;;
    install) __miniplug_install ;;
    help) __miniplug_usage ;;
    *) __miniplug_usage ;;
  esac
}
