require("teletasks")
local finders = require("teletasks.lib.finders")
local buffers = require("teletasks.lib.buffers")
local async = require("plenary.async")

local tasks_md = "tests/single_tasks_file/tasks.md"

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

describe("buffers", function()
	describe("write_in_box_at_selection", function()
		local tasks_filename

		before_each(function()
			tasks_filename = os.tmpname()
			local original_file = io.open(tasks_md, "r")
			if original_file == nil then
				error("Could not open file")
			end

			local original = original_file:read("*a")
			original_file:close()

			local tasks_file = io.open(tasks_filename, "w")
			if tasks_file == nil then
				error("Could not open file" .. tasks_filename)
			end

			tasks_file:write(original)
			tasks_file:close()
		end)

		after_each(function()
			os.remove(tasks_filename)
		end)

		it("Should write character at selection", function()
			local selection = {
				lnum = 1,
				col = 1,
				filename = tasks_filename,
				text = "- [ ] First task",
			}
			local character = "x"
			local expected_line = "- [x] First task"

			local bufnr = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_call(bufnr, function()
				buffers.write_in_box_at_selection(selection, character)
			end)

			local file = io.open(tasks_filename, "r")
			local file_first_line = file:read("*l")
			file:close()
			assert.is.same(expected_line, file_first_line)
		end)
	end)
end)

describe("finders", function()
	it("Should find uncompleted tasks", function()
		local finder = finders.new(tasks_md)
		local results = run_finder(finder)

		assert.is.same(3, #results)

		assert_subset(assert, {
			filename = tasks_md,
			lnum = 1,
			col = 1,
			text = "- [ ] First task",
		}, results[1])
		assert_subset(assert, {
			filename = tasks_md,
			lnum = 3,
			col = 5,
			text = "    - [ ] Subtask that is a task",
		}, results[2])
		assert_subset(assert, {
			filename = tasks_md,
			lnum = 8,
			col = 1,
			text = "- [ ] Second task",
		}, results[3])
	end)

	it("Should find completed tasks", function()
		local finder = finders.new(tasks_md, { task_status = finders.task_status.completed })
		local results = run_finder(finder)

		assert.is.same(2, #results)

		assert_subset(assert, {
			filename = tasks_md,
			lnum = 4,
			col = 5,
			text = "    - [x] Completed subtask",
		}, results[1])
		assert_subset(assert, {
			filename = tasks_md,
			lnum = 10,
			col = 1,
			text = "- [x] Completed task",
		}, results[2])
	end)

	it("Should find cancelled tasks", function()
		local finder = finders.new(tasks_md, { task_status = finders.task_status.cancelled })
		local results = run_finder(finder)

		assert.is.same(1, #results)

		assert_subset(assert, {
			filename = tasks_md,
			lnum = 7,
			col = 1,
			text = "- [-] Cancelled task",
		}, results[1])
	end)

	it("Should find all tasks", function()
		local finder = finders.new(tasks_md, { task_status = finders.task_status.any })
		local results = run_finder(finder)

		assert.is.same(6, #results)
	end)
end)
