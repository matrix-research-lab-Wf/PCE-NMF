function assemble_independent_formal20_R2019a
% Verify and summarize the released independent 20-seed raw records.
% Test seeds: 20260627:20260646. MATLAB R2019a compatible.

root_dir=fileparts(fileparts(mfilename('fullpath')));
raw_file=fullfile(root_dir,'results','independent_test_raw.csv');
out_dir=fullfile(root_dir,'results','formal8_independent20');
if ~exist(out_dir,'dir'), mkdir(out_dir); end

T=readtable(raw_file,'Delimiter',',');
datasets={'YaleB','COIL20','Optdigits','ORL','PIE','COIL100'};
methods={'NMF','CNMF','GNMFLD','EDNMF','LCNMF','GOCNMF','SNMFWLP','PCE_NMF'};

% Canonical order and strict integrity gate.
dk=zeros(height(T),1); mk=zeros(height(T),1);
for i=1:numel(datasets), dk(strcmp(T.dataset,datasets{i}))=i; end
for i=1:numel(methods), mk(strcmp(T.method,methods{i}))=i; end
[~,ord]=sortrows([dk,T.seed,mk],[1 2 3]); T=T(ord,:);
issues={}; expected=(20260627:20260646)';
if height(T)~=960, issues{end+1}=sprintf('row_count=%d',height(T)); end %#ok<AGROW>
for d=1:numel(datasets)
    for m=1:numel(methods)
        z=strcmp(T.dataset,datasets{d}) & strcmp(T.method,methods{m});
        if sum(z)~=20 || ~isequal(sort(T.seed(z)),expected)
            issues{end+1}=sprintf('%s/%s seed coverage',datasets{d},methods{m}); %#ok<AGROW>
        end
        if any(~isfinite(T.ACC_unlabeled(z))) || any(~isfinite(T.NMI_unlabeled(z))) || ...
                any(T.finite_output(z)~=1)
            issues{end+1}=sprintf('%s/%s invalid metric',datasets{d},methods{m}); %#ok<AGROW>
        end
    end
end
zp=strcmp(T.method,'PCE_NMF'); zl=strcmp(T.method,'LCNMF');
if any(~isfinite(T.objective_monotone(zp))) || ...
        any(~isfinite(T.anchor_coverage(zp))) || ...
        any(T.support_violation(zp)~=0) || any(T.support_violation(zl)~=0)
    issues{end+1}='PCE/LCNMF diagnostic integrity';
end
if ~isempty(issues), error('INDEPENDENT20_INTEGRITY_FAIL: %s',strjoin(issues,'; ')); end
writetable(T,fullfile(out_dir,'raw.csv'));

% Descriptive statistics with 95%% t intervals across the 20 paired seeds.
R=cell(numel(datasets)*numel(methods),12); q=0; tcrit=2.093024054;
for d=1:numel(datasets)
    for m=1:numel(methods)
        q=q+1; z=strcmp(T.dataset,datasets{d}) & strcmp(T.method,methods{m});
        a=T.ACC_unlabeled(z); n=T.NMI_unlabeled(z); r=T.runtime_seconds(z);
        ah=tcrit*std(a)/sqrt(numel(a)); nh=tcrit*std(n)/sqrt(numel(n));
        R(q,:)={datasets{d},methods{m},numel(a),mean(a),std(a),mean(a)-ah,mean(a)+ah, ...
            mean(n),std(n),mean(n)-nh,mean(n)+nh,mean(r)};
    end
end
Summary=cell2table(R,'VariableNames',{'dataset','method','n','ACC_mean','ACC_std', ...
    'ACC_CI95_low','ACC_CI95_high','NMI_mean','NMI_std','NMI_CI95_low', ...
    'NMI_CI95_high','runtime_mean'});
writetable(Summary,fullfile(out_dir,'summary.csv'));

% PCE-minus-baseline paired effects and exact signed-rank tests.
baselines=methods(1:end-1); Q=cell(numel(baselines)*12,12); q=0;
for b=1:numel(baselines)
    first=q+1;
    for d=1:numel(datasets)
        B=T(strcmp(T.dataset,datasets{d}) & strcmp(T.method,baselines{b}),:);
        C=T(strcmp(T.dataset,datasets{d}) & strcmp(T.method,'PCE_NMF'),:);
        [seeds,ib,ic]=intersect(B.seed,C.seed);
        for k=1:2
            q=q+1;
            if k==1, metric='ACC'; delta=C.ACC_unlabeled(ic)-B.ACC_unlabeled(ib);
            else, metric='NMI'; delta=C.NMI_unlabeled(ic)-B.NMI_unlabeled(ib); end
            sd=std(delta); half=tcrit*sd/sqrt(numel(delta));
            if sd<=eps, dz=sign(mean(delta))*Inf; else, dz=mean(delta)/sd; end
            Q(q,:)={datasets{d},metric,baselines{b},numel(seeds),mean(delta),sd, ...
                mean(delta)-half,mean(delta)+half,dz,mean(delta>1e-12), ...
                exact_signed_rank(delta),nan};
        end
    end
    ids=first:q; pv=cell2mat(Q(ids,11)); [sp,ordp]=sort(pv);
    adj=zeros(size(sp)); running=0; nt=numel(sp);
    for j=1:nt, running=max(running,(nt-j+1)*sp(j)); adj(j)=min(1,running); end
    for j=1:nt, Q{ids(ordp(j)),12}=adj(j); end
end
Pairwise=cell2table(Q,'VariableNames',{'dataset','metric','baseline','n_pairs', ...
    'mean_difference','std_difference','CI95_low','CI95_high','paired_dz', ...
    'win_rate','wilcoxon_p','holm_p'});
writetable(Pairwise,fullfile(out_dir,'pairwise.csv'));

write_table(Summary,datasets,methods,fullfile(out_dir,'PCE_NMF_INDEPENDENT20_table.tex'));
fid=fopen(fullfile(out_dir,'diagnostics.txt'),'w');
fprintf(fid,'PCE-NMF independent 20-seed test integrity: PASS\n');
fprintf(fid,'Rows: 960 = 6 datasets x 20 seeds x 8 methods.\n');
fprintf(fid,'Seeds: 20260627:20260646. Development seeds excluded.\n');
fprintf(fid,'Nonfinite ACC/NMI: 0. Failed runs: 0.\n');
fprintf(fid,'Canonical released raw source: results/independent_test_raw.csv\n');
fprintf(fid,'PCE objective/coverage diagnostics: 120/120 finite.\n');
fprintf(fid,'PCE and LCNMF labeled support violation: 0.\n');
fclose(fid);
fprintf('INDEPENDENT20_PASS rows=%d output=%s\n',height(T),out_dir);
end

function p=exact_signed_rank(delta)
d=delta(:); d=d(isfinite(d)); d(abs(d)<=1e-12)=0; d=d(d~=0); n=numel(d);
if n==0, p=1; return; end
a=abs(d); [sa,ord]=sort(a); ranks=zeros(n,1); i=1;
while i<=n
    j=i; tol=1e-12*max(1,sa(i));
    while j<n && abs(sa(j+1)-sa(i))<=tol, j=j+1; end
    ranks(ord(i:j))=(i+j)/2; i=j+1;
end
r2=round(2*ranks); total=sum(r2); dp=zeros(1,total+1); dp(1)=1;
for i=1:n, dp((r2(i)+1):end)=dp((r2(i)+1):end)+dp(1:(end-r2(i))); end
obs=sum(r2(d>0)); lower=sum(dp(1:obs+1)); upper=sum(dp(obs+1:end));
p=min(1,2*min(lower,upper)/(2^n));
end

function write_table(S,datasets,methods,out_file)
fid=fopen(out_file,'w');
fprintf(fid,'\\begin{table*}[t]\n\\centering\n');
fprintf(fid,'\\caption{Independent-test clustering performance over 20 paired seeds.}\n');
fprintf(fid,'\\label{tab:pce_independent20}\n\\scriptsize\n');
fprintf(fid,'\\setlength{\\tabcolsep}{2.4pt}\n\\resizebox{\\textwidth}{!}{%%\n');
fprintf(fid,'\\begin{tabular}{llcccccccc}\n\\toprule\n');
fprintf(fid,'Dataset & Metric & NMF & CNMF & GNMFLD & EDNMF & LCNMF & GOCNMF & SNMFWLP & PCE-NMF\\\\\n\\midrule\n');
for d=1:numel(datasets)
    for k=1:2
        vals=zeros(1,numel(methods)); sds=vals;
        for m=1:numel(methods)
            z=strcmp(S.dataset,datasets{d}) & strcmp(S.method,methods{m});
            if k==1, vals(m)=S.ACC_mean(z); sds(m)=S.ACC_std(z); metric='ACC';
            else, vals(m)=S.NMI_mean(z); sds(m)=S.NMI_std(z); metric='NMI'; end
        end
        [~,ord]=sort(vals,'descend');
        if k==1, fprintf(fid,'%s & %s',datasets{d},metric); else, fprintf(fid,' & %s',metric); end
        for m=1:numel(methods)
            txt=sprintf('%.4f $\\pm$ %.4f',vals(m),sds(m));
            if m==ord(1), txt=['\\textbf{' txt '}']; elseif m==ord(2), txt=['\\underline{' txt '}']; end
            fprintf(fid,' & %s',txt);
        end
        fprintf(fid,' \\\\\n');
    end
end
fprintf(fid,'\\bottomrule\n\\end{tabular}\n}\n\\end{table*}\n'); fclose(fid);
end
