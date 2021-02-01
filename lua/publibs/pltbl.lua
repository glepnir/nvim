local ptbl = {}

-- check value in table
function ptbl.has_value (tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

-- check index in table
function ptbl.has_key (tab,idx)
  for index,_ in pairs(tab) do
    if index == idx then
      return true
    end
  end
  return false
end

return ptbl
