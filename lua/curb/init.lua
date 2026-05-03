local M = {}

function currDirPrint()
	print(vim.fn.getcwd())
end

function M.setup()
	vim.api.nvim_create_user_command("Curb", function()
		currDirPrint()
	end, {})
end

return M
