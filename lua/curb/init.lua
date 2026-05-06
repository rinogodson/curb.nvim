local M = {}

M.config = {
	trigger_key = "<leader>ai",
	accept_key = "<C-y>",
	highlights = {
		normal = "Normal",
		border = "Keyword",
		title_icon = "DiagnosticInfo",
		title_text = "Keyword",
		footer = "Comment",
	},
}

function M.replace_visual()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_line = start_pos[2]
	local end_line = end_pos[2]
	local target_buf = vim.api.nvim_get_current_buf()

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, " ")
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
		border = "single",
		title = {
			{ " ⚡", M.config.highlights.title_icon },
			{ "CURB ", M.config.highlights.title_text },
		},
		title_pos = "center",
		footer = {
			{ " Press ", M.config.highlights.footer },
			{ M.config.accept_key, M.config.highlights.footer },
			{ " to Apply ", M.config.highlights.footer },
		},
		footer_pos = "right",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_set_option_value(
		"winhighlight",
		("NormalFloat:%s,FloatBorder:%s"):format(M.config.highlights.normal, M.config.highlights.border),
		{ win = win }
	)
	vim.api.nvim_set_option_value("wrap", true, { win = win })
	vim.api.nvim_set_option_value("linebreak", true, { win = win })

	-- Dynamic Height change logic
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = buf,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			local total_height = 0

			for _, line in ipairs(lines) do
				local line_width = vim.fn.strdisplaywidth(line)
				local needed_height = math.max(1, math.ceil(line_width / width))
				total_height = total_height + needed_height
			end

			local new_height = math.min(math.max(total_height, 1), 5)

			vim.api.nvim_win_set_config(win, { height = new_height })
		end,
	})

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

	M.config = vim.tbl_deep_extend("force", M.config, user_opts or {})

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
