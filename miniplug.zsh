#!/usr/bin/env zsh

# Miniplug - minimalistic plugin manager for ZSH
#
# Copyright 2020 Alexey Yerin

# Globals
declare MINIPLUG_HOME="${MINIPLUG_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/miniplug}"
declare MINIPLUG_THEME="${MINIPLUG_THEME:-}"
declare MINIPLUG_PLUGINS=()

[ -z "$MINIPLUG_LOADED_PLUGINS" ] && declare MINIPLUG_LOADED_PLUGINS=()

# Helper functions {{{
# Loggers
function __miniplug_success() {
  fmt="$1"
  shift 1
  printf "\x1b[32m$fmt\x1b[0m\n" "$@"
}
function __miniplug_warning() {
  fmt="$1"
  shift 1
  printf "[warn] \x1b[33m$fmt\x1b[0m\n" "$@"
}
function __miniplug_error() {
  fmt="$1"
  shift 1
  printf "[err] \x1b[31m$fmt\x1b[0m\n" "$@"
}

# Friendly wrapper around find
function __miniplug_find() {
  local searchdir="$1"
  local searchterm="$2"

  find "$searchdir" -maxdepth 1 -type f -name "$searchterm" | head -n 1
}

# Check if plugin is already loaded
function __miniplug_check_loaded() {
  local target_plugin="$1" plugin_url

  for plugin_url in ${MINIPLUG_LOADED_PLUGINS[*]}; do
    [ "$target_plugin" = "$plugin_url" ] && return
  done

  return 1
}

# Resolve URL shorthand
# user/repo -> https://github.com/user/repo
function __miniplug_resolve_url() {
  printf '%s' "$1" | awk -F '/' '{
    if (match($0, /^(git|https?):\/\//)) {
      print $0
    } else {
      print "https://github.com/" $0
    }
  }'
}

# Get last two URL path segments
# https://github.com/user/repo -> user/repo
function __miniplug_get_plugin_name() {
  printf '%s' "$1" | awk -F '/' '{ print $(NF - 1) "/" $NF }'
}
# }}}

# Core functions {{{
# Show help message
function __miniplug_usage() {
  echo "Miniplug - minimalistic plugin manager for ZSH"
  echo "Usage: miniplug <command> [arguments]"
  echo "Commands:"
  echo "  plugin <source> - Register a plugin"
  echo "  theme <source> - Register a theme (can be done only once)"
  echo "  install - Install plugins"
  echo "  update - Update plugins"
  echo "  help - Show this message"
  echo "About <source>:"
  echo "  <source> can be either full URL to Git repository or Github's user/repo"
  echo "  Examples: https://gitlab.com/user/repo, zsh-users/repo (expanded to https://github.com/zsh-users/repo)"
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
    __miniplug_error "Theme is already set"
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
    plugin_name="$(__miniplug_get_plugin_name "$plugin_url")"

    # Get URL for git clone
    clone_url="$(__miniplug_resolve_url "$plugin_url")"

    # Where to clone this plugin
    clone_dest="$MINIPLUG_HOME/$plugin_name"

    # Check if plugin is already installed
    if [ -d "$clone_dest" ]; then
      __miniplug_warning "%s is already installed, skipping" "$plugin_url"
      continue
    fi

    # Clone
    printf 'Installing %s ...\n' "$plugin_url"
    git clone "$clone_url" "$clone_dest" -q --depth 1 || (
      __miniplug_error "Failed to install %s, exiting" "$plugin_url"
      return 1
    )
  done
}

# Update plugins
function __miniplug_update() {
  local plugin_url plugin_name plugin_location branch remote diffs

  # Make sure MINIPLUG_HOME exists
  mkdir -p "$MINIPLUG_HOME"

  for plugin_url in ${MINIPLUG_PLUGINS[*]}; do
    # Get plugin name (last two URL segments)
    plugin_name="$(__miniplug_get_plugin_name "$plugin_url")"

    # Where plugin is located
    plugin_location="$MINIPLUG_HOME/$plugin_name"

    # Pull changes from remote
    git -C "$plugin_location" remote update >/dev/null

    # Get current branch and remote
    branch="$(git -C "$plugin_location" branch --show-current)"
    remote="$(git -C "$plugin_location" remote show)"

    [ -z "$branch" ] && __miniplug_warning "%s: HEAD is detached, skipping" "$plugin_url" && continue

    # Check the difference between remote and local branches
    diffs="$(git -C "$plugin_location" diff "$remote/$branch")"

    if [ -n "$diffs" ]; then
      # Pull!
      git -C "$plugin_location" pull -q "$remote" "$branch" && __miniplug_success "%s has been successfully updated!" "$plugin_url"
    else
      __miniplug_warning "%s is up-to-date!" "$plugin_url"
    fi
  done
}

# Load plugins
function __miniplug_load() {
  local plugin_url plugin_name plugin_location source_zsh_plugin source_dotzsh source_zsh_theme

  # Make sure MINIPLUG_HOME exists
  mkdir -p "$MINIPLUG_HOME"

  for plugin_url in ${MINIPLUG_PLUGINS[*]}; do
    # Get plugin name (last two URL segments)
    plugin_name="$(__miniplug_get_plugin_name "$plugin_url")"

    # Where this plugin is located
    plugin_location="$MINIPLUG_HOME/$plugin_name"

    # Check if plugin is installed
    if [ ! -d "$plugin_location" ]; then
      __miniplug_warning "%s is not installed, run 'miniplug install' to install it" "$plugin_url"
      continue
    fi

    # Check if plugin is already loaded
    __miniplug_check_loaded "$plugin_url" && continue

    # 1st source - .plugin.zsh file
    source_zsh_plugin="$(__miniplug_find "$plugin_location" "*.plugin.zsh")"

    if [ -n "$source_zsh_plugin" ]; then
      source "$source_zsh_plugin"
      MINIPLUG_LOADED_PLUGINS+=("$plugin_url")

      continue
    fi

    # 2nd source - .zsh file
    source_dotzsh="$(__miniplug_find "$plugin_location" "*.zsh")"

    if [ -n "$source_dotzsh" ]; then
      source "$source_dotzsh"
      MINIPLUG_LOADED_PLUGINS+=("$plugin_url")

      continue
    fi

    # 3rd source - .zsh-theme file (only for themes)
    if [ "$MINIPLUG_THEME" = "$plugin_url" ]; then
      source_zsh_theme="$(__miniplug_find "$plugin_location" "*.zsh-theme")"

      if [ -n "$source_zsh_theme" ]; then
        source "$source_zsh_theme"
        MINIPLUG_LOADED_PLUGINS+=("$plugin_url")

        continue
      fi
    fi

    # If none of sources has been found
    if [ "$MINIPLUG_THEME" = "$plugin_url" ]; then
      __miniplug_error "No .zsh-theme, .plugin.zsh or .zsh file found, most likely, %s is not a valid ZSH theme" "$plugin_url"
    else
      __miniplug_error "No .plugin.zsh or .zsh file found, most likely, %s is not a valid ZSH plugin" "$plugin_url"
    fi
  done
}
# }}}

# Wrapper command for core functions
function miniplug() {
  case "$1" in
    plugin) __miniplug_plugin "$2" ;;
    theme) __miniplug_theme "$2" ;;
    install) __miniplug_install ;;
    update) __miniplug_update ;;
    load) __miniplug_load ;;
    help) __miniplug_usage ;;
    *) __miniplug_usage ;;
  esac
}
