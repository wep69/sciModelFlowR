from pathlib import Path
import re, json, hashlib, csv, sys
ROOT=Path(__file__).resolve().parents[1]
errors=[]; checks=[]

def check(ok,msg):
    ok=bool(ok); checks.append((ok,msg))
    if not ok: errors.append(msg)

def scan_r(text,path):
    local=[]; stack=[]; pairs={')':'(',']':'[','}':'{'}; opens=set(pairs.values()); i=0; line=1; quote=None; esc=False; backtick=False
    while i<len(text):
        ch=text[i]
        if ch=='\n': line+=1
        if backtick:
            if ch=='`': backtick=False
            i+=1; continue
        if quote:
            if esc: esc=False
            elif ch=='\\': esc=True
            elif ch==quote: quote=None
            i+=1; continue
        if ch=='`': backtick=True; i+=1; continue
        if ch in ('"',"'"): quote=ch; i+=1; continue
        if ch=='#':
            j=text.find('\n',i)
            if j<0: break
            i=j; continue
        if ch in opens: stack.append((ch,line))
        elif ch in pairs:
            if not stack or stack[-1][0]!=pairs[ch]: local.append(f'{path}: unmatched {ch} at line {line}'); return local
            stack.pop()
        i+=1
    if quote: local.append(f'{path}: unterminated quote')
    if backtick: local.append(f'{path}: unterminated backtick')
    if stack: local.append(f'{path}: unclosed delimiters {stack[-5:]}')
    return local

# Source / NAMESPACE / roxygen parity
rfiles=sorted((ROOT/'R').glob('*.R'))
scan_errors=[]
for p in rfiles: scan_errors += scan_r(p.read_text(encoding='utf-8'),p.relative_to(ROOT))
check(len(rfiles)==46,f'46 R source files present ({len(rfiles)})')
check(not scan_errors,'R delimiter/quote scan passes' if not scan_errors else '; '.join(scan_errors[:5]))
ns=(ROOT/'NAMESPACE').read_text(encoding='utf-8')
exports=re.findall(r'^export\(([^)]+)\)',ns,re.M)
allr='\n'.join(p.read_text(encoding='utf-8') for p in rfiles)
defs=set(re.findall(r'(?m)^([A-Za-z.][A-Za-z0-9._]*)\s*<-\s*function\s*\(',allr))
rox=set(re.findall(r"#' @export\s*\n([A-Za-z.][A-Za-z0-9._]*)\s*<-\s*function",allr))
check(len(exports)==234,f'234 public exports declared ({len(exports)})')
check(len(exports)==len(set(exports)),'public exports are unique')
check(not sorted(set(exports)-defs),'all public exports resolve to function definitions')
check(rox==set(exports),f'roxygen/NAMESPACE export parity ({len(rox)})')
check('S3method(' not in ns,'no stale S3method entries in NAMESPACE')
check('S7::methods_register()' in allr,'S7 dynamic method registration retained')

# 0.8 public API
api080={
'smf_tracking_spec','smf_tracker_local','smf_tracker_mlflow','smf_start_run','smf_log_metric','smf_log_params','smf_log_artifact','smf_log_result','smf_end_run','smf_list_runs','smf_get_run',
'smf_persistence_spec','smf_deployment_spec','smf_scalability_spec','smf_save_bundle','smf_validate_bundle','smf_load_bundle','smf_predict_bundle','smf_bundle_info','smf_hardware_info',
'smf_vetiver_model','smf_vetiver_pin_write','smf_pins_publish_bundle','smf_pins_fetch_bundle','smf_write_plumber','smf_export_onnx',
'smf_chunk_plan','smf_data_iterator','smf_iterator_next','smf_iterator_reset','smf_batch_predict','smf_map_iterator'}
check(api080.issubset(set(exports)),f'all {len(api080)} version-0.8 public functions present')

# Core class / spec evolution
core=(ROOT/'R/core-classes.R').read_text(encoding='utf-8')
core080=(ROOT/'R/core-classes-080.R').read_text(encoding='utf-8')
for cls in ['TrackingSpec','PersistenceSpec','DeploymentSpec','ScalabilitySpec','TrackerRun','BundleValidationResult','InferenceBundle','BatchPredictionResult']:
    check(f'"{cls}"' in core080,f'{cls} contract present')
for fld in ['tracking=S7::class_any','persistence=S7::class_any','deployment=S7::class_any','scalability=S7::class_any']:
    check(fld in core,f'ExperimentSpec contains {fld.split("=")[0]} component')
check('hardware=S7::class_any' in core,'RunManifest contains hardware provenance')
check('calibration=S7::class_any' in core080,'InferenceBundle retains calibration state')
construct=(ROOT/'R/spec-constructors.R').read_text(encoding='utf-8')
for token in ['tracking=tracking','persistence=persistence','deployment=deployment','scalability=scalability']:
    check(token in construct,f'ExperimentSpec constructor forwards {token.split("=")[0]}')

# Serialization backward compatibility
ser=(ROOT/'R/core-serialization.R').read_text(encoding='utf-8')
for cls in ['TrackingSpec','PersistenceSpec','DeploymentSpec','ScalabilitySpec','TrackerRun','BundleValidationResult','InferenceBundle','BatchPredictionResult']:
    check(f'{cls}={cls}' in ser,f'{cls} included in portable class map')
for fld in ['tracking','persistence','deployment','scalability']:
    check(f'x${fld} <- NULL' in ser,f'older ExperimentSpec payloads receive {fld}=NULL')
check('x$hardware <- list()' in ser,'older RunManifest payloads receive hardware=list()')

# Tracking
tracking=(ROOT/'R/tracking.R').read_text(encoding='utf-8')
for token,msg in [
('TRACK_RUN_FINISHED','finished-run resume is blocked'),('MLFLOW_MISSING','optional MLflow absence is explicit'),('smf_tracker_local','dependency-light local tracker present'),('smf_tracker_mlflow','optional MLflow tracker present'),('.smf_atomic_write_json','tracker writes metadata atomically'),('resume_run_id=character()','explicit resume semantics present')]: check(token in tracking,msg)

# Persistence / security / compatibility
pers=(ROOT/'R/persistence.R').read_text(encoding='utf-8')
for token,msg in [
('checksums.sha256','bundle checksum manifest present'),('BUNDLE_CHECKSUM_MISMATCH','checksum corruption is blocking'),('BUNDLE_SCHEMA_MAJOR_INCOMPATIBLE','major schema mismatch is blocking'),('UNTRUSTED_BUNDLE','opaque loading requires explicit trust'),('model_state.json','portable model state path present'),('model/model.rds','opaque model state path present'),('trusted=FALSE','safe loading default is untrusted'),('smf_apply_calibration(bundle@calibration,prob)','loaded calibrated classifiers replay calibration'),('BUNDLE_SCHEMA_TYPE_MISMATCH','strict schema type guard present'),('PORTABLE_BUNDLE_UNSUPPORTED','portable mode refuses unsupported scientific state')]: check(token in pers,msg)
check('calibration<-if(file.exists(file.path(path,"calibration.rds")))readRDS' in pers,'opaque bundle loads calibration only after trust gate')

# Deployment adapters / no blind equivalence claims
dep=(ROOT/'R/deployment.R').read_text(encoding='utf-8')
for token,msg in [
('VETIVER_PIPELINE_NOT_PORTABLE','vetiver adapter refuses non-equivalent pipeline'),('PINS_MISSING','pins remains optional'),('VETIVER_MISSING','vetiver remains optional'),('ONNX_EXPORT_UNAVAILABLE','ONNX has no unvalidated automatic exporter'),('ONNX equivalence is not implied','ONNX export explicitly disclaims equivalence'),('smf_validate_bundle(bundle_path)','pins publication validates bundle first')]: check(token in dep,msg)

# Scalability / resume
scal=(ROOT/'R/scalability.R').read_text(encoding='utf-8')
for token,msg in [
('BATCH_RESUME_MISMATCH','batch resume identity mismatch is blocking'),('BATCH_CHECKPOINT_CORRUPT','corrupted checkpoint is blocking'),('smf_chunk_plan','deterministic chunk planning present'),('smf_iterator_reset','iterator reset semantics present'),('parallel::makePSOCKcluster','optional process-parallel execution present'),('smf_data_hash(new_data)','batch resume records data identity')]: check(token in scal,msg)

# Hardware provenance
prov=(ROOT/'R/provenance.R').read_text(encoding='utf-8')
for token,msg in [('parallel::detectCores','CPU core detection present'),('torch::cuda_is_available()','GPU availability capture present'),('torch::cuda_runtime_version()','CUDA runtime capture present'),('CUDA_VISIBLE_DEVICES','CUDA visibility environment captured')]: check(token in prov,msg)
exp=(ROOT/'R/experiment.R').read_text(encoding='utf-8')
check('hardware=.smf_hardware_info()' in exp,'managed RunManifest receives hardware provenance')

# Optional dependency isolation and capabilities
desc=(ROOT/'DESCRIPTION').read_text(encoding='utf-8')
check(bool(re.search(r'(?m)^Version: 0\.8\.0$',desc)),'DESCRIPTION marks final 0.8.0 version')
for depname in ['mlflow','pins','vetiver','plumber']:
    check(re.search(r'(?m)^\s*'+re.escape(depname)+r',?\s*$',desc) is not None,f'{depname} declared as optional dependency')
imports=desc.split('Imports:',1)[1].split('Suggests:',1)[0]
check(all(x not in imports for x in ['mlflow','pins','vetiver','plumber','torch','brms','xgboost']),'heavy operational/model backends absent from Imports')
caps=(ROOT/'R/core-capabilities.R').read_text(encoding='utf-8')
check('cap@safe_export <- TRUE' in caps,'stats backend advertises validated safe-export capability')

# Retained scientific safeguards from earlier releases
retained=[
('R/experiment.R','CALIBRATION_TEST_OVERLAP','calibration/test overlap guard retained'),
('R/imbalance.R','smf_leakage_error','imbalance leakage guard retained'),
('R/tuning-core.R','TEST_DATA_IN_TUNING','test data blocked from tuning'),
('R/benchmark.R','no_universal_winner=is.null(benchmark@decision_rule)','benchmark avoids implicit universal winner'),
('R/explain.R','causal_interpretation=FALSE','XAI remains explicitly non-causal'),
('R/explain-stability.R','EXTERNAL_TEST_IN_EXPLANATION_STABILITY','external test blocked from explanation stability'),
('R/deep-learning-train.R','TEST_DATA_IN_DL_VALIDATION','final/external test blocked from neural validation'),
('R/deep-learning-train.R','UNTRUSTED_CHECKPOINT','unsafe checkpoint loading remains blocked'),
('R/conformal.R','CONFORMAL_TEST_OVERLAP','conformal calibration/final-test overlap guard retained'),
('R/uncertainty.R','UNCERTAINTY_NOT_IDENTIFIABLE','non-identifiable uncertainty decomposition remains blocked')]
for rel,token,msg in retained: check(token in (ROOT/rel).read_text(encoding='utf-8'),msg)

# Gold datasets and hashes
with (ROOT/'inst/gold/gold_hashes.csv').open(newline='',encoding='utf-8') as f: rows=list(csv.DictReader(f))
hash_ok=True
for row in rows:
    p=ROOT/'inst/extdata/gold'/f"{row['dataset']}.csv"
    if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest().lower()!=row['sha256'].lower(): hash_ok=False
check(len(rows)==12,f'12 Gold datasets registered ({len(rows)})')
check(hash_ok,'all 12 Gold SHA-256 hashes verified')
check(len(list((ROOT/'inst/gold/cards').glob('*.md')))>=12,'Gold dataset cards distributed')

# Cross-language fixtures
json_ok=True; json_n=0
for p in (ROOT/'inst/crosslang').rglob('*.json'):
    json_n+=1
    try: json.loads(p.read_text(encoding='utf-8'))
    except Exception as e: json_ok=False; errors.append(f'{p.relative_to(ROOT)} invalid JSON: {e}')
check(json_ok and json_n==16,f'16 cross-language JSON fixtures parsed ({json_n})')
check(len([p for p in (ROOT/'inst/crosslang').rglob('*') if p.is_file()])==17,'17 total cross-language fixtures present including frozen CSV')
for rel in ['inst/crosslang/operations/bundle_schema_v1.json','inst/crosslang/operations/tracking_run_v1.json','inst/crosslang/operations/batch_manifest_v1.json']:
    check((ROOT/rel).exists(),f'{rel} present')

# Public calls in test/tool/vignette surfaces resolve
used=set()
for base in [ROOT/'tests/testthat',ROOT/'tools',ROOT/'vignettes']:
    for p in base.rglob('*'):
        if p.is_file() and p.suffix in {'.R','.qmd','.md','.py'}:
            used |= set(re.findall(r'(?<!\.)(?<![A-Za-z0-9_])(smf_[A-Za-z0-9_]+)\s*\(',p.read_text(encoding='utf-8',errors='ignore')))
unknown=sorted(used-set(exports)-defs)
check(not unknown,'all smf_* calls in tests/tools/vignettes resolve to source definitions' if not unknown else 'unresolved smf calls: '+', '.join(unknown))

# Tests / validation entry points
tests=sorted((ROOT/'tests/testthat').glob('test-*.R'))
check(len(tests)==52,f'52 testthat files present ({len(tests)})')
for fn in ['test-specs-080.R','test-tracking-080.R','test-persistence-080.R','test-batch-080.R','test-deployment-080.R']:
    check((ROOT/'tests/testthat'/fn).exists(),f'{fn} present')
persist_test=(ROOT/'tests/testthat/test-persistence-080.R').read_text(encoding='utf-8')
for token,msg in [('portable bundle round-trip reproduces predictions','portable prediction differential test present'),('checksum corruption is rejected before loading','corruption rejection test present'),('opaque bundles require explicit trust','opaque trust test present'),('replays calibration after trusted load','calibrated opaque replay test present')]: check(token in persist_test,msg)
for fn in ['validate_0.8.0.R','validate_0.8.0_scalability.R']:
    p=ROOT/'tools'/fn; check(p.exists(),f'{fn} present'); check('0.8.0' in p.read_text(encoding='utf-8'),f'{fn} targets 0.8.0')

# Documentation aliases
aliases=set()
for p in (ROOT/'man').glob('*.Rd'): aliases |= set(re.findall(r'\\alias\{([^}]+)\}',p.read_text(encoding='utf-8')))
undoc=sorted(set(exports)-aliases)
check(not undoc,'every public export has an Rd alias' if not undoc else 'missing Rd aliases: '+', '.join(undoc))
for fun in sorted(api080): check(fun in aliases,f'{fun} has Rd alias')
pkg_rd=(ROOT/'man/sciModelFlowR-package.Rd').read_text(encoding='utf-8')
check('Version 0.8.0' in pkg_rd and 'experiment tracking' in pkg_rd,'package Rd reflects 0.8.0 operational scope')

# Vignette extension contract
def words(p): return len(re.findall(r"\b[\w'-]+\b",p.read_text(encoding='utf-8'),flags=re.UNICODE))
integ=ROOT/'vignettes/v01-foundations-to-advanced-scientific-modeling.qmd'; n=words(integ)
check(8500<=n<=10000,f'integrating vignette word count {n} within 8500-10000')
focused=[p for p in sorted((ROOT/'vignettes').glob('v*.qmd')) if p.name not in {'v00-overview.qmd','v01-foundations-to-advanced-scientific-modeling.qmd'}]
for p in focused:
    m=words(p); ratio=m/n; check(.60<=ratio<=.70,f'{p.name} word count {m} is {ratio:.1%} of integrating vignette')
check((ROOT/'vignettes/v20-tracking-persistence-and-scalable-inference.qmd').exists(),'v20 tracking/persistence/scalability vignette present')

# Lesson contract / notebook
lesson=ROOT/'inst/lesson-contracts/tracking-persistence-and-scalable-inference.yml'
check(lesson.exists() and 'release: 0.8.0' in lesson.read_text(encoding='utf-8'),'0.8.0 lesson contract present')
nb=ROOT/'inst/notebooks/jupyter/20-tracking-persistence-and-scalable-inference.ipynb'
good=False
try:
    obj=json.loads(nb.read_text(encoding='utf-8')); good=obj.get('metadata',{}).get('kernelspec',{}).get('name')=='ir'
except Exception: pass
check(good,'0.8.0 IRkernel notebook is valid JSON with IR kernel')

# Release metadata
check('version: 0.8.0' in (ROOT/'CITATION.cff').read_text(encoding='utf-8'),'CITATION.cff version synchronized')
check('R package version 0.8.0' in (ROOT/'inst/CITATION').read_text(encoding='utf-8'),'inst/CITATION version synchronized')
check((ROOT/'NEWS.md').read_text(encoding='utf-8').splitlines()[0].strip()=='# sciModelFlowR 0.8.0','NEWS begins with 0.8.0')
check('Version **0.8.0**' in (ROOT/'README.md').read_text(encoding='utf-8'),'README marks 0.8.0')
check('implementation-complete' in (ROOT/'IMPLEMENTATION_SUMMARY.md').read_text(encoding='utf-8').lower(),'implementation summary records implementation-complete')
check('validation-deferred' in (ROOT/'IMPLEMENTATION_SUMMARY.md').read_text(encoding='utf-8'),'implementation summary records validation-deferred')
pkgdown=(ROOT/'_pkgdown.yml').read_text(encoding='utf-8')
check('v20-tracking-persistence-and-scalable-inference' in pkgdown,'pkgdown index includes v20')

# No executable placeholders / stale release labels
placeholder=[]
for p in list((ROOT/'R').glob('*.R'))+[ROOT/'DESCRIPTION',ROOT/'NAMESPACE']:
    for i,line in enumerate(p.read_text(encoding='utf-8').splitlines(),1):
        if re.search(r'\b(TODO|FIXME|XXX)\b',line): placeholder.append(f'{p.relative_to(ROOT)}:{i}')
check(not placeholder,'no TODO/FIXME/XXX placeholders in executable source')
for rel in ['IMPLEMENTATION_SUMMARY.md','VALIDATION.md','LOCAL_VALIDATION.md','PACKAGE_PLAN.md','README.md']:
    txt=(ROOT/rel).read_text(encoding='utf-8')
    check('sciModelFlowR 0.7.0' not in txt,f'{rel} is not mislabeled as release 0.7.0')

print('STATIC VALIDATION sciModelFlowR 0.8.0')
for ok,msg in checks: print(('PASS' if ok else 'FAIL')+': '+msg)
if errors:
    print('\nERRORS')
    for e in errors: print('ERROR: '+e)
    sys.exit(1)
print(f'\nPASS: {len(checks)} checks; {len(rfiles)} R files; {len(exports)} exports; runtime R status intentionally not evaluated')
