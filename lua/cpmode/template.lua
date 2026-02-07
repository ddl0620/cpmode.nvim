local M = {}

local config = require('cpmode.config')

function M.insert_template()
  local buf = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(buf, 'filetype')
  
  -- Get the template for the current filetype
  local template = config.options.templates[filetype]
  
  if not template then
    vim.notify("No template configured for filetype: " .. filetype, vim.log.levels.WARN)
    return
  end
  
  -- Get cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1  -- 0-indexed
  local col = cursor[2]
  
  -- Split template into lines
  local lines = vim.split(template, '\n', { plain = true })
  
  -- Insert the template at cursor position
  vim.api.nvim_buf_set_lines(buf, row, row, false, lines)
  
  -- Move cursor to the solve() function body
  -- Find the line with "void solve() {" or similar
  local solve_line = nil
  for i, line in ipairs(lines) do
    if line:match("void%s+solve%s*%(%)%s*{") or 
       line:match("def%s+solve%s*%(%)%s*:") or
       line:match("public%s+static%s+void%s+solve%s*%(%)%s*{") then
      solve_line = row + i
      break
    end
  end
  
  if solve_line then
    -- Move cursor to inside the solve function (next line, indented)
    vim.api.nvim_win_set_cursor(0, {solve_line + 1, 4})
  else
    -- If no solve function found, move cursor to the end of inserted template
    vim.api.nvim_win_set_cursor(0, {row + #lines, 0})
  end
  
  -- Enter insert mode
  vim.cmd('startinsert!')
  
  vim.notify("Template inserted", vim.log.levels.INFO)
end

return M