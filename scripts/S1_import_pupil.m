%importing .edf files as separate .asc files for events and samples

%% clear contents
clear 
close all
clc
%% add paths and set folder structure

%root directory for this project
homedir = 'C:\DATA\Pupil_code\';

%data folders
rawdir     = [homedir 'data\raw\edf\']; %folder where the .edf files are stored
wrtdir     = [homedir 'data\raw\imported\']; %sub-folder where the .asc files are saved to
edf2ascdir = [homedir 'functions\edf2asc\']; %folder that contains the conversion program

%files that do the conversion from .edf to .asc process
edf2ascexe = [edf2ascdir 'edf2asc.exe'];
edfapidll  = [edf2ascdir 'edfapi.dll'];

%if the folders where the data are written out to don't yet exist, this creates them
if ~exist(wrtdir,'dir'); mkdir([wrtdir 'events']); mkdir([wrtdir 'samples']); end
if ~exist(rawdir,'dir'); mkdir(rawdir); end


%% get files to process

filz = dir([rawdir '*.edf']);

%% loop over files

for fi = 1:length(filz)
    
    %% define output files, and check if they are already there
    
    edffile = filz(fi).name;
    if exist([wrtdir 'events\' edffile(1:end-4) '_e.asc'], 'file' ); disp(['skipping ' edffile]); continue; end
    
    %% place the conversion program in the pupil data folder
    
    copyfile(edf2ascexe,rawdir);
    copyfile(edfapidll, rawdir);
    
    %% convert EDF to ASCII file and put in correct folder
    
    cd(rawdir)
    
    %run the conversion to .asc
    disp(['working on ' edffile ' events']);
    system(['edf2asc -ns ' edffile ' ' edffile(1:end-4) '_e']); %-ns for no samples, so these are just the events
    
    disp(['working on ' edffile ' samples']);
    system(['edf2asc -ne ' edffile ' ' edffile(1:end-4) '_s']); %-ne for no events, so these are just the samples
    
    
    movefile([edffile(1:end-4) '_e.asc'], [wrtdir 'events\'] )
    movefile([edffile(1:end-4) '_s.asc'], [wrtdir 'samples\'])
    
    %file clean up
    delete('edf2asc.exe','edfapi.dll')
    
    
end



