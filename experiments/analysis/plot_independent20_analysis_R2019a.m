function plot_independent20_analysis_R2019a
% Publication-style diagnostic figures for the independent 20-seed results.
root=fileparts(mfilename('fullpath'));
in_dir=fullfile(root,'results','formal8_independent20');
out_dir=fullfile(in_dir,'analysis','figures');
if ~exist(out_dir,'dir'), mkdir(out_dir); end
S=readtable(fullfile(in_dir,'summary.csv'),'Delimiter',',');
P=readtable(fullfile(in_dir,'pairwise.csv'),'Delimiter',',');
datasets={'YaleB','COIL20','Optdigits','ORL','PIE','COIL100'};
methods={'NMF','CNMF','GNMFLD','EDNMF','LCNMF','GOCNMF','SNMFWLP','PCE_NMF'};
labels={'NMF','CNMF','GNMFLD','EDNMF','LCNMF','GOCNMF','SNMFWLP','PCE-NMF'};
colors=[0.78 0.16 0.12; 0.93 0.49 0.13];

% Figure 1: paired differences against the two strongest direct baselines.
f=figure('Color','w','Units','centimeters','Position',[2 2 18 7.4]);
for metric_id=1:2
    ax=subplot(1,2,metric_id); hold(ax,'on');
    if metric_id==1, metric='ACC'; else, metric='NMI'; end
    for b=1:2
        base={'GNMFLD','GOCNMF'}; z=strcmp(P.metric,metric)&strcmp(P.baseline,base{b}); Q=P(z,:);
        [~,ord]=ismember(datasets,Q.dataset); [~,ix]=sort(ord); Q=Q(ix,:);
        x=(1:6)+(b-1.5)*0.16;
        lo=Q.mean_difference-Q.CI95_low; hi=Q.CI95_high-Q.mean_difference;
        errorbar(x,Q.mean_difference,lo,hi,'Color',colors(b,:), ...
            'LineStyle','none','LineWidth',1.0,'Marker',char('o'+(b-1)*4), ...
            'MarkerSize',4.5,'MarkerFaceColor','w');
    end
    plot([0.5 6.5],[0 0],'k--','LineWidth',0.7);
    xlim([0.5 6.5]); set(ax,'XTick',1:6,'XTickLabel',datasets,'XTickLabelRotation',25);
    ylabel(['PCE-NMF minus baseline (' metric ')'],'FontSize',11);
    set(ax,'FontName','Times New Roman','FontSize',10,'LineWidth',0.7, ...
        'TickDir','out','Box','off','XGrid','off','YGrid','off');
    if metric_id==1, legend({'GNMFLD','GOCNMF'},'Location','southwest','FontSize',9,'Box','off'); end
    text(0.02,0.96,['(' char(96+metric_id) ')'],'Units','normalized', ...
        'FontName','Times New Roman','FontSize',10,'VerticalAlignment','top');
end
print(f,fullfile(out_dir,'figure-01-paired-differences.png'),'-dpng','-r300');
print(f,fullfile(out_dir,'figure-01-paired-differences.pdf'),'-dpdf','-painters');
print(f,fullfile(out_dir,'figure-01-paired-differences.eps'),'-depsc','-painters'); close(f);

% Figure 2: mean rank over six datasets and two metrics (lower is better).
ranks=zeros(numel(methods),12); col=0;
for d=1:numel(datasets)
    for metric_id=1:2
        col=col+1; vals=zeros(numel(methods),1);
        for m=1:numel(methods)
            z=strcmp(S.dataset,datasets{d})&strcmp(S.method,methods{m});
            if metric_id==1, vals(m)=S.ACC_mean(z); else, vals(m)=S.NMI_mean(z); end
        end
        [~,ord]=sort(vals,'descend'); rr=zeros(numel(methods),1); rr(ord)=1:numel(methods); ranks(:,col)=rr;
    end
end
mr=mean(ranks,2); [mrs,ord]=sort(mr,'ascend');
f=figure('Color','w','Units','centimeters','Position',[2 2 11 7.8]); ax=axes('Parent',f); hold(ax,'on');
for i=1:numel(methods)
    if strcmp(methods{ord(i)},'PCE_NMF'), c=[0.78 0.16 0.12]; mk='o';
    else, c=[0.30 0.48 0.34]; mk='s'; end
    plot(mrs(i),i,mk,'Color',c,'MarkerFaceColor','w','MarkerSize',4.5,'LineWidth',1.0);
end
set(ax,'YTick',1:numel(methods),'YTickLabel',labels(ord),'YDir','reverse');
xlabel('Mean rank across 12 dataset--metric tasks','FontSize',11); xlim([1 8]);
set(ax,'FontName','Times New Roman','FontSize',10,'LineWidth',0.7, ...
    'TickDir','out','Box','off','XGrid','off','YGrid','off');
print(f,fullfile(out_dir,'figure-02-mean-rank.png'),'-dpng','-r300');
print(f,fullfile(out_dir,'figure-02-mean-rank.pdf'),'-dpdf','-painters');
print(f,fullfile(out_dir,'figure-02-mean-rank.eps'),'-depsc','-painters'); close(f);

fid=fopen(fullfile(in_dir,'analysis','mean_ranks.csv'),'w'); fprintf(fid,'method,mean_rank\n');
for i=1:numel(methods), fprintf(fid,'%s,%.12g\n',methods{i},mr(i)); end
fclose(fid);
fprintf('INDEPENDENT20_FIGURES_PASS %s\n',out_dir);
end
