setl nocindent
setl expandtab
setl sw=4
setl sts=4
setl tabstop=4
setl cinkeys-=:

" === Simple Loops and Control Flow ===
iabbrev <buffer> fi <C-R>=expand('for (int i = 0; i <condition; i++) {\\n}')<CR><Esc>?condition<CR>ciw
iabbrev <buffer> fj <C-R>=expand('for (int j = 0; j <condition; j++) {\\n}')<CR><Esc>?condition<CR>ciw

" === Simple Container Declarations ===
iabbrev <buffer> vecint std::vector<int> vec;
iabbrev <buffer> vecstr std::vector<std::string> vec;
iabbrev <buffer> veca std::vector<auto> vec;
iabbrev <buffer> mapint std::map<int, int> mp;
iabbrev <buffer> mapstr std::map<std::string, int> mp;

" === Simple Statements ===
iabbrev <buffer> cou std::cout << condition << std::endl;<Esc>?condition<CR>ciw
iabbrev <buffer> cinn std::cin >> variable;<Esc>?variable<CR>ciw
iabbrev <buffer> prf printf("format\\n", args);<Esc>?format<CR>ciw
iabbrev <buffer> dbg std::cout << "DEBUG: " << variable << std::endl;<Esc>?variable<CR>ciw


" === Simple Lambdas ===
iabbrev <buffer> lambm auto mapper = [](const auto& x) { return transformation; };<Esc>?transformation<CR>ciw
iabbrev <buffer> lambf auto filter = [](const auto& x) { return condition; };<Esc>?condition<CR>ciw
iabbrev <buffer> lambr auto reducer = [](const auto& acc, const auto& x) { return result; };<Esc>?result<CR>ciw
