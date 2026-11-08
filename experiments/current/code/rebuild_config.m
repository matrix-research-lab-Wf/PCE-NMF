function cfg = rebuild_config()
%REBUILD_CONFIG Locked configuration for the released PCE-NMF experiments.
% Paths below adapt the original workspace layout to this repository.

code_dir = fileparts(mfilename('fullpath'));
cfg.root_dir = fileparts(fileparts(fileparts(code_dir)));
cfg.data_dir = fullfile(cfg.root_dir,'data');
cfg.results_dir = fullfile(cfg.root_dir,'results','current');
cfg.adapter_dir = fullfile(code_dir,'adapters');
cfg.vendor_dir = fullfile(cfg.root_dir,'third_party');
cfg.hlpnmf_dir = fullfile(cfg.vendor_dir,'HLPNMF');

cfg.datasets = {'YaleB','COIL20','Optdigits','ORL','PIE','COIL100', ...
                'AR','MSRA25','MNIST','USPS'};
cfg.methods = {'NMF','CNMF','GNMFLD','EDNMF','LCNMF','GOCNMF', ...
               'SNMFWLP','HLPNMF','PCE_NMF'};
cfg.seed_smoke = 20261029;
cfg.seeds_development = 20261009:20261013;
cfg.seeds_formal = 20261029:20261048;
cfg.label_ratio = 0.10;
cfg.max_iter = 200;
cfg.tol = 0;
cfg.pce_lambda = 100;
cfg.pce_dev_p_fixed = 3;
cfg.pce_dev_lambda_grid = [0.1 1 10 100 1000 10000];
cfg.pce_dev_p_grid = [2 3 5 7 10];
cfg.pce_p_locked = [2 2 3 3 3 2 3 3 5 3];
cfg.pce_lambda_locked = [100 100 100 100 1000 1000 100 1 100 1000];

% Baseline graph settings retained from the locked formal protocol.
cfg.graph_p = [2 2 4 3 3 2 5 10 5 5];
cfg.snmfwlp_p = [3 3 4 3 3 3 5 10 5 5];

% GOCNMF author table: PIE (3,1000), UMIST (3,100), COIL20
% (2,100), COIL100 (2,1000), Optdigits (5,100), MNIST (5,100).
% YaleB/AR/MSRA25 transfer the PIE pair; ORL transfers UMIST; USPS
% transfers the digit setting.
cfg.goc_p = [3 2 5 3 3 2 3 3 5 5];

% GOCNMF source values where available; remaining entries are transferred.
cfg.goc_alpha = [1000 100 100 100 1000 1000 1000 1000 100 100];
cfg.goc_parameter_tag = { ...
    'transferred-PIE','source-COIL20','source-Optdigits', ...
    'transferred-UMIST','source-PIE','source-COIL100', ...
    'transferred-PIE','transferred-PIE','source-MNIST', ...
    'transferred-MNIST'};

% GNMFLD values: first six preserve the audited mapping; added data use
% domain-related transferred settings pending source verification.
cfg.gnmfld_alpha = [1000 800 600 400 1000 600 1000 1000 600 600];
cfg.gnmfld_beta  = [50 200 100 10 50 50 50 50 100 100];
cfg.gnmfld_parameter_tag = { ...
    'aligned-prelocked-not-published-optimum', ...
    'aligned-prelocked-not-published-optimum', ...
    'aligned-prelocked-not-published-optimum', ...
    'aligned-prelocked-not-published-optimum', ...
    'aligned-prelocked-not-published-optimum', ...
    'aligned-prelocked-not-published-optimum', ...
    'aligned-prelocked-not-published-optimum', ...
    'aligned-prelocked-not-published-optimum', ...
    'aligned-prelocked-not-published-optimum', ...
    'aligned-prelocked-not-published-optimum'};

% ERDNMF source table: Yale 10, PIE 400, MSRA25 10, AR 200,
% COIL20 800, COIL100 1000, Optdigits 600, USPS 600.
cfg.ednmf_alpha = [10 800 600 10 400 1000 200 10 600 600];
cfg.ednmf_parameter_tag = { ...
    'source-Yale','source-COIL20','source-Optdigits','transferred-Yale', ...
    'source-PIE','source-COIL100','source-AR','source-MSRA25', ...
    'transferred-USPS','source-USPS'};

cfg.snmfwlp_alpha = 1e3;
cfg.snmfwlp_beta = 1e5;

% HLPNMF author settings; Optdigits, ORL, and USPS are transferred.
cfg.hlpnmf_p = [2 2 5 2 3 2 5 10 5 5];
cfg.hlpnmf_k = [3 3 1 3 5 3 1 1 1 1];
cfg.hlpnmf_alpha = 1000*ones(1,numel(cfg.datasets));
cfg.hlpnmf_parameter_tag = { ...
    'source-YaleB','source-COIL20','transferred-MNIST','transferred-YaleB', ...
    'source-PIE','source-COIL100','source-AR','source-MSRA25', ...
    'source-MNIST','transferred-MNIST'};

cfg.expected_samples = [2414 1440 5620 400 2856 7200 1680 1799 6996 9298];
cfg.expected_features = [1024 1024 64 4096 1024 1024 2000 256 784 256];
cfg.expected_classes = [38 20 10 40 68 100 120 12 10 10];
end

