+++
title = "Neovim and Rust"
date = "2020-09-21"
author = "sharksforarms"
authorTwitter = "sharksforarms"
cover = ""
tags = ["neovim", "rust"]
keywords = ["vim", "neovim", "rust", "lua", "lsp"]
description = """An effective Rust development experience with Neovim LSP client
and rust-analyzer"""
showFullContent = false
+++

{{< rawhtml >}}
<img class="center" src="/neovim-rust/cover.png" />
{{< /rawhtml >}}

I have used many editors in the last 5 years.

Sublime Text, Vim, then CLion, then VSCode, back to Vim, briefly Onivim and now Neovim.

I find it important to experiment with different editors and IDEs in order to
have an idea of what powers they hold and how they could be included in your
development toolbox.

Over the last couple months, I have been looking at ways to "sharpen" my development
toolset and have been playing around with multiple vim configurations, one in which
I'd like to share today.

[Neovim](https://neovim.io/) is a fork of vim, which is focused on extensibility
and usability. An example of this is the ability to use Lua instead of VimL for
plugins providing greater flexibility for extending the editor.

In the 0.5 release of Neovim, the developers have introduced
an [Language Server Protocol](https://microsoft.github.io/language-server-protocol/)
(LSP) client framework (`:help lsp`)

This means, Neovim can act as a client to LSP servers (like rust-analyzer) and
assist in building enhanced LSP tools.

LSP facilitates programming language specific features such as go-to-definition,
completion, refactoring, formatting, etc. The goal of LSP is to separate
language support and the editor.

Why use LSP? Well, for one, it allows the developers of an editor to focus on the
editor and not of specific language support. This is a win-win for language providers
and those who release tooling.  This is turning a X*Y problem into X+Y.
(Where X is the number of editors and Y is the number of languages). There are LSP
servers available for almost every language out there.

**So how do we configure Neovim LSP with rust-analyzer? Simple!**

Check out this github repository for the complete, up-to date configuration.

https://github.com/sharksforarms/neovim-rust

Let's start with the prerequisites:
- Neovim >= 0.8, see [Installing Neovim](https://github.com/neovim/neovim/wiki/Installing-Neovim)
  - Currently, 0.8 can be found as a
  [github download](https://github.com/neovim/neovim/releases),
  in the [unstable PPA](https://github.com/neovim/neovim/wiki/Installing-Neovim#ubuntu)
  or other repositories. I am currently living on the bleeding edge (0.9): [building
  and installing neovim from the master git branch](https://github.com/neovim/neovim#install-from-source).
- [Install rust-analyzer](https://rust-analyzer.github.io/manual.html#rust-analyzer-language-server-binary)

Note: The binary must be in your environment's `PATH`

Diving in, let's install some plugins.

The plugin manager used here is [packer.nvim](https://github.com/wbthomason/packer.nvim),
but any plugin manager can be used.

Let's start off with a fresh `~/.config/nvim/init.lua` file.

```lua
-- ensure the packer plugin manager is installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
    vim.cmd([[packadd packer.nvim]])
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

require("packer").startup(function(use)
  -- Packer can manage itself
  use("wbthomason/packer.nvim")
  -- Collection of common configurations for the Nvim LSP client
  use("neovim/nvim-lspconfig")
  -- Visualize lsp progress
  use({
    "j-hui/fidget.nvim",
    config = function()
      require("fidget").setup()
    end
  })

  -- Autocompletion framework
  use("hrsh7th/nvim-cmp")
  use({
    -- cmp LSP completion
    "hrsh7th/cmp-nvim-lsp",
    -- cmp Snippet completion
    "hrsh7th/cmp-vsnip",
    -- cmp Path completion
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-buffer",
    after = { "hrsh7th/nvim-cmp" },
    requires = { "hrsh7th/nvim-cmp" },
  })
  -- See hrsh7th other plugins for more great completion sources!
  -- Snippet engine
  use('hrsh7th/vim-vsnip')
  -- Adds extra functionality over rust analyzer
  use("simrat39/rust-tools.nvim")

  -- Optional
  use("nvim-lua/popup.nvim")
  use("nvim-lua/plenary.nvim")
  use("nvim-telescope/telescope.nvim")

  -- Some color scheme other then default
  use("arcticicestudio/nord-vim")
end)

-- the first run will install packer and our plugins
if packer_bootstrap then
  require("packer").sync()
  return
end
```

To install the above run the `:PackerUpdate` command in neovim, or start it with `nvim +PackerUpdate`.

Let's setup the rust-analyzer LSP and start configuring the completion

```lua
-- Set completeopt to have a better completion experience
-- :help completeopt
-- menuone: popup even when there's only one match
-- noinsert: Do not insert text until a selection is made
-- noselect: Do not auto-select, nvim-cmp plugin will handle this for us.
vim.o.completeopt = "menuone,noinsert,noselect"

-- Avoid showing extra messages when using completion
vim.opt.shortmess = vim.opt.shortmess + "c"

local function on_attach(client, buffer)
  -- This callback is called when the LSP is atttached/enabled for this buffer
  -- we could set keymaps related to LSP, etc here.
end

-- Configure LSP through rust-tools.nvim plugin.
-- rust-tools will configure and enable certain LSP features for us.
-- See https://github.com/simrat39/rust-tools.nvim#configuration
local opts = {
  tools = {
    runnables = {
      use_telescope = true,
    },
    inlay_hints = {
      auto = true,
      show_parameter_hints = false,
      parameter_hints_prefix = "",
      other_hints_prefix = "",
    },
  },

  -- all the opts to send to nvim-lspconfig
  -- these override the defaults set by rust-tools.nvim
  -- see https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#rust_analyzer
  server = {
    -- on_attach is a callback called when the language server attachs to the buffer
    on_attach = on_attach,
    settings = {
      -- to enable rust-analyzer settings visit:
      -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
      ["rust-analyzer"] = {
        -- enable clippy on save
        checkOnSave = {
          command = "clippy",
        },
      },
    },
  },
}

require("rust-tools").setup(opts)

-- Setup Completion
-- See https://github.com/hrsh7th/nvim-cmp#basic-configuration
local cmp = require("cmp")
cmp.setup({
  preselect = cmp.PreselectMode.None,
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    -- Add tab support
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    }),
  },

  -- Installed sources
  sources = {
    { name = "nvim_lsp" },
    { name = "vsnip" },
    { name = "path" },
    { name = "buffer" },
  },
})
```

Now when nvim is restarted, you should be able to autocomplete and view warnings
and errors inside the editor!

![gif of completionm](/neovim-rust/completion.gif "Completion")

And inlay hints!

![image of inlay hints](/neovim-rust/inlayhints.png "Inlay Hints")

What about key maps and code navigation? (`:help lsp`)

This can be added to the `on_attach` callback, we only want these keymaps to be
available when the LSP is attached to the buffer.

```lua
local keymap_opts = { buffer = buffer }
-- Code navigation and shortcuts
vim.keymap.set("n", "<c-]>", vim.lsp.buf.definition, keymap_opts)
vim.keymap.set("n", "K", vim.lsp.buf.hover, keymap_opts)
vim.keymap.set("n", "gD", vim.lsp.buf.implementation, keymap_opts)
vim.keymap.set("n", "<c-k>", vim.lsp.buf.signature_help, keymap_opts)
vim.keymap.set("n", "1gD", vim.lsp.buf.type_definition, keymap_opts)
vim.keymap.set("n", "gr", vim.lsp.buf.references, keymap_opts)
vim.keymap.set("n", "g0", vim.lsp.buf.document_symbol, keymap_opts)
vim.keymap.set("n", "gW", vim.lsp.buf.workspace_symbol, keymap_opts)
vim.keymap.set("n", "gd", vim.lsp.buf.definition, keymap_opts)
```

![gif of code navigation](/neovim-rust/code_nav.gif "Code Navigation")

Code actions are also very useful.

```lua
vim.keymap.set("n", "ga", vim.lsp.buf.code_action, keymap_opts)
```

![gif of code actions](/neovim-rust/code_action.gif "Code Action")


Let's improve the diagnostics experience. Same with the keymaps, we could add
this to the `on_attach` callback.

```lua
-- Set updatetime for CursorHold
-- 300ms of no cursor movement to trigger CursorHold
vim.opt.updatetime = 100

-- Show diagnostic popup on cursor hover
local diag_float_grp = vim.api.nvim_create_augroup("DiagnosticFloat", { clear = true })
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
   vim.diagnostic.open_float(nil, { focusable = false })
  end,
  group = diag_float_grp,
})

-- Goto previous/next diagnostic warning/error
vim.keymap.set("n", "g[", vim.diagnostic.goto_prev, keymap_opts)
vim.keymap.set("n", "g]", vim.diagnostic.goto_next, keymap_opts)
```

![gif of diagnostics](/neovim-rust/diagnostic.gif "Diagnostics")

You may notice, there's a slight vertical jitter when a new diagnostic comes in.

To avoid this, you can set `signcolumn`

```lua
-- have a fixed column for the diagnostics to appear in
-- this removes the jitter when warnings/errors flow in
vim.wo.signcolumn = "yes"
```

# What's Next?

Here's some other great plugins to keep you going.

**Neovim LSP**

The built in neovim LSP combined with neovim features can be very powerful.

Here's an example of "format-on-write" (with a timeout of 200ms)

```lua
local format_sync_grp = vim.api.nvim_create_augroup("Format", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.rs",
  callback = function()
    vim.lsp.buf.format({ timeout_ms = 200 })
  end,
  group = format_sync_grp,
})
```

Check out `:help lsp` for more information!

**Better UI**
- [lspsaga](https://github.com/glepnir/lspsaga.nvim)

**Fuzzy finding**
- [telescope](https://github.com/nvim-telescope/telescope.nvim)

**Debugging**
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)

Note: you may need to do the following to make debugging work.
```sh
sudo apt install lldb-11
sudo ln -s /usr/bin/lldb-vscode-11 /usr/bin/lldb-vscode
```

To conclude, this introduces a basic and flexible setup for Rust development.
Here's the best part though, it's simple to configure
[more languages servers](https://github.com/neovim/nvim-lspconfig#configurations)!
This setup allows you, the developer, to add more lsp'
(just like we did with rust-analyzer) to have a full featured cross-language experience.

Thanks for reading!

Questions? Found an error? [Create an issue on Github!](https://github.com/sharksforarms/sharksforarms.github.io/issues/new)

Edits:
- 2022-11-29: Fix format-on-write
- 2022-10-22: Convert viml to ✨lua✨
- 2022-01-09: Use `vim.diagnostic.open_float` instead of `vim.lsp.diagnostic.show_line_diagnostics` See [neovim/neovim#15154](https://github.com/neovim/neovim/issues/15154)
- 2021-10-11: Removed references to nightly and added formatting example
- 2021-09-06: Added "what next" section
- 2021-09-06: Added rust-analyzer config example, enable clippy on save.
- 2021-09-01: Updated completion framework, enhanced LSP with rust-tools.nvim and more!
- 2021-02-02: Added `enabled` to `inlay_hints` function call to support more hints
- 2020-12-23: Updated tab completion config to reflect latest
[completion.nvim](https://github.com/nvim-lua/completion-nvim/commit/5c153f8ae094867a414cb2a7c0f59454299f17b3) developments
- 2020-12-17: Updated diagnostics and lsp config to reflect latest neovim developments
- 2020-10-05: Added note about code actions and gif
- 2020-09-23: Added note about `signcolumn`
