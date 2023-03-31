function run_preprocessing(partid,runid)
    
    %% get files
    datapath = '~/DATA_LOCAL/200_objects';
    mkdir(sprintf('%s/derivatives/eeglab',datapath));
    mkdir(sprintf('%s/derivatives/cosmomvpa',datapath));
    
    contfn = sprintf('%s/derivatives/eeglab/sub-%02i_run-%02i_task-rsvp_continuous.set',datapath,partid,runid);
    if isfile(contfn)
        fprintf('Using %s\n',contfn)
    	EEG_cont = pop_loadset(contfn);
    else
        % load EEG file
        EEG_raw = pop_loadbv(sprintf('%s/sub-%02i/eeg/',datapath,partid), sprintf('sub-%02i_task-rsvp_run-%02i_eeg.vhdr',partid,runid));
        EEG_raw = eeg_checkset(EEG_raw);
        EEG_raw.setname = partid;
        EEG_raw = eeg_checkset(EEG_raw);
        
        % high pass filter
        EEG_raw = pop_eegfiltnew(EEG_raw, 0.1,[]);

        % low pass filter
        EEG_raw = pop_eegfiltnew(EEG_raw, [],100);

        % downsample
        EEG_cont = pop_resample(EEG_raw, 250);
        EEG_cont = eeg_checkset(EEG_cont);
        
        % save
        pop_saveset(EEG_cont,contfn);
    end
    
    %% read eventinfo and events
    eventsfn= sprintf('%s/sub-%02i/eeg/sub-%02i_task-rsvp_run-%02i_events.tsv',datapath,partid,partid,runid);
    eventlist = readtable(eventsfn,'FileType','text','Delimiter','\t');
    
    %% create epochs
    % get rid of rogue triggers of 1. sent one at start that was to designate start of experiment
    ntrigs = size(EEG_cont.event,2);
    ntrials = size(eventlist,1);
    if ntrigs ~= size(eventlist,1)
       EEG_cont.event(1:(ntrigs-ntrials)) = []; % remove first event
    end
    EEG_epoch = pop_epoch(EEG_cont, {'E  1'}, [-0.100 0.600]);
    EEG_epoch = eeg_checkset(EEG_epoch);

    %% convert to cosmo
    ds = cosmo_flatten(permute(EEG_epoch.data,[3 1 2]),{'chan','time'},{{EEG_epoch.chanlocs.labels},EEG_epoch.times},2);
    ds.a.meeg=struct(); %or cosmo thinks it's not a meeg ds 
    ds.sa = table2struct(eventlist,'ToScalar',true);
    cosmo_check_dataset(ds,'meeg');
    
    %% save epochs
    fprintf('Saving.\n');
    save(sprintf('%s/derivatives/cosmomvpa/sub-%02i_run-%02i_cosmomvpa.mat',datapath,partid,runid),'ds','-v7.3')
    fprintf('Finished.\n');
end
