function run_PCE_labelnoise20_R2019a(dataset_ids,method_ids,seeds,noise_counts)
%RUN_PCE_FORMAL20_R2019A Resumable formal 10-dataset, 9-method experiment.
% Examples:
%   run_PCE_formal20_R2019a(1,1:9)          % YaleB, all methods, 20 seeds
%   run_PCE_formal20_R2019a(1:10,9)         % PCE-NMF only
%   run_PCE_formal20_R2019a(1,1:9,20261029) % one-seed gate

cfg=rebuild_config();
if nargin<1 || isempty(dataset_ids), dataset_ids=[2 5]; end
if nargin<2 || isempty(method_ids), method_ids=1:numel(cfg.methods); end
if nargin<3 || isempty(seeds), seeds=cfg.seeds_formal; end
if nargin<4 || isempty(noise_counts), noise_counts=0:3; end
if any(~ismember(dataset_ids,[2 5])) || any(~ismember(noise_counts,0:3))
    error('Outside the locked label-noise protocol.');
end
if any(~ismember(dataset_ids,1:numel(cfg.datasets))), error('Invalid dataset id.'); end
if any(~ismember(method_ids,1:numel(cfg.methods))), error('Invalid method id.'); end
if any(~ismember(seeds,cfg.seeds_formal)), error('Seeds must belong to the formal lock.'); end

addpath(cfg.adapter_dir); addpath(cfg.hlpnmf_dir);
out_dir=fullfile(cfg.results_dir,'labelnoise20');
if exist(out_dir,'dir')~=7, mkdir(out_dir); end
raw_file=fullfile(out_dir,'raw.csv'); local_init_raw(raw_file);
completed=local_existing_keys(raw_file);

semantic_methods={'GNMFLD','EDNMF','LCNMF','GOCNMF','HLPNMF','PCE_NMF'};
for d=dataset_ids
    [X,y]=local_load(cfg,d); [m,n]=size(X); c=max(y);
    fprintf('FORMAL dataset=%s n=%d d=%d c=%d\n',cfg.datasets{d},n,m,c);
    for seed=seeds
        local_seed(seed); labeled=local_split(y,cfg.label_ratio); unlabeled=~labeled;
        W0=max(rand(m,c),eps); H0=max(rand(c,n),eps);
      for noise_count=noise_counts
        y_train=y;
        local_seed(seed+1000+noise_count);
        for class_id=1:c
            ids=find(labeled & y==class_id);
            if numel(ids)<noise_count, error('Insufficient labeled samples.'); end
            picked=ids(randperm(numel(ids),noise_count));
            for q=1:numel(picked)
                other=randperm(c-1,1);
                y_train(picked(q))=other+(other>=class_id);
            end
        end
        for jj=1:numel(method_ids)
            method=cfg.methods{method_ids(jj)};
            key=local_key([cfg.datasets{d} '_' num2str(noise_count)],seed,method);
            if isKey(completed,key), continue; end
            status='OK'; msg=''; finite_output=0; native_acc=NaN;
            M=local_empty_metrics(); info=local_empty_info();
            try
                opt=cfg; opt.dataset=cfg.datasets{d}; opt.dataset_index=d; opt.seed=seed;
                if strcmp(method,'SNMFWLP')
                    opt.graph_p=cfg.snmfwlp_p;
                elseif strcmp(method,'PCE_NMF')
                    opt.graph_p=cfg.pce_p_locked;
                    opt.pce_lambda=cfg.pce_lambda_locked(d);
                else
                    opt.graph_p=cfg.graph_p;
                end
                local_seed(seed);
                [pred,info]=feval(['run_' method],X,y_train,labeled,W0,H0,opt);
                pred=pred(:);
                if numel(pred)~=n || any(~isfinite(pred)), error('Invalid prediction vector.'); end
                truth=y(unlabeled); guess=pred(unlabeled);
                M=pce_clustering_metrics(truth,guess);
                if any(strcmp(semantic_methods,method)), native_acc=mean(guess==truth); end
                values=[M.ACC M.NMI M.Purity M.Fscore M.Precision M.Recall info.runtime_sec];
                finite_output=double(all(isfinite(values)) && ...
                    (isnan(native_acc) || isfinite(native_acc)));
                if ~finite_output, error('Non-finite formal output.'); end
            catch err
                status='FAILED'; msg=err.message;
            end
            local_append(raw_file,[cfg.datasets{d} '_' num2str(noise_count)],seed,method,n,m,c, ...
                sum(labeled),sum(unlabeled),M,native_acc,info,finite_output,status,msg);
            completed(key)=true;
            fprintf('%s seed=%d %-9s ACC=%.5f NMI=%.5f %s\n', ...
                cfg.datasets{d},seed,method,M.ACC,M.NMI,status);
        end
      end
    end
end
fprintf('Requested formal batch complete.\n');
end

function [X,y]=local_load(cfg,d)
S=load(fullfile(cfg.data_dir,[cfg.datasets{d} '.mat']));
if isfield(S,'fea'), X=double(S.fea'); elseif isfield(S,'X'), X=double(S.X');
else, error('Missing fea/X in %s.',cfg.datasets{d}); end
if isfield(S,'gnd'), y=double(S.gnd(:)); elseif isfield(S,'Y'), y=double(S.Y(:));
else, error('Missing gnd/Y in %s.',cfg.datasets{d}); end
if size(X,2)~=numel(y)
    if size(X,1)==numel(y), X=X'; else, error('Data-label dimension mismatch.'); end
end
[~,~,y]=unique(y);
if size(X,2)~=cfg.expected_samples(d) || size(X,1)~=cfg.expected_features(d) || max(y)~=cfg.expected_classes(d)
    error('Audited identity changed for %s.',cfg.datasets{d});
end
if any(~isfinite(X(:))) || any(X(:)<0), error('Data must be finite and nonnegative.'); end
nr=sqrt(sum(X.^2,1)); nr(nr==0)=1; X=bsxfun(@rdivide,X,nr);
end

function labeled=local_split(y,ratio)
labeled=false(numel(y),1);
for k=1:max(y)
    idx=find(y==k); idx=idx(randperm(numel(idx)));
    labeled(idx(1:max(1,floor(ratio*numel(idx)))))=true;
end
end

function local_init_raw(file)
if exist(file,'file')==2, return; end
fid=fopen(file,'w'); cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,['dataset,seed,method,n_samples,n_features,n_classes,n_labeled,n_unlabeled,' ...
    'ACC,NMI,Purity,Fscore,Precision,Recall,native_ACC,runtime_seconds,iterations,' ...
    'finite_output,status,parameter_tag,source_id,message\n']);
end

function keys=local_existing_keys(file)
keys=containers.Map('KeyType','char','ValueType','logical');
T=readtable(file,'Delimiter',',');
for i=1:height(T), keys(local_key(T.dataset{i},T.seed(i),T.method{i}))=true; end
end

function s=local_key(dataset,seed,method)
s=[dataset '|' num2str(seed) '|' method];
end

function local_append(file,dataset,seed,method,n,m,c,nl,nu,M,native_acc,info,finite_output,status,msg)
fid=fopen(file,'a'); cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,['%s,%d,%s,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,' ...
    '%.17g,%.17g,%.17g,%d,%s,%s,%s,%s\n'],dataset,seed,method,n,m,c,nl,nu, ...
    M.ACC,M.NMI,M.Purity,M.Fscore,M.Precision,M.Recall,native_acc, ...
    info.runtime_sec,info.iterations,finite_output,status, ...
    local_safe(info.parameter_tag),local_safe(info.source_id),local_safe(msg));
end

function M=local_empty_metrics()
M=struct('ACC',NaN,'NMI',NaN,'Purity',NaN,'Fscore',NaN,'Precision',NaN,'Recall',NaN);
end

function info=local_empty_info()
info=struct('runtime_sec',NaN,'iterations',NaN,'parameter_tag','unknown','source_id','unknown');
end

function local_seed(seed)
rand('twister',seed); randn('state',seed); %#ok<RAND>
end

function s=local_safe(s)
if ~ischar(s), s=''; end
s=strrep(s,',',';'); s=strrep(s,sprintf('\n'),' '); s=strrep(s,sprintf('\r'),' ');
end
