function run_PCE_noise_R2019a(dataset_ids,noise_ids,level_ids,method_ids,seeds)
%RUN_PCE_NOISE_R2019A Locked paired noise experiment, MATLAB R2019a.
% dataset_ids: [1 2 5] = YaleB, COIL20, PIE.
% noise_ids: 1 = salt-pepper; 2 = one 5-by-5 black occlusion.
% level_ids: 1:5 = 10:10:50 percent of samples corrupted.
cfg=rebuild_config(); levels=[.1 .2 .3 .4 .5]; names={'saltpepper','occlusion'};
if nargin<1||isempty(dataset_ids),dataset_ids=[1 2 5];end
if nargin<2||isempty(noise_ids),noise_ids=1:2;end
if nargin<3||isempty(level_ids),level_ids=1:5;end
if nargin<4||isempty(method_ids),method_ids=1:9;end
if nargin<5||isempty(seeds),seeds=cfg.seeds_formal;end
if any(~ismember(dataset_ids,[1 2 5]))||any(~ismember(noise_ids,1:2))||...
   any(~ismember(level_ids,1:5))||any(~ismember(method_ids,1:9))||...
   any(~ismember(seeds,cfg.seeds_formal)),error('Outside locked noise protocol.');end
addpath(cfg.adapter_dir);addpath(cfg.hlpnmf_dir);
out=fullfile(cfg.results_dir,'noise20');if exist(out,'dir')~=7,mkdir(out);end
file=fullfile(out,'raw.csv');init(file);done=existing(file);
semantic={'GNMFLD','EDNMF','LCNMF','GOCNMF','HLPNMF','PCE_NMF'};
for d=dataset_ids
 [X,y]=load_data(cfg,d);[nf,n]=size(X);c=max(y);
 for seed=seeds
  setseed(seed);labeled=split_labels(y,.10);unlabeled=~labeled;
  W0=max(rand(nf,c),eps);H0=max(rand(c,n),eps);
  % Draw corruption after the formal split and initialization, preserving pairing.
  for ni=noise_ids
   for li=level_ids
    level=levels(li);key0=sprintf('%s|%s|%.2f|%d',cfg.datasets{d},names{ni},level,seed);
    setseed(seed+ni*100+li*10);Xn=corrupt(X,ni,level);
    for jj=1:numel(method_ids)
     method=cfg.methods{method_ids(jj)};key=[key0 '|' method];
     if isKey(done,key),continue;end
     M=emptyM();info=emptyI();status='OK';msg='';finite=0;native=NaN;
     try
      opt=cfg;opt.dataset=cfg.datasets{d};opt.dataset_index=d;opt.seed=seed;
      if strcmp(method,'SNMFWLP'),opt.graph_p=cfg.snmfwlp_p;
      elseif strcmp(method,'PCE_NMF'),opt.graph_p=cfg.pce_p_locked;opt.pce_lambda=cfg.pce_lambda_locked(d);
      else,opt.graph_p=cfg.graph_p;end
      setseed(seed);[pred,info]=feval(['run_' method],Xn,y,labeled,W0,H0,opt);pred=pred(:);
      if numel(pred)~=n||any(~isfinite(pred)),error('Invalid prediction.');end
      truth=y(unlabeled);guess=pred(unlabeled);M=pce_clustering_metrics(truth,guess);
      if any(strcmp(semantic,method)),native=mean(guess==truth);end
      finite=double(all(isfinite([M.ACC M.NMI M.Purity M.Fscore M.Precision M.Recall info.runtime_sec])));
      if ~finite,error('Non-finite metric.');end
     catch err,status='FAILED';msg=err.message;end
     append(file,cfg.datasets{d},names{ni},level,seed,method,n,nf,c,sum(labeled),sum(unlabeled),M,native,info,finite,status,msg);
     done(key)=true;
     fprintf('%s %s %.2f seed=%d %s ACC=%.5f NMI=%.5f %s\n',cfg.datasets{d},names{ni},level,seed,method,M.ACC,M.NMI,status);
    end
   end
  end
 end
end
end

function Xn=corrupt(X,ni,level)
[nf,n]=size(X);if nf~=1024,error('Noise requires audited 32-by-32 images.');end
Xn=X;selected=randperm(n,floor(level*n));
for j=selected
 if ni==1
  mask=rand(nf,1)<.1;salt=rand(nf,1)<.5;
  col=Xn(:,j);col(mask & salt)=max(col);col(mask & ~salt)=0;Xn(:,j)=col;
 else
  image=reshape(Xn(:,j),32,32);row=randi(28);col=randi(28);
  image(row:row+4,col:col+4)=0;Xn(:,j)=image(:);
 end
end
end
function [X,y]=load_data(cfg,d)
S=load(fullfile(cfg.data_dir,[cfg.datasets{d} '.mat']));
if isfield(S,'fea'),X=double(S.fea');else,X=double(S.X');end
if isfield(S,'gnd'),y=double(S.gnd(:));else,y=double(S.Y(:));end
if size(X,2)~=numel(y),X=X';end;[~,~,y]=unique(y);
if size(X,2)~=cfg.expected_samples(d)||size(X,1)~=cfg.expected_features(d)||max(y)~=cfg.expected_classes(d),error('Data identity changed.');end
if any(~isfinite(X(:)))||any(X(:)<0),error('Invalid data.');end
z=sqrt(sum(X.^2,1));z(z==0)=1;X=bsxfun(@rdivide,X,z);
end
function L=split_labels(y,r)
L=false(numel(y),1);for k=1:max(y),z=find(y==k);z=z(randperm(numel(z)));L(z(1:max(1,floor(r*numel(z)))))=true;end
end
function setseed(s),rand('twister',s);randn('state',s);end %#ok<RAND>
function init(f)
if exist(f,'file')==2,return;end;h=fopen(f,'w');cl=onCleanup(@()fclose(h)); %#ok<NASGU>
fprintf(h,'dataset,noise_type,corruption_ratio,seed,method,n_samples,n_features,n_classes,n_labeled,n_unlabeled,ACC,NMI,Purity,Fscore,Precision,Recall,native_ACC,runtime_seconds,iterations,finite_output,status,parameter_tag,source_id,message\n');
end
function K=existing(f)
K=containers.Map('KeyType','char','ValueType','logical');T=readtable(f,'Delimiter',',');
for i=1:height(T),K(sprintf('%s|%s|%.2f|%d|%s',T.dataset{i},T.noise_type{i},T.corruption_ratio(i),T.seed(i),T.method{i}))=true;end
end
function append(f,d,ni,r,s,m,n,nf,c,nl,nu,M,na,I,fin,st,msg)
h=fopen(f,'a');cl=onCleanup(@()fclose(h)); %#ok<NASGU>
fprintf(h,['%s,%s,%.2f,%d,%s,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d,%s,%s,%s,%s\n'],...
d,ni,r,s,m,n,nf,c,nl,nu,M.ACC,M.NMI,M.Purity,M.Fscore,M.Precision,M.Recall,na,I.runtime_sec,I.iterations,fin,st,safe(I.parameter_tag),safe(I.source_id),safe(msg));
end
function M=emptyM(),M=struct('ACC',NaN,'NMI',NaN,'Purity',NaN,'Fscore',NaN,'Precision',NaN,'Recall',NaN);end
function I=emptyI(),I=struct('runtime_sec',NaN,'iterations',NaN,'parameter_tag','unknown','source_id','unknown');end
function s=safe(s),if ~ischar(s),s='';end;s=strrep(s,',',';');s=strrep(s,sprintf('\n'),' ');s=strrep(s,sprintf('\r'),' ');end
