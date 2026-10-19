function run_formal8_independent_test_R2019a(mode)
%RUN_FORMAL8_INDEPENDENT_TEST_R2019A Locked independent-test extension.
%   run_formal8_independent_test_R2019a('audit') replays ORL/20260627.
%   run_formal8_independent_test_R2019a('new') runs seeds 20260637:20260646.
% MATLAB R2019a compatible. Results are resumable at method level.

if nargin<1 || isempty(mode), mode='new'; end
root_dir=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root_dir,'experiments','config'));
addpath(fullfile(root_dir,'experiments','adapters'));
cfg=pce_protocol_config(root_dir);
cfg.max_iter=200;
cfg.tol=0; % fixed-iteration adapters ignore tolerance; prevents early NMF stop
cfg.pce_lambda=100;
pce_p=[2 2 4 3 3 2];
sn_p=[3 3 4 3 3 3];

if strcmpi(mode,'audit')
    dataset_ids=4; seeds=20260627;
    out_dir=fullfile(root_dir,'results','formal8_independent_test_audit');
elseif strcmpi(mode,'new')
    dataset_ids=1:numel(cfg.datasets); seeds=20260637:20260646;
    out_dir=fullfile(root_dir,'results','formal8_independent_test_new10');
else
    error('Mode must be ''audit'' or ''new''.');
end
if ~exist(out_dir,'dir'), mkdir(out_dir); end
raw_file=fullfile(out_dir,'raw.csv');
if exist(raw_file,'file')~=2
    fid=fopen(raw_file,'w');
    fprintf(fid,['dataset,seed,method,n_labeled,n_unlabeled,ACC_unlabeled,' ...
        'direct_ACC_unlabeled,NMI_unlabeled,runtime_seconds,iterations,' ...
        'finite_output,status,init_mode,parameter_tag,source_id,message\n']);
    fclose(fid);
end
done=local_done(raw_file);
diary(fullfile(out_dir,'diagnostics.txt'));
cleaner=onCleanup(@() diary('off')); %#ok<NASGU>
fprintf('Independent test started %s mode=%s\n',datestr(now,31),mode);
fprintf('New seeds are 20260637:20260646; no parameters may be changed.\n');

for d=dataset_ids
    ds=cfg.datasets{d}; [X,y]=local_load(cfg,ds); K=max(y); [m,n]=size(X);
    for si=1:numel(seeds)
        seed=seeds(si);
        local_seed(seed); labeled=local_split(y,cfg.label_ratio); unlabeled=~labeled;
        % This is the common initialization stream used by the external adapters.
        W0=max(rand(m,K),eps); H0=max(rand(K,n),eps);
        for q=1:numel(cfg.methods)
            method=cfg.methods{q}; key=sprintf('%s|%d|%s',ds,seed,method);
            if any(strcmp(done,key)), fprintf('Resume skip %s\n',key); continue; end
            opt=cfg; opt.dataset=ds; opt.dataset_index=d; opt.seed=seed;
            if strcmp(method,'SNMFWLP'), opt.graph_p=sn_p; else, opt.graph_p=pce_p; end
            status='OK'; msg=''; acc=NaN; direct=NaN; nmi=NaN;
            info=local_info();
            try
                if strcmp(method,'PCE_NMF')
                    % Preserve the verified formal PCE initialization exactly.
                    local_seed(seed+97); U0=rand(m,K)+0.01; V0=rand(n,K)+0.01;
                    local_seed(seed);
                    [pred,info]=run_PCE_HCE_FORMAL_CORE_STABILIZED(X,y,labeled,U0,V0,opt,100);
                else
                    local_seed(seed);
                    [pred,info]=feval(['run_' method],X,y,labeled,W0,H0,opt);
                end
                truth=y(unlabeled); guess=pred(unlabeled);
                direct=mean(guess==truth);
                mapped=bestMap(truth,guess);
                acc=mean(mapped(:)==truth(:));
                nmi=local_nmi(truth,guess);
                finite_output=double(all(isfinite([acc direct nmi info.runtime_sec])));
                if ~finite_output, error('Non-finite metric or runtime.'); end
            catch err
                status='FAILED'; msg=err.message; finite_output=0;
                fprintf(2,'%s FAILED: %s\n',key,msg);
            end
            local_append(raw_file,ds,seed,method,sum(labeled),sum(unlabeled), ...
                acc,direct,nmi,info,finite_output,status,msg);
            fprintf('%s ACC=%.6f direct=%.6f NMI=%.6f time=%.3fs %s\n', ...
                key,acc,direct,nmi,info.runtime_sec,status);
            if strcmp(status,'OK'), done{end+1}=key; end %#ok<AGROW>
        end
    end
end
fprintf('Independent test mode %s completed %s\n',mode,datestr(now,31));
end

function done=local_done(raw_file)
done={}; T=readtable(raw_file,'Delimiter',',');
if isempty(T), return; end
ok=find(strcmp(T.status,'OK'));
for i=1:numel(ok)
    done{end+1}=sprintf('%s|%d|%s',T.dataset{ok(i)},T.seed(ok(i)),T.method{ok(i)}); %#ok<AGROW>
end
end

function [X,y]=local_load(cfg,name)
S=load(fullfile(cfg.data_dir,[name '.mat']));
if isfield(S,'X'), X=S.X; elseif isfield(S,'fea'), X=S.fea'; else, error('Need X or fea.'); end
if isfield(S,'y'), y=S.y; elseif isfield(S,'gnd'), y=S.gnd; else, error('Need y or gnd.'); end
X=double(X); y=double(y(:));
if size(X,2)~=numel(y), if size(X,1)==numel(y), X=X'; else, error('Dimension mismatch.'); end, end
[~,~,y]=unique(y); nr=sqrt(sum(X.^2,1)); nr(nr==0)=1; X=bsxfun(@rdivide,X,nr);
if any(~isfinite(X(:))) || any(X(:)<0), error('X must be finite and nonnegative.'); end
end

function labeled=local_split(y,ratio)
labeled=false(numel(y),1);
for k=1:max(y)
    idx=find(y==k); idx=idx(randperm(numel(idx)));
    labeled(idx(1:max(1,floor(ratio*numel(idx)))))=true;
end
end

function local_seed(seed)
rand('twister',seed); randn('state',seed); %#ok<RAND>
end

function z=local_nmi(a,b)
a=a(:); b=b(:); ua=unique(a); ub=unique(b); n=numel(a); mi=0;
pa=zeros(numel(ua),1); pb=zeros(numel(ub),1);
for i=1:numel(ua), pa(i)=sum(a==ua(i))/n; end
for j=1:numel(ub), pb(j)=sum(b==ub(j))/n; end
for i=1:numel(ua)
    for j=1:numel(ub)
        pij=sum(a==ua(i)&b==ub(j))/n;
        if pij>0, mi=mi+pij*log(pij/(pa(i)*pb(j))); end
    end
end
ha=-sum(pa(pa>0).*log(pa(pa>0))); hb=-sum(pb(pb>0).*log(pb(pb>0)));
z=mi/max(sqrt(ha*hb),eps);
end

function info=local_info
info.iterations=NaN; info.runtime_sec=NaN; info.init_mode='unknown';
info.parameter_tag='unknown'; info.source_id='unknown';
end

function local_append(file,ds,seed,method,nl,nu,acc,direct,nmi,info,finite_output,status,msg)
msg=local_safe(msg); im=local_safe(info.init_mode); pt=local_safe(info.parameter_tag); sid=local_safe(info.source_id);
fid=fopen(file,'a'); cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s,%d,%s,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%d,%s,%s,%s,%s,%s\n', ...
    ds,seed,method,nl,nu,acc,direct,nmi,info.runtime_sec,info.iterations, ...
    finite_output,status,im,pt,sid,msg);
end

function s=local_safe(s)
if ~ischar(s), s=''; end
s=strrep(s,',',';'); s=strrep(s,sprintf('\n'),' '); s=strrep(s,sprintf('\r'),' ');
end
