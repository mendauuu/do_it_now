import sys
path=r"c:\Users\HP\Desktop\do_it_now\lib\ui\ui_screens\analysis\analysis_screen.dart"
text=open(path,'r',encoding='utf-8').read()
stack=[]
for i,ch in enumerate(text):
    if ch=='(':
        stack.append(i)
    elif ch==')':
        if not stack:
            print('unmatched ) at',i)
        else:
            stack.pop()
print('remaining opens count',len(stack))
if stack:
    for pos in stack[:10]:
        line=text.count('\n',0,pos)+1
        print('unmatched ( at line',line)
