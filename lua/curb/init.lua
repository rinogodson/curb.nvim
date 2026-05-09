local config = require("curb.config")
local highlights = require("curb.highlights")
local editor = require("curb.editor")
local prompt = require("curb.prompt")
local provider = require("curb.provider")

local M = {}

M.editor = editor
M.prompt = prompt
M._name = "curb"

function M.set_api_key()
	vim.ui.input({ prompt = "Curb API key: " }, function(input)
		if input == nil then
			return
		end

		local api_key = vim.trim(input)
		if api_key == "" then
			vim.notify("Curb: API key was empty", vim.log.levels.WARN)
			return
		end

		local path = provider.set_api_key(api_key)
		vim.notify("Curb: saved API key to " .. path, vim.log.levels.INFO)
	end)
end

function M.api_key_status()
	local path = provider.api_key_path()
	if provider.has_api_key() then
		vim.notify("Curb: API key is configured. File path: " .. path, vim.log.levels.INFO)
		return
	end

	vim.notify("Curb: no API key configured. Run :CurbSetApiKey", vim.log.levels.WARN)
end

function M.replace_visual()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_row = start_pos[2] - 1
	local start_col = start_pos[3] - 1
	local end_row = end_pos[2] - 1
	local end_col = end_pos[3]

	local target_buf = vim.api.nvim_get_current_buf()

	-- Extmark ID here!
	local extmark_id = editor.create_extmark(target_buf, start_row, start_col, end_row, end_col)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, " ")
	local width = 40
	local height = 1
	local ui = vim.api.nvim_list_uis()[1]
	local resolved_highlights = highlights.resolve(config.values.highlights)
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = (ui.width / 2) - (width / 2),
		row = (ui.height / 2) - (height / 2),
		style = "minimal",
		border = "single",
		title = {
			{ " ⚡", resolved_highlights.title_icon },
			{ "CURB ", resolved_highlights.title_text },
		},
		title_pos = "center",
		footer = {
			{ " Press ", resolved_highlights.footer },
			{ config.values.accept_key, resolved_highlights.footer },
			{ " to Apply ", resolved_highlights.footer },
		},
		footer_pos = "right",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_set_option_value(
		"winhighlight",
		("NormalFloat:%s,FloatBorder:%s"):format(resolved_highlights.normal, resolved_highlights.border),
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

	vim.keymap.set("i", config.values.accept_key, function()
		-- Get the user prompt
		local prompt_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local instruction = table.concat(prompt_lines, " "):gsub("^%s*", "")

		-- Prompt Building here
		local sys_prompt, user_prompt = prompt.build(target_buf, start_row, end_row, instruction)

		vim.api.nvim_win_close(win, true)

		provider.generate_replacement(sys_prompt, user_prompt, function(replacement)
			if not replacement then
				editor.clear_extmark(target_buf, extmark_id)
				return
			end

			editor.replace_with_extmark(target_buf, extmark_id, replacement)
		end)
	end, { buffer = buf, noremap = true, silent = true })

	vim.cmd("startinsert")
end

--- @param user_opts table? User configuration options to override defaults.
function M.setup(user_opts)
	config.setup(user_opts)

	vim.api.nvim_create_user_command("Curb", function()
		M.replace_visual()
	end, { range = true })

	vim.api.nvim_create_user_command("CurbSetApiKey", function()
		M.set_api_key()
	end, {})

	vim.api.nvim_create_user_command("CurbApiKeyStatus", function()
		M.api_key_status()
	end, {})

	vim.keymap.set(
		"x",
		config.values.trigger_key,
		":<C-u>lua require('" .. (M._name or "curb") .. "').replace_visual()<CR>",
		{
			noremap = true,
			silent = true,
			desc = "Open Curb prompt for selection",
		}
	)
end

return M
