function analyze_HLPNMF_common_R2019a
% 从保存的预测重新评价；不改变训练，不覆写原始几何NMI记录。
script_dir=fileparts(mfilename('fullpath'));
repo=fileparts(fileparts(script_dir));
out=fullfile(repo,'results','hlpnmf','rerun');
base=repo;
T=readtable(fullfile(out,'raw.csv'),'Delimiter',',');
B=readtable(fullfile(base,'results','formal8_independent20','raw.csv'),'Delimiter',',');
names={'YaleB','COIL20','Optdigits','ORL','PIE','COIL100'};
if numel(unique(strcat(T.dataset,cellstr(num2str(T.seed)))))~=height(T), error('Duplicate trial'); end
T.NMI_geometric=T.NMI; T.NMI_arithmetic=nan(height(T),1);
for d=1:6
    datafile=fullfile(base,'data',[names{d} '.mat']); vars=whos('-file',datafile);
    if any(strcmp({vars.name},'y')), L=load(datafile,'y'); y=L.y; else, L=load(datafile,'gnd'); y=L.gnd; end
    [~,~,y]=unique(double(y(:)));
    rows=find(strcmp(T.dataset,names{d}));
    for i=rows'
        A=load(fullfile(out,sprintf('%s_%d.mat',names{d},T.seed(i))));
        a=y(~A.labeled); b=A.pred(~A.labeled); c=max(y); n=numel(a);
        M=full(sparse(a,b,1,c,c))/n; px=sum(M,2); py=sum(M,1); den=px*py; nz=M>0;
        mi=sum(M(nz).*log(M(nz)./den(nz)));
        hx=-sum(px(px>0).*log(px(px>0))); hy=-sum(py(py>0).*log(py(py>0)));
        T.NMI_arithmetic(i)=2*mi/max(hx+hy,eps);
        geo=mi/max(sqrt(hx*hy),eps);
        if abs(geo-T.NMI_geometric(i))>1e-12, error('Saved prediction NMI mismatch'); end
    end
end
writetable(T,fullfile(out,'evaluated_common.csv'));
R=cell(6,10); Q=cell(0,7);
for d=1:6
    A=T(strcmp(T.dataset,names{d}),:); n=height(A);
    R(d,:)={names{d},n,mean(A.ACC),std(A.ACC),mean(A.NMI_arithmetic),std(A.NMI_arithmetic),mean(A.NMI_geometric),std(A.NMI_geometric),mean(A.runtime_seconds),double(n==20)};
    if n~=20, continue; end
    C=B(strcmp(B.dataset,names{d}) & strcmp(B.method,'PCE_NMF'),:);
    [seeds,ia,ic]=intersect(A.seed,C.seed);
    if numel(seeds)~=20, error('Seed mismatch'); end
    for k=1:2
        if k==1, metric='ACC'; delta=C.ACC_unlabeled(ic)-A.ACC(ia);
        else, metric='NMI_arithmetic'; delta=C.NMI_unlabeled(ic)-A.NMI_arithmetic(ia); end
        Q(end+1,:)={names{d},metric,20,mean(delta),mean(delta>1e-12),signed_rank(delta),NaN}; %#ok<AGROW>
    end
end
Summary=cell2table(R,'VariableNames',{'dataset','n','ACC_mean','ACC_std','NMI_arithmetic_mean','NMI_arithmetic_std','NMI_geometric_mean','NMI_geometric_std','runtime_including_graph_mean','complete20'});
writetable(Summary,fullfile(out,'summary.csv'));
if size(Q,1)==12
    p=cell2mat(Q(:,6)); [sp,ord]=sort(p); adj=zeros(12,1); run=0;
    for j=1:12, run=max(run,(13-j)*sp(j)); adj(j)=min(1,run); end
    for j=1:12, Q{ord(j),7}=adj(j); end
end
P=cell2table(Q,'VariableNames',{'dataset','metric','n_pairs','PCE_minus_HLPNMF','PCE_win_rate','wilcoxon_p','holm_p_12_tests'});
writetable(P,fullfile(out,'pairwise.csv'));
disp(Summary); fprintf('Rows evaluated: %d/120. Holm correction filled only at 12 complete tests.\n',height(T));
end

function p=signed_rank(delta)
d=delta(:); d(abs(d)<=1e-12)=0; d=d(d~=0); n=numel(d);
if n==0, p=1; return; end
[a,ord]=sort(abs(d)); ranks=zeros(n,1); i=1;
while i<=n
    j=i; while j<n && abs(a(j+1)-a(i))<=1e-12*max(1,a(i)), j=j+1; end
    ranks(ord(i:j))=(i+j)/2; i=j+1;
end
r2=round(2*ranks); total=sum(r2); dp=zeros(1,total+1); dp(1)=1;
for i=1:n, dp(r2(i)+1:end)=dp(r2(i)+1:end)+dp(1:end-r2(i)); end
obs=sum(r2(d>0)); p=min(1,2*min(sum(dp(1:obs+1)),sum(dp(obs+1:end)))/2^n);
end
