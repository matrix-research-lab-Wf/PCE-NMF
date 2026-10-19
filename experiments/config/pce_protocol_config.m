function cfg = pce_protocol_config(root_dir)
cfg.root_dir = root_dir;
cfg.data_dir = fullfile(root_dir,'data');
cfg.results_dir = fullfile(root_dir,'results');
cfg.adapter_dir = fullfile(root_dir,'experiments','adapters');
cfg.vendor_dir = fullfile(root_dir,'vendor');
cfg.datasets = {'YaleB','COIL20','Optdigits','ORL','PIE','COIL100'};
cfg.methods = {'NMF','CNMF','GNMFLD','EDNMF','LCNMF','GOCNMF','SNMFWLP','PCE_NMF'};
cfg.adapter_ready = [1 1 1 1 1 1 1 1];
cfg.development_seeds = 20260617:20260626;
cfg.seeds = 20260627:20260646;
cfg.label_ratio = 0.10;
cfg.max_iter = 500;
cfg.tol = 1e-5;
cfg.allow_partial = 0;
cfg.matlab_target = 'R2019a';
cfg.ednmf_variant = 'ERDNMF';
cfg.pce_lambda = 100;
cfg.graph_p = [2 2 4 3 3 2];
cfg.goc_alpha = [1000 10 10 100 1000 10];
cfg.goc_parameter_tag = {'source-aligned','source-aligned','source-aligned', ...
    'transferred-face-setting','source-aligned','source-aligned'};
cfg.gnmfld_alpha = [1000 800 600 400 1000 600];
cfg.gnmfld_beta = [50 200 100 10 50 50];
cfg.gnmfld_parameter_tag = {'transfer-Yale-face','source-COIL20', ...
    'transfer-USPS-digits','source-ORL','transfer-Yale-face','source-COIL100'};
cfg.ednmf_alpha = [10 800 600 10 400 1000];
cfg.ednmf_parameter_tag = {'transfer-Yale','source-COIL20','source-Optdigits', ...
    'transfer-Yale-face','source-PIE','source-COIL100'};
cfg.snmfwlp_alpha = 1e3;
cfg.snmfwlp_beta = 1e5;
cfg.expected_samples = [2414 1440 5620 400 2856 7200];
cfg.expected_features = [1024 1024 64 4096 1024 1024];
cfg.expected_classes = [38 20 10 40 68 100];
end
