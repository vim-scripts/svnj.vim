"===============================================================================
" File:         autoload/svnj/brwsr.vim
" Description:  SVN Browser
" Author:       Juneed Ahamed
"===============================================================================

"svnj#brwsr.vim {{{1

"vars {{{2
if !exists('g:svnj_glb_init') | let g:svnj_glb_init = svnjglobals#init() | en
call svnj#caop#fetchbmarks()
let [s:selectkey, s:selectdscr] = svnj#utils#selkey()
let [s:topkey, s:topdscr] = svnj#utils#topkey()
let [s:reckey, s:recdscr] = svnj#utils#CtrlEntReplace('Rec')
"2}}}

"Key mappings for browseops {{{3
fun! s:browseops()
   return { 
               \ "\<Enter>"  : {"bop":"<enter>", "dscr":'Ent:Opn', "fn":'svnj#brwsr#digin', "args":[0]},
               \ s:reckey    : {"bop":"<c-enter>", "dscr":s:recdscr, "fn":'svnj#brwsr#digin', "args":[1]},
               \ "\<C-u>"    : {"bop":"<c-u>", "dscr":'C-u:Up', "fn":'svnj#brwsr#digout'},
               \ "\<C-h>"    : {"bop":"<c-h>", "dscr":'C-h:Home', "fn":'svnj#brwsr#root'},
               \ "\<C-o>"    : {"bop":"<c-o>", "dscr":'C-o:OpnAll', "fn":'svnj#gopshdlr#openFltrdFiles', "args":['winj#newBufOpen']},
               \ "\<C-v>"    : {"bop":"<c-v>", "dscr":'C-v:VS', "fn":'svnj#gopshdlr#openFile', "args":['winj#openVS']},
               \ "\<C-d>"    : {"bop":"<c-d>", "dscr":'C-d:Diff', "fn":'svnj#gopshdlr#openFile', "args":['winj#diffFile']},
               \ "\<C-l>"    : {"bop":"<c-l>", "dscr":'C-l:Log', "fn":'svnj#brwsr#fileLogs'},
               \ "\<C-b>"    : {"bop":"<c-b>", "dscr":'C-b:Bk', "fn":'svnj#gopshdlr#book'},
               \ s:topkey    : {"bop":"<c-t>", "dscr":s:topdscr, "fn":'svnj#stack#top'},
               \ "\<C-i>"    : {"bop":"<c-i>", "dscr":'C-i:Info', "fn":'svnj#gopshdlr#info'},
               \ "\<C-a>"    : {"bop":"<c-a>", "dscr":'C-a:Afls', "fn":'svnj#brwsr#affectedfiles'},
               \ "\<C-r>"    : {"bop":"<c-r>", "dscr":'C-r:Redo', "fn":'svnj#brwsr#refresh'},
               \ s:selectkey : {"bop":"<c-space>", "dscr":s:selectdscr, "fn":'svnj#gopshdlr#select'},
               \ "\<C-s>"    : {"dscr":'C-s:stick!', "fn":'winj#hidePrompt'},
               \ "\<F5>"     : {"dscr":'F5:redr', "fn":'winj#forceredr'},
               \ }
endf
"2}}}

"3}}}


"Browser {{{2
fun! svnj#brwsr#SVNBrowse()
    try
        call svnj#init()
        call svnj#brwsr#Menu('winj#populateJWindow')
    catch 
        let bdict = svnj#dict#new("Browser")
        call svnj#dict#addErrUp(bdict, 'Failed ', v:exception)
        call winj#populateJWindow(bdict)
        call svnj#utils#dbgHld('At svnj#Browse', v:exception)
        call bdict.clear()
        unlet! bdict
    endtry
endf

fun! svnj#brwsr#SVNBrowseRepo(...)
    try
        call svnj#init()
        if a:0 > 0 && a:1 == "/" 
            let url = svnj#svn#repoRoot()
        else
            let url = svnj#svn#url(a:0 > 0 ? a:1 : getcwd())
        endif
        call svnj#brwsr#svnBrowse(url, "", 0, 0, 'winj#populateJWindow')
    catch
        let bdict = svnj#dict#new("Browser")
        call svnj#dict#addErr(bdict, 'Failed ', v:exception)
        call winj#populateJWindow(bdict)
        unlet! bdict
    endtry
endf

fun! svnj#brwsr#SVNBrowseWC(...)
    try
        call svnj#init()
        let recursive = a:1
        let url = (a:0 > 1  && svnj#utils#isdir(a:2)) ? (a:2) : getcwd()
        call svnj#brwsr#svnBrowse(url, "", 0, recursive, 'winj#populateJWindow')
    catch
        call svnj#utils#dbgHld("At svnj#brwsr#SVNBrowseWC", v:exception)
        let bdict = svnj#dict#new("Browser")
        call svnj#dict#addErr(bdict, 'Failed ', v:exception)
        call winj#populateJWindow(bdict)
        unlet! bdict
    endtry
endf

fun! svnj#brwsr#Menu(populatecb)
    let bdict = svnj#dict#new("SVNJ Browser Menu")
    call bdict.setMeta(svnj#svn#blankMeta())

    call svnj#dict#addEntries(bdict, 'menud',
                \  [svnj#dict#menuItem('Repository', 'svnj#brwsr#browseRepoMenuCb', "")], {})
    call svnj#dict#addEntries(bdict, 'menud',
                \ [svnj#dict#menuItem('Working Copy/Current Dir', 'svnj#brwsr#browseWCMenuCb', "")], {})
    call svnj#dict#addEntries(bdict, 'menud',
                \ [svnj#dict#menuItem('MyList', 'svnj#brwsr#browseMyListMenuCb', "")], {})
    call svnj#dict#addEntries(bdict, 'menud',
                \ [svnj#dict#menuItem('BookMarks', 'svnj#brwsr#browseBMarksMenuCb', "")], {})
    
    let menuops = { 
                \ "\<Enter>": {"bop":"<enter>", "dscr":'Enter:Open', "fn":'svnj#brwsr#browseMenuHandler'},
                \ s:reckey  : {"bop":"<c-enter>", "dscr":s:recdscr, "fn":'svnj#brwsr#browseMenuHandler', "args":["recursive"]},
                \ "\<C-u>"  : {"bop":"<c-u>", "dscr":'C-u:up', "fn":'svnj#stack#pop'},
                \ s:topkey  : {"bop":"<c-t>", "dscr":s:topdscr, "fn":'svnj#stack#top'},
                \ }

    call svnj#dict#addOps(bdict, 'menud', menuops)
    call svnj#stack#push('svnj#brwsr#Menu', ['winj#populate'])
    call call(a:populatecb, [bdict])
endf

fun! svnj#brwsr#browseMenuHandler(argdict)
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    return call(adict.menud.contents[akey].callback, [a:argdict])
endf

fun! svnj#brwsr#browseRepoMenuCb(argdict)
    try
        let [adict, akey] = [a:argdict.dict, a:argdict.key]
        call adict.setMeta(svnj#svn#getMeta(getcwd()))
        let url = adict.meta.url
        let recursive = len(a:argdict.opt) > 0 && a:argdict.opt[0] ==# 'recursive' ? 1 : 0
        let args = s:browsItArgs(url, "", 0, recursive, 'winj#populate')
        return svnj#brwsr#browseIt(args)
    catch
        call svnj#utils#dbgHld("At svnj#brwsr#browseRepoMenuCb", v:exception)
        call svnj#utils#showErrorConsole("Failed the current dir/file " .
                    \ "May not be a valid svn entity")
    endtry
endf

fun! svnj#brwsr#browseWCMenuCb(argdict)
    try
        let [adict, akey] = [a:argdict.dict, a:argdict.key]
        call adict.setMeta(svnj#svn#getMetaFS(getcwd()))
        let url = adict.meta.fpath
        if url == "" | let url = getcwd() | en
        let recursive = len(a:argdict.opt) > 0 && a:argdict.opt[0] ==# 'recursive' ? 1 : 0
        let args = s:browsItArgs(url, "", 0, recursive, 'winj#populate')
        return svnj#brwsr#browseIt(args)
    catch
        return svnj#utils#showErrorConsole("Failed the current dir/file " .
                    \ "May not be a valid svn entity")
    endtry
endf

fun! svnj#brwsr#svnBrowse(url, purl, ignore_dirs, recursive, populatecb)
    let args = s:browsItArgs(a:url, a:purl, a:ignore_dirs, a:recursive, a:populatecb)
    call svnj#stack#push('svnj#brwsr#svnBrowse', 
                \ [a:url, a:purl, a:ignore_dirs, a:recursive, 'winj#populate'])

    call svnj#brwsr#browseIt(args)
endf

fun! s:browsItArgs(url, purl, ignore_dirs, recursive, populatecb)
    retu {
                \ 'url' : a:url,
                \ 'purl' : a:purl,
                \ 'igndirs' : a:ignore_dirs,
                \ 'recursive' : a:recursive,
                \ 'populatecb' : a:populatecb,
                \ }
endf

fun! svnj#brwsr#browseIt(args)
    let result = 1
    let bdict = svnj#dict#new("Browser")
    try
        let url = a:args.url
        let bdict.meta = svnj#svn#getMetaURL(url)
        let bdict.title = bdict.meta.url
        let bdict.bparent = bdict.meta.url
        let bdict.brecursive = a:args.recursive
        let is_repo = !svnj#utils#localFS(url)
        let files_lister = is_repo ? 'svnj#svn#list' : 'svnj#utils#listFiles'
        let entries = call(files_lister, [url, a:args.recursive, a:args.igndirs])
        if empty(entries)
            if has_key(a:args, 'purl') && a:args.purl != ""
                let args = a:args
                let args.url = a:args.purl
                let args.purl = url
                let args.populatecb = 'winj#populate'
                call svnj#stack#push('svnj#brwsr#browseIt', [args])
                call svnj#dict#addErrUp(bdict, "No files listed for ", url)
            else
                call svnj#dict#addErrUp(bdict, "No files listed for ", url)
            endif
            let result = 0
        else
            call svnj#dict#addBrowseEntries(bdict, 'browsed', entries, s:browseops())
        endif
        unlet! entries
    catch
        call svnj#dict#addErrUp(bdict, 'Failed ', v:exception)
        call svnj#utils#dbgHld("At svnj#brwsr#browseIt", v:exception)
        let result = 0
    endtry
    call call(a:args.populatecb, [bdict])
    return result
endf
"2}}}

"callbacks from window {{{2
fun! svnj#brwsr#root(argdict)
    try
        let bparent = a:argdict.dict.bparent
        let brecursive = a:argdict.dict.brecursive
        let url = ""

        if svnj#utils#isdir(bparent) 
            let wcrp = svnj#svn#workingCopyRootPath()
            let url = (wcrp != bparent) ? wcrp : expand("$HOME")
        endif

        if url == "" && svnj#svn#issvndir(getcwd())
            let url = svnj#svn#repoRoot()
        endif

        if url == "" | let url = expand("$HOME") | en
        call svnj#brwsr#svnBrowse(url, "", 0, brecursive, 'winj#populate')
        return 1
    catch | call svnj#utils#dbgHld("At svnj#brwsr#root", v:exception) | endt
    return 0
endf

fun! svnj#brwsr#digin(argdict)
    try
        let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
        let arec = a:argdict.opt[0]
        let newurl = svnj#utils#joinPath(adict.bparent, aline)
        if svnj#utils#isdir(newurl) || svnj#svn#issvndir(newurl)
            let args = {'url' : newurl, 'purl': adict.bparent, 'igndirs' : 0,
                        \ 'recursive' : arec, 'populatecb' : 'winj#populate'}
            return svnj#brwsr#browseIt(args)
        else
            call svnj#select#add(akey, aline, newurl, "")
            retu svnj#select#openFiles('winj#newBufOpen', g:svnj_max_open_files)
        endif
    catch | call svnj#utils#dbgHld("At svnj#brwsr#digin", v:exception) | endt
    return 0
endf

fun! svnj#brwsr#digout(argdict)
    try
        let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
        let newurl = svnj#utils#getparent(adict.bparent)
        let is_repo = !svnj#utils#localFS(newurl)
        if (is_repo && !svnj#svn#validURL(newurl)) || (!is_repo && newurl == "//")
            call svnj#dict#addErrUp(adict, "Looks, like reached tip of the SVN/FS", "")
            call winj#populate(adict) | retu 0
        endif
        let args = {'url' : newurl, 'purl': adict.bparent, 'igndirs' : 0,
                    \ 'recursive' : adict.brecursive, 'populatecb' : 'winj#populate'}
        return svnj#brwsr#browseIt(args)
    catch | call svnj#utils#dbgHld("Exception at digout", v:exception)
    endtry
    return 0
endf

fun! svnj#brwsr#fileLogs(argdict)
    try
        let [adict, aline] = [a:argdict.dict, a:argdict.line]
        try
            let args = {'url' : adict.bparent, 'purl': '',
                        \  'igndirs' : 0, 'recursive' : 0,
                        \  'populatecb' : 'winj#populate'}
            call svnj#stack#push('svnj#brwsr#browseIt', [args])
        catch | call svnj#utils#dbgHld("Exception at svnj#brwsr#fileLogs", v:exception)
        endt

        let pathurl = svnj#utils#joinPath(adict.bparent, aline)
        if svnj#svn#validURL(pathurl)
            call svnj#log#logs(pathurl, g:svnj_max_logs, 'winj#populate', 0)
        else 
            call svnj#utils#showErrorConsole("Failed, May not be a valid svn entity")
        endif
    catch | call svnj#utils#showErrorConsole("Failed, Exception") | endt
    return 1
endf

fun! svnj#brwsr#affectedfiles(argdict)
    let [adict, aline] = [a:argdict.dict, a:argdict.line]
    try
        let args = {'url' : adict.bparent, 'purl': '',
                    \  'igndirs' : 0, 'recursive' : 0,
                    \  'populatecb' : 'winj#populate'}
        call svnj#stack#push('svnj#brwsr#browseIt', [args])
    catch | call svnj#utils#dbgHld("Exception at svnj#brwsr#affectedfiles", v:exception)
    endt

    try
        let url = svnj#utils#joinPath(adict.bparent, aline)
        let lcr = svnj#svn#lastChngdRev(url)
        if lcr == ""
            call svnj#utils#showErrorConsole("May Not be a valid svn entity")
            return
        endif
        let title = lcr . '@' . url
        let [slist, adict.meta.cmd] = svnj#svn#affectedfiles(url, lcr)
        return svnj#gopshdlr#displayAffectedFiles(adict, title, slist)
    catch
        call svnj#utils#dbgHld("At svnj#brwsr#affectedfiles", v:exception)
    endtry
endf

fun! svnj#brwsr#refresh(argdict)
    try
        let [adict, aline] = [a:argdict.dict, a:argdict.line]
        let newurl = adict.bparent
        call svnj#caop#cls(newurl)
        let args = {'url' : newurl, 'purl': adict.bparent, 'igndirs' : 0,
                    \ 'recursive' : 1, 'populatecb' : 'winj#populate'}
        return svnj#brwsr#browseIt(args)
    catch | call svnj#utils#dbgHld("At svnj#brwsr#refresh", v:exception) | endt

endf
"2}}}

"Browse BMarks {{{2
fun! svnj#brwsr#SVNBrowseMarked()
    call svnj#init()
    call svnj#brwsr#bmarked('winj#populateJWindow')
endf

fun! svnj#brwsr#browseBMarksMenuCb(...)
    return svnj#brwsr#bmarked('winj#populate')
endf

fun! svnj#brwsr#bmarked(populateCb)
    try
        let bdict = svnj#dict#new("Bookmarks")
        let bdict.meta = svnj#svn#blankMeta()
        let entries = svnj#utils#formatBrowsedEntries(svnj#select#booked())
        call svnj#stack#push('svnj#brwsr#bmarked', ['winj#populate'])
        if empty(entries)
            call svnj#dict#addErrTop(bdict, "No Marked files", "")
        else
            call svnj#dict#addBrowseEntries(bdict, 'browsed', entries, s:browseops())
        endif
        unlet! entries
        call call(a:populateCb, [bdict])
        unlet! bdict
    catch | call svnj#utils#dbgHld("At svnj#brwsr#bmarked", v:exception)
    endtry
    return 1
endf
"2}}}

"Browse MyList {{{2
fun! svnj#brwsr#SVNBrowseMyList()
    call svnj#init()
    call svnj#brwsr#brwsMyList('winj#populateJWindow')
endf

fun! svnj#brwsr#browseMyListMenuCb(...)
    call svnj#brwsr#brwsMyList('winj#populate')
endf

fun! svnj#brwsr#brwsMyList(populateCb)
    if len(g:p_browse_mylist) == 0 
        let edict = svnj#utils#errDict("BrowseMyList", 
                    \ "Please set g:svnj_browse_mylist " .
                    \ "at .vimrc see :help g:svnj_browse_mylist")
        call call(a:populateCb, [edict]) | unlet! edict | retu 1
    endif
    
    let bdict = svnj#dict#new("BrowseMyList")
    try
        let bdict.meta = svnj#svn#blankMeta()
        call svnj#stack#push('svnj#brwsr#brwsMyList', ['winj#populate'])
        if empty(g:p_browse_mylist)
            call svnj#dict#addErrUp(bdict, "No files", "")
        else
            let ops = s:browseops()
            call remove(ops, "\<C-u>")
            let entries = svnj#utils#formatBrowsedEntries(g:p_browse_mylist)
            call svnj#dict#addBrowseEntries(bdict, 'browsed', entries, ops)
        endif
        call call(a:populateCb, [bdict])
        unlet! bdict
    catch | call svnj#utils#dbgHld("At svnj#brwsr#brwsMyList", v:exception) 
    endtry
    return 1
endf
"2}}}
"1}}}
