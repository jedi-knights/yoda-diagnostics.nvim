-- lua/yoda-diagnostics/lsp.lua
-- LSP diagnostics - generic LSP health checking

local M = {}

--- Check LSP server status
--- @param opts table|nil Options {silent = boolean}
--- @return boolean True if any LSP clients are active
function M.check_status(opts)
  opts = opts or {}
  local clients = vim.lsp.get_active_clients()

  if not opts.silent then
    if #clients == 0 then
      vim.notify("❌ No LSP clients are currently active", vim.log.levels.WARN)
    else
      vim.notify("✅ Active LSP clients:", vim.log.levels.INFO)
      for _, client in ipairs(clients) do
        vim.notify("  - " .. client.name, vim.log.levels.INFO)
      end
    end
  end

  return #clients > 0
end

--- Get active LSP clients
--- @return table Array of active LSP clients
function M.get_clients()
  return vim.lsp.get_active_clients()
end

--- Get LSP client names
--- @return table Array of client names
function M.get_client_names()
  local clients = M.get_clients()
  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  return names
end

--- Check if specific LSP client is running
--- @param name string Client name to check
--- @return boolean True if client is active
function M.is_client_active(name)
  local clients = M.get_clients()
  for _, client in ipairs(clients) do
    if client.name == name then
      return true
    end
  end
  return false
end

--- Get name for composite pattern
--- @return string
function M.get_name()
  return "LSP"
end

return M
