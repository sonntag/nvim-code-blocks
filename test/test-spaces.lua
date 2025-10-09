-- Test file with spaces instead of tabs

local function outer_function()
  print("outer start")

  local function inner_function()
    print("inner start")
    if true then
      print("inside if")
      local x = 1
      local y = 2
    end
    print("inner end")
  end

  inner_function()
  print("outer end")
end

local function another_function()
  for i = 1, 10 do
    if i % 2 == 0 then
      print("even: " .. i)
    else
      print("odd: " .. i)
    end
  end
end

while true do
  print("infinite loop")
  break
end

outer_function()
another_function()
