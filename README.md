# gounit-vim

Vim plugin for [gounit](https://github.com/hexdigest/gounit) tool, that allows you to generate table driven tests easily.

## Demo

![demo](https://github.com/hexdigest/gounit-vim/blob/master/demo.gif)

## Installation
gounit-vim requires **gounit** to be available in your `$PATH`. Alternatively you can provide path to **gounit** using `g:gounit_bin` setting.

Plugin installation:
* [Pathogen](https://github.com/tpope/vim-pathogen)
    ```
    git clone https://github.com/hexdigest/gounit-vim.git ~/.vim/bundle/gounit-vim
    ```
*  [vim-plug](https://github.com/junegunn/vim-plug)
    ```
    Plug 'hexdigest/gounit-vim'
    ```
*  [NeoBundle](https://github.com/Shougo/neobundle.vim)
    ```
    NeoBundle 'hexdigest/gounit-vim'
    ```
*  [Vundle](https://github.com/gmarik/vundle)
    ```
    Plugin 'hexdigest/gounit-vim'
    ```
*  [Vim packages](http://vimhelp.appspot.com/repeat.txt.html#packages) (since Vim 7.4.1528)
    ```
    git clone https://github.com/hexdigest/gounit-vim.git ~/.vim/pack/plugins/start/gounit-vim
    ```  
You will also need to install all the necessary GoUnit binaries. 
It is easy to install by providing a command `:GoUnitInstallBinaries`, which will `go get` all the required binaries.

## Usage
Call `:GoUnit` to generate test for the function declaration in the current line or all functions selected in visual mode.
`GoUnit` also understands "range" parameters:
```vim
:5,10GoUnit     " genereate tests for functions from line 5 to line 10
:.,$GoUnit      " from the current line till the end of the file
:0,.GoUnit      " from the first line to the current line
:%GoUnit        " generate tests for the whole file
```

These commands generate tests using template that you set as a default with the `gounit template use <template>` command.
Yet you can use all of the above commands followed by the name of the template: `:GoUnit minimock`
If you have `wildmenu` option enabled you can pick desired template from the list of all registered templates with: `:GoUnit <TAB>`

Also you can create useful maps to use it with [go-vim](https://github.com/fatih/vim-go) plugin for fast function tests generation.
```vim
" maps your leader key + gt to generate tests for the function under your cursor
nnoremap <leader>gt :normal vaf<cr>:GoUnit<cr>
```

## Settings
If you want you can set path to your **gounit** binary if it's not in your path, for example:

    let g:gounit_bin = '/home/user/go/bin/gounit'
