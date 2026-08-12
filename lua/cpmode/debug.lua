local M = {}

local buffers = require('cpmode.buffers')
local config = require('cpmode.config')
local util = require('cpmode.util')

-- gdb's DAP mode has no "stdinFile" parameter, so the contents of the input
-- pane are written to a real file and fed to the program via shell
-- redirection (see `stdin_args` below).
local function write_input_file(state, file_info)
  local content = buffers.get_input_content(state.input_buf)
  local path = vim.fs.joinpath(file_info.dir, '.' .. file_info.base .. '.cpmode.in')

  local ok, err = pcall(vim.fn.writefile, vim.split(content, '\n'), path)
  if not ok then
    vim.notify('cpmode: could not write debug input file: ' .. tostring(err), vim.log.levels.WARN)
    return nil
  end

  return path
end

-- gdb assigns DAP `args` straight to `inferior.arguments`. A *list* gets each
-- element shell-quoted (so "<" would arrive as a literal argv entry), while a
-- *string* is used verbatim and therefore still goes through the startup
-- shell. Passing a string is what makes redirection work.
local function stdin_args(input_path)
  if not input_path then
    return ''
  end
  return '< ' .. vim.fn.shellescape(input_path)
end

-- Path to the gdb script that keeps `step` inside the user's own code.
function M.skip_file()
  local source = debug.getinfo(1, 'S').source:sub(2)
  local plugin_root = vim.fn.fnamemodify(source, ':h:h:h')
  return vim.fs.joinpath(plugin_root, 'gdb', 'cpmode-skip.gdb')
end

function M.adapter()
  local args = { '-i', 'dap' }

  local skip = M.skip_file()
  if vim.fn.filereadable(skip) == 1 then
    -- Loaded before the DAP handshake, so the skip rules are already active
    -- for the first step.
    table.insert(args, '-x')
    table.insert(args, skip)
  end

  return {
    type = 'executable',
    command = config.options.debugger,
    args = args,
  }
end

-- Build the debug binary and start a DAP session against it.
function M.start()
  local cpmode = require('cpmode')
  local state = cpmode.state

  local ok_dap, dap = pcall(require, 'dap')
  if not ok_dap then
    vim.notify('cpmode: nvim-dap is not installed', vim.log.levels.ERROR)
    return
  end

  local target_buf, err = util.resolve_target_buf(state)
  if not target_buf then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  util.save_if_modified(target_buf)

  local file_info = util.file_info(target_buf)
  local lang = util.detect_language(file_info.ext)

  if not config.options.debug_compile_commands[lang] then
    vim.notify('cpmode: debugging is not supported for .' .. file_info.ext, vim.log.levels.ERROR)
    return
  end

  if vim.fn.executable(config.options.debugger) == 0 then
    vim.notify('cpmode: ' .. config.options.debugger .. ' not found in PATH', vim.log.levels.ERROR)
    return
  end

  if state.active then
    buffers.set_output_content(state.output_buf, 'Building debug binary for ' .. file_info.name .. '...')
  end

  local runner = require('cpmode.runner')
  runner.compile(file_info, lang, 'debug', function(ok, result)
    if not ok then
      if state.active then
        buffers.set_output_content(
          state.output_buf,
          '[Debug build failed: ' .. file_info.name .. ']\n\n' .. result
        )
      end
      vim.notify('Debug build failed: ' .. file_info.name, vim.log.levels.ERROR)
      return
    end

    local input_path = write_input_file(state, file_info)

    if state.active then
      buffers.set_output_content(
        state.output_buf,
        'Debug session started for ' .. file_info.name .. '.\n'
          .. 'Input is taken from the pane above (snapshot taken at launch).\n\n'
          .. 'F9 breakpoint  F8 continue  F10 over  F11 into  F12 out  F7 stop'
      )
    end

    dap.run({
      name = 'cpmode: ' .. file_info.name,
      type = 'cpmode_gdb',
      request = 'launch',
      program = vim.fs.joinpath(file_info.dir, result),
      args = stdin_args(input_path),
      cwd = file_info.dir,
      stopAtBeginningOfMainSubprogram = config.options.debug_stop_at_main,
    })
  end)
end

-- Remove the generated debug binaries and input snapshots for a source file.
function M.clean(file_info)
  local suffix = config.options.debug_suffix
  vim.fn.delete(vim.fs.joinpath(file_info.dir, util.executable_name(file_info, suffix)))
  vim.fn.delete(vim.fs.joinpath(file_info.dir, '.' .. file_info.base .. '.cpmode.in'))
end

return M
