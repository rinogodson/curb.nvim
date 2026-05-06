local M = {}

local defaults = {
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

M.values = vim.deepcopy(defaults)

function M.setup(user_opts)
	M.values = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_opts or {})
	return M.values
end

return M
