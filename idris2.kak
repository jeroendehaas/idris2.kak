hook global BufCreate .*[.](idr) %{
    set-option buffer filetype idris2
}

hook global WinSetOption filetype=idris2 %{
    require-module idris2

    set-option buffer extra_word_chars "_" "'"
}

hook -group idris2-highlight global WinSetOption filetype=idris2 %{
    add-highlighter window/idris2 ref idris2
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/idris2 }
}

provide-module -override idris2 %€

define-command -hidden idris2-priv-indent %<
    execute-keys i<space><esc><gt>i<backspace><esc>
>

define-command -hidden \
    -docstring "Either increments or decrements the indentation of the line the anchor is on.

The first parameter controls whether to indent or unindent the region. By default, the line is
indented. If, however, the parameter is non-empty, it is treated as the number of whitespace
characters preceding the current line. This information will be used to unindent the line.
" \
    -params 0.. \
    idris2-priv-indent-line %<
    evaluate-commands -draft -save-regs '^"/ab' %{
        # Store cursor position in a and yank line up to and including cursor in b
        execute-keys -save-regs '' <semicolon>\"aZGh\"by

        execute-keys -save-regs '' %sh{
            alternatives='([^-]-[<gt>]\h*$|\b(data|mutual|where|do|if|let|of)\b|\h[=]\h*$)'
            if [ -z "$1" ]; then
                printf '\\"azk<a-x>s(%s|^$)<ret><space>' "$alternatives"
            else
                # Find point that is closer to line start than cursor
                count=$(expr "$1" - 1)
                if [ $count -le 0 ]; then
                    count=0
                fi
                printf '<a-x>s^\h*<ret>d<a-/>^[^\\n]{,%s}(%s|$)<ret><a-n>' "$count" "$alternatives"
            fi
        }

        execute-keys -save-regs '' Z

        try %<
            execute-keys -save-regs '' <a-k>^$<ret>
        > catch %<
            execute-keys -save-regs '' <a-k>(mutual|do|where|let|of)\h*$<ret>\"a<a-z>a<a-&>\)<space>
            idris2-priv-indent
        > catch %<
            execute-keys -save-regs '' <a-k>-<gt>\h*$<ret><a-x>s^.*?\w[\w\d']*\h*:\h*\H<ret>\"a<a-z>a<a-S>&
        > catch %<
            execute-keys -save-regs '' <a-k>data<ret>f=<semicolon>\"a<a-z>a<a-S>&
        > catch %<
            execute-keys -save-regs '' <a-k>where<ret><a-x>s.*data\h+\H<ret><semicolon>\"a<a-z>a<a-S>&
        > catch %<
            execute-keys -save-regs '' z<a-L>s\b(where|do|if|let)\b\h+\H<ret><semicolon>\"a<a-z>a<a-S>&
        > catch %<
            execute-keys -save-regs '' zs\bthen\b<ret>b<semicolon>\"a<a-z>a<a-S>&
        > catch %<
            execute-keys -save-regs '' zs(\b(do|where|let|mutual|of)|\h[=])\h*$<ret>\"a<a-z>a<a-&>\)<space>
            idris2-priv-indent
        >
    }
>

define-command idris2-newline -docstring "indents newly inserted lines and continues comments.

This command is intended to be run in a hook after a newline was inserted." \
%<
    # first trim whitespace on past line
    try %< execute-keys -draft -itersel <semicolon> K s \h+$<ret> d >

    evaluate-commands -draft -itersel %<
        execute-keys <semicolon>
        # Continue documentation
        try %< execute-keys -draft k<a-k>s^\|\|\|\h*<ret>y<a-x><a-K>^\|\|\|\h*$<ret> j<a-x>s^\h*<ret>P
        # Continue comment
        > catch %< execute-keys -draft k<a-x>s^---*[^}]\h*<ret>y<a-x><a-K>^---*[^}]\h*$<ret> j<a-x>s^\h*<ret>P
        # Indent line
        > catch %< idris2-indent >
    >
>

define-command idris2-delete \
-docstring "Deindents a line.

This command is intended to be run as a hook" %<
    evaluate-commands -draft -itersel -no-hooks %<
        execute-keys -draft Gh<a-k>^\h+\H?\z<ret>
        idris2-unindent
    >
>


define-command idris2-unindent \
-docstring "unindent selected lines, aligning the result to the surrounding context." \
%<
    evaluate-commands -draft -itersel -no-hooks %<
        execute-keys -save-regs '' <a-x>s^\h+\H<ret>\"ay
        set-register a %sh{
            # subtract 2: cursor is at first non-whitespace character. Subtract
            # one to find the amount of leading whitespace
            count=$(expr $(printf '%s' "$kak_reg_a" | wc -c | tr -d ' ') - 1)
            printf '%s' $count
        }
        try %<
            evaluate-commands -draft -save-regs "a" %<
                idris2-priv-indent-line %reg{a}
            >
        > catch %<
            execute-keys Z<a-/>^\h{, %reg{a} }\S<ret><a-z>a<a-&>"
        >
    >
>

define-command idris2-indent \
-docstring "indent selected lines, aligning the result to the surrounding context." %<
    evaluate-commands -draft -itersel %<
        try %<
            idris2-priv-indent-line
        > catch %<
            execute-keys -draft -itersel k<a-x><a-k>\h[=]\h*$<ret>J<a-&><semicolon>
            idris2-priv-indent
        > catch %<
            try %< execute-keys -draft K<a-&> >
        >
    >
>

define-command -hidden add-raw-string-literal -params 1 %~
    add-highlighter "shared/idris2/code/raw-string-literal%arg{1}" region -match-capture "([#]{%arg{1}})[""]" "[""]([#]{%arg{1}})" regions
    add-highlighter "shared/idris2/code/raw-string-literal%arg{1}/text" default-region fill string
    add-highlighter "shared/idris2/code/raw-string-literal%arg{1}/interpolation" region "\\[#]{%arg{1}}\{" \} ref idris2
~

define-command -hidden add-raw-multiline-string-literal -params 1 %~
    add-highlighter "shared/idris2/code/raw-multiline-string-literal%arg{1}" region -match-capture "([#]{%arg{1}})[""]{3}" "[""]{3}([#]{%arg{1}})" regions
    add-highlighter "shared/idris2/code/raw-multiline-string-literal%arg{1}/text" default-region fill string
    add-highlighter "shared/idris2/code/raw-multiline-string-literal%arg{1}/interpolation" region "\\[#]{%arg{1}}\{" \} ref idris2
~

add-highlighter shared/idris2 regions
# Based on Idris2's lexer
add-highlighter shared/idris2/block-comment region -recurse \{- \{- -\} fill comment
add-highlighter shared/idris2/documentation region \|\|\| $ fill documentation
add-highlighter shared/idris2/line-comment region ---*(?![}]) $ fill comment

add-highlighter shared/idris2/code default-region regions


add-raw-multiline-string-literal 0
add-raw-multiline-string-literal 1
add-raw-multiline-string-literal 2
add-raw-multiline-string-literal 3
add-raw-multiline-string-literal 4

add-raw-string-literal 0
add-raw-string-literal 1
add-raw-string-literal 2
add-raw-string-literal 3
add-raw-string-literal 4


add-highlighter shared/idris2/parens region -recurse \( \( \) ref idris2/code
add-highlighter shared/idris2/braces region -recurse \{ \{ \} ref idris2/code
add-highlighter shared/idris2/brackets region -recurse \[ \[ \] ref idris2/code

add-highlighter shared/idris2/code/inline default-region group
add-highlighter shared/idris2/code/inline/operator regex  ([-!#$%&*+./<=>?@\\^|~:]) 0:operator
add-highlighter shared/idris2/code/inline/float regex '\b\d+\.\d+([eE][-+]?\d+)?\b' 0:value
add-highlighter shared/idris2/code/inline/int regex '\b(\d+|0[xX][a-fA-F\d]+|0[oO][0-7]+)\b' 0:value
add-highlighter shared/idris2/code/inline/char regex \B[']([^\\']|[\\]['"\w\d\\]|[\\]u[0-9a-fA-F]{4})[']\B 0:string
add-highlighter shared/idris2/code/inline/type regex \b([A-Z][a-zA-Z0-9_']*|_)\b 0:type
add-highlighter shared/idris2/code/inline/meta-variable regex \B(\?[a-z][a-zA-Z0-9_']*)\b 0:variable
add-highlighter shared/idris2/code/inline/keyword regex \b(data|record|interface|implementation|where|parameters|mutual|using|auto|impossible|default|constructor|do|case|of|rewrite|with|let|in|forall|noHints|uniqueSearch|search|external|noNewtype|containedin=idris2Brackets|if|then|else)\b 0:keyword
add-highlighter shared/idris2/code/inline/underscore regex \b_\b 0:variable
add-highlighter shared/idris2/code/inline/module regex \h*(module)\h+(([A-Z][\w\d_']*\.)*[A-Z][\w\d_']*)\b 1:keyword 2:module 3:module
add-highlighter shared/idris2/code/inline/import regex \h*(import)(\s+public)?\s+(([A-Z][\w\d_']*\.)*[A-Z][\w\d_']*)(\h*as\h*([A-Z][\w\d_']*))?\b 1:keyword 2:keyword 3:module 4:module 5:keyword 6:module
add-highlighter shared/idris2/code/inline/visibility regex \b(private|export|public\ export)\b 0:attribute
add-highlighter shared/idris2/code/inline/totality regex \b(total|partial|covering)\b 0:attribute
add-highlighter shared/idris2/code/inline/pragma regex '%(hide|logging|auto_lazy|unbound_implicits|undotted_record_projections|amibguity_depth|pair|rewrite|integerLit|stringLit|charLit|name|start|allow_overloads|language|default|transform|hint|global_hint|defaulthint|inline|extern|macro|spec|foreign|runElab|tcinline|defaulthint|auto_implicit_depth)' 0:attribute
add-highlighter shared/idris2/code/inline/backtick regex `[a-zA-Z][a-zA-Z0-9_']*` 0:operator
add-highlighter shared/idris2/code/inline/introduce regex ((?<=[({])\h*([01])\h+)?\b[_a-z][a-zA-Z0-9_']*\h*(?=\h:\h) 0:variable 1:variable
  
€
