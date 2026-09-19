if exists("b:current_syntax")
  finish
endif

syntax match GenericConfigValue /\([=:]\)\@<=\s*\S.*$/ contains=GenericConfigString,GenericConfigBoolean,GenericConfigNumber
syntax match GenericConfigBoolean /\c\<\(true\|false\|yes\|no\|on\|off\)\>/ contained
syntax match GenericConfigNumber /\<\d\+\(\.\d\+\)\?\>/ contained
syntax region GenericConfigString start=/"/ skip=/\\./ end=/"/ contained oneline
syntax region GenericConfigString start=/'/ skip=/\\./ end=/'/ contained oneline
syntax match GenericConfigKey /^\s*[^#;=:[:space:]][^=:]*\ze\s*[=:]/
syntax match GenericConfigSeparator /[=:]/
syntax match GenericConfigComment /^\s*[#;].*$/

highlight default link GenericConfigComment Comment
highlight default link GenericConfigKey Identifier
highlight default link GenericConfigSeparator Delimiter
highlight default link GenericConfigValue String
highlight default link GenericConfigString String
highlight default link GenericConfigBoolean Boolean
highlight default link GenericConfigNumber Number

let b:current_syntax = "genericconfig"
