local M = {}
local namespace = vim.api.nvim_create_namespace("curb_extmarks")

local uv = vim.uv or vim.loop
local timer
local loading_extmark_id
local loading_group
local review_states = {}

---@param buf number
---@param start_row number
---@param start_col number
---@param end_row number
---@param end_col number
---@return number
function M.create_extmark(buf, start_row, start_col, end_row, end_col)
	local line_count = vim.api.nvim_buf_line_count(buf)
	if end_row >= line_count then
		end_row = line_count - 1
	end
	local line = vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, false)[1] or ""
	if end_col > #line then
		end_col = #line
	end

	return vim.api.nvim_buf_set_extmark(buf, namespace, start_row, start_col, {
		end_row = end_row,
		end_col = end_col,
		hl_group = "Comment",
	})
end

---@param buf number
---@param extmark_id number
function M.clear_extmark(buf, extmark_id)
	if extmark_id and vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.api.nvim_buf_del_extmark, buf, namespace, extmark_id)
	end
end

---@param buf number
---@param extmark_id number
---@return number|nil, number|nil
function M.get_extmark_rows(buf, extmark_id)
	local mark = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, extmark_id, { details = true })
	if not mark or #mark == 0 then
		return nil, nil
	end
	return mark[1], mark[3].end_row
end

---@param buf number
---@param extmark_id number
function M.start_loading(buf, extmark_id)
	local mark = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, extmark_id, { details = true })
	if not mark or #mark == 0 then
		return
	end

	local s_row, e_row = mark[1], mark[3].end_row
	local original_lines = vim.api.nvim_buf_get_lines(buf, s_row, e_row + 1, false)
	local expected_str = table.concat(original_lines, "\n")

	local spinner_frames = { "𜱩", "𜱪", "◌", "○" }
	local frame = 1

	local function update_spinner()
		loading_extmark_id = vim.api.nvim_buf_set_extmark(buf, namespace, s_row, 0, {
			id = loading_extmark_id,
			virt_lines = { { { " " .. spinner_frames[frame] .. " Curb is processing...", "DiagnosticInfo" } } },
			virt_lines_above = true,
		})
	end

	update_spinner()
	timer = uv.new_timer()
	timer:start(
		0,
		100,
		vim.schedule_wrap(function()
			if not vim.api.nvim_buf_is_valid(buf) then
				M.stop_loading(buf)
				return
			end
			frame = frame % #spinner_frames + 1
			update_spinner()
		end)
	)

	loading_group = vim.api.nvim_create_augroup("CurbLoading_" .. extmark_id, { clear = true })
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = loading_group,
		buffer = buf,
		callback = function()
			local m = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, extmark_id, { details = true })
			if not m or #m or m[1] > m[3].end_row then
				return
			end
			local current_lines = vim.api.nvim_buf_get_lines(buf, m[1], m[3].end_row + 1, false)
			if table.concat(current_lines, "\n") ~= expected_str then
				local cursor = vim.api.nvim_win_get_cursor(0)
				vim.api.nvim_buf_set_lines(buf, m[1], m[3].end_row + 1, false, original_lines)
				pcall(vim.api.nvim_win_set_cursor, 0, cursor)
				vim.notify("Curb: Selection is locked during processing", vim.log.levels.WARN)
			end
		end,
	})
end

---@param buf number
function M.stop_loading(buf)
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
	if loading_extmark_id then
		M.clear_extmark(buf, loading_extmark_id)
		loading_extmark_id = nil
	end
	if loading_group then
		pcall(vim.api.nvim_del_augroup_by_id, loading_group)
		loading_group = nil
	end
end

---@param action string
---@param key string
---@return string
local function action_hint(action, key)
	return string.format("[%s] %s", key, action)
end

---@param state table
local function clear_review_state(state)
	if not state then
		return
	end

	if state.group then
		pcall(vim.api.nvim_del_augroup_by_id, state.group)
	end

	for _, mode in ipairs({ "n", "i" }) do
		if state.accept_key then
			pcall(vim.keymap.del, mode, state.accept_key, { buffer = state.buf })
		end
		if state.reject_key then
			pcall(vim.keymap.del, mode, state.reject_key, { buffer = state.buf })
		end
		if state.reprompt_key then
			pcall(vim.keymap.del, mode, state.reprompt_key, { buffer = state.buf })
		end
	end

	M.clear_extmark(state.buf, state.extmark_id)
	review_states[state.buf] = nil
end

---@param buf number
---@param extmark_id number
---@return number|nil, number|nil, table|nil
local function get_review_region(buf, extmark_id)
	local mark = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, extmark_id, { details = true })
	if not mark or #mark == 0 then
		return nil, nil, nil
	end

	return mark[1], mark[3].end_row, mark
end

---@param buf number
---@param extmark_id number
---@param new_lines string|table
---@param reprompt_cb function
function M.replace_interactive(buf, extmark_id, new_lines, reprompt_cb)
	local s_row, e_row = get_review_region(buf, extmark_id)
	if not s_row then
		return
	end

	local original_lines = vim.api.nvim_buf_get_lines(buf, s_row, e_row + 1, false)

	if type(new_lines) == "string" then
		new_lines = vim.split(new_lines, "\n")
	end
	vim.api.nvim_buf_set_lines(buf, s_row, e_row + 1, false, new_lines)
	M.clear_extmark(buf, extmark_id)

	if review_states[buf] then
		clear_review_state(review_states[buf])
	end

	local config = require("curb.config")
	local accept_key = config.values.accept_key
	local reject_key = config.values.reject_key
	local reprompt_key = config.values.reprompt_key
	local hints = table.concat({
		action_hint("Accept", accept_key),
		action_hint("Reject", reject_key),
		action_hint("Reprompt", reprompt_key),
	}, "  ")

	local interactive_id = vim.api.nvim_buf_set_extmark(buf, namespace, s_row, 0, {
		end_row = s_row + #new_lines - 1,
		end_col = 0,
		hl_group = "DiffAdd",
		virt_lines = { { { hints, "Comment" } } },
	})

	local state = {
		buf = buf,
		extmark_id = interactive_id,
		group = vim.api.nvim_create_augroup("CurbInteractive_" .. interactive_id, { clear = true }),
		accept_key = accept_key,
		reject_key = reject_key,
		reprompt_key = reprompt_key,
	}
	review_states[buf] = state

	vim.api.nvim_create_autocmd({ "BufWipeout" }, {
		group = state.group,
		buffer = buf,
		callback = function()
			clear_review_state(review_states[buf])
		end,
	})

	local function get_current_lines()
		local cur_s, cur_e = get_review_region(buf, interactive_id)
		if not cur_s then
			return nil, nil, nil
		end

		return cur_s, cur_e, vim.api.nvim_buf_get_lines(buf, cur_s, cur_e + 1, false)
	end

	local function finish(action)
		local cur_s, cur_e, current_lines = get_current_lines()
		if not cur_s then
			clear_review_state(state)
			return
		end

		clear_review_state(state)

		if action == "accept" then
			vim.notify("Curb: Applied", vim.log.levels.INFO)
			return
		end

		vim.api.nvim_buf_set_lines(buf, cur_s, cur_e + 1, false, original_lines)
		if action == "reject" then
			vim.notify("Curb: Cancelled", vim.log.levels.WARN)
			return
		end

		local new_mark = M.create_extmark(buf, cur_s, 0, cur_s + #original_lines - 1, 0)
		vim.schedule(function()
			reprompt_cb(new_mark, current_lines)
		end)
	end

	local function map_action(mode, lhs, action)
		vim.keymap.set(mode, lhs, function()
			finish(action)
		end, {
			buffer = buf,
			noremap = true,
			silent = true,
			desc = "Curb " .. action,
		})
	end

	for _, mode in ipairs({ "n", "i" }) do
		map_action(mode, accept_key, "accept")
		map_action(mode, reject_key, "reject")
		map_action(mode, reprompt_key, "reprompt")
	end
end

return M
