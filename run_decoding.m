function run_decoding(runnr)
    addpath('~/CoSMoMVPA/mvpa/')
    datapath = '~/DATA_LOCAL/200_objects';
    nproc = cosmo_parallel_get_nproc_available();
    rng('shuffle')
    subjectnrs = randsample(1:16,16);
    for subjectnr=subjectnrs
        outfn = sprintf('results/sub-%02i_run%02i_decoding.mat',subjectnr,runnr);
        if exist(outfn,'file')
            fprintf('skipping %s\n',outfn)
        else
            load(sprintf('%s/derivatives/cosmomvpa/sub-%02i_run-%02i_cosmomvpa.mat',datapath,subjectnr,runnr),'ds')
            ds = cosmo_slice(ds,~ds.sa.istarget);
            ds.sa.targets = ds.sa.stimulusnumber;
            ds.sa.chunks = ds.sa.trialnumber;
            nh = cosmo_interval_neighborhood(ds,'time','radius',0);
            res_cell = {};
            blocknrs = 3:40;
            for blocknr = 1:numel(blocknrs)
                fprintf('s%02i r%02i b%02i\n',subjectnr,runnr,blocknrs(blocknr));
                dsb = cosmo_slice(ds,ds.sa.chunks<=blocknrs(blocknr));
                ma = {};
                ma.classifier = @cosmo_classify_lda;
                ma.partitions = cosmo_nfold_partitioner(dsb);
                ma.nproc = nproc;
                res = cosmo_searchlight(dsb,nh,@cosmo_crossvalidation_measure,ma);
                res.sa.subjectnr = subjectnr;
                res.sa.runnr = runnr;
                res.sa.blocknr = blocknrs(blocknr);
                res_cell{blocknr} = res;
            end
            res = cosmo_stack(res_cell);
            save(outfn,'res');
        end
    end