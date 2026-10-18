local M = {}

local function set_highlights()
  vim.api.nvim_set_hl(0, 'LspCodeLens', { link = 'Comment' })
  vim.api.nvim_set_hl(0, 'LspCodeLensSeparator', { link = 'Comment' })
end

function M.setup()
  set_highlights()

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('lsp-codelens', { clear = true }),
    callback = set_highlights,
  })

  -- Enables code lens for all clients that support it, including clients
  -- attached before setup() was called.
  vim.lsp.codelens.enable(true)
end

return M
