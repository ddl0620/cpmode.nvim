local M = {}

-- Map a file extension to a language key used across the config tables.
local LANG_BY_EXT = {
  cpp = 'cpp',
  cc = 'cpp',
  cxx = 'cpp',
  ['c++'] = 'cpp',
  c = 'c',
  java = 'java',
  py = 'python',
}

function M.detect_language(ext)
  return LANG_BY_EXT[ext]
end

function M.file_info(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  return {
    path = filepath,
    name = vim.fn.fnamemodify(filepath, ':t'),
    dir = vim.fn.fnamemodify(filepath, ':p:h'),
    base = vim.fn.fnamemodify(filepath, ':t:r'),
    ext = vim.fn.fnamemodify(filepath, ':e'),
  }
end

-- Name of the executable produced for a source file.
-- `suffix` distinguishes the debug build from the normal one so the two
-- never overwrite each other.
function M.executable_name(file_info, suffix)
  local name = file_info.base .. (suffix or '')
  if vim.fn.has('win32') == 1 then
    name = name .. '.exe'
  end
  return name
end

-- Resolve the buffer a CP action should apply to.
-- When the cursor sits in one of the I/O panes we fall back to whatever the
-- code pane is showing, so the keymaps work from anywhere in the layout.
function M.resolve_target_buf(state)
  local current_win = vim.api.nvim_get_current_win()
  local target_buf

  if current_win == state.input_win or current_win == state.output_win then
    if state.main_win and vim.api.nvim_win_is_valid(state.main_win) then
      target_buf = vim.api.nvim_win_get_buf(state.main_win)
    end
  else
    target_buf = vim.api.nvim_get_current_buf()
  end

  if not target_buf or not vim.api.nvim_buf_is_valid(target_buf) then
    return nil, 'No valid buffer to use'
  end

  if target_buf == state.input_buf or target_buf == state.output_buf then
    return nil, 'Cannot use an I/O buffer. Focus a code file.'
  end

  if vim.bo[target_buf].buftype ~= '' then
    return nil, 'Current buffer is not a file'
  end

  if vim.api.nvim_buf_get_name(target_buf) == '' then
    return nil, 'Please save the file first'
  end

  return target_buf
end

-- Write the buffer to disk if the user has unsaved edits, so the compiler
-- always sees what is on screen.
function M.save_if_modified(bufnr)
  if vim.bo[bufnr].modified then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd('silent write')
    end)
  end
end

-- Run a shell command asynchronously in `cwd`, without touching Neovim's
-- global working directory. `on_done(ok, output)` is called on the main loop.
function M.run_shell(cmd, cwd, on_done, opts)
  opts = opts or {}

  local system_opts = { cwd = cwd, text = true }
  if opts.stdin then
    system_opts.stdin = opts.stdin
  end
  if opts.timeout then
    system_opts.timeout = opts.timeout * 1000
  end

  vim.system({ 'sh', '-c', cmd }, system_opts, function(res)
    vim.schedule(function()
      on_done(res.code == 0, (res.stdout or '') .. (res.stderr or ''), res.code, res.signal)
    end)
  end)
end

return M
