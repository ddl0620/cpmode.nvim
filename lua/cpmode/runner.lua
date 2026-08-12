local M = {}

local buffers = require('cpmode.buffers')
local config = require('cpmode.config')
local util = require('cpmode.util')

-- Compile `file_info` for `lang`, then hand the executable name to `cb`.
-- Passing a `flavour` of 'debug' selects the unoptimised, -g build.
function M.compile(file_info, lang, flavour, cb)
  local commands = flavour == 'debug' and config.options.debug_compile_commands
    or config.options.compile_commands
  local compile_cmd = commands[lang]

  if not compile_cmd then
    -- Interpreted language: nothing to build, run the source directly.
    cb(true, file_info.name)
    return
  end

  local suffix = flavour == 'debug' and config.options.debug_suffix or nil
  local output_file = util.executable_name(file_info, suffix)
  local cmd = string.format(compile_cmd, vim.fn.shellescape(file_info.name), vim.fn.shellescape(output_file))

  util.run_shell(cmd, file_info.dir, function(ok, output)
    if not ok then
      cb(false, output)
    else
      cb(true, output_file)
    end
  end)
end

local function run_program(file_info, lang, executable, input_content, cb)
  local run_cmd = config.options.run_commands[lang]

  if not run_cmd then
    cb(false, 'No run command configured for ' .. lang)
    return
  end

  local cmd = string.format(run_cmd, vim.fn.shellescape(executable or file_info.name))
  local timeout = config.options.timeout

  local started = vim.uv.hrtime()

  util.run_shell(cmd, file_info.dir, function(ok, output, code, signal)
    local elapsed_ms = (vim.uv.hrtime() - started) / 1e6

    -- vim.system reports a timeout as SIGKILL (9); surface that as TLE
    -- rather than as a generic crash.
    if signal == 9 and elapsed_ms >= timeout * 1000 - 50 then
      output = output .. string.format('\n\n[Time Limit Exceeded > %ds]', timeout)
    elseif not ok then
      output = output .. string.format('\n\n[Runtime Error - Exit Code: %s]', tostring(code))
    else
      output = output .. string.format('\n[Finished in %.0f ms]', elapsed_ms)
    end

    cb(true, output)
  end, { stdin = input_content, timeout = timeout })
end

function M.run(state)
  local target_buf, err = util.resolve_target_buf(state)
  if not target_buf then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  util.save_if_modified(target_buf)

  local file_info = util.file_info(target_buf)
  local lang = util.detect_language(file_info.ext)

  if not lang then
    vim.notify('Unsupported file type: ' .. file_info.ext, vim.log.levels.ERROR)
    return
  end

  local input_content = buffers.get_input_content(state.input_buf)

  buffers.set_output_content(state.output_buf, 'Compiling ' .. file_info.name .. '...')

  M.compile(file_info, lang, 'release', function(ok, result)
    if not ok then
      buffers.set_output_content(
        state.output_buf,
        '[Compilation Error: ' .. file_info.name .. ']\n\n' .. result
      )
      vim.notify('Compilation failed: ' .. file_info.name, vim.log.levels.ERROR)
      return
    end

    buffers.set_output_content(state.output_buf, 'Running ' .. file_info.name .. '...')

    run_program(file_info, lang, result, input_content, function(run_ok, output)
      if not run_ok then
        buffers.set_output_content(state.output_buf, '[Error: ' .. file_info.name .. ']\n\n' .. output)
        vim.notify('Execution failed: ' .. file_info.name, vim.log.levels.ERROR)
        return
      end

      buffers.set_output_content(state.output_buf, output)
    end)
  end)
end

return M
