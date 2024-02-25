local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local finders = require("teletasks.lib.finders")
local buffers = require("teletasks.lib.buffers")

local action_state = require("telescope.actions.state")

local function commit_task_state_change(commit_prefix, text, match_column, filename)
	local column = match_column + string.len("- [ ] ")

	local sanitized_text = commit_prefix .. ": " .. string.sub(string.gsub(text, "'", ""), column, -1)
	if string.len(sanitized_text) > 52 then
		sanitized_text = string.sub(sanitized_text, 0, 52 - 3) .. "..."
	end

	vim.api.nvim_command("!git add " .. filename)
	vim.api.nvim_command("!git commit -m '" .. sanitized_text .. "' " .. filename)
end

local function refresh_preview(current_picker, selection, opts)
	buffers.write_in_box(current_picker.previewer.state.bufnr, selection.lnum, selection.col, "x")
	local new_finder = finders.new(".", opts)
	current_picker:refresh(new_finder, opts)
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
				local function mark(checkbox_character, commit_prefix)
					local selection = action_state.get_selected_entry()
					local current_picker = action_state.get_current_picker(prompt_bufnr)

					local bufnr = vim.api.nvim_create_buf(false, true)
					vim.api.nvim_buf_call(bufnr, function()
						buffers.write_in_box_at_selection(selection, checkbox_character)
						commit_task_state_change(commit_prefix, selection.text, selection.col, selection.filename)
						refresh_preview(current_picker, selection, opts)
					end)
				end

				local function finish_task()
					mark("x", "Finish task")
				end
				local function cancel_task()
					mark("-", "Cancel task")
				end

				map("i", "<c-x>", finish_task)
				map("i", "<c-e>", cancel_task)

				return true
			end,
		})
		:find()
end

vim.api.nvim_create_user_command("Tasks", function()
	TeleTasks(require("telescope.themes").get_dropdown({}))
end, {})
