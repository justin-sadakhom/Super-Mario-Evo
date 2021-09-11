module("utils", package.seeall)

local function deepCopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepCopy(orig_key, copies)] = deepCopy(orig_value, copies)
            end
            setmetatable(copy, deepCopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function union(table1, table2)
  local union = {}
  
  for k, v in pairs(table1) do
    if union[k] == nil then
      union[k] = v
    end
  end
  
  for k, v in pairs(table2) do
    if union[k] == nil then
      union[k] = v
    end
  end
  
  return union
end

local U = {}

U.deepCopy = deepCopy
U.union = union

return U