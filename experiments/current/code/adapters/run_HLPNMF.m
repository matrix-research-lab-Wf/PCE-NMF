function [pred,info] = run_HLPNMF(X,y,labeled,W0,H0,opt) %#ok<INUSD>
%RUN_HLPNMF Native-decision wrapper for the public HLPNMF implementation.
% X is features-by-samples. The author code requires samples-by-features and
% all labeled samples placed before all unlabeled samples.

t0 = tic;
n = numel(y);
c = max(y);
L = find(labeled);
Uidx = find(~labeled);
perm = [L; Uidx];
invperm = zeros(n,1);
invperm(perm) = 1:n;

Xp = X(:,perm)';
yp = y(perm);

Options.maxIter = 30;
Options.p = opt.hlpnmf_p(opt.dataset_index);
Options.k = opt.hlpnmf_k(opt.dataset_index);
Options.alpha = opt.hlpnmf_alpha(opt.dataset_index);
Options.SampNum = numel(L);
Options.SampGnd = yp;
Options.SelectClasses = c;

% The public function initializes internally. The common seed is set by the
% driver immediately before this call and the initialization mode is logged.
[~,V,obj] = HLPNMF(Xp,Options);
[~,predp] = max(V,[],2);
pred = predp(invperm);

info.iterations = Options.maxIter;
info.runtime_sec = toc(t0);
info.objective = obj;
info.init_mode = 'author_internal_seeded_initialization';
info.parameter_tag = opt.hlpnmf_parameter_tag{opt.dataset_index};
info.source_id = 'public_HLPNMF_author_code_wrapper';
end

