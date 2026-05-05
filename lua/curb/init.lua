local M = {}

M.config = {
	trigger_key = "<leader>rino",
	accept_key = "<C-y>",
}

function M.replace_visual()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line = start_pos[2]
	local end_line = end_pos[2]
	local target_buf = vim.api.nvim_get_current_buf()

	local buf = vim.api.nvim_create_buf(false, true)

	local width = 40
	local height = 1
	local ui = vim.api.nvim_list_uis()[1]
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = (ui.width / 2) - (width / 2),
		row = (ui.height / 2) - (height / 2),
		style = "minimal",
		border = "solid",
		title = " Curb Prompt ",
		title_pos = "center",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)
	vim.keymap.set("i", M.config.accept_key, function()
		vim.api.nvim_win_close(win, true)

		local line_count = end_line - start_line + 1
		local replacement = {}

		for i = 1, line_count do
			table.insert(replacement, i, "Curb Output")
		end

		vim.api.nvim_buf_set_lines(target_buf, start_line - 1, end_line, false, replacement)
	end, { buffer = buf, noremap = true, silent = true })

	vim.cmd("startinsert")
end

-- commenting these out because this was a starting nooby point...
-- function CurrDirPrint()
-- 	print(vim.fn.getcwd())
-- end

-- @param user_opts table: User configuration options to override defaults
function M.setup(user_opts)
	-- vim.api.nvim_create_user_command("Curb", function()
	-- 	CurrDirPrint()
	-- end, {})

	M.config = vim.tbl_extend("force", M.config, user_opts or {})

	vim.api.nvim_create_user_command("Curb", function()
		M.replace_visual()
	end, { range = true })

	vim.keymap.set(
		"x",
		M.config.trigger_key,
		":<C-u>lua require('" .. (M._name or "curb") .. "').replace_visual()<CR>",
		{
			noremap = true,
			silent = true,
			desc = "Open Curb prompt for selection",
		}
	)
end

M._name = "curb"

return M
