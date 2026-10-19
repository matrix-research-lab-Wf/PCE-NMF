function plot_pce_mechanism_figures_R2019a(mode)
% PLOT_PCE_MECHANISM_FIGURES_R2019A
% MATLAB R2019a-compatible generation of the PCE-NMF framework and
% mechanism-validation figures. The mechanism heatmaps use all unlabeled
% COIL20 samples from V2 formal seed 20260617, p=2, lambda=100, 50 iterations.

fig_dir = fileparts(mfilename('fullpath'));
base_dir = fileparts(fig_dir);
data_file = fullfile(base_dir,'data','COIL20.mat');

set(0,'DefaultAxesFontName','Times New Roman');
set(0,'DefaultTextFontName','Times New Roman');
set(0,'DefaultAxesFontSize',10);
set(0,'DefaultAxesLineWidth',0.7);
set(0,'DefaultAxesTickDir','out');

red = [178 24 43]/255;
orange = [239 138 98]/255;
green = [27 120 55]/255;
dark = [0.18 0.18 0.18];
if nargin<1, mode='all'; end

%% Figure 1: PCE-NMF framework.
if strcmpi(mode,'all') || strcmpi(mode,'framework')
fig = figure('Color','w','Units','inches','Position',[1 1 7.2 4.05], ...
    'PaperPositionMode','auto','Renderer','painters');
ax = axes('Parent',fig,'Position',[0 0 1 1],'Visible','off'); %#ok<LAXES>
axis(ax,[0 1 0 1]); hold(ax,'on');

% Left: input matrix with labeled/unlabeled column groups.
local_matrix(ax,[0.035 0.16 0.115 0.68],12,8,[1 1 1],dark);
patch(ax,[0.035 0.150 0.150 0.035],[0.70 0.70 0.84 0.84], ...
    [0.94 0.73 0.66],'EdgeColor','none');
for j=0:8, plot(ax,0.035+j*0.115/8*[1 1],[0.16 0.84],'-','Color',[.72 .72 .72],'LineWidth',0.35); end
text(ax,0.0925,0.885,'Data matrix  $X$','Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',10.5);
text(ax,0.0925,0.735,'labeled','HorizontalAlignment','center','FontSize',8.5,'Color',red);
text(ax,0.0925,0.57,'unlabeled','HorizontalAlignment','center','FontSize',8.5,'Color',dark);

% Upper path: graph construction -> harmonic class evidence -> exclusion.
local_arrow(ax,0.155,0.215,0.67,0.67,dark,'-');
local_graph(ax,[0.225 0.54 0.145 0.27],dark,red,green,orange);
text(ax,0.2975,0.845,'Cosine $p$-NN graph  $W$','Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',10);
text(ax,0.2975,0.515,'$L=D-W$','Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',9);
local_arrow(ax,0.375,0.425,0.67,0.67,dark,'-');
local_heatblock(ax,[0.435 0.54 0.105 0.27],green,false);
text(ax,0.4875,0.845,'Harmonic evidence','HorizontalAlignment','center','FontSize',10);
text(ax,0.4875,0.515,'$P_{\mathcal U}=L_{\mathcal{UU}}^{-1}W_{\mathcal{UL}}C$', ...
    'Interpreter','latex','HorizontalAlignment','center','FontSize',8.7);
local_arrow(ax,0.545,0.595,0.67,0.67,dark,'-');
local_heatblock(ax,[0.605 0.54 0.105 0.27],orange,true);
text(ax,0.6575,0.845,'Exclusion field','HorizontalAlignment','center','FontSize',10);
text(ax,0.6575,0.515,'$Q_{\mathcal U}=\mathbf{1}-P_{\mathcal U}$', ...
    'Interpreter','latex','HorizontalAlignment','center','FontSize',9);

% Lower path: constrained factorization and class-specific contribution energy.
local_arrow(ax,0.155,0.215,0.32,0.32,dark,'-');
local_matrix(ax,[0.225 0.18 0.07 0.28],8,4,[0.82 0.89 0.96],dark);
text(ax,0.260,0.145,'$U$','Interpreter','latex','HorizontalAlignment','center','FontSize',11);
text(ax,0.310,0.32,'$\times$','Interpreter','latex','HorizontalAlignment','center','FontSize',13);
local_matrix(ax,[0.325 0.23 0.16 0.18],4,9,[0.98 0.84 0.75],dark);
% Hard labeled support: one admissible class per labeled row.
patch(ax,[0.325 0.485 0.485 0.325],[0.365 0.365 0.41 0.41], ...
    [0.94 0.73 0.66],'EdgeColor','none');
plot(ax,[0.325 0.485],[0.365 0.365],'-','Color',dark,'LineWidth',0.35);
text(ax,0.405,0.145,'$V^{\mathrm T}$   (hard labeled support)', ...
    'Interpreter','latex','HorizontalAlignment','center','FontSize',9.3);
text(ax,0.355,0.435,'$X\approx UV^{\mathrm T}$','Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',9.2);
local_arrow(ax,0.495,0.555,0.32,0.32,dark,'-');

% Mechanism core: exclusion field gates contribution energy.
local_heatblock(ax,[0.565 0.20 0.105 0.23],red,false);
text(ax,0.6175,0.455,'Contribution energy','HorizontalAlignment','center','FontSize',9.7);
text(ax,0.6175,0.17,'$s_{ik}=\Vert u_k\Vert_2^2v_{ik}^2$', ...
    'Interpreter','latex','HorizontalAlignment','center','FontSize',8.7);
local_arrow(ax,0.6575,0.6575,0.535,0.445,orange,'-');
text(ax,0.688,0.475,'$Q\odot[s_{ik}]$','Interpreter','latex', ...
    'HorizontalAlignment','left','FontSize',9,'Color',red);

% Joint optimization and native class decision.
local_arrow(ax,0.72,0.775,0.32,0.32,dark,'-');
rectangle(ax,'Position',[0.775 0.205 0.205 0.23],'FaceColor',[0.96 0.98 0.96], ...
    'EdgeColor',green,'LineWidth',0.8);
text(ax,0.8775,0.39,'PCE-NMF','HorizontalAlignment','center','FontSize',10.5,'Color',green);
text(ax,0.8775,0.322,{'$\min_{U,V\geq 0}\ \Vert X-UV^{\mathrm T}\Vert_F^2$', ...
    '$+\lambda\sum_{i=1}^{n}\sum_{k=1}^{c}q_{ik}s_{ik}$'},'Interpreter','latex', ...
    'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',8.5);
text(ax,0.8775,0.245,'$\widehat y_i=\arg\max_k s_{ik}$','Interpreter','latex', ...
    'HorizontalAlignment','center','FontSize',9.2,'Color',red);
local_arrow(ax,0.71,0.785,0.67,0.405,red,'--');

% Structural labels clarify the two coupled routes.
text(ax,0.184,0.78,'propagation route','Rotation',90,'HorizontalAlignment','center', ...
    'FontSize',8.5,'Color',green);
text(ax,0.184,0.29,'factorization route','Rotation',90,'HorizontalAlignment','center', ...
    'FontSize',8.5,'Color',red);
local_save(fig,fig_dir,'fig1_pce_framework');
close(fig);
end

%% Figure 2: mechanism validation from the formal COIL20 run.
if strcmpi(mode,'framework'), return; end
[X,y,c] = local_load_prepare(data_file);
if c~=20, error('Expected 20 classes in COIL20.'); end
seed = 20260617; p = 2; lambda = 100; label_fraction = 0.1;
rand('twister',seed);
labeled = local_stratified_labels(y,c,label_fraction);
unlabeled = true(length(y),1); unlabeled(labeled)=false;
rand('twister',seed+97);
U0 = rand(size(X,1),c)+0.01;
V0 = rand(size(X,2),c)+0.01;
W = local_binary_cosine_pnn(X,p);
D = full(sum(W,2)); L = spdiags(D,0,size(W,1),size(W,2))-W;
[P,Q] = local_harmonic_exclusion(W,L,labeled,y,c,1e-12);
[U,V] = local_train_pce(X,labeled,y,U0,V0,Q,lambda,50,1e-12);
S = (V.^2).*repmat(sum(U.^2,1),size(V,1),1);
Sshare = S./max(repmat(sum(S,2),1,c),1e-12);

meanP=zeros(c,c); meanQ=zeros(c,c); meanS=zeros(c,c);
for k=1:c
    ids=find(unlabeled & y==k);
    meanP(k,:)=mean(P(ids,:),1);
    meanQ(k,:)=mean(Q(ids,:),1);
    meanS(k,:)=mean(Sshare(ids,:),1);
end

csv_file=fullfile(fig_dir,'fig2_mechanism_source_data.csv');
fid=fopen(csv_file,'w');
if fid<0, error('Cannot write %s.',csv_file); end
fprintf(fid,'true_class,target_class,mean_P,mean_Q,mean_energy_share\n');
for i=1:c
    for j=1:c
        fprintf(fid,'%d,%d,%.12g,%.12g,%.12g\n',i,j,meanP(i,j),meanQ(i,j),meanS(i,j));
    end
end
fclose(fid);

fig=figure('Color','w','Units','inches','Position',[1 1 7.2 2.65], ...
    'PaperPositionMode','auto','Renderer','painters');
mats={meanP,meanQ,meanS};
titles={'(a) Harmonic evidence $P$','(b) Exclusion weights $Q=\mathbf{1}-P$', ...
        '(c) Final class-energy share'};
maps={local_white_map(green,256),local_white_map(orange,256), ...
      local_white_map(red,256)};
for panel=1:3
    ax=subplot(1,3,panel);
    imagesc(ax,mats{panel},[0 1]); axis(ax,'image');
    colormap(ax,maps{panel});
    set(ax,'XTick',[1 5 10 15 20],'YTick',[1 5 10 15 20], ...
        'TickDir','out','Box','off','LineWidth',0.7,'FontName','Times New Roman', ...
        'FontSize',9,'YDir','normal');
    xlabel(ax,'Class coordinate','FontSize',10);
    if panel==1, ylabel(ax,'True class','FontSize',10); else, set(ax,'YTickLabel',{}); end
    title(ax,titles{panel},'Interpreter','latex','FontName','Times New Roman', ...
        'FontSize',10,'FontWeight','normal');
    cb=colorbar(ax); set(cb,'Ticks',[0 0.5 1],'FontName','Times New Roman','FontSize',8);
end
local_save(fig,fig_dir,'fig2_pce_mechanism_heatmaps');
close(fig);

fprintf('Saved PCE-NMF framework and mechanism figures in %s\n',fig_dir);
end

function local_matrix(ax,pos,nr,nc,fillc,edgec)
x=pos(1); y=pos(2); w=pos(3); h=pos(4);
rectangle(ax,'Position',pos,'FaceColor',fillc,'EdgeColor',edgec,'LineWidth',0.7);
for i=1:nr-1
    yy=y+i*h/nr; plot(ax,[x x+w],[yy yy],'-','Color',[.72 .72 .72],'LineWidth',0.3);
end
for j=1:nc-1
    xx=x+j*w/nc; plot(ax,[xx xx],[y y+h],'-','Color',[.72 .72 .72],'LineWidth',0.3);
end
end

function local_heatblock(ax,pos,color,invert)
nr=7; nc=5; x=pos(1); y=pos(2); w=pos(3); h=pos(4);
for i=1:nr
    for j=1:nc
        d=abs((i-1)/(nr-1)-(j-1)/(nc-1));
        val=max(0.08,1-1.25*d);
        if invert, val=1-val; end
        fc=(1-val)*[1 1 1]+val*color;
        rectangle(ax,'Position',[x+(j-1)*w/nc y+(nr-i)*h/nr w/nc h/nr], ...
            'FaceColor',fc,'EdgeColor',[.82 .82 .82],'LineWidth',0.25);
    end
end
rectangle(ax,'Position',pos,'FaceColor','none','EdgeColor',[.25 .25 .25],'LineWidth',0.65);
end

function local_graph(ax,pos,dark,red,green,orange)
x=pos(1); y=pos(2); w=pos(3); h=pos(4);
xy=[.10 .58;.25 .88;.46 .70;.70 .88;.90 .55;.76 .22;.48 .12;.20 .25];
xy(:,1)=x+w*xy(:,1); xy(:,2)=y+h*xy(:,2);
edges=[1 2;1 3;1 8;2 3;2 4;3 4;3 7;3 8;4 5;4 6;5 6;6 7;7 8];
for e=1:size(edges,1)
    plot(ax,xy(edges(e,:),1),xy(edges(e,:),2),'-','Color',[.70 .74 .78],'LineWidth',0.55);
end
cols=[red;red;green;green;orange;orange;dark;dark];
for i=1:size(xy,1)
    rectangle(ax,'Position',[xy(i,1)-.008 xy(i,2)-.011 .016 .022], ...
        'Curvature',[1 1],'FaceColor',cols(i,:),'EdgeColor','w','LineWidth',0.45);
end
rectangle(ax,'Position',pos,'FaceColor','none','EdgeColor',[.65 .65 .65], ...
    'LineStyle',':','LineWidth',0.6);
end

function local_box(ax,pos,fillc,edgec,label,color)
rectangle(ax,'Position',pos,'FaceColor',fillc,'EdgeColor',edgec, ...
    'LineWidth',0.9,'Curvature',[0.08 0.08]);
text(ax,pos(1)+pos(3)/2,pos(2)+pos(4)/2,label, ...
    'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'FontName','Times New Roman','FontSize',9.2,'Color',color);
end

function local_arrow(ax,x1,x2,y1,y2,color,style)
plot(ax,[x1 x2],[y1 y2],style,'Color',color,'LineWidth',0.9);
dx=x2-x1; dy=y2-y1; len=sqrt(dx^2+dy^2);
if len<=0, return; end
ux=dx/len; uy=dy/len; px=-uy; py=ux; h=0.014; w=0.008;
patch(ax,[x2 x2-h*ux+w*px x2-h*ux-w*px], ...
    [y2 y2-h*uy+w*py y2-h*uy-w*py],color,'EdgeColor',color);
end

function local_save(fig,out_dir,name)
set(fig,'InvertHardcopy','off');
old_units=get(fig,'Units'); set(fig,'Units','inches'); pos=get(fig,'Position');
set(fig,'PaperUnits','inches','PaperSize',pos(3:4), ...
    'PaperPosition',[0 0 pos(3) pos(4)]);
figure(fig);
print(fullfile(out_dir,[name '.png']),'-dpng','-r300');
print(fullfile(out_dir,[name '.pdf']),'-dpdf','-painters');
print(fullfile(out_dir,[name '.eps']),'-depsc','-painters');
set(fig,'Units',old_units);
end

function map=local_white_map(color,n)
t=linspace(0,1,n)';
map=(1-t)*[1 1 1]+t*color;
end

function [X,y,c]=local_load_prepare(filename)
S=load(filename); fields=fieldnames(S); y=[]; X=[];
yn={'gnd','label','labels','Y','y','truth','class','classes','target','targets'};
for i=1:length(yn)
    if isfield(S,yn{i})
        a=S.(yn{i});
        if isnumeric(a)&&isvector(a)&&numel(a)>=2, y=double(a(:)); break; end
    end
end
if isempty(y), error('Could not identify labels in %s.',filename); end
xn={'fea','X','data','Data','features','feature','A'};
for i=1:length(xn)
    if isfield(S,xn{i})
        a=S.(xn{i});
        if isnumeric(a)&&ndims(a)==2&&(size(a,1)==numel(y)||size(a,2)==numel(y))
            X=double(a); break;
        end
    end
end
if isempty(X), error('Could not identify features in %s.',filename); end
if size(X,1)==numel(y), X=X'; end
classes=unique(y); c=length(classes); yy=zeros(size(y));
for k=1:c, yy(y==classes(k))=k; end
y=yy; X(X<0 & X>-1e-12)=0;
norms=sqrt(sum(X.*X,1));
if any(norms<=1e-15), error('Zero-norm sample.'); end
X=X./repmat(norms,size(X,1),1);
end

function labeled=local_stratified_labels(y,c,rate)
labeled=[];
for k=1:c
    idx=find(y==k); nl=max(1,floor(rate*length(idx)));
    rp=randperm(length(idx)); labeled=[labeled;idx(rp(1:nl))]; %#ok<AGROW>
end
labeled=sort(labeled);
end

function W=local_binary_cosine_pnn(X,p)
n=size(X,2); block=32; rows=zeros(n*p,1); cols=zeros(n*p,1); ptr=0;
for first=1:block:n
    last=min(n,first+block-1); G=X'*X(:,first:last);
    for jj=1:(last-first+1)
        i=first+jj-1; G(i,jj)=-Inf; [dummy,ord]=sort(G(:,jj),'descend'); %#ok<ASGLU>
        nb=ord(1:p); rows(ptr+1:ptr+p)=i; cols(ptr+1:ptr+p)=nb; ptr=ptr+p;
    end
end
A=sparse(rows,cols,1,n,n); W=spones(A+A'); W=W-spdiags(diag(W),0,n,n); W=spones(W);
end

function [P,Q]=local_harmonic_exclusion(W,L,labeled,y,c,small)
n=size(W,1); islab=false(n,1); islab(labeled)=true;
C=zeros(length(labeled),c); C(sub2ind(size(C),(1:length(labeled))',y(labeled)))=1;
P=zeros(n,c); P(labeled,:)=C; Q=zeros(n,c); comp=local_components(W);
for cc=1:max(comp)
    nodes=find(comp==cc); lab=nodes(islab(nodes)); unlab=nodes(~islab(nodes));
    if isempty(lab)||isempty(unlab), continue; end
    [dummy,loc]=ismember(lab,labeled); %#ok<ASGLU>
    Pc=L(unlab,unlab)\(W(unlab,lab)*C(loc,:));
    Pc(Pc<0 & Pc>-1e-10)=0;
    if any(~isfinite(Pc(:)))||min(Pc(:))<-1e-8, error('Invalid harmonic field.'); end
    Pc(Pc<0)=0; rs=sum(Pc,2);
    if any(rs<=small), error('Zero harmonic row sum.'); end
    Pc=Pc./repmat(rs,1,c); P(unlab,:)=Pc; Q(unlab,:)=1-Pc;
end
end

function comp=local_components(W)
n=size(W,1); comp=zeros(n,1); queue=zeros(n,1); cc=0;
for start=1:n
    if comp(start)~=0, continue; end
    cc=cc+1; head=1; tail=1; queue(1)=start; comp(start)=cc;
    while head<=tail
        v=queue(head); head=head+1; nb=find(W(v,:)>0);
        for j=1:length(nb)
            u=nb(j); if comp(u)==0, tail=tail+1; queue(tail)=u; comp(u)=cc; end
        end
    end
end
end

function [U,V]=local_train_pce(X,labeled,y,U0,V0,Q,lambda,maxiter,small)
U=max(U0,small); V=max(V0,small); n=size(V,1); c=size(V,2);
for t=1:length(labeled)
    i=labeled(t); yi=y(i); V(i,:)=0; V(i,yi)=max(V0(i,yi),small);
end
for it=1:maxiter
    b=zeros(c,1);
    for k=1:c, b(k)=sum(Q(:,k).*(V(:,k).^2)); end
    U=U.*((X*V)./max(U*(V'*V)+lambda*(U.*repmat(b',size(U,1),1)),small));
    U=max(U,small); a=sum(U.^2,1); UtU=U'*U;
    for first=1:64:n
        last=min(n,first+63); ids=first:last;
        num=X(:,ids)'*U;
        den=V(ids,:)*UtU+lambda*((Q(ids,:).*V(ids,:)).*repmat(a,length(ids),1));
        V(ids,:)=max(V(ids,:).*(num./max(den,small)),small);
    end
    for t=1:length(labeled)
        i=labeled(t); yi=y(i); keep=V(i,yi); V(i,:)=0; V(i,yi)=max(keep,small);
    end
end
end
