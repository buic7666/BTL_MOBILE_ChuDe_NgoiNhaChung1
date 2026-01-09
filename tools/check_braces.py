from pathlib import Path
p=Path('d:/BTL_MOBILE_ChuDe_NgoiNhaChung1/lib/features/finance/finance_main_screen.dart')
s=p.read_text(encoding='utf-8')
level=0
for i,line in enumerate(s.splitlines(),start=1):
    level += line.count('{') - line.count('}')
    if i<=240 or i>=240 and i<=340: # print some range to inspect
        print(f"{i:03d} L={level} | {line.rstrip()}")
print('\nFinal nesting level:', level)
