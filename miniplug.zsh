#!/usr/bin/env zsh

# Miniplug - minimalistic plugin manager for ZSH

# Globals
declare MINIPLUG_HOME="${MINIPLUG_HOME:-$HOME/.miniplug}"
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
  echo "  help - Show this message"
}

# Register a plugin
function __miniplug_plugin() {
  local plugin_url="$1"

  MINIPLUG_PLUGINS+=("$plugin_url")
}
# }}}

# Wrapper command for core functions
function miniplug() {
  case "$1" in
    plugin) __miniplug_plugin "$2" ;;
    help) __miniplug_usage ;;
    *) __miniplug_usage ;;
  esac
}
