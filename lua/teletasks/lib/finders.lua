local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")

local tt_finders = {}

tt_finders.task_status = {
	completed = {
		name = "completed",
		symbol = "x",
	},
	in_progress = {
		name = "in_progress",
		symbol = " ",
	},
	cancelled = {
		name = "cancelled",
		symbol = "-",
	},
	any = {
		name = "any",
		symbol = ".",
	}
}

function tt_finders.new(target, opts)
	opts = opts or {}
	local task_status = opts.task_status or tt_finders.task_status.in_progress
	local pattern = "\\- \\[" .. task_status.symbol .. "\\]"
	return finders.new_oneshot_job(
		vim.tbl_flatten({
			"rg",
			"--vimgrep",
			pattern,
			vim.fn.expand(target),
		}),
		{
			entry_maker = make_entry.gen_from_vimgrep(opts.telescope_opts),
		}
	)
end

return tt_finders
