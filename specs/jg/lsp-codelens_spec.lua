local codelens = require('jg.lsp-codelens')

-- In-process language server that reports a single code lens on line 1.
local function fake_server(dispatchers)
  local closing = false
  return {
    request = function(method, _, callback)
      if method == 'initialize' then
        callback(nil, { capabilities = { codeLensProvider = { resolveProvider = false } } })
      elseif method == 'textDocument/codeLens' then
        callback(nil, {
          {
            range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 1 } },
            command = { title = 'lens', command = 'noop' },
          },
        })
      elseif method == 'shutdown' then
        callback(nil, nil)
      end
      return true, 1
    end,
    notify = function(method)
      if method == 'exit' then
        dispatchers.on_exit(0, 15)
      end
      return true
    end,
    is_closing = function()
      return closing
    end,
    terminate = function()
      closing = true
    end,
  }
end

local function create_buf()
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'line' })
  vim.api.nvim_set_current_buf(bufnr)
  return bufnr
end

local function attach(bufnr)
  local client_id = vim.lsp.start({ name = 'fake', cmd = fake_server, root_dir = vim.uv.cwd() }, { bufnr = bufnr })
  assert(
    vim.wait(1000, function()
      return vim.lsp.get_client_by_id(client_id).initialized
    end),
    'client did not initialize'
  )
  -- Capabilities are activated in a scheduled callback after LspAttach.
  vim.wait(50)
  return client_id
end

local function has_lenses(bufnr)
  return vim.wait(1000, function()
    return #vim.lsp.codelens.get({ bufnr = bufnr }) > 0
  end)
end

describe('jg.lsp-codelens', function()
  after_each(function()
    pcall(vim.api.nvim_del_augroup_by_name, 'lsp-codelens')
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop(true)
    end
    vim.wait(1000, function()
      return #vim.lsp.get_clients() == 0
    end)
    vim.lsp.codelens.enable(false)
    vim.g._lsp_enabled_codelens = nil
  end)

  it('shows code lenses for clients attached after setup', function()
    codelens.setup()

    local bufnr = create_buf()
    attach(bufnr)

    assert.is_true(vim.lsp.codelens.is_enabled({ bufnr = bufnr }))
    assert.is_true(has_lenses(bufnr))
  end)

  it('shows code lenses for clients attached before setup', function()
    local bufnr = create_buf()
    attach(bufnr)

    codelens.setup()

    assert.is_true(vim.lsp.codelens.is_enabled({ bufnr = bufnr }))
    assert.is_true(has_lenses(bufnr))
  end)

  it('links the highlight groups to Comment', function()
    codelens.setup()

    assert.are.equal('Comment', vim.api.nvim_get_hl(0, { name = 'LspCodeLens' }).link)
    assert.are.equal('Comment', vim.api.nvim_get_hl(0, { name = 'LspCodeLensSeparator' }).link)
  end)

  it('keeps the highlight links after a colorscheme change', function()
    codelens.setup()
    vim.cmd.colorscheme('default')

    assert.are.equal('Comment', vim.api.nvim_get_hl(0, { name = 'LspCodeLens' }).link)
    assert.are.equal('Comment', vim.api.nvim_get_hl(0, { name = 'LspCodeLensSeparator' }).link)
  end)

  it('does not duplicate autocmds when setup is called again', function()
    codelens.setup()
    codelens.setup()

    assert.are.equal(1, #vim.api.nvim_get_autocmds({ group = 'lsp-codelens' }))
  end)
end)
