
[![Build Status](https://www.travis-ci.org/rakus/vimscript-editorconfig.svg?branch=master)](https://www.travis-ci.org/rakus/vimscript-editorconfig)
[![Build status](https://ci.appveyor.com/api/projects/status/p2w1cqxauntyexhg/branch/master?svg=true)](https://ci.appveyor.com/project/rakus/vimscript-editorconfig/branch/master)



# VimScript-EditorConfig

This plugin adds [editorconfig][1] support to Vim.

The plugin is developed and tested for Vim 8.1, but _should_ run on 8.0.1630
and higher.

Also successfully tested with Neovim v0.4.0-609-gaa82f8b.

## Installation

### Vim Pack

The plugin is distributed as package and should be cloned below `pack/{somename}/opt`
in your runtime path (e.g. `~/.vim/pack/github/opt/vimscript-editorconfig`). Then
it can be activated in your .vimrc using the command:

    :packadd! vimscript-editorconfig

If you clone it into `pack/{somename}/start` (e.g.
`~/.vim/pack/github/start/vimscript-editorconfig`) it will be loaded automatically.

After installing read `:help editorconfig`!

## Documentation

The documentation is available in [doc/editorconfig.txt](doc/editorconfig.txt)
or from inside Vim with `:help editorconfig`.

## License & Copyright

The [Vim license][2] (see `:help license` inside Vim) applies to this Vim plugin.

__NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK__

[1]: http://editorconfig.org
[2]: https://github.com/vim/vim/blob/master/runtime/doc/uganda.txt

