local M = {}
local l = {}

function M.setup()
  vim.cmd([[
    hi! link LspCodeLens          Comment
    hi! link LspCodeLensSeparator Comment
  ]])

  vim.cmd([[
    augroup lsp-codelens
      au!
      au! BufEnter,CursorHold,InsertLeave <buffer> lua require('jg.lsp-codelens').on_refresh()
    augroup END
  ]])
end

function M.on_refresh()
  if l.anyClientSupports('textDocument/codeLens') then
    vim.lsp.codelens.refresh()
  end
end

function l.anyClientSupports(method)
  local bufnr = vim.api.nvim_get_current_buf()
  local supported = false
  vim.lsp.for_each_buffer_client(bufnr, function(client)
    if client.supports_method(method) then
      supported = true
    end
  end)
  return supported
end

return M
