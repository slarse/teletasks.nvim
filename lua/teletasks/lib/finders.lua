local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")

local tt_finders = {}

function tt_finders.new(target, opts)
	return finders.new_oneshot_job(
		vim.tbl_flatten({
			"rg",
			"--vimgrep",
			"\\- \\[ \\]",
			vim.fn.expand(target),
		}),
		{
			entry_maker = make_entry.gen_from_vimgrep(opts),
		}
	)
end

return tt_finders
