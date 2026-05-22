local config = require("curb.config")

local M = {}

local function extract_text(response)
	if type(response) == "table" and response.choices and response.choices[1] then
		return response.choices[1].message.content
	end
	return nil
end

local SYSTEM_PROMPT = [[
You are an autonomous expert security auditor and code reviewer.
You have access to the user's project files. 
You must analyze the architecture, find security flaws, and suggest refactors.

You must communicate strictly in valid JSON format. Do NOT wrap your response in markdown blocks (no ```json).

AVAILABLE ACTIONS:
1. To read a file to gain context, output exactly:
{"action": "read", "file": "path/to/file.lua"}

2. When you have enough context and are ready to deliver the final report, output exactly:
{"action": "done", "report": "# Security & Refactor Audit\n<your markdown report here>"}
]]

local function show_report(report_text)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.cmd("vsplit")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)

	local lines = vim.split(report_text, "\n")
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
	vim.api.nvim_set_option_value("wrap", true, { win = win })

	vim.notify("Curb: Audit complete!", vim.log.levels.INFO)
end
