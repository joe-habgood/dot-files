" wip.vim - wip list manager 
" Maintainer:   Joe Habgood 
" Version:      0.1
"

if exists('g:loaded_wip') || &compatible
  finish
else
  let g:loaded_wip = 1
endif

" XXX if vimflowy installed?
autocmd BufRead,BufNewFile *.wip set filetype=vimflowy

function! KeyValue(line)
	let kv = split(a:line, ":")
	if len(kv) < 2
		return {"key" : Strip(kv[0]), "value": "" }
	else
		return {"key" : Strip(kv[0]), "value": Strip(kv[1]).body }
	endif
endfunction


function! ReadBlockAsDict(block)
	"
	let dict = {}
	let idx = 0
	for line in a:block.lines
		let kv = KeyValue(line)
		let dict[kv.key.body] = { "line" : idx, "indent" : kv.key.indent, "value" : kv.value }
		let idx += 1
	endfor
	return dict
endfunction


function! GetLineAndCall(func)

	let pos=getcurpos()

	let block = ReadBlock()
	let d = ReadBlockAsDict(block)

	call function(a:func)(d)

	" update the block with new values from d
	for kv in items(d)
		"let block.lines[kv[1].line] = kv[1].indent . kv[0] . ":" . kv[1].value
		let block.lines[kv[1].line] = printf("%s%s: %s", kv[1].indent, kv[0], kv[1].value)
	endfor

	call WriteBlock(block)
	call setpos('.', pos)

endfunction


function! Strip(input_string)
	let content = {}
	let content.indent = substitute(a:input_string, '^\(\s*\).*', '\1', '')
	let content.body   = substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
	return content
endfunction


function! ReadBlock()
	let numlines = line('$')
	let origpos = getcurpos()
	" find start of block
	let pos=getcurpos()
	"let line = Strip(getline('.'))
	let line = getline('.')

	" go to previous unindented line
	while line[0] == " "
		let pos = getcurpos()
		let pos = [pos[0], pos[1] - 1] + pos[2:] 
		call setpos('.', pos)
		let line = getline('.')
	endwhile

	" start stepping forward to end of block
	let startpos=pos
	"let line = Strip(getline('.'))
	let readlines = [line]
	let pos = [pos[0], pos[1] + 1] + pos[2:] 
	call setpos('.', pos)
	let line = getline('.')

	"while line[-1:] != a:stopchar
	while line[0] == " "
		let readlines = readlines + [line]
		let pos = getcurpos()
		let pos = [pos[0], pos[1] + 1] + pos[2:] 
		call setpos('.', pos)
		let line = getline('.')
	endwhile

	call setpos('.', origpos)
	return { "firstpos" : startpos, "lines" :  readlines}
endfunction


function! WriteBlock(block)
	let i=0
	for line in a:block.lines
		call setline(a:block.firstpos[1] + i, line)
		let i = i + 1
	endfor
endfunction


function! ListBlocks()
	let origpos = getcurpos()
	call setpos(".", [0,0,0,0])
	let blocks = []
	let startpattern = "^w"
	while search(startpattern, 'W') 
		let blocks = blocks + [getcurpos()]
	endwhile
	call setpos('.', origpos)
	return blocks
endfunction

highlight currenttask ctermfg=red
highlight othertask ctermfg=white

function! StartTask(d)
	"
	"
	"
	if a:d.current.value ==? "False"
		if a:d.started.value
			let a:d.touched.value = strftime("%s")
		else
			let a:d.started.value = strftime("%s")
			let a:d.touched.value = strftime("%s")
		endif

		call JumpToTask("current", "True")
		call GetLineAndCall("StopTask")

		let a:d.current.value = "True"
		echom "current task" . a:d.tag.value

                match currenttask /^wip^*current: True.*^$/
	else
		echom "current task" . a:d.tag.value
	endif

endfunction


function! StopTask(d)
	"
	"
	"
	if a:d.current.value ==? "True"
		if a:d.touched.value
			let a:d.seconds.value = a:d.seconds.value + (strftime("%s") - a:d.touched.value)
			let a:d.minutes.value = a:d.seconds.value / 60
			let a:d.hours.value   = a:d.seconds.value / 3600
			let a:d.days.value    = a:d.seconds.value / 25200
		endif
	endif

	" update the touch time 
	let a:d.touched.value = strftime("%s")
	let a:d.current.value = "False"

endfunction


function! JumpToTask(key, value)
	"
	"
	"
	let blocks = ListBlocks()
	let matches = []
	for pos in blocks
		call setpos(".", pos)
		let block = ReadBlock()
		let d = ReadBlockAsDict(block)
		if Strip(d[a:key].value).body == Strip(a:value).body
			let matches = matches + [pos]
		endif
	endfor 

	if len(matches) > 0 
		call setpos(".", matches[0])
	endif
endfunction


function! ListTasksBy(key)
	"
	"
	"
	let tasks=[]
	let blocks = ListBlocks()
	for pos in blocks
		call setpos(".", pos)
		let block = ReadBlock()
		let d = ReadBlockAsDict(block)
		if has_key(d, a:key)
			let tasks = tasks + [Strip(d[a:key].value).body]
		endif
	endfor  
	return join(tasks, "\n") 
endfunction

function! ListTasksByTag(A,L,P)
	"
	"
	"
	return ListTasksBy("tag")
endfunction

function! ListKeys()
	"
	"
	"
	let keys = []
	for pos in ListBlocks()
		call setpos(".", pos)
		let d = ReadBlockAsDict(ReadBlock())
		for k in keys(d)
			let c=0
			for e in keys
				if e == k
					let c=1
				endif
			endfor
			if c == 0
				let keys = keys + [k]
			endif
		endfor
	endfor
	return join(keys, "\n")
endfunction

function! GeneralFind(A,L,P)
	"
	" A : the leading portion of the argument being completed
	"
	let line = split(a:L, " ")

	if len(line) == 1 || (len(line) == 2 && a:L[-1:] != " ") 
		return ListKeys()
	else 
		return ListTasksBy(line[1])
	endif
endfunction

function! UpdateElapsedTime(d)
	let a:d.elapsed.value = (strftime("%s") - a:d.started.value) / (24*3600)
endfunction

function! UpdateAllElapsedTimes()
	for block_pos in ListBlocks()
		call setpos(".", block_pos)
		call GetLineAndCall("UpdateElapsedTime")
	endfor
endfunction

nmap tt :call GetLineAndCall("StartTask")<cr>
nmap tr :call GetLineAndCall("StopTask")<cr>
"nmap ts :%!sort -k1,1n -k2,2n -s<cr>

command! -nargs=1 -complete=custom,ListTasksByTag Tag :call JumpToTask("tag", "<args>")

command! -nargs=* -complete=custom,GeneralFind Taskfind :call JumpToTask(<f-args>)

autocmd BufWrite *.out :call UpdateAllElapsedTimes() 


