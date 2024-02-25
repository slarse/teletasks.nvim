local finders = require("teletasks.lib.finders")
local async = require("plenary.async")

local function run_finder(finder)
	local complete = false
	local results = {}

	async.run(function()
		finder("", function(result)
			results[#results + 1] = result
		end, function()
			complete = true
		end)
	end)

	vim.wait(2000, function()
		return complete
	end)

	return results
end

local function assert_subset(assert, expected, actual)
	local corresponding_from_actual = {}

	for k, v in pairs(expected) do
		corresponding_from_actual[k] = actual[k]
	end

	assert.is.same(expected, corresponding_from_actual)
end

describe("finders", function()
	it("Should find uncompleted tasks", function()
		local filename = "tests/single_tasks_file/tasks.md"
		local finder = finders.new(filename)
		local results = run_finder(finder)

		assert.is.same(3, #results)

		assert_subset(assert, {
			filename = "tests/single_tasks_file/tasks.md",
			lnum = 1,
			col = 1,
			text = "- [ ] First task",
		}, results[1])
		assert_subset(assert, {
			filename = "tests/single_tasks_file/tasks.md",
			lnum = 3,
			col = 5,
			text = "    - [ ] Subtask that is a task",
		}, results[2])
		assert_subset(assert, {
			filename = "tests/single_tasks_file/tasks.md",
			lnum = 8,
			col = 1,
			text = "- [ ] Second task",
		}, results[3])
	end)
end)
