local M = {}

function M.setup()
  vim.cmd([[
    hi! link LspCodeLens          Comment
    hi! link LspCodeLensSeparator Comment
  ]])

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp-codelens', { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client:supports_method('textDocument/codeLens') then
        vim.lsp.codelens.enable(true, { bufnr = args.buf })
      end
    end,
  })
end

return M
