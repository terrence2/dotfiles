if !has('conceal') || &enc != 'utf-8'
	finish
endif

syntax match cAssignmentOperator "=" conceal cchar=←
syntax match cNotOperator "!" conceal cchar=¬
" last definition has precedense: we don't want "¬←".
syntax match cNotEqual "!=" conceal cchar=≠

syntax match cOrOperator "||" conceal cchar=∨ "⋁
syntax match cAndOperator "&&" conceal cchar=∧ "⋀
syntax match cFalse "false" conceal cchar=⊥
syntax match cTrue "true" conceal cchar=⊤
syntax match cGreaterOrEqual ">=" conceal cchar=≥
syntax match cLessOrEqual "<=" conceal cchar=≤
syntax match cEqual "==" conceal cchar== "⇌
syntax match cAccessor "->" conceal cchar=→
syntax match cColon ": public" conceal cchar=≼
hi conceal ctermfg=DarkBlue ctermbg=NONE guifg=LightGrey guibg=NONE
