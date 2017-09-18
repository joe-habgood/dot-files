"
" key mappings to reduce effort of moving fingers across keyboard
"
" Left hand is responsible for Ctrl and Shift keys
" Right hand remains on the vim h,j,k,l navigation keys most of the time
" Right hand hits <Enter> to enter command mode from normal mode
"

" in insert mode map esc to jj 
imap jj <Esc>
imap <Tab> <Space><Space><Space>

" map variants of h,j,k,l to replace left, down, up, right in all circumstances
nmap <C-k> <C-W><Up>
nmap <C-j> <C-W><Down>
nmap <C-h> <C-W><Left>
nmap <C-l> <C-W><Right>

cmap <C-k> <Up>
cmap <C-j> <Down>
cmap <C-h> <Left>
cmap <C-l> <Right>

" map <Enter> when not in insert mode
nmap <Enter> :

set mouse=a
