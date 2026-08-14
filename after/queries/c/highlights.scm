; extends

((identifier) @constant
 (#lua-match? @constant "^k[A-Z]"))

((identifier) @keyword.repeat
 (#match? @keyword.repeat "^FOR_ALL.*"))

(function_definition
  type: (type_identifier) @keyword.repeat
  (#match? @keyword.repeat "^FOR_ALL_.*"))

(function_declarator
  (identifier) @annotation
  (#lua-match? @annotation "^FUNC_ATTR_"))
