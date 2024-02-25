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

local function refresh_preview(current_picker, selection, checkbox_character, opts)
	buffers.write_in_box(current_picker.previewer.state.bufnr, selection.lnum, selection.col, checkbox_character)
	local new_finder = finders.new(".", opts)
	current_picker:refresh(new_finder, opts.telescope_opts)
end

TeleTasks = function(opts)
	opts = opts or {}
	opts.telescope_opts = require("telescope.themes").get_dropdown({})

	if opts.args == "" then
		opts.task_status = finders.task_status.in_progress
	elseif finders.task_status[opts.args] == nil then
		error("Invalid task status: " .. opts.args)
	else
		opts.task_status = finders.task_status[opts.args]
	end

	pickers
		.new(opts.telescope_opts, {
			prompt_title = "Tasks (" .. opts.task_status.name .. ")",
			finder = finders.new(".", opts),
			previewer = conf.grep_previewer(opts.telescope_opts),
			sorter = conf.generic_sorter(opts.telescope_opts),
			attach_mappings = function(prompt_bufnr, map)
				local function mark(checkbox_character, commit_prefix)
					local selection = action_state.get_selected_entry()
					local current_picker = action_state.get_current_picker(prompt_bufnr)

					local bufnr = vim.api.nvim_create_buf(false, true)
					vim.api.nvim_buf_call(bufnr, function()
						buffers.write_in_box_at_selection(selection, checkbox_character)
						commit_task_state_change(commit_prefix, selection.text, selection.col, selection.filename)
						refresh_preview(current_picker, selection, checkbox_character, opts)
					end)
				end

				local function finish_task()
					mark(finders.task_status.completed.symbol, "Finish task")
				end
				local function cancel_task()
					mark(finders.task_status.cancelled.symbol, "Cancel task")
				end
				local function restart_task()
					mark(finders.task_status.in_progress.symbol, "Restart task")
				end

				map("i", "<c-x>", finish_task)
				map("i", "<c-e>", cancel_task)
				map("i", "<c-r>", restart_task)

				return true
			end,
		})
		:find()
end

vim.api.nvim_create_user_command("Tasks", TeleTasks, { nargs = "?" })
