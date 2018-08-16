# gounit-vim

Vim plugin for [gounit](https://github.com/hexdigest/gounit) tool, that allows you to generate table driven tests easily.

## Demo

[![asciicast](https://asciinema.org/a/IOOukARgdEeeDRsRnHYxSNbLx.png)](https://asciinema.org/a/IOOukARgdEeeDRsRnHYxSNbLx?autoplay=1&theme=solarized-dark&loop=true)

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
Call `:GoUnit` to generate test for function in current line (function declaration line) or functions in text selected in visual mode.
Another example of usage is to give vim "range" parameter:
```vim
:5,10GoUnit     " genereate tests for functions from line 5 to line 10
:.,$GoUnit      " from the current line till the end of the file
:0,.GoUnit      " from the first line to the current line
:%GoUnit        " generate tests for the whole file
```

Also you can create useful maps to use it with [go-vim](https://github.com/fatih/vim-go) plugin for fast function tests generation.
```vim
" maps your leader key + gt to generate tests for the function under your cursor
nnnoremap <leader>gt :normal vaf<cr>:GoUnit<cr>
```



## Settings
If you want you can set path to your **gounit** binary if it's not in your path, for example:

    let g:gounit_bin = '/home/user/go/bin/gounit'
