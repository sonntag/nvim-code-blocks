-- Test file for anonymous functions and edge cases

-- Anonymous function as argument
local result = map({1, 2, 3}, function(x)
	return x * 2
end)

-- Nested anonymous functions
local nested = filter(items, function(item)
	return transform(item, function(val)
		return val > 10
	end)
end)

-- Anonymous function with multiple statements
process(data, function(d)
	local x = d.value
	local y = x * 2

	if y > 100 then
		return y
	end

	return x
end)

-- Multiple anonymous functions as arguments
combine(
	function(a)
		return a + 1
	end,
	function(b)
		return b * 2
	end
)

-- Anonymous function immediately invoked
local value = (function()
	local temp = 42
	return temp * 2
end)()

-- Table with anonymous function values
local handlers = {
	onClick = function(event)
		print("clicked")
		event.preventDefault()
	end,

	onHover = function(event)
		print("hovering")
	end,
}

-- Anonymous function with empty lines
configure({
	handler = function(req)
		local body = req.body

		local processed = process(body)

		return processed
	end,
})

-- Deeply nested anonymous functions in method chain
api.get("/users")
	:map(function(user)
		return user.name
	end)
	:filter(function(name)
		return #name > 5
	end)
	:forEach(function(name)
		print(name)
	end)

-- Anonymous function with complex block structure
setup({
	before = function()
		for i = 1, 10 do
			if i % 2 == 0 then
				print(i)
			end
		end
	end,

	after = function()
		while condition do
			cleanup()
		end
	end,
})
