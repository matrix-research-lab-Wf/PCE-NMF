function analyze_controls20_R2019a()
%ANALYZE_CONTROLS20_R2019A HCE-NMF / LP-only / PCE-NMF 配对分析。
code_dir=fileparts(mfilename('fullpath')); root=fileparts(code_dir);
control_file=fullfile(root,'results','controls20','raw.csv');
formal_file=fullfile(root,'results','formal20','raw.csv');
out=fullfile(root,'analysis','controls20'); if exist(out,'dir')~=7,mkdir(out);end
C=readtable(control_file,'Delimiter',','); F=readtable(formal_file,'Delimiter',',');
F=F(strcmp(F.method,'PCE_NMF'),:); datasets=unique(F.dataset,'stable');
metrics={'ACC','NMI','Purity','Fscore','Precision','Recall'};
assert(height(C)==400 && height(F)==200,'Expected 400 control and 200 PCE rows.');
assert(all(strcmp(C.status,'OK'))&&all(strcmp(F.status,'OK')),'Failed rows exist.');
methods={'HCE_NMF','Harmonic_LP_only','PCE_NMF'};

% 完整性和均值。
S=cell(10*3*6,7); k=0;
for d=1:10
 for m=1:3
  if m<3,T=C(strcmp(C.dataset,datasets{d})&strcmp(C.method,methods{m}),:);else,T=F(strcmp(F.dataset,datasets{d}),:);end
  assert(height(T)==20,'Each dataset-method block must contain 20 rows.');
  for q=1:6,x=T.(metrics{q});k=k+1;S(k,:)={datasets{d},methods{m},metrics{q},20,mean(x),std(x,0),median(x)};end
 end
end
ST=cell2table(S,'VariableNames',{'dataset','method','metric','n','mean','std','median'});writetable(ST,fullfile(out,'control_summary.csv'));

% 每数据集 PCE 对两个控制的精确配对检验；每个数据集-指标内校正两项比较。
P=cell(10*6*2,14); k=0;
for d=1:10
 for q=1:6
  pce=seedvec(F,datasets{d},'PCE_NMF',metrics{q}); ids=[];
  for m=1:2
   z=seedvec(C,datasets{d},methods{m},metrics{q}); delta=pce-z;
   [pv,Wp,rb]=wx(delta); mu=mean(delta);sd=std(delta,0);ci=2.093024054*sd/sqrt(20);
   k=k+1;ids(end+1)=k;P(k,:)={datasets{d},metrics{q},methods{m},20,mu,sd,mu-ci,mu+ci,median(delta),sum(delta>0),sum(delta<0),Wp,pv,rb};
  end
  pa=holm(cell2mat(P(ids,13)));for j=1:2,P{ids(j),13}=pa(j);end
 end
end
PT=cell2table(P,'VariableNames',{'dataset','metric','control','n_pairs','mean_difference','std_difference','ci95_low','ci95_high','median_difference','wins','losses','Wplus','p_holm','rank_biserial'});writetable(PT,fullfile(out,'pce_vs_controls_by_dataset.csv'));

% 跨数据集：每个数据集均值作为一个配对单位。
G=cell(6*2,13);k=0;
for q=1:6
 ids=[];
 for m=1:2
  delta=zeros(10,1);
  for d=1:10
   delta(d)=ST.mean(strcmp(ST.dataset,datasets{d})&strcmp(ST.method,'PCE_NMF')&strcmp(ST.metric,metrics{q}))-ST.mean(strcmp(ST.dataset,datasets{d})&strcmp(ST.method,methods{m})&strcmp(ST.metric,metrics{q}));
  end
  [pv,Wp,rb]=wx(delta);mu=mean(delta);sd=std(delta,0);ci=2.262157163*sd/sqrt(10);
  k=k+1;ids(end+1)=k;G(k,:)={metrics{q},methods{m},10,mu,sd,mu-ci,mu+ci,median(delta),sum(delta>0),sum(delta<0),Wp,pv,rb};
 end
 pa=holm(cell2mat(G(ids,12)));for j=1:2,G{ids(j),12}=pa(j);end
end
GT=cell2table(G,'VariableNames',{'metric','control','n_datasets','mean_difference','std_difference','ci95_low','ci95_high','median_difference','wins','losses','Wplus','p_holm','rank_biserial'});writetable(GT,fullfile(out,'pce_vs_controls_global.csv'));

% 论文之外的审计报告，不改正文。
fid=fopen(fullfile(out,'CONTROL_AUDIT.txt'),'w');fprintf(fid,'Control rows: %d / 400\nPCE rows joined: %d / 200\nFailures: %d\nMissing block rows: 0\nComplete PASS: 1\n',height(C),height(F),sum(~strcmp(C.status,'OK')));fclose(fid);
fid=fopen(fullfile(out,'control-analysis.md'),'w');
fprintf(fid,'# PCE-NMF controlled comparison\n\n- 10 data sets, 20 matched seeds, unlabeled-only evaluation.\n- HCE-NMF removes propagated exclusion only; LP-only removes NMF coupling.\n- Positive differences favor PCE-NMF. Exact paired Wilcoxon tests use Holm correction over the two pre-specified controls within each metric family.\n\n## Global data-set-level comparisons\n\n| Metric | Control | Mean delta | 95%% CI | Wins/10 | Holm p | Rank-biserial |\n|---|---|---:|---:|---:|---:|---:|\n');
for i=1:height(GT),fprintf(fid,'| %s | %s | %.6f | [%.6f, %.6f] | %d | %.6g | %.4f |\n',GT.metric{i},strrep(GT.control{i},'_','-'),GT.mean_difference(i),GT.ci95_low(i),GT.ci95_high(i),GT.wins(i),GT.p_holm(i),GT.rank_biserial(i));end
fprintf(fid,'\nThese results test only the two locked mechanism questions. They do not establish noise robustness, scalability, or superiority to all external baselines.\n');fclose(fid);
fprintf('Control analysis complete: %s\n',out);
end

function x=seedvec(T,d,m,q),S=sortrows(T(strcmp(T.dataset,d)&strcmp(T.method,m),{'seed',q}),'seed');x=S.(q);end
function r=trank(x),[sx,o]=sort(x(:));n=numel(x);a=zeros(n,1);i=1;while i<=n,j=i;while j<n&&sx(j+1)==sx(i),j=j+1;end;a(i:j)=(i+j)/2;i=j+1;end;r=zeros(n,1);r(o)=a;end
function [p,Wp,rb]=wx(d),d=d(:);d=d(abs(d)>1e-15);n=numel(d);if n==0,p=1;Wp=0;rb=0;return;end;r=trank(abs(d));Wp=sum(r(d>0));Wm=sum(r(d<0));rb=(Wp-Wm)/sum(r);ri=round(2*r);obs=round(2*Wp);w=zeros(1,sum(ri)+1);w(1)=1;for i=1:n,w(ri(i)+1:end)=w(ri(i)+1:end)+w(1:end-ri(i));end;p=min(1,2*min(sum(w(1:obs+1)),sum(w(obs+1:end)))/(2^n));end
function q=holm(p),p=p(:);m=numel(p);[s,o]=sort(p);a=zeros(m,1);z=0;for i=1:m,z=max(z,(m-i+1)*s(i));a(i)=min(1,z);end;q=zeros(m,1);q(o)=a;end
