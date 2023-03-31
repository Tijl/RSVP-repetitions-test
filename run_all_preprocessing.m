
%% cosmo & eeglab
addpath('../../../CoSMoMVPA/mvpa')
addpath('../../../Matlabtoolboxes/eeglab/')
eeglab;close gcf

for r=2
    for p=1:16
        try
            run_preprocessing(p,r)
        catch
        end
    end
end