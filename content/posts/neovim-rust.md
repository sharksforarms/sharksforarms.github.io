+++
title = "Neovim and Rust"
date = "2020-09-21"
author = "sharksforarms"
authorTwitter = "sharksforarms"
cover = ""
tags = ["vim", "neovim", "rust"]
keywords = ["vim", "neovim", "rust"]
description = """An effective Rust development experience with Neovim LSP client
and rust-analyzer"""
showFullContent = false
+++

{{< rawhtml >}}
<p align="center">
  <img src="/neovim-rust/cover.png" />
</p>
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

Check out this repository for the complete configuration and more


https://github.com/sharksforarms/vim-rust

Let's start with the prerequisites:
- Neovim >= 0.5, see [Installing Neovim](https://github.com/neovim/neovim/wiki/Installing-Neovim)
  - Currently, 0.5 can be found as a
  [github download](https://github.com/neovim/neovim/releases),
  in the [unstable PPA](https://github.com/neovim/neovim/wiki/Installing-Neovim#ubuntu)
  or other repositories. I am currently living on the bleeding edge (0.6): [building
  and installing neovim from the master git branch](https://github.com/neovim/neovim#install-from-source).
- [Install rust-analyzer](https://rust-analyzer.github.io/manual.html#rust-analyzer-language-server-binary)
Note: The binary must be in your `PATH`

Diving in, let's install some plugins.

The plugin manager used here is [vim-plug](https://github.com/junegunn/vim-plug),
but any plugin manager can be used.

```vim
call plug#begin('~/.vim/plugged')

" Collection of common configurations for the Nvim LSP client
Plug 'neovim/nvim-lspconfig'

" Completion framework
Plug 'hrsh7th/nvim-cmp'

" LSP completion source for nvim-cmp
Plug 'hrsh7th/cmp-nvim-lsp'

" Snippet completion source for nvim-cmp
Plug 'hrsh7th/cmp-vsnip'

" Other usefull completion sources
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-buffer'

" See hrsh7th's other plugins for more completion sources!

" To enable more of the features of rust-analyzer, such as inlay hints and more!
Plug 'simrat39/rust-tools.nvim'

" Snippet engine
Plug 'hrsh7th/vim-vsnip'

" Fuzzy finder
" Optional
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

" Color scheme used in the GIFs!
" Plug 'arcticicestudio/nord-vim'

call plug#end()
```

To install the above run the `:PlugInstall` command in neovim, or start it with `nvim +PlugInstall`.

Let's setup the rust-analyzer LSP and start configuring the completion

```vim
" Set completeopt to have a better completion experience
" :help completeopt
" menuone: popup even when there's only one match
" noinsert: Do not insert text until a selection is made
" noselect: Do not select, force user to select one from the menu
set completeopt=menuone,noinsert,noselect

" Avoid showing extra messages when using completion
set shortmess+=c

" Configure LSP through rust-tools.nvim plugin.
" rust-tools will configure and enable certain LSP features for us.
" See https://github.com/simrat39/rust-tools.nvim#configuration
lua <<EOF
local nvim_lsp = require'lspconfig'

local capabilities = require('cmp_nvim_lsp').default_capabilities()
require('lspconfig')['rust_analyzer'].setup {
  capabilities = capabilities
}

local opts = {
    tools = { -- rust-tools options
        autoSetHints = true,
        hover_with_actions = true,
        inlay_hints = {
            show_parameter_hints = false,
            parameter_hints_prefix = "",
            other_hints_prefix = "",
        },
    },

    -- all the opts to send to nvim-lspconfig
    -- these override the defaults set by rust-tools.nvim
    -- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#rust_analyzer
    server = {
        -- on_attach is a callback called when the language server attachs to the buffer
        -- on_attach = on_attach,
        settings = {
            -- to enable rust-analyzer settings visit:
            -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
            ["rust-analyzer"] = {
                -- enable clippy on save
                checkOnSave = {
                    command = "clippy"
                },
            }
        }
    },
}

require('rust-tools').setup(opts)
EOF

" Setup Completion
" See https://github.com/hrsh7th/nvim-cmp#basic-configuration
lua <<EOF
local cmp = require'cmp'
cmp.setup({
  -- Enable LSP snippets
  snippet = {
    expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    -- Add tab support
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    })
  },

  -- Installed sources
  sources = {
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
    { name = 'path' },
    { name = 'buffer' },
  },
})
EOF
```

Now when nvim is restarted, you should be able to autocomplete and view warnings
and errors inside the editor!

![gif of completionm](/neovim-rust/completion.gif "Completion")

And inlay hints!

![image of inlay hints](/neovim-rust/inlayhints.png "Inlay Hints")


What about code navigation? (`:help lsp`)

```vim
" Code navigation shortcuts
nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
nnoremap <silent> gd    <cmd>lua vim.lsp.buf.definition()<CR>
```

![gif of code navigation](/neovim-rust/code_nav.gif "Code Navigation")

Code actions are also very useful.

```vim
nnoremap <silent> ga    <cmd>lua vim.lsp.buf.code_action()<CR>
```

![gif of code actions](/neovim-rust/code_action.gif "Code Action")


Let's improve the diagnostics experience.

```vim
" Set updatetime for CursorHold
" 300ms of no cursor movement to trigger CursorHold
set updatetime=300
" Show diagnostic popup on cursor hold
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })

" Goto previous/next diagnostic warning/error
nnoremap <silent> g[ <cmd>lua vim.diagnostic.goto_prev()<CR>
nnoremap <silent> g] <cmd>lua vim.diagnostic.goto_next()<CR>
```

![gif of diagnostics](/neovim-rust/diagnostic.gif "Diagnostics")

You may notice, there's a slight vertical jitter when a new diagnostic comes in.

To avoid this, you can set `signcolumn`

```rust
" have a fixed column for the diagnostics to appear in
" this removes the jitter when warnings/errors flow in
set signcolumn=yes
```

# What's Next?

Here's some other great plugins to keep you going.

**Neovim LSP**

The built in neovim LSP combined with neovim features can be very powerful.

Here's an example of "format-on-write" (with a timeout of 200ms)

```vim
autocmd BufWritePre *.rs lua vim.lsp.buf.formatting_sync(nil, 200)
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
