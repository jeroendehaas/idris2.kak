# idris2.kak

A plugin for [Kakoune](https://kakoune.org) which adds syntax highlighting and indentation support for [Idris 2](https://www.idris-lang.org).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

![idris2.kak in action](https://user-images.githubusercontent.com/117874/147911576-fa144563-150a-4afd-a4ba-b4967c1c80d5.png)

## Enabling idris2.kak

To enable `idris2.kak`, either place it somewhere in your autoload directory, source it manually from your `kakrc`, or use a plugin manager such as [`plug.kak`](https://github.com/andreyorst/plug.kak).

## Using idris2.kak

Once `idris2.kak` is loaded, it will set the variable `filetype` to `"idris2"`. Syntax highlighting is added to buffers of that file type and the value of `extra_word_chars` is set to include underscores and apostrophes.

That is all `idris2.kak` does by default. Additional functionality is provided via commands.

The commands `idris2-newline` and `idris2-delete` are intended to be run as hooks. The former will continue comments and documentation, and indent new lines. The latter can be used to unindent a line, if leading white space is deleted.

```kak
hook global WinSetOption filetype=idris2 %{

    hook window InsertChar \n -group my-idris2-indent idris2-newline
    hook window InsertDelete ' ' -group my-idris2-indent idris2-delete

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window my-idris2-.* }
}
```

To manually indent or unindent a selection, use the commands `idris2-indent` and `idris2-unindent`.

## Interactive Editing

This plugin does not add interactive editing capabilities. Consider using the [Idris2 Language Server](https://github.com/idris-community/idris2-lsp) in conjunction with [kak-lsp](https://github.com/kak-lsp/kak-lsp).
