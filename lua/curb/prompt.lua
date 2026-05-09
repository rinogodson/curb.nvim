local M = {}

local function get_lsp_context(buf, start_row, end_row)
	local context = { diagnostics = {}, symbols = "" }

	for _, diag in ipairs(vim.diagnostic.get(buf)) do
		if diag.lnum >= start_row and diag.lnum <= end_row then
			local severity = vim.diagnostic.severity[diag.severity] or "WARN"
			table.insert(context.diagnostics, string.format("[%s] Line %d: %s", severity, diag.lnum + 1, diag.message))
		end
	end

	local params = { textDocument = vim.lsp.util.make_text_document_params(buf) }
	local results = vim.lsp.buf_request_sync(buf, "textDocument/documentSymbol", params, 1000)

	if results then
		local context_names = {}
		for _, res in pairs(results) do
			if res.result then
				local function traverse(symbols)
					for _, sym in ipairs(symbols) do
						local range = sym.range or (sym.location and sym.location.range)
						if range and range.start.line <= start_row and range["end"].line >= end_row then
							local kind = vim.lsp.protocol.SymbolKind[sym.kind] or "Symbol"
							table.insert(context_names, string.format("%s (%s)", sym.name, kind))
							if sym.children then
								traverse(sym.children)
							end
						end
					end
				end
				traverse(res.result)
			end
		end
		context.symbols = table.concat(context_names, " > ")
	end

	return context
end

--- System & User Prompts
--- @return string system_prompt, string user_prompt
function M.build(buf, start_row, end_row, user_instruction)
	local ft = vim.bo[buf].filetype
	local lines = vim.api.nvim_buf_get_lines(buf, start_row, end_row + 1, false)
	local code_snippet = table.concat(lines, "\n")
	local lsp_context = get_lsp_context(buf, start_row, end_row)

  local system_prompt = string.format([[
    You are editing `%s` code.

    Return ONLY raw replacement code.
    Do NOT use markdown.
    Do NOT wrap code in triple backticks.
    Do NOT include a language label.
    ]], ft)

  local user_prompt = string.format([[
    Instruction:
    %s

    Code:
    %s
    ]], user_instruction, code_snippet)

	if lsp_context.symbols ~= "" then
		user_prompt = user_prompt .. string.format("LSP Enclosing Scope:\n%s\n\n", lsp_context.symbols)
	end

	if #lsp_context.diagnostics > 0 then
		user_prompt = user_prompt
			.. "LSP Diagnostics in Range:\n"
			.. table.concat(lsp_context.diagnostics, "\n")
			.. "\n\n"
	end

	user_prompt = user_prompt .. string.format("Code Snippet:\n```%s\n%s\n```", ft, code_snippet)

	return system_prompt, user_prompt
end

return M
