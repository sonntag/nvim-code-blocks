-- Test file for nvim-code-blocks

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

outer_function()
