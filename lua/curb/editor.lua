local M = {}
local namespace = vim.api.nvim_create_namespace("curb_extmarks")

-- Extmark placing
--- @param buf number Buffer handle
--- @param start_row number 0- indexed start row
--- @param start_col number 0 indexed start col
--- @param end_row number 0  indexed end row
--- @param end_col number 0 -indexed end col
--- @return number Extmark ID
function M.create_extmark(buf, start_row, start_col, end_row, end_col)
	local line_length = #vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, false)[1]
	if end_col > line_length then
		end_col = line_length
	end

	return vim.api.nvim_buf_set_extmark(buf, namespace, start_row, start_col, {
		end_row = end_row,
		end_col = end_col,
		hl_group = "Comment",
	})
end

--- @param buf number buffer handle
--- @param extmark_id number The ID returned from create_extmark function
--- @param replacer_fn function|table|string Function that returns the output, or the output lines directly
function M.replace_with_extmark(buf, extmark_id, replacer_fn)
	local mark = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, extmark_id, { details = true })
	if not mark or #mark == 0 then
		return
	end

	local new_lines
	if type(replacer_fn) == "function" then
		new_lines = replacer_fn()
	else
		new_lines = replacer_fn
	end

	if not new_lines then
		return
	end

	if type(new_lines) == "string" then
		new_lines = vim.split(new_lines, "\n")
	end

	local start_row, start_col = mark[1], mark[2]
	local details = mark[3]
	local end_row, end_col = details.end_row, details.end_col

	vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, new_lines)

	M.clear_extmark(buf, extmark_id)
end

-- @arungeorgesaji : Extmark clearer here, make sure to use it
function M.clear_extmark(buf, extmark_id)
	vim.api.nvim_buf_del_extmark(buf, namespace, extmark_id)
end

return M
