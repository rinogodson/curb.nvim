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
try to read files in detail for this.

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

local function run_agent(messages, api_key, iteration)
	if iteration > 90 then
		vim.schedule(function()
			vim.notify("Curb: Auditor reached max iterations (90).", vim.log.levels.WARN)
		end)
		return
	end

	local provider_opts = config.values.provider
	local model = (config.values.auditor and config.values.auditor.model) or provider_opts.model

	local body = vim.json.encode({
		model = model,
		messages = messages,
	})

	vim.system({
		"curl",
		"-sS",
		"--max-time",
		"60",
		"-X",
		"POST",
		provider_opts.endpoint,
		"-H",
		"Authorization: Bearer " .. api_key,
		"-H",
		"Content-Type: application/json",
		"-d",
		body,
	}, { text = true }, function(obj)
		vim.schedule(function()
			if obj.code ~= 0 then
				vim.notify("Curb: Auditor request failed.", vim.log.levels.ERROR)
				return
			end

			local ok_api, decoded_api = pcall(vim.json.decode, obj.stdout)
			if not ok_api then
				vim.notify("Curb: Failed to decode API JSON.", vim.log.levels.ERROR)
				return
			end

			local raw_ai_text = extract_text(decoded_api)
			if not raw_ai_text then
				vim.notify("Curb: Empty response from auditor.", vim.log.levels.ERROR)
				return
			end

			table.insert(messages, { role = "assistant", content = raw_ai_text })

			-- cleaning if AI is failing
			local cleaned_text = raw_ai_text:gsub("^```json%s*", ""):gsub("```%s*$", "")

			local ok_ai, command = pcall(vim.json.decode, cleaned_text)

			-- this is kinda like the ralph loop, breaks -> ask it again
			if not ok_ai then
				vim.notify("Curb: Auditor sent invalid JSON, asking for retry...", vim.log.levels.WARN)
				table.insert(messages, {
					role = "user",
					content = "System Error: Your response was not valid JSON. Please respond STRICTLY in JSON without markdown wrappers.",
				})
				run_agent(messages, api_key, iteration + 1)
				return
			end

			-- Handle Action: DONE
			if command.action == "done" then
				if command.report then
					show_report(command.report)
					vim.notify("Curb: Auditor finished and provided a report.", vim.log.levels.INFO)
				else
					vim.notify("Curb: Auditor finished but provided no report.", vim.log.levels.ERROR)
				end
				return
			end

			-- Handle Action: READ
			if command.action == "read" and command.file then
				vim.notify("Curb Auditor reading: " .. command.file, vim.log.levels.INFO)

				-- Check if file exists and is readable
				if vim.fn.filereadable(command.file) == 1 then
					local lines = vim.fn.readfile(command.file)
					local content = table.concat(lines, "\n")

					table.insert(messages, {
						role = "user",
						content = string.format(
							"Content of %s:\n```\n%s\n```\nWhat would you like to do next?",
							command.file,
							content
						),
					})
				else
					-- uf File not found
					table.insert(messages, {
						role = "user",
						content = string.format("System Error: File '%s' not found or not readable.", command.file),
					})
				end

				-- the ralph loop
				run_agent(messages, api_key, iteration + 1)
				return
			end

			-- Fallback
			table.insert(messages, {
				role = "user",
				content = "System Error: Unknown action. Use 'read' or 'done'.",
			})
			run_agent(messages, api_key, iteration + 1)
		end)
	end)
end

function M.start_audit()
	local env_name = config.values.provider.api_key_env
	local api_key = vim.env[env_name]

	if not api_key or api_key == "" then
		local key_file = vim.fs.joinpath(vim.fn.stdpath("data"), "curb", "api_key")
		if vim.fn.filereadable(key_file) == 1 then
			api_key = table.concat(vim.fn.readfile(key_file), "")
		else
			vim.notify("Curb: Missing API key for Auditor. Run :CurbSetApiKey", vim.log.levels.ERROR)
			return
		end
	end

	vim.notify("Curb: Starting Agentic Auditor... Gathering project files.", vim.log.levels.INFO)

	-- files retrieving
	local files_list = ""
	local git_files = vim.fn.systemlist({ "git", "ls-files" })
	if vim.v.shell_error == 0 then
		files_list = table.concat(git_files, "\n")
	else
		vim.notify("Curb: Not a Git repository. Audit might be weak.", vim.log.levels.WARN)
	end

	local initial_user_prompt = "Here is the list of files in the project:\n"
		.. files_list
		.. "\n\nWhich file do you want to read first?"

	local messages = {
		{ role = "system", content = SYSTEM_PROMPT },
		{ role = "user", content = initial_user_prompt },
	}

	run_agent(messages, api_key, 1)
end

return M
