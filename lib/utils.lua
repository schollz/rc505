utils = {}


function utils.sign(value)
  if value>0 then
    return 1
  elseif value<0 then
    return-1
  end
  return 0
end

function utils.sign_cycle(value,d,min,max)
  if d>0 then
    value=value+1
  elseif d<0 then
    value=value-1
  end
  if value>max then
    value=min
  elseif value<min then
    value=max
  end
  return value
end

return utils