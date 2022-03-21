# idris2.kak

A plugin for [Kakoune](https://kakoune.org) which adds syntax highlighting and indentation support for [Idris 2](https://www.idris-lang.org).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

![idris2.kak in action](https://user-images.githubusercontent.com/117874/147911576-fa144563-150a-4afd-a4ba-b4967c1c80d5.png)

## Enabling idris2.kak

To enable `idris2.kak`, either place it somewhere in your autoload directory, source it manually from your `kakrc`, or use a plugin manager such as [`plug.kak`](https://github.com/andreyorst/plug.kak).

## Using idris2.kak

idris2.kak will automatically set the variable `filetype` to `"idris"` for any file with the `idr` extension. Syntax highlighting is then added and the value of `extra_word_chars` is set to include underscores and apostrophes.

That is all `idris2.kak` does by default. Additional functionality is provided via commands.

The commands `idris-newline` and `idris-delete` are intended to be run as hooks. The former will continue comments and documentation, and indent new lines. The latter can be used to unindent a line, if leading white space is deleted.

```kak
hook global WinSetOption filetype=idris %{

    hook window InsertChar \n -group my-idris-indent idris-newline
    hook window InsertDelete ' ' -group my-idris-indent idris-delete

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window my-idris-.* }
}
```

To manually indent or unindent a selection, use the commands `idris-indent` and `idris-unindent`.

## Interactive Editing

This plugin does not add interactive editing capabilities. Consider using the [Idris2 Language Server](https://github.com/idris-community/idris2-lsp) in conjunction with [kak-lsp](https://github.com/kak-lsp/kak-lsp).

### Helper commands
Idris2.kak provides some commands to quickly initiate code actions using kak-lsp:

1. `idris-case` performs a case split.
2. `idris-hole-case` transforms a hole into a case.
3. `idris-hole-with` adds a with-clause for a hole.
4. `idris-hole-lemma` creates a lemma for a hole.
