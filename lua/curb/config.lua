local Keys = {}

local defaults = {
	trigger_key = "<leader>ai",
	accept_key = "<C-y>",
	reject_key = "<C-n>",
	reprompt_key = "<C-p>",
	provider = {
		endpoint = "https://ai.hackclub.com/proxy/v1/chat/completions",
		model = "deepseek/deepseek-v4-flash:free",
		api_key_env = "HACKCLUB_API_KEY",
		api_key_file = nil,
	},
	auditor = {
		model = "deepseek/deepseek-v4-flash:free",
	},
	highlights = {
		normal = "Normal",
		border = "Keyword",
		title_icon = "DiagnosticInfo",
		title_text = "Keyword",
		footer = "Comment",
	},
}

Keys.values = vim.deepcopy(defaults)

function Keys.setup(user_opts)
	Keys.values = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_opts or {})
	return Keys.values
end

return Keys
