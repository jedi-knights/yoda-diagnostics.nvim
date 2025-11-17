-- lua/yoda-diagnostics/init.lua
-- Generic health check framework using Composite pattern
-- Provides extensible diagnostic system for Neovim configurations

local M = {}

-- ============================================================================
-- Submodule Exports
-- ============================================================================

M.composite = require("yoda-diagnostics.composite")
M.lsp = require("yoda-diagnostics.lsp")

-- ============================================================================
-- Registry (allows users to register custom diagnostics)
-- ============================================================================

local registered_diagnostics = {}

--- Register a custom diagnostic
--- @param name string Diagnostic name
--- @param diagnostic table Diagnostic module with check_status() method
function M.register(name, diagnostic)
  assert(type(name) == "string", "name must be a string")
  assert(type(diagnostic) == "table", "diagnostic must be a table")
  assert(type(diagnostic.check_status) == "function", "diagnostic must have check_status() method")

  registered_diagnostics[name] = diagnostic
end

--- Get registered diagnostic by name
--- @param name string Diagnostic name
--- @return table|nil Diagnostic or nil if not found
function M.get(name)
  return registered_diagnostics[name]
end

--- Get all registered diagnostic names
--- @return table Array of diagnostic names
function M.list()
  local names = {}
  for name, _ in pairs(registered_diagnostics) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Run all registered diagnostics
--- @return table Results {name -> boolean}
function M.run_all()
  local composite = M.composite:new()

  -- Add all registered diagnostics
  for _, diagnostic in pairs(registered_diagnostics) do
    composite:add(diagnostic)
  end

  -- Run and get results
  local results = composite:run_all()
  local stats = composite:get_aggregate_status()

  vim.notify(
    string.format("Diagnostics: %d/%d passed (%.0f%%)", stats.passed, stats.total, stats.pass_rate * 100),
    vim.log.levels.INFO
  )

  return results, stats
end

--- Quick status check
--- @return table Status of all registered diagnostics
function M.quick_check()
  local results = {}
  for name, diagnostic in pairs(registered_diagnostics) do
    results[name] = diagnostic.check_status()
  end
  return results
end

--- Run diagnostics using Composite pattern
--- @param diagnostics table Array of diagnostic modules
--- @return table results, table stats
function M.run_with_composite(diagnostics)
  local composite = M.composite:new()

  for _, diagnostic in ipairs(diagnostics) do
    composite:add(diagnostic)
  end

  local results = composite:run_all()
  local stats = composite:get_aggregate_status()

  return results, stats
end

-- ============================================================================
-- Setup
-- ============================================================================

--- Setup with default diagnostics
--- @param opts table|nil Options {register_defaults = boolean}
function M.setup(opts)
  opts = opts or {}

  if opts.register_defaults ~= false then
    -- Register LSP diagnostic by default
    M.register("lsp", M.lsp)
  end

  -- Register user-provided diagnostics
  if opts.diagnostics then
    for name, diagnostic in pairs(opts.diagnostics) do
      M.register(name, diagnostic)
    end
  end
end

return M
