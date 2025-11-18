-- lua/yoda-diagnostics/init.lua
-- Generic health check framework using Composite pattern
-- Provides extensible diagnostic system for Neovim configurations

local M = {}

local state = {
  composite = nil,
  lsp = nil,
  registered_diagnostics = {},
  is_setup = false,
}

--- Setup with default diagnostics
--- @param opts table|nil Options {register_defaults = boolean, diagnostics = table}
function M.setup(opts)
  opts = opts or {}

  if state.is_setup then
    vim.notify("yoda-diagnostics already setup", vim.log.levels.WARN)
    return
  end

  state.composite = require("yoda-diagnostics.composite")
  state.lsp = require("yoda-diagnostics.lsp")

  if opts.register_defaults ~= false then
    M.register("lsp", state.lsp)
  end

  if opts.diagnostics then
    for name, diagnostic in pairs(opts.diagnostics) do
      M.register(name, diagnostic)
    end
  end

  state.is_setup = true
end

local function ensure_setup()
  if not state.is_setup then
    error("yoda-diagnostics not initialized. Call setup() first.")
  end
end

--- Register a custom diagnostic
--- @param name string Diagnostic name
--- @param diagnostic table Diagnostic module with check_status() method
function M.register(name, diagnostic)
  assert(type(name) == "string", "name must be a string")
  assert(type(diagnostic) == "table", "diagnostic must be a table")
  assert(type(diagnostic.check_status) == "function", "diagnostic must have check_status() method")

  state.registered_diagnostics[name] = diagnostic
end

--- Get registered diagnostic by name
--- @param name string Diagnostic name
--- @return table|nil Diagnostic or nil if not found
function M.get(name)
  ensure_setup()
  return state.registered_diagnostics[name]
end

--- Get all registered diagnostic names
--- @return table Array of diagnostic names
function M.list()
  ensure_setup()
  local names = {}
  for name, _ in pairs(state.registered_diagnostics) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

--- Run all registered diagnostics
--- @return table results, table stats
function M.run_all()
  ensure_setup()
  local composite = state.composite:new()

  for _, diagnostic in pairs(state.registered_diagnostics) do
    composite:add(diagnostic)
  end

  local results = composite:run_all()
  local stats = composite:get_aggregate_status()

  vim.notify(string.format("Diagnostics: %d/%d passed (%.0f%%)", stats.passed, stats.total, stats.pass_rate * 100), vim.log.levels.INFO)

  return results, stats
end

--- Quick status check
--- @return table Status of all registered diagnostics
function M.quick_check()
  ensure_setup()
  local results = {}
  for name, diagnostic in pairs(state.registered_diagnostics) do
    results[name] = diagnostic.check_status()
  end
  return results
end

--- Run diagnostics using Composite pattern
--- @param diagnostics table Array of diagnostic modules
--- @return table results, table stats
function M.run_with_composite(diagnostics)
  ensure_setup()
  local composite = state.composite:new()

  for _, diagnostic in ipairs(diagnostics) do
    composite:add(diagnostic)
  end

  local results = composite:run_all()
  local stats = composite:get_aggregate_status()

  return results, stats
end

--- Get composite module (for direct access)
--- @return table Composite module
function M.get_composite()
  ensure_setup()
  return state.composite
end

--- Get LSP module (for direct access)
--- @return table LSP module
function M.get_lsp()
  ensure_setup()
  return state.lsp
end

return M
