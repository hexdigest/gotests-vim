# gounit-vim

Vim plugin for [gounit](https://github.com/hexdigest/gounit), that allows
you to generate table driven tests easily.

## Usage
Call `:GoUnit` to generate test for function in current line or functions in
text selected in visual mode.

## Installation
gounit-vim requires **gounit** to be available in your `$PATH`. Alternatively you
can provide path to **gounit** using `g:gounit_bin` setting.

Plugin installation:
*  [Pathogen](https://github.com/tpope/vim-pathogen)
  * `git clone https://github.com/buoto/gounit-vim.git ~/.vim/bundle/gounit-vim`
*  [vim-plug](https://github.com/junegunn/vim-plug)
  * `Plug 'buoto/gounit-vim'`
*  [NeoBundle](https://github.com/Shougo/neobundle.vim)
  * `NeoBundle 'buoto/gounit-vim'`
*  [Vundle](https://github.com/gmarik/vundle)
  * `Plugin 'buoto/gounit-vim'`
*  [Vim packages](http://vimhelp.appspot.com/repeat.txt.html#packages) (since Vim 7.4.1528)
  * `git clone https://github.com/buoto/gounit-vim.git ~/.vim/pack/plugins/start/gounit-vim`

## Settings
If you want you can set path to your **gounit** binary if it's not in your path, for example:

    let g:gounit_bin = '/home/user/go/bin/gounit'
