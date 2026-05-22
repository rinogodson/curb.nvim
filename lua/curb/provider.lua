local config = require("curb.config")

local M = {}

local function default_api_key_file()
	return vim.fs.joinpath(vim.fn.stdpath("data"), "curb", "api_key")
end

local function api_key_file_path()
	local provider = config.values.provider or {}
	return provider.api_key_file or default_api_key_file()
end

local function read_api_key_file(path)
	local lines = vim.fn.readfile(path)
	local key = table.concat(lines, "\n"):gsub("%s+$", "")
	if key == "" then
		return nil
	end

	return key
end

local function resolve_api_key()
	local provider = config.values.provider or {}
	local env_name = provider.api_key_env
	local env_key = env_name and vim.env[env_name] or nil
	if env_key and env_key ~= "" then
		return env_key, "env", env_name
	end

	local path = api_key_file_path()
	if vim.fn.filereadable(path) == 1 then
		local ok, file_key = pcall(read_api_key_file, path)
		if ok and file_key then
			return file_key, "file", path
		end
	end

	return nil, nil, env_name
end

local function extract_text(response)
	if type(response) ~= "table" then
		return nil
	end

	local choices = response.choices
	if type(choices) == "table" then
		local first = choices[1]
		if type(first) == "table" and type(first.message) == "table" and type(first.message.content) == "string" then
			return first.message.content
		end
	end

	if type(response.output_text) == "string" and response.output_text ~= "" then
		return response.output_text
	end

	local output = response.output
	if type(output) ~= "table" then
		return nil
	end

	local chunks = {}
	for _, item in ipairs(output) do
		if type(item) == "table" and type(item.content) == "table" then
			for _, content in ipairs(item.content) do
				if type(content) == "table" and type(content.text) == "string" then
					table.insert(chunks, content.text)
				end
			end
		end
	end

	if #chunks == 0 then
		return nil
	end

	return table.concat(chunks, "\n")
end

function M.api_key_path()
	return api_key_file_path()
end

function M.has_api_key()
	local api_key = resolve_api_key()
	return api_key ~= nil
end

function M.set_api_key(api_key)
	local path = api_key_file_path()
	local dir = vim.fs.dirname(path)
	vim.fn.mkdir(dir, "p")
	vim.fn.writefile({ api_key }, path)

	if vim.uv and vim.uv.fs_chmod then
		pcall(vim.uv.fs_chmod, path, 384)
	end

	return path
end

function M.generate_replacement(system_prompt, user_prompt, on_done)
	local provider = config.values.provider or {}
	local api_key, source, source_name = resolve_api_key()

	if not api_key or api_key == "" then
		vim.schedule(function()
			vim.notify(
				string.format("Curb: missing API key. Set $%s or run :CurbSetApiKey", provider.api_key_env),
				vim.log.levels.ERROR
			)
			on_done(nil)
		end)
		return
	end

	local body = vim.json.encode({
		model = provider.model,
		messages = {
			{
				role = "system",
				content = system_prompt,
			},
			{
				role = "user",
				content = user_prompt,
			},
		},
	})

	vim.system({
		"curl",
		"-sS",
		"-X",
		"POST",
		provider.endpoint,
		"-H",
		"Authorization: Bearer " .. api_key,
		"-H",
		"Content-Type: application/json",
		"-d",
		body,
	}, { text = true }, function(obj)
		vim.schedule(function()
			if obj.code ~= 0 then
				local message = "Curb: request failed: " .. (obj.stderr or "unknown error")
				if source == "file" then
					message = message .. string.format(" (using key from %s)", source_name)
				end
				vim.notify(message, vim.log.levels.ERROR)
				on_done(nil)
				return
			end

			local ok, decoded = pcall(vim.json.decode, obj.stdout)
			if not ok then
				vim.notify("Curb: failed to decode model response", vim.log.levels.ERROR)
				on_done(nil)
				return
			end

			local text = extract_text(decoded)
			if not text or text == "" then
				vim.notify("Curb: model response did not contain replacement text", vim.log.levels.ERROR)
				on_done(nil)
				return
			end

			on_done(text)
		end)
	end)
end

return M
