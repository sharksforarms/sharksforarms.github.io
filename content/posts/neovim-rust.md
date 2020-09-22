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

In the 0.5 release of Neovim (currently nightly), the developers have introduced
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
  [nightly download](https://github.com/neovim/neovim/releases/nightly),
  in the [unstable PPA](https://github.com/neovim/neovim/wiki/Installing-Neovim#ubuntu)
  or other nightly sources. I am currently living on the bleeding edge: building
  and installing neovim from the master git branch.
- [Install rust-analyzer](https://rust-analyzer.github.io/manual.html#rust-analyzer-language-server-binary)
Note: The binary must be in your `PATH`

Diving in, let's install some plugins.

The plugin manager used here is [vim-plug](https://github.com/junegunn/vim-plug),
but any plugin manager can be used.

```vim
call plug#begin('~/.vim/plugged')

" Collection of common configurations for the Nvim LSP client
Plug 'neovim/nvim-lspconfig'

" Extensions to built-in LSP, for example, providing type inlay hints
Plug 'tjdevries/lsp_extensions.nvim'

" Autocompletion framework for built-in LSP
Plug 'nvim-lua/completion-nvim'

" Diagnostic navigation and settings for built-in LSP
Plug 'nvim-lua/diagnostic-nvim'

call plug#end()
```

To install the above run `:PlugInstall` in neovim.

Enable syntax highlighting and file type identification, plugin and indenting
```vim
syntax enable
filetype plugin indent on
```

Let's setup the rust-analyzer LSP and attach completion and diagnostics functions

```vim
" Set completeopt to have a better completion experience
" :help completeopt
" menuone: popup even when there's only one match
" noinsert: Do not insert text until a selection is made
" noselect: Do not select, force user to select one from the menu
set completeopt=menuone,noinsert,noselect

" Avoid showing extra messages when using completion
set shortmess+=c

" Configure LSP
" https://github.com/neovim/nvim-lspconfig#rust_analyzer
lua <<EOF

-- nvim_lsp object
local nvim_lsp = require'nvim_lsp'

-- function to attach completion and diagnostics
-- when setting up lsp
local on_attach = function(client)
    require'completion'.on_attach(client)
    require'diagnostic'.on_attach(client)
end

-- Enable rust_analyzer
nvim_lsp.rust_analyzer.setup({ on_attach=on_attach })

EOF
```

Now when nvim is restarted, you should be able to autocomplete and view warnings
and errors inside the editor! You'll notice, however, that the completion experience
is not like what you might be use to in VSCode or other editors.
Mostly surrounding the lack `<Tab>` completion. Vim uses `<C-N>`!

![gif of tab not working](/neovim-rust/tab_complete_fail.gif "Tab Completion Fail")

`<Tab>` completion can be accomplished with the following

(Found in `:help completion`)

```vim
" Trigger completion with <Tab>
inoremap <silent><expr> <TAB>
  \ pumvisible() ? "\<C-n>" :
  \ <SID>check_back_space() ? "\<TAB>" :
  \ completion#trigger_completion()

function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~ '\s'
endfunction
```

![gif of tab working](/neovim-rust/tab_complete_works.gif "Tab Completion Working")

What about code navigation? (`:help lsp`)

```vim
" Code navigation shortcuts
nnoremap <silent> ga    <cmd>lua vim.lsp.buf.code_action()<CR>
nnoremap <silent> <c+]> <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
inoremap <silent> <c+k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> gT    <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> rn    <cmd>lua vim.lsp.buf.rename()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
```

![gif of code navigation](/neovim-rust/code_nav.gif "Code Navigation")

Let's improve the diagnostics.

```vim
" Visualize diagnostics
let g:diagnostic_enable_virtual_text = 1
let g:diagnostic_trimmed_virtual_text = '40'
" Don't show diagnostics while in insert mode
let g:diagnostic_insert_delay = 1

" Set updatetime for CursorHold
" 300ms of no cursor movement to trigger CursorHold
set updatetime=300
" Show diagnostic popup on cursor hold
autocmd CursorHold * lua vim.lsp.util.show_line_diagnostics()

" Goto previous/next diagnostic warning/error
nnoremap <silent> g[ <cmd>PrevDiagnosticCycle<cr>
nnoremap <silent> g] <cmd>NextDiagnosticCycle<cr>
```

![gif of diagnostics](/neovim-rust/diagnostic.gif "Diagnostics")

And to cap it off, let's enable inlay hints!

```vim
" Enable type inlay hints
autocmd CursorMoved,InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost *
\ lua require'lsp_extensions'.inlay_hints{ prefix = '', highlight = "Comment" }
```

![image of inlay hints](/neovim-rust/inlayhints.png "Inlay Hints")

To conclude, this introduces a basic and flexible setup for Rust development
which is also extensible to other languages. This setup allows you, the developer,
to add more language servers (just like we did with rust-analyzer) to have a full
featured cross-language experience.

Thanks for reading!

Questions? Found an error? [Create an issue on Github!](https://github.com/sharksforarms/sharksforarms.github.io/issues/new)
