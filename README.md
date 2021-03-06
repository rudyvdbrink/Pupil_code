# Pupil code

Template MATLAB scripts for importing and preprocessing EyeLink .edf eyetracking files. The code does the following:

- S1_import_pupil: converts .edf files into text files that separate out event information and sample information, and save this as .asc (text) files.
- S2_convert_pupil: run through the text files, and extract the relevant event information and data. This is then combined and stored in a format that can be read and understood by the EEGLAB toolbox. 
- S3_preprocess_pupil: this cleans the pupil data. First sections with missing data or artifactual data are identified and interpolated across. If requested, deconvolution is used to remove artifactual variance surrounding missing data.   

Notes:

- After running these three steps, you should have output .mat files that contain an EEGLAB structure. EEG.data contains the pupil data, where the 1st channel is pupil diameter, the 2nd is gaze X position, and the 3rd is gaze Y position. The variable 'baddata' indexes what samples were artifactual and interpolated across. Event information is stored in EEG.event.
- It's possible that some steps are version dependent. I wrote this code in MATLAB 2017b, and using EEGLAB version 14.1.1b.
- For the code to be able to run, you'd need to change the 'homedir' variable in each script to refer to the directory where you've stored this code. 
- Raw data (.edf) should be placed in a sub-directory named '/data/raw/'. You can also just run S1_import_pupil, and it will create these folders for you.
- The code assumes that the sample rate is 1000 Hz. Should this differ, change the variable 'srate' in S2_convert_pupil.m, and please read the comments in S3_preprocess_pupil.m. 
- Please see the comments within the code for more specifics.

Dependencies:

- EEGLAB (https://sccn.ucsd.edu/eeglab/index.php)
- The image processing toolbox (only the deconvolution step requires this)

Parts of this this code are modified from: 
- van den Brink RL, Murphy PR, Nieuwenhuis S (2016) Pupil Diameter Tracks Lapses of Attention. PLoS ONE 11(10): e0165274. https://doi.org/10.1371/journal.pone.0165274

If you use this code for a publication, please cite it.

