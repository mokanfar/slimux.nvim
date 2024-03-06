local M = {}

M.__target_socket = ""
M.__target_pane = ""
M.__escaped_strings = { '\\', ';', '"', '$', '\'' }

function M.setup(config)
	M.__target_socket = config.target_socket
	M.__target_pane = config.target_pane
	if config.escaped_strings ~= nil then
		M.__escaped_strings = config.escaped_strings
	end
end

function M.get_tmux_socket()
	local tmux = vim.env.TMUX ~= nil and vim.env.TMUX or ""
	local socket = vim.split(tmux, ",")[1]
	return socket
end

function M.get_tmux_window()
	return vim.fn.systemlist("tmux display-message -p '#I'")[1]
end

function M.print_config()
	vim.print(string.format("socket: %s, pane: %s", M.__target_socket, M.__target_pane))
end

function M.configure_target_socket(socket)
	M.__target_socket = socket
end

function M.configure_target_pane(pane)
	M.__target_pane = pane
end

function M.configure_escape_strings(strings)
	M.__escaped_strings = strings
end

local function capture_current_line_text()
    local current_buffer = vim.api.nvim_get_current_buf() -- Get the current buffer ID
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1] -- Get the current line number where the cursor is located
    local line_text = vim.api.nvim_buf_get_lines(current_buffer, cursor_line - 1, cursor_line, false)[1] -- Retrieve the current line's text
    return line_text -- Return the current line's text
end

local function escape(text)
	local escapedString = text
	for _, substring in ipairs(M.__escaped_strings) do
		local escapedSubstring = string.gsub(substring, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
		escapedString = string.gsub(escapedString, escapedSubstring, function(match)
			return "\\" .. match
		end)
	end
	return escapedString
end

local function send(text)
	text = escape(text)
	local flag
	if string.sub(M.__target_socket, 1, 1) == "/" then
		flag = "S"
	else
		flag = "L"
	end
	local cmd = string.format('tmux -%s %s send-keys -t %s -- "%s" Enter', flag, M.__target_socket, M.__target_pane,
		text)
	vim.fn.systemlist(cmd)
end

function M.capture_current_line_text()
	local para = capture_current_line_text()
	send(para)
end
return M
