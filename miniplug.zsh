#!/usr/bin/env zsh

# Miniplug - minimalistic plugin manager for ZSH

# Helper functions {{{

# }}}

# Core functions {{{
function __miniplug_usage() {
  echo "Miniplug - minimalistic plugin manager for ZSH"
  echo "Usage: miniplug <command> [arguments]"
  echo "Commands:"
  echo "  help - Show this message"
}
# }}}

# Wrapper command for core functions
function miniplug() {
  case "$1" in
    help) __miniplug_usage ;;
    *) __miniplug_usage ;;
  esac
}
