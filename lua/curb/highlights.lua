local M = {}

local highlight_ns = "Curb"

function M.resolve(specs)
	local function resolve_highlight(name, spec, default_group)
		if type(spec) == "string" then
			if spec:match("^#%x%x%x%x%x%x$") then
				local group = ("%s%s"):format(highlight_ns, name)
				vim.api.nvim_set_hl(0, group, { fg = spec })
				return group
			end

			return spec
		end

		if type(spec) == "table" then
			local group = ("%s%s"):format(highlight_ns, name)
			vim.api.nvim_set_hl(0, group, spec)
			return group
		end

		return default_group
	end

	return {
		normal = resolve_highlight("Normal", specs.normal, "Normal"),
		border = resolve_highlight("Border", specs.border, "Keyword"),
		title_icon = resolve_highlight("TitleIcon", specs.title_icon, "DiagnosticInfo"),
		title_text = resolve_highlight("TitleText", specs.title_text, "Keyword"),
		footer = resolve_highlight("Footer", specs.footer, "Comment"),
	}
end

return M
