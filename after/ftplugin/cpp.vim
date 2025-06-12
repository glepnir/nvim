setl nocindent
setl expandtab
setl sw=4
setl sts=4
setl tabstop=4
setl cinkeys-=:

" === Control Structures ===
" for loop
iabbrev <buffer> fi <C-R>=expand('for (int i = 0; i <condition; i++) {\\n}')<CR><Esc>?condition<CR>ciw
iabbrev <buffer> fj <C-R>=expand('for (int j = 0; j <condition; j++) {\\n}')<CR><Esc>?condition<CR>ciw

" enhanced for loop (range-based)
iabbrev <buffer> fore <C-R>=expand('for (auto& item: container) {\\n}')<CR><Esc>O

" while loop
iabbrev <buffer> whi <C-R>=expand('while (condition) {\\n}')<CR><Esc>?condition<CR>ciw

" if statement
iabbrev <buffer> iff <C-R>=expand('if (condition) {\\n}')<CR><Esc>?condition<CR>ciw

" if-else statement
iabbrev <buffer> ife <C-R>=expand('if (condition) {\\n\\n} else {\\n\\n}')<CR><Esc>?condition<CR>ciw

" switch statement
iabbrev <buffer> swi <C-R>=expand('switch (variable) {\\ncase value:\\n    break;\\ndefault:\\n    break;\\n}')<CR><Esc>?variable<CR>ciw

" === Function Definitions ===
" main function
iabbrev <buffer> mainn <C-R>=expand('int main() {\\n\\n    return 0;\\n}')<CR><Esc>2ko<Tab>

" function definition
iabbrev <buffer> func <C-R>=expand('returnType functionName(parameters) {\\n\\n}')<CR><Esc>?returnType<CR>ciw

" === Class Definitions ===
" basic class definition
iabbrev <buffer> classs <C-R>=expand('class ClassName {\\npublic:\\n    ClassName();\\n    ~ClassName();\\n\\nprivate:\\n\\n};')<CR><Esc>?ClassName<CR>ciw

" struct definition
iabbrev <buffer> structt <C-R>=expand('struct StructName {\\n\\n};')<CR><Esc>?StructName<CR>ciw

" === Headers and Includes ===
" common headers
iabbrev <buffer> incio #include <iostream>
iabbrev <buffer> incv #include <vector>
iabbrev <buffer> incs #include <string>
iabbrev <buffer> incm #include <map>
iabbrev <buffer> incu #include <unordered_map>
iabbrev <buffer> inca #include <algorithm>
iabbrev <buffer> incmem #include <memory>
iabbrev <buffer> incf #include <fstream>

" using statements
iabbrev <buffer> usestd using namespace std;
iabbrev <buffer> usec using std::cout;
iabbrev <buffer> usecin using std::cin;
iabbrev <buffer> useend using std::endl;

" === Common Statements ===
" cout output
iabbrev <buffer> cou cout << "" << endl;<Esc>?""<CR>i

" cin input
iabbrev <buffer> cinn cin >> variable;<Esc>?variable<CR>ciw

" printf
iabbrev <buffer> prf printf("format\\n", args);<Esc>?format<CR>ciw

" comment block
iabbrev <buffer> comm <C-R>=expand('/*\\n * \\n */')<CR><Esc>?*<CR>la

" === Memory Management ===
" smart pointers
iabbrev <buffer> uniq std::unique_ptr<Type> ptr = std::make_unique<Type>();<Esc>?Type<CR>ciw
iabbrev <buffer> shar std::shared_ptr<Type> ptr = std::make_shared<Type>();<Esc>?Type<CR>ciw

" === Exception Handling ===
" try-catch
iabbrev <buffer> tryc <C-R>=expand('try {\\n\\n} catch (const std::exception& e) {\\n\\n}')<CR><Esc>3ko<Tab>

" === STL Containers ===
" vector declarations
iabbrev <buffer> vecint std::vector<int> vec;
iabbrev <buffer> vecstr std::vector<std::string> vec;
iabbrev <buffer> veca std::vector<auto> vec;

" map declarations
iabbrev <buffer> mapint std::map<int, int> mp;
iabbrev <buffer> mapstr std::map<std::string, int> mp;

" === Templates ===
" template function
iabbrev <buffer> templ <C-R>=expand('template<typename T>\\nreturnType functionName(T param) {\\n\\n}')<CR><Esc>?returnType<CR>ciw

" template class
iabbrev <buffer> templc <C-R>=expand('template<typename T>\\nclass ClassName {\\npublic:\\n\\nprivate:\\n\\n};')<CR><Esc>?ClassName<CR>ciw

" === Algorithm Common Usage ===
" sort
iabbrev <buffer> sortv std::sort(container.begin(), container.end());<Esc>?container<CR>ciw

" find
iabbrev <buffer> findd auto it = std::find(container.begin(), container.end(), value);<Esc>?container<CR>ciw

" === Debugging ===
" debug output
iabbrev <buffer> dbg cout << "DEBUG: " << variable << endl;<Esc>?variable<CR>ciw

" === Lambda Expressions ===
iabbrev <buffer> lamb auto lambda = [](parameters) { return expression; };<Esc>?parameters<CR>ciw

" === Constructor Common Patterns ===
" default constructor
iabbrev <buffer> ctor ClassName() = default;
iabbrev <buffer> dtor ~ClassName() = default;

" copy constructor
iabbrev <buffer> cctor ClassName(const ClassName& other) = default;

" move constructor
iabbrev <buffer> mctor ClassName(ClassName&& other) = default;

" === Common Macro Definitions ===
iabbrev <buffer> defi #define NAME value
iabbrev <buffer> ifnd #ifndef HEADER_NAME_H<CR>#define HEADER_NAME_H<CR><CR><CR><CR>#endif // HEADER_NAME_H<Esc>3k?HEADER<CR>ciw

" === Modern C++ Features ===
" auto type deduction
iabbrev <buffer> autoo auto variable = expression;<Esc>?variable<CR>ciw

" constexpr
iabbrev <buffer> conste constexpr auto variable = value;<Esc>?variable<CR>ciw

" === Operator Overloading ===
iabbrev <buffer> opeq bool operator==(const ClassName& other) const {<CR>return true;<CR>}<Esc>?ClassName<CR>ciw

" === Common Assert ===
iabbrev <buffer> asse assert(condition); // description<Esc>?condition<CR>ciw

" === Conditional Compilation ===
iabbrev <buffer> ifdef #ifdef CONDITION<CR><CR>#endif // CONDITION<Esc>?CONDITION<CR>ciw
iabbrev <buffer> ifd #if defined(CONDITION)<CR><CR>#endif // CONDITION<Esc>?CONDITION<CR>ciw

" === Namespaces ===
iabbrev <buffer> nspace namespace Name {<CR><CR>} // namespace Name<Esc>?Name<CR>ciw
iabbrev <buffer> nspac namespace {<CR><CR>} // anonymous namespace<Esc>ko<Tab>

" === Enumerations ===
iabbrev <buffer> enuma enum class EnumName {<CR>Value1,<CR>Value2<CR>};<Esc>?EnumName<CR>ciw
iabbrev <buffer> enumo enum EnumName {<CR>VALUE1,<CR>VALUE2<CR>};<Esc>?EnumName<CR>ciw

" === RAII Pattern ===
iabbrev <buffer> raii class RAIIClass {<CR>public:<CR>RAIIClass() { /* acquire */ }<CR>~RAIIClass() { /* release */ }<CR>RAIIClass(const RAIIClass&) = delete;<CR>RAIIClass& operator=(const RAIIClass&) = delete;<CR>};<Esc>?RAIIClass<CR>ciw

" === Function Objects ===
iabbrev <buffer> functor struct FunctorName {<CR>ReturnType operator()(ParamType param) const {<CR>return result;<CR>}<CR>};<Esc>?FunctorName<CR>ciw

" === Type Aliases ===
iabbrev <buffer> usinga using AliasName = OriginalType;<Esc>?AliasName<CR>ciw
iabbrev <buffer> typedefi typedef OriginalType AliasName;<Esc>?OriginalType<CR>ciw

" === Common Design Patterns ===
" Singleton pattern
iabbrev <buffer> single class Singleton {<CR>public:<CR>static Singleton& getInstance() {<CR>static Singleton instance;<CR>return instance;<CR>}<CR>private:<CR>Singleton() = default;<CR>Singleton(const Singleton&) = delete;<CR>Singleton& operator=(const Singleton&) = delete;<CR>};<Esc>?Singleton<CR>ciw

" Observer pattern interface
iabbrev <buffer> observer class Observer {<CR>public:<CR>virtual ~Observer() = default;<CR>virtual void update() = 0;<CR>};<Esc>?Observer<CR>ciw

" === Smart Pointer Common Operations ===
iabbrev <buffer> makeun auto ptr = std::make_unique<Type>(args);<Esc>?Type<CR>ciw
iabbrev <buffer> makesh auto ptr = std::make_shared<Type>(args);<Esc>?Type<CR>ciw
iabbrev <buffer> dyncast auto derived = std::dynamic_pointer_cast<DerivedType>(basePtr);<Esc>?DerivedType<CR>ciw

" === Concurrent Programming ===
iabbrev <buffer> thread std::thread t([]() {<CR>// thread work<CR>});<CR>t.join();<Esc>3k?work<CR>

iabbrev <buffer> mutex std::mutex mtx;<CR>std::lock_guard<std::mutex> lock(mtx);

iabbrev <buffer> atomic std::atomic<Type> atomicVar;<Esc>?Type<CR>ciw

" === Modern C++ Features ===
" constexpr if (C++17)
iabbrev <buffer> ifcons if constexpr (condition) {<CR><CR>}<Esc>?condition<CR>ciw

" structured binding (C++17)
iabbrev <buffer> autob auto [var1, var2] = expression;<Esc>?var1<CR>ciw

" initializer list
iabbrev <buffer> initl : member1(value1), member2(value2) {<CR>}<Esc>?member1<CR>ciw

" === Container Iteration ===
iabbrev <buffer> forit for (auto it = container.begin(); it != container.end(); ++it) {<CR><CR>}<Esc>?container<CR>ciw

iabbrev <buffer> forci for (auto it = container.cbegin(); it != container.cend(); ++it) {<CR><CR>}<Esc>?container<CR>ciw

iabbrev <buffer> forri for (auto it = container.rbegin(); it != container.rend(); ++it) {<CR><CR>}<Esc>?container<CR>ciw

" === Algorithm Library Common Usage ===
iabbrev <buffer> transf std::transform(input.begin(), input.end(), output.begin(), [](const auto& item) {<CR>return transformation;<CR>});<Esc>?input<CR>ciw

iabbrev <buffer> filte auto result = std::find_if(container.begin(), container.end(), [](const auto& item) {<CR>return condition;<CR>});<Esc>?container<CR>ciw

iabbrev <buffer> accum auto sum = std::accumulate(container.begin(), container.end(), initialValue);<Esc>?container<CR>ciw

" === File Operations ===
iabbrev <buffer> ifstm std::ifstream file("filename");<CR>if (!file.is_open()) {<CR>// handle error<CR>}<Esc>?filename<CR>ciw

iabbrev <buffer> ofstm std::ofstream file("filename");<CR>if (!file.is_open()) {<CR>// handle error<CR>}<Esc>?filename<CR>ciw

" === String Operations ===
iabbrev <buffer> sstream std::stringstream ss;<CR>ss << value;<CR>std::string result = ss.str();<Esc>?value<CR>ciw

iabbrev <buffer> substr std::string sub = str.substr(pos, len);<Esc>?str<CR>ciw

" === Time Related ===
iabbrev <buffer> chrono auto start = std::chrono::high_resolution_clock::now();<CR>// code to time<CR>auto end = std::chrono::high_resolution_clock::now();<CR>auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

" === Common Assertions and Checks ===
iabbrev <buffer> static_ass static_assert(condition, "error message");<Esc>?condition<CR>ciw

" === Functional Programming Style ===
iabbrev <buffer> lambm auto mapper = [](const auto& x) { return transformation; };<Esc>?transformation<CR>ciw
iabbrev <buffer> lambf auto filter = [](const auto& x) { return condition; };<Esc>?condition<CR>ciw
iabbrev <buffer> lambr auto reducer = [](const auto& acc, const auto& x) { return result; };<Esc>?result<CR>ciw

" ========== Usage Instructions ==========
" How to use: Type the abbreviation in insert mode, then press space or other delimiter to expand
" 
" Examples:
" Type "fi " -> expands to for loop, cursor positioned at condition
" Type "classs " -> expands to class definition, cursor positioned at class name
" Type "incio" -> expands to #include <iostream>
"
" Tips:
" 1. Extra letters in abbreviations prevent conflicts with common words
" 2. Uses ?pattern<CR> for search positioning without showing in command line
" 3. Uses ciw to select and replace entire word
" 4. Customize abbreviations according to personal habits
