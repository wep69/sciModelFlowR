from pathlib import Path
import re,csv,json,hashlib,sys
ROOT=Path(__file__).resolve().parents[1]
checks=[]
def check(ok,label): checks.append((bool(ok),label))
# 1) 246 exports x 4 = 984
api=list(csv.DictReader(open(ROOT/'inst/metadata/API_FREEZE_0.9.0.csv',encoding='utf-8')))
ns=set(re.findall(r'(?m)^export\(([^)]+)\)$',(ROOT/'NAMESPACE').read_text(encoding='utf-8')))
texts={p.name:p.read_text(encoding='utf-8',errors='ignore') for p in (ROOT/'R').glob('*.R')}
for row in api:
    fn=row['function_name']; sf=row['source_file']
    patt=re.compile(r'(?m)^'+re.escape(fn)+r'\s*<-\s*function\s*\(')
    hits=[nm for nm,t in texts.items() if patt.search(t)]
    check(fn in ns,f'API {fn}: exported in NAMESPACE')
    check(bool(hits),f'API {fn}: source definition exists')
    check(sf in hits,f'API {fn}: source_file matches freeze')
    if sf in texts:
        m=patt.search(texts[sf]); pre=texts[sf][max(0,(m.start() if m else 0)-800):(m.start() if m else 0)] if m else ''
        check('@export' in pre,f'API {fn}: roxygen export tag present')
    else: check(False,f'API {fn}: roxygen export tag present')
# 2) 25 Gold x4 =100
truth=json.load(open(ROOT/'inst/gold/known_truth.json',encoding='utf-8'))
hashes={r['dataset']:r['sha256'] for r in csv.DictReader(open(ROOT/'inst/gold/gold_hashes.csv',encoding='utf-8'))}
gold_names=[]
for row in csv.DictReader(open(ROOT/'inst/gold/gold_hashes.csv',encoding='utf-8')): gold_names.append(row['dataset'])
for nm in gold_names:
    f=ROOT/'inst/extdata/gold'/f'{nm}.csv'; card=ROOT/'inst/gold/cards'/f'{nm}.md'
    check(f.exists(),f'Gold {nm}: CSV exists')
    got=hashlib.sha256(f.read_bytes()).hexdigest() if f.exists() else ''
    check(got.lower()==hashes.get(nm,'').lower(),f'Gold {nm}: SHA-256 matches')
    check(card.exists() and len(card.read_text(encoding='utf-8',errors='ignore'))>40,f'Gold {nm}: dataset card exists')
    check(nm in truth,f'Gold {nm}: known truth metadata exists')
# 3) 25 crosslang x2 =50
cross_files=sorted([p for p in (ROOT/'inst/crosslang').rglob('*') if p.is_file()])
for p in cross_files:
    check(p.exists() and p.stat().st_size>0,f'Crosslang {p.relative_to(ROOT)}: exists')
    ok=True
    try:
        if p.suffix.lower()=='.json': json.load(open(p,encoding='utf-8'))
        elif p.suffix.lower()=='.csv': list(csv.reader(open(p,encoding='utf-8')))
        else: p.read_text(encoding='utf-8')
    except Exception: ok=False
    check(ok,f'Crosslang {p.relative_to(ROOT)}: parses')
# 4) 28 lesson contracts x1 =28
contracts=sorted([p for p in (ROOT/'inst/lesson-contracts').glob('*') if p.is_file()])
for p in contracts:
    t=p.read_text(encoding='utf-8',errors='ignore')
    check(('id:' in t and 'learning_objectives:' in t),f'Lesson {p.name}: contract fields present')
# 5) 27 notebooks x2 =54
nbs=sorted((ROOT/'inst/notebooks/jupyter').glob('*.ipynb'))
for p in nbs:
    ok=True; obj=None
    try: obj=json.load(open(p,encoding='utf-8'))
    except Exception: ok=False
    check(ok,f'Notebook {p.name}: valid JSON')
    good=bool(obj and obj.get('metadata',{}).get('kernelspec',{}).get('name')=='ir' and obj.get('metadata',{}).get('sciModelFlowR',{}).get('release')=='0.9.0')
    check(good,f'Notebook {p.name}: IRkernel and release metadata')
# 6) 10 release metadata checks => total 1226
desc=(ROOT/'DESCRIPTION').read_text(encoding='utf-8')
check(bool(re.search(r'(?m)^Version: 0\.9\.0$',desc)),'DESCRIPTION version is 0.9.0')
check((ROOT/'NEWS.md').read_text(encoding='utf-8').splitlines()[0].strip()=='# sciModelFlowR 0.9.0','NEWS begins with 0.9.0')
check('Version 0.9.0' in (ROOT/'README.md').read_text(encoding='utf-8'),'README marks 0.9.0')
check('version: 0.9.0' in (ROOT/'CITATION.cff').read_text(encoding='utf-8') and 'R package version 0.9.0' in (ROOT/'inst/CITATION').read_text(encoding='utf-8'),'CITATION metadata synchronized')
check(len(texts)==50 and len(api)==246 and len(list((ROOT/'tests/testthat').glob('test-*.R')))==59,'source/API/test counts match RC contract')
api_hash=(ROOT/'inst/metadata/API_FREEZE_0.9.0.sha256').read_text().split()[0]
check(api_hash==hashlib.sha256((ROOT/'inst/metadata/API_FREEZE_0.9.0.csv').read_bytes()).hexdigest(),'API freeze SHA-256 valid')
bm=list(csv.DictReader(open(ROOT/'inst/metadata/BACKEND_MATRIX_0.9.0.csv',encoding='utf-8')))
check(all(r['release_status'] in ('pending-final-runtime','quarantined-pending-local-validation') for r in bm),'optional backend release statuses are quarantined/pending')
# vignette contract v02-v27
def words(p): return len(re.findall(r"\b[\w'-]+\b",p.read_text(encoding='utf-8',errors='ignore')))
base=words(ROOT/'vignettes/v01-foundations-to-advanced-scientific-modeling.qmd')
focused=sorted([p for p in (ROOT/'vignettes').glob('v*.qmd') if re.match(r'v(0[2-9]|1[0-9]|2[0-7])-',p.name)])
rat=[words(p)/base for p in focused]
check(len(focused)==26 and all(0.60 <= x <= 0.70 for x in rat),'all focused vignettes satisfy 60-70 percent length contract')
needed=['validate_0.9.0.R','validate_0.9.0_differential.R','validate_0.9.0_curriculum.R','validate_0.9.0_release_candidate.R']
check(all((ROOT/'tools'/x).exists() for x in needed),'0.9.0 local validation entry points present')
# no unresolved source markers
source_text='\n'.join(texts.values())
check(not re.search(r'\b(TODO|FIXME|XXX)\b',source_text),'no unresolved TODO/FIXME/XXX markers in R source')
# fixed contract count
assert len(checks)==1226, len(checks)
failed=[x for x in checks if not x[0]]
out=ROOT/'STATIC_AUDIT.md'
lines=['# sciModelFlowR 0.9.0 final static audit','',f'**Result:** {len(checks)-len(failed)}/{len(checks)} checks passed.','', 'Runtime and numerical certification remain deliberately deferred to the consolidated local validation campaign.','', '## Checks','']
lines += [f"- [{'x' if ok else ' '}] {label}" for ok,label in checks]
if failed:
    lines += ['', '## Failures',''] + [f'- {label}' for _,label in failed]
out.write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(f'STATIC VALIDATION sciModelFlowR 0.9.0: {len(checks)-len(failed)}/{len(checks)} passed')
for _,label in failed[:40]: print('FAIL:',label)
sys.exit(1 if failed else 0)
