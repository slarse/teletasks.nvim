local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local finders = require("teletasks.lib.finders")

local action_state = require("telescope.actions.state")

local function commit_finished_task(text, match_column, filename)
	local column = match_column + string.len("- [ ] ")

	local sanitized_text = string.sub(string.gsub(text, "'", ""), column, -1)
	if string.len(sanitized_text) > 35 then
		sanitized_text = string.sub(sanitized_text, 0, 35) .. "..."
	end

	vim.api.nvim_command("!git add " .. filename)
	vim.api.nvim_command("!git commit -m 'Finish task: " .. sanitized_text .. "' " .. filename)
end

local function write_tick(bufnr, match_line, match_column)
	local line_index = match_line - 1
	local tick_column = match_column + 2
	vim.api.nvim_buf_set_text(bufnr, line_index, tick_column, line_index, tick_column + 1, { "x" })
end

local function refresh_preview(current_picker, selection, opts)
	write_tick(current_picker.previewer.state.bufnr, selection.lnum, selection.col)
	local new_finder = finders.new(".", opts)
	current_picker:refresh(new_finder, opts)
end

local function tick_box_at_selection(selection)
	vim.cmd.edit(selection.filename)
	write_tick(0, selection.lnum, selection.col)
	vim.cmd.write(selection.filename)

	commit_finished_task(selection.text, selection.col, selection.filename)
end

TeleTasks = function(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Tasks",
			finder = finders.new(".", opts),
			previewer = conf.grep_previewer(opts),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				local function mark()
					local selection = action_state.get_selected_entry()
					local current_picker = action_state.get_current_picker(prompt_bufnr)

					local bufnr = vim.api.nvim_create_buf(false, true)
					vim.api.nvim_buf_call(bufnr, function()
						tick_box_at_selection(selection)
						refresh_preview(current_picker, selection, opts)
					end)
				end

				map("i", "<c-x>", mark)

				return true
			end,
		})
		:find()
end

vim.api.nvim_create_user_command("Tasks", function()
	TeleTasks(require("telescope.themes").get_dropdown({}))
end, {})
