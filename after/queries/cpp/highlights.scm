; extends

((call_expression
  function: (identifier) @function)
  (#lua-match? @function "^%u"))
