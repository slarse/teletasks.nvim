local function write_in_box(bufnr, match_line, match_column, character)
	local line_index = match_line - 1
	local tick_column = match_column + 2
	vim.api.nvim_buf_set_text(bufnr, line_index, tick_column, line_index, tick_column + 1, { character })
end

local function write_in_box_at_selection(selection, character)
	vim.cmd.edit(selection.filename)
	write_in_box(0, selection.lnum, selection.col, character)
	vim.cmd.write(selection.filename)
end

return {
	write_in_box = write_in_box,
	write_in_box_at_selection = write_in_box_at_selection,
}
