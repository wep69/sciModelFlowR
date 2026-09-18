from pathlib import Path
import re, csv, json, hashlib, sys

ROOT = Path(__file__).resolve().parents[1]
checks = []

def check(ok, label):
    checks.append((bool(ok), label))

api09 = list(csv.DictReader(open(ROOT / 'inst/metadata/API_FREEZE_0.9.0.csv', encoding='utf-8')))
api10 = list(csv.DictReader(open(ROOT / 'inst/metadata/API_FREEZE_1.0.0.csv', encoding='utf-8')))
ns = set(re.findall(r'(?m)^export\(([^)]+)\)$', (ROOT / 'NAMESPACE').read_text(encoding='utf-8')))
texts = {p.name: p.read_text(encoding='utf-8', errors='ignore') for p in (ROOT / 'R').glob('*.R')}

check(len(api09) == 246 and len(api10) == 246, 'API freeze contains 246 exports in both 0.9.0 and 1.0.0')
check([r['function_name'] for r in api09] == [r['function_name'] for r in api10], '0.9.0 -> 1.0.0 export names unchanged')
check([r['signature_prefix'] for r in api09] == [r['signature_prefix'] for r in api10], '0.9.0 -> 1.0.0 signature prefixes unchanged')

for row in api10:
    fn = row['function_name']
    sf = row['source_file']
    patt = re.compile(r'(?m)^' + re.escape(fn) + r'\s*<-\s*function\s*\(')
    hits = [nm for nm, t in texts.items() if patt.search(t)]
    check(fn in ns, f'API {fn}: exported')
    check(sf in hits, f'API {fn}: source definition matches freeze')

# Gold release manifest
gold = list(csv.DictReader(open(ROOT / 'inst/metadata/GOLD_RELEASE_MANIFEST_1.0.0.csv', encoding='utf-8')))
for r in gold:
    nm = r['dataset']
    f = ROOT / 'inst/extdata/gold' / f'{nm}.csv'
    got = hashlib.sha256(f.read_bytes()).hexdigest() if f.exists() else ''
    check(f.exists() and got.lower() == r['sha256'].lower(), f'Gold {nm}: release SHA-256 matches')
    check(r['known_truth_present'] == 'true' and r['card_present'] == 'true', f'Gold {nm}: truth/card release metadata complete')

required = [
    'API_FREEZE_1.0.0.csv', 'API_FREEZE_1.0.0.sha256',
    'API_DIFF_0.9.0_TO_1.0.0.csv', 'FINAL_COMPATIBILITY_MATRIX_1.0.0.csv',
    'BACKEND_MATRIX_1.0.0.csv', 'GOLD_RELEASE_MANIFEST_1.0.0.csv',
    'BENCHMARK_BASELINES_1.0.0.csv', 'SECURITY_REVIEW_1.0.0.json',
    'RELEASE_MANIFEST_1.0.0.json', 'BIBLIOGRAPHY_LEDGER_1.0.0.csv'
]
for x in required:
    check((ROOT / 'inst/metadata' / x).exists(), f'metadata {x} exists')

desc = (ROOT / 'DESCRIPTION').read_text(encoding='utf-8')
check(bool(re.search(r'(?m)^Version: 1\.0\.0$', desc)), 'DESCRIPTION version 1.0.0')
check((ROOT / 'NEWS.md').read_text(encoding='utf-8').startswith('# sciModelFlowR 1.0.0'), 'NEWS begins 1.0.0')
check('version: 1.0.0' in (ROOT / 'CITATION.cff').read_text(encoding='utf-8'), 'CITATION.cff version 1.0.0')
check('R package version 1.0.0' in (ROOT / 'inst/CITATION').read_text(encoding='utf-8'), 'inst/CITATION version 1.0.0')

nbs = list((ROOT / 'inst/notebooks/jupyter').glob('*.ipynb'))
for p in nbs:
    try:
        o = json.load(open(p, encoding='utf-8'))
        good = o.get('metadata', {}).get('sciModelFlowR', {}).get('release') == '1.0.0'
    except Exception:
        good = False
    check(good, f'Notebook {p.name}: release metadata 1.0.0')

for x in [
    'SECURITY_REVIEW_1.0.0.md', 'COMPATIBILITY_1.0.0.md',
    'MIGRATION_0.9.0_TO_1.0.0.md', 'RELEASE_NOTES_1.0.0.md',
    'RELEASE_CHECKLIST_1.0.0.md', 'BIBLIOGRAPHY_VERIFICATION_1.0.0.md'
]:
    check((ROOT / x).exists() and (ROOT / x).stat().st_size > 200, f'document {x} exists')

check(not re.search(r'\b(TODO|FIXME|XXX)\b', '\n'.join(texts.values())), 'no TODO/FIXME/XXX in R source')
source = '\n'.join(texts.values())
for pat, name in [
    (r'\bsystem2?\s*\(', 'system/system2'),
    (r'\bshell\s*\(', 'shell'),
    (r'eval\s*\(\s*parse\s*\(', 'eval(parse)'),
    (r'\bsource\s*\(', 'source'),
    (r'download\.file\s*\(', 'download.file')
]:
    check(not re.search(pat, source), f'no direct {name} call in package R source')

api_hash = (ROOT / 'inst/metadata/API_FREEZE_1.0.0.sha256').read_text().split()[0]
check(api_hash == hashlib.sha256((ROOT / 'inst/metadata/API_FREEZE_1.0.0.csv').read_bytes()).hexdigest(), 'API freeze SHA-256 valid')

failed = [x for x in checks if not x[0]]
out = ROOT / 'STATIC_AUDIT.md'
lines = [
    '# sciModelFlowR 1.0.0 definitive source-freeze static audit', '',
    f'**Result:** {len(checks) - len(failed)}/{len(checks)} checks passed.', '',
    'This audit validates the definitive frozen source/release structure only. Runtime, numerical, optional-backend, documentation-rendering and CRAN-style certification remain pending actual local execution.', '',
    '## Checks', ''
]
lines += [f"- [{'x' if ok else ' '}] {label}" for ok, label in checks]
if failed:
    lines += ['', '## Failures', ''] + [f'- {label}' for _, label in failed]
out.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f'STATIC VALIDATION sciModelFlowR 1.0.0 definitive source freeze: {len(checks)-len(failed)}/{len(checks)} passed')
for _, label in failed[:40]:
    print('FAIL:', label)
sys.exit(1 if failed else 0)
