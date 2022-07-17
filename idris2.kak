hook global BufCreate .*[.](idr) %{
    set-option buffer filetype idris
}

hook global WinSetOption filetype=idris %{
    require-module idris

    set-option buffer extra_word_chars "_" "'"
}

hook -group idris-highlight global WinSetOption filetype=idris %{
    add-highlighter window/idris ref idris
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/idris }
}

provide-module -override idris %€

define-command idris-priv-with-word -override -params 1 %{
    evaluate-commands %{
        write
        evaluate-commands -draft %{
            execute-keys "<semicolon><a-i>w"
            lsp-code-action "%arg{1} \?%val{selection}"
        }
        write
    }
}

define-command idris-add-clause -override %{
    evaluate-commands %{
        write
        lsp-code-action 'Add clause'
        write
    }
}

define-command idris-case -override %{
    idris-priv-with-word "Case split on"
}

define-command idris-hole-case -override %{
    idris-priv-with-word "Make case for hole"
}

define-command idris-hole-lemma -override %{
    idris-priv-with-word "Make lemma for hole"
}

define-command idris-hole-with -override %{
    idris-priv-with-word "Make with for hole"
}


define-command -hidden idris-priv-indent %<
    execute-keys i<space><esc><gt>i<backspace><esc>
>

define-command -hidden \
    -docstring "Either increments or decrements the indentation of the line the anchor is on.

The first parameter controls whether to indent or unindent the region. By default, the line is
indented. If, however, the parameter is non-empty, it is treated as the number of whitespace
characters preceding the current line. This information will be used to unindent the line.
" \
    -params 0.. \
    idris-priv-indent-line %{
    evaluate-commands -draft -save-regs '^"/ab' %{
        # Store cursor position in a and yank line up to and including cursor in b
        execute-keys -save-regs '' <semicolon>\"aZGh\"by

        evaluate-commands -save-regs '' %sh{
            alternatives='((?!<gt>-)-[<gt>]\h*$|\b(data|mutual|where|do|if|let|of)\b|\h[=]\h*$)'
            if [ -z "$1" ]; then
                printf 'exec \\"azk<a-x>s(%s|^$)<ret><space>\n' "$alternatives"
            else
                printf 'exec <a-x>s^\h*<ret>d<a-/>(^[^\\n]{,%s}%s|^$)<ret>\n' "$1" "$alternatives"
                printf 'try %%< exec <a-k>^$<ret> > catch %%< exec <a-n> >\n'
            fi
        }


        execute-keys -save-regs '' Z

        try %<
            execute-keys -save-regs '' <a-k>^$<ret>
        > catch %<
            execute-keys -save-regs '' <a-k>(mutual|do|where|let|of)\h*$<ret>\"a<a-z>a<a-&>\)<space>
            idris-priv-indent
        > catch %<
            execute-keys -save-regs '' zGlL<a-k>\A-<gt>\h*$<ret><a-x>s^.*?\w[\w\d']*\h*:\h*\H<ret><semicolon>\"a<a-z>a<a-S>&
        > catch %<
            execute-keys -save-regs '' z<a-k>(data|record)<ret>f=<semicolon>\"a<a-z>a<a-S>&
        > catch %<
            execute-keys -save-regs '' <a-k>where<ret><a-x>s.*(data|interface|implementation)\h+\H<ret><semicolon>\"a<a-z>a<a-S>&
        > catch %<
            execute-keys -save-regs '' z<a-L>s\b(where|do|if|let)\b\h+\H<ret><semicolon>\"a<a-z>a<a-S>&
        > catch %<
            execute-keys -save-regs '' zs\bthen\b<ret>b<semicolon>\"a<a-z>a<a-S>&
        > catch %<
            execute-keys -save-regs '' zs(\b(do|where|let|mutual|of)|\h[=])\h*$<ret>\"a<a-z>a<a-&>\)<space>
            idris-priv-indent
        >
    }
}

define-command idris-newline -docstring "indents newly inserted lines and continues comments.

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
        > catch %< idris-indent >
    >
>

define-command idris-delete \
-docstring "Deindents a line.

This command is intended to be run as a hook" %<
    evaluate-commands -draft -itersel -no-hooks %<
        try %<
            execute-keys -draft Gh<a-k>^\h+\H?\z<ret>
            idris-unindent
        >
    >
>


define-command idris-unindent \
-docstring "unindent selected lines, aligning the result to the surrounding context." \
%<
    evaluate-commands -draft -itersel -no-hooks %<
        execute-keys -save-regs '' <a-x>s^\h+\H<ret>\"ay
        set-register a %sh{
            # subtract 2: cursor is at first non-whitespace character. Subtract
            # one to find the amount of leading whitespace
            count=$(expr $(printf '%s' "$kak_reg_a" | wc -c | tr -d ' ') - 2)
            printf '%s' $count
        }
        try %<
            evaluate-commands -draft -save-regs "a" %<
                idris-priv-indent-line %reg{a}
            >
        > catch %<
            execute-keys Z<a-/>^\h{, %reg{a} }\S<ret><a-z>a<a-&>"
        >
    >
>

define-command idris-indent \
-docstring "indent selected lines, aligning the result to the surrounding context." %<
    evaluate-commands -draft -itersel %<
        try %<
            execute-keys gh
            idris-priv-indent-line
        > catch %<
            execute-keys -draft -itersel k<a-x><a-k>\h[=]\h*$<ret>J<a-&><semicolon>
            idris-priv-indent
        > catch %<
            try %< execute-keys -draft K<a-&> >
        >
    >
>

add-highlighter shared/idris regions
# Based on Idris2's lexer
add-highlighter shared/idris/block-comment region -recurse \{- \{- -\} fill comment
add-highlighter shared/idris/documentation region \|\|\| $ fill documentation
add-highlighter shared/idris/line-comment region ---*(?![}]) $ fill comment

add-highlighter shared/idris/code default-region regions


define-command -hidden add-raw-strings %~
    evaluate-commands %sh[
        for kind in -sl -ml; do
            prefix=''
            for i in $(seq 1 5); do
                quotes='["]'
                [ "$kind" = "-ml" ] && quotes=$quotes'{3}'
                prefix='#'$prefix
                escape='\\'$prefix
                cat <<-EOF
                    add-highlighter shared/idris/string${kind}$i               region         %{$prefix$quotes} %{(?<!$escape)(?:$escape$escape)*$quotes$prefix} regions
                    add-highlighter shared/idris/string${kind}$i/text          default-region fill string
                    add-highlighter shared/idris/string${kind}$i/interpolation region         %<$escape\{> %<\}> ref idris
		EOF
            done
        done
    ]
~

add-highlighter shared/idris/code/string region (?<!')["] (?<!\\)(?:\\\\)*["] regions
add-highlighter shared/idris/code/string/ default-region fill string
add-highlighter shared/idris/code/string/ region (?<!\\)(?:\\\\)*\\\{ \} ref idris
add-raw-strings

add-highlighter shared/idris/code/inline default-region group
add-highlighter shared/idris/code/inline/operator regex  ([-!#$%&*+./<=>?@\\^|~:]) 0:operator
add-highlighter shared/idris/code/inline/float regex '\b\d+\.\d+([eE][-+]?\d+)?\b' 0:value
add-highlighter shared/idris/code/inline/int regex '\b(\d+|0[xX][a-fA-F\d]+|0[oO][0-7]+)\b' 0:value
add-highlighter shared/idris/code/inline/char regex \B'([^\\']|\\.|[\\]u[0-9a-fA-F]{4})'\B 0:value
add-highlighter shared/idris/code/inline/type regex \b([A-Z][a-zA-Z0-9_']*|_)\b 0:type
add-highlighter shared/idris/code/inline/meta-variable regex \B(\?[a-z][a-zA-Z0-9_']*)\b 0:variable
add-highlighter shared/idris/code/inline/keyword regex \b(data|record|interface|implementation|where|parameters|mutual|using|auto|impossible|default|constructor|do|case|of|rewrite|with|let|in|forall|noHints|uniqueSearch|search|external|noNewtype|containedin=idris2Brackets|if|then|else)\b 0:keyword
add-highlighter shared/idris/code/inline/underscore regex \b_\b 0:variable
add-highlighter shared/idris/code/inline/module regex \h*(module)\h+(([A-Z][\w\d_']*\.)*[A-Z][\w\d_']*)\b 1:keyword 2:module 3:module
add-highlighter shared/idris/code/inline/import regex \h*(import)(\s+public)?\s+(([A-Z][\w\d_']*\.)*[A-Z][\w\d_']*)(\h*as\h*([A-Z][\w\d_']*))?\b 1:keyword 2:keyword 3:module 4:module 5:keyword 6:module
add-highlighter shared/idris/code/inline/visibility regex \b(private|export|public\ export)\b 0:attribute
add-highlighter shared/idris/code/inline/totality regex \b(total|partial|covering)\b 0:attribute
add-highlighter shared/idris/code/inline/pragma regex '%(hide|logging|auto_lazy|unbound_implicits|undotted_record_projections|amibguity_depth|pair|rewrite|integerLit|stringLit|charLit|name|start|allow_overloads|language|default|transform|hint|global_hint|defaulthint|inline|extern|macro|spec|foreign|runElab|tcinline|defaulthint|auto_implicit_depth)' 0:attribute
add-highlighter shared/idris/code/inline/backtick regex `[a-zA-Z][a-zA-Z0-9_']*` 0:operator
add-highlighter shared/idris/code/inline/introduce regex ([01]\h+)?\b([_A-Za-z][a-zA-Z0-9_']*)\h*(?=\h:\h) 0:variable 1:variable
€
