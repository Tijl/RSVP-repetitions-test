# RSVP-repetitions-test

# steps to create the figures:
- Matlab (tested in R2022a)
- CoSMoMVPA (https://www.cosmomvpa.org/)
- Run 'make_figures.m' (set paths at top of the function)

To run the entire pipeline:
- Install EEGlab (https://sccn.ucsd.edu/eeglab/index.php)
- Download the raw data from https://openneuro.org/datasets/ds004018/versions/2.0.0
- Run 'run_all_preprocessing.m' (set paths in run_preprocessing)
- Run 'run_decoding.m' (set paths)
