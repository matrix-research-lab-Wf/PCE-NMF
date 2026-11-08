function [pred,info] = run_EDNMF(X,y,labeled,W0,H0,opt)
% ERDNMF (element-ratio EDNMF) author objective/update with paired factors.
t0=tic; small=1e-12; n=length(y); c=size(H0,1); L=find(labeled); Uidx=find(~labeled);
perm=[L;Uidx]; invperm=zeros(n,1); invperm(perm)=1:n; Xp=X(:,perm); yp=y(perm);
U=max(W0,small); V=max(H0(:,perm)',small); nl=length(L);
Y=zeros(n,c); idx=sub2ind([n c],(1:nl)',yp(1:nl)); Y(idx)=1; wrong=zeros(n,c); wrong(1:nl,:)=1-Y(1:nl,:);
alpha=opt.ednmf_alpha(opt.dataset_index);
for it=1:200
    U=U.*((Xp*V)./max(U*(V'*V),small));
    correct=sum(sum(Y.*V)); incorrect=sum(sum(wrong.*V)); correct=max(correct,small);
    num=Xp'*U+alpha*(incorrect/(correct^2))*Y;
    den=V*(U'*U)+alpha*(1/correct)*wrong;
    V=V.*(num./max(den,small)); V=max(V,small);
end
[dummy,pp]=max(V,[],2); %#ok<ASGLU>
pred=pp(invperm); info.iterations=it; info.runtime_sec=toc(t0);
info.U=U; info.V=V(invperm,:);
info.init_mode='exact_common_W0_H0_protocol_adaptation'; info.parameter_tag=opt.ednmf_parameter_tag{opt.dataset_index};
info.source_id='ERDNMF_commit_f2fd73adbc38947ee1848f500c84a770ea09e9a5';
end
