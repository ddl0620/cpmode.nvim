local M = {}

function M.create_input_buffer()
  local buf = vim.api.nvim_create_buf(false, true) -- unlisted, scratch buffer
  
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_name(buf, 'CP-Input')
  
  -- Set filetype for syntax highlighting (optional)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'text')
  
  return buf
end

function M.create_output_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false) -- Read-only initially
  vim.api.nvim_buf_set_name(buf, 'CP-Output')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'text')
  
  return buf
end

function M.get_input_content(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines == 0 then
    return ''
  end

  -- Ensure the returned input ends with a newline so programs that expect line-terminated
  -- input (or use getline-like reads) receive proper EOF/newline semantics.
  return table.concat(lines, '\n') .. '\n'
end

function M.set_output_content(buf, content)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  local lines = vim.split(content, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

function M.clear_buffer(buf, opts)
  local readonly = opts and opts.readonly
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  if readonly then
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end
end

return M