# Miniplug
Minimalistic plugin manager for ZSH.

It was developed as a drop-in replacement for [zplug](https://github.com/zplug/zplug) and [Antigen](https://github.com/zsh-users/antigen). They both have serious problems and are not maintained anymore.
The suggested [Antibody](https://github.com/getantibody/antibody) is just weird, why would we need a native language like Go to write a plugin manager for the shell?

## Features
- No crashes or double plugin loading when re-sourcing `.zshrc`
- Unlike [Antigen](https://github.com/zsh-users/antigen), Miniplug does not pollute your `$PATH`
- Only bare minimum for managing plugins

## Requirements
- ZSH
- Git
- `awk` (`gawk`)

# Installation
To install Miniplug you need to download [`miniplug.zsh`](./miniplug.zsh) file and source it in your `.zshrc`:
```sh
curl \
  -sL --create-dirs \
  https://git.sr.ht/~yerinalexey/miniplug/blob/master/miniplug.zsh \
  -o $HOME/.miniplug/miniplug.zsh

# Add to zshrc:
source "$HOME/.miniplug/miniplug.zsh"
```
> You can download this file anywhere, `$HOME/.miniplug/miniplug.zsh` is just an example

# Usage
After `miniplug.zsh` file is sourced, you'll get access to `miniplug` CLI
utility. Define plugins using `miniplug plugin <URL>`. Or define a theme using
`miniplug theme <URL>` (theme can be set only once)
> `<URL>` can be URL to Git repo or Github's `user/repo`

After plugins are defined, you can download them using `miniplug install` and
source them using `miniplug load` (should be added to `.zshrc`).

## Example `.zshrc`:
```sh
source "$HOME/.miniplug/miniplug.zsh"

# Define a plugin
miniplug plugin 'zsh-users/zsh-syntax-highlighting'

# Define a theme
miniplug theme 'dracula/zsh'

# Source plugins
miniplug load
```

## Changing plugin folder
Plugins will be downloaded to `~/.miniplug` by default, to change that
location, set `MINIPLUG_HOME` environment variable with a new path:
```sh
export MINIPLUG_HOME="$HOME/.local/share/miniplug"
```

## Updating plugins
To update plugins you can run:
```sh
miniplug update
```

If you want to force plugin not to update, you can detach repo's `HEAD` by running this snippet in plugin folder (`$MINIPLUG_HOME/user/repo`):
```sh
git checkout "$(git log --format=%H | head -1)"
```

After that, plugin will be skipped when you run `miniplug update`

# License
MIT, [learn more](./LICENSE)
