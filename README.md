# Pupil code

Template MATLAB scripts for importing and preprocessing EyeLink .edf eyetracking files. The code does the following:

- S1_import_pupil: converts .edf files into text files that separate out event information and sample information, and save this as .asc (text) files.
- S2_convert_pupil: run through the text files, and extract the relevant event information and data. This is then combined and stored in a format that can be read and understood by the EEGLAB toolbox. 
- S3_preprocess_pupil: this cleans the pupil data. First sections with missing data or artifactual data are identified and interpolated across. If requested, deconvolution is used to remove artifactual variance surrounding missing data.   

Dependencies:

- EEGLAB (https://sccn.ucsd.edu/eeglab/index.php)
- The image processing toolbox (only the deconvolution step requires this)
