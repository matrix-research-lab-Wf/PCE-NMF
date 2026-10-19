function audit_harmonic_stabilization_R2019a(dataset_index)
% Compare the formal unstabilized harmonic solve with (L_UU+1e-12 I).
% MATLAB R2019a compatible. No external-baseline method is rerun.

root_dir=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root_dir,'experiments','config'));
addpath(fullfile(root_dir,'experiments','adapters'));
cfg=pce_protocol_config(root_dir);
pce_p=[2 2 4 3 3 2];
seeds=20260627:20260646;
if nargin<1 || isempty(dataset_index), dataset_index=1:numel(cfg.datasets); end
dataset_index=dataset_index(:)';
out_dir=fullfile(root_dir,'results','harmonic_stabilization_audit');
if ~exist(out_dir,'dir'), mkdir(out_dir); end
tag=sprintf('%d_',dataset_index); tag=tag(1:end-1);
raw_file=fullfile(out_dir,['raw_dataset_' tag '.csv']);
fid=fopen(raw_file,'w');
fprintf(fid,['dataset,seed,n_unlabeled,max_abs_Q_difference,' ...
    'prediction_agreement,ACC0,ACCdelta,ACC_difference,' ...
    'NMI0,NMIdelta,NMI_difference,objective0,objectivedelta\n']);
fclose(fid);

for d=dataset_index
    ds=cfg.datasets{d}; [X,y]=local_load(cfg,ds); K=max(y); [m,n]=size(X);
    for seed=seeds
        local_seed(seed); labeled=local_split(y,cfg.label_ratio); unlabeled=~labeled;
        local_seed(seed+97); U0=rand(m,K)+0.01; V0=rand(n,K)+0.01;
        opt=cfg; opt.dataset=ds; opt.dataset_index=d; opt.seed=seed;
        opt.graph_p=pce_p;
        [pred0,info0]=run_PCE_HCE_FORMAL_CORE_UNSHIFTED_AUDIT(X,y,labeled,U0,V0,opt,100);
        [predd,infod]=run_PCE_HCE_FORMAL_CORE_STABILIZED(X,y,labeled,U0,V0,opt,100);
        truth=y(unlabeled); g0=pred0(unlabeled); gd=predd(unlabeled);
        % Native PCE labels are class semantic; identical predictions also
        % imply identical permutation-aligned ACC.
        acc0=mean(truth==g0); accd=mean(truth==gd);
        nmi0=local_nmi(truth,g0); nmid=local_nmi(truth,gd);
        qdiff=max(abs(info0.Qeff(:)-infod.Qeff(:)));
        agree=mean(g0==gd);
        fid=fopen(raw_file,'a');
        fprintf(fid,'%s,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n', ...
            ds,seed,sum(unlabeled),qdiff,agree,acc0,accd,accd-acc0, ...
            nmi0,nmid,nmid-nmi0,info0.objective_trace(end),infod.objective_trace(end));
        fclose(fid);
        fprintf('%s %d q=%.3e agree=%.12f dACC=%+.3e dNMI=%+.3e\n', ...
            ds,seed,qdiff,agree,accd-acc0,nmid-nmi0);
    end
end

T=readtable(raw_file,'Delimiter',',');
summary_file=fullfile(out_dir,['summary_dataset_' tag '.txt']); fid=fopen(summary_file,'w');
fprintf(fid,'trials=%d\n',height(T));
fprintf(fid,'max_abs_Q_difference=%.17g\n',max(T.max_abs_Q_difference));
fprintf(fid,'min_prediction_agreement=%.17g\n',min(T.prediction_agreement));
fprintf(fid,'max_abs_ACC_difference=%.17g\n',max(abs(T.ACC_difference)));
fprintf(fid,'max_abs_NMI_difference=%.17g\n',max(abs(T.NMI_difference)));
fprintf(fid,'all_predictions_identical=%d\n',all(T.prediction_agreement==1));
fclose(fid);
type(summary_file);
end

function [X,y]=local_load(cfg,name)
S=load(fullfile(cfg.data_dir,[name '.mat']));
if isfield(S,'X'), X=S.X; elseif isfield(S,'fea'), X=S.fea'; else, error('Need X or fea.'); end
if isfield(S,'y'), y=S.y; elseif isfield(S,'gnd'), y=S.gnd; else, error('Need y or gnd.'); end
X=double(X); y=double(y(:));
if size(X,2)~=numel(y), if size(X,1)==numel(y), X=X'; else, error('Dimension mismatch.'); end, end
[~,~,y]=unique(y); nr=sqrt(sum(X.^2,1)); nr(nr==0)=1; X=bsxfun(@rdivide,X,nr);
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
