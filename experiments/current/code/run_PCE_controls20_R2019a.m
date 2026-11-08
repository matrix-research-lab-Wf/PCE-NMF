function run_PCE_controls20_R2019a(dataset_ids,seeds)
%RUN_PCE_CONTROLS20_R2019A Resumable HCE-NMF and LP-only controls.
% Tests fixed questions:
% Q2: PCE-NMF versus HCE-NMF isolates propagated exclusion.
% Q3: PCE-NMF versus LP-only isolates coupling with factorization.
% A result changes the mechanism claim only when the paired PCE difference
% is consistent and survives the pre-specified Holm-corrected analysis.
cfg=rebuild_config();
if nargin<1 || isempty(dataset_ids), dataset_ids=1:numel(cfg.datasets); end
if nargin<2 || isempty(seeds), seeds=cfg.seeds_formal; end
if any(~ismember(dataset_ids,1:numel(cfg.datasets))), error('Invalid dataset id.'); end
if any(~ismember(seeds,cfg.seeds_formal)), error('Seeds must belong to the formal lock.'); end
addpath(cfg.adapter_dir);
out_dir=fullfile(cfg.results_dir,'controls20'); if exist(out_dir,'dir')~=7, mkdir(out_dir); end
raw_file=fullfile(out_dir,'raw.csv'); local_init(raw_file); done=local_keys(raw_file);
methods={'HCE_NMF','Harmonic_LP_only'};
for d=dataset_ids
    [X,y]=local_load(cfg,d); [m,n]=size(X); c=max(y);
    for seed=seeds
        local_seed(seed); labeled=local_split(y,cfg.label_ratio); unlabeled=~labeled;
        W0=max(rand(m,c),eps); H0=max(rand(c,n),eps);
        for j=1:numel(methods)
            method=methods{j}; key=sprintf('%s|%d|%s',cfg.datasets{d},seed,method);
            if isKey(done,key), continue; end
            M=empty_metrics(); info=empty_info(); status='OK'; msg=''; finite=0; native=NaN;
            try
                opt=cfg; opt.dataset=cfg.datasets{d}; opt.dataset_index=d; opt.seed=seed;
                opt.graph_p=cfg.pce_p_locked; local_seed(seed);
                if strcmp(method,'HCE_NMF')
                    [pred,info]=run_HCE_NMF(X,y,labeled,W0,H0,opt);
                else
                    [pred,info]=run_Harmonic_LP_only(X,y,labeled,opt);
                end
                pred=pred(:); truth=y(unlabeled); guess=pred(unlabeled);
                if numel(pred)~=n || any(~isfinite(pred)), error('Invalid prediction vector.'); end
                M=pce_clustering_metrics(truth,guess); native=mean(guess==truth);
                finite=double(all(isfinite([M.ACC M.NMI M.Purity M.Fscore M.Precision M.Recall native info.runtime_sec])));
                if ~finite, error('Non-finite control output.'); end
            catch err, status='FAILED'; msg=err.message; end
            append_row(raw_file,cfg.datasets{d},seed,method,n,m,c,sum(labeled),sum(unlabeled),M,native,info,finite,status,msg);
            done(key)=true; fprintf('%s seed=%d %-16s ACC=%.5f NMI=%.5f %s\n',cfg.datasets{d},seed,method,M.ACC,M.NMI,status);
        end
    end
end
end

function [X,y]=local_load(cfg,d)
S=load(fullfile(cfg.data_dir,[cfg.datasets{d} '.mat']));
if isfield(S,'fea'),X=double(S.fea');else,X=double(S.X');end
if isfield(S,'gnd'),y=double(S.gnd(:));else,y=double(S.Y(:));end
if size(X,2)~=numel(y),X=X';end; [~,~,y]=unique(y);
if size(X,2)~=cfg.expected_samples(d)||size(X,1)~=cfg.expected_features(d)||max(y)~=cfg.expected_classes(d),error('Audited identity changed.');end
nr=sqrt(sum(X.^2,1));nr(nr==0)=1;X=bsxfun(@rdivide,X,nr);
end
function labeled=local_split(y,ratio)
labeled=false(numel(y),1);for k=1:max(y),idx=find(y==k);idx=idx(randperm(numel(idx)));labeled(idx(1:max(1,floor(ratio*numel(idx)))))=true;end
end
function local_seed(seed),rand('twister',seed);randn('state',seed);end %#ok<RAND>
function local_init(file)
if exist(file,'file')==2,return;end;fid=fopen(file,'w');c=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'dataset,seed,method,n_samples,n_features,n_classes,n_labeled,n_unlabeled,ACC,NMI,Purity,Fscore,Precision,Recall,native_ACC,runtime_seconds,iterations,finite_output,status,parameter_tag,source_id,message\n');
end
function K=local_keys(file)
K=containers.Map('KeyType','char','ValueType','logical');T=readtable(file,'Delimiter',',');for i=1:height(T),K(sprintf('%s|%d|%s',T.dataset{i},T.seed(i),T.method{i}))=true;end
end
function append_row(file,dataset,seed,method,n,m,c,nl,nu,M,native,info,finite,status,msg)
fid=fopen(file,'a');cl=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,['%s,%d,%s,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d,%s,%s,%s,%s\n'],dataset,seed,method,n,m,c,nl,nu,M.ACC,M.NMI,M.Purity,M.Fscore,M.Precision,M.Recall,native,info.runtime_sec,info.iterations,finite,status,safe(info.parameter_tag),safe(info.source_id),safe(msg));
end
function M=empty_metrics(),M=struct('ACC',NaN,'NMI',NaN,'Purity',NaN,'Fscore',NaN,'Precision',NaN,'Recall',NaN);end
function I=empty_info(),I=struct('runtime_sec',NaN,'iterations',NaN,'parameter_tag','unknown','source_id','unknown');end
function s=safe(s),if ~ischar(s),s='';end;s=strrep(s,',',';');s=strrep(s,sprintf('\n'),' ');s=strrep(s,sprintf('\r'),' ');end
