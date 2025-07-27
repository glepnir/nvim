; extends

((call_expression
  function: (identifier) @function)
  (#lua-match? @function "^%u"))

("mutable" @keyword
 (#has-ancestor? @keyword lambda_expression))
