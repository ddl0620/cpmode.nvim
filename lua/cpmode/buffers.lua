local M = {}

local function create_scratch(name, opts)
  local buf = vim.api.nvim_create_buf(false, true) -- unlisted, so it stays out of the tab bar

  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'text'
  vim.api.nvim_buf_set_name(buf, name)

  if opts and opts.readonly then
    vim.bo[buf].modifiable = false
  end

  return buf
end

function M.create_input_buffer()
  return create_scratch('CP-Input')
end

function M.create_output_buffer()
  return create_scratch('CP-Output', { readonly = true })
end

function M.get_input_content(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return ''
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines == 0 then
    return ''
  end

  -- Ensure the returned input ends with a newline so programs that expect line-terminated
  -- input (or use getline-like reads) receive proper EOF/newline semantics.
  return table.concat(lines, '\n') .. '\n'
end

function M.set_output_content(buf, content)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, '\n'))
  vim.bo[buf].modifiable = false
end

function M.clear_buffer(buf, opts)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

  if opts and opts.readonly then
    vim.bo[buf].modifiable = false
  end
end

return M
