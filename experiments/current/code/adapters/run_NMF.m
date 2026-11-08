function [pred,info] = run_NMF(X,y,labeled,W0,H0,opt)
% MATLAB R2019a Euclidean NMF multiplicative updates.
t0 = tic; W = max(W0,eps); H = max(H0,eps);
for it = 1:opt.max_iter
    Hold = H;
    W = W .* ((X*H') ./ max(W*(H*H'),eps));
    H = H .* ((W'*X) ./ max((W'*W)*H,eps));
    rel = norm(H-Hold,'fro') / max(norm(Hold,'fro'),eps);
    if rel <= opt.tol, break; end
end
pred = pce_kmeans_eval(H',y,labeled,opt.seed,50);
info.iterations = it;
info.runtime_sec = toc(t0);
info.init_mode = 'exact_common_W0_H0';
info.parameter_tag = 'protocol_200iter_kmeans50';
info.source_id = 'local_Lee_Seung_Euclidean_MU';
end
