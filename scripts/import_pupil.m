%importing .edf files as separate .asc files for events and samples

%% clear contents
clear 
close all
clc
%% add paths and set folder structure

%root directory for this project
homedir = 'C:\DATA\Pupil_code\';

%data folders
rawdir     = [homedir 'data\raw\edf\'];
wrtdir     = [homedir 'data\raw\imported\'];
edf2ascdir = [homedir 'functions\edf2asc\'];

edf2ascexe = [edf2ascdir 'edf2asc.exe'];
edfapidll  = [edf2ascdir 'edfapi.dll'];

%% get files to process

filz = dir([rawdir '*.edf']);

%% loop over files

for fi = 1:length(filz)
    
    %% define output files, and check if they are already there
    
    edffile = filz(fi).name;
    if exist([wrtdir 'events\' edffile(1:end-4) '_e.asc'], 'file' ); disp(['skipping ' edffile]); continue; end
    
    %% place the conversion program in the pupil folder
    
    copyfile(edf2ascexe,rawdir);
    copyfile(edfapidll, rawdir);
    
    %% convert EDF to ASCII file and put in correct folder
    
    cd(rawdir)
    
    disp(['working on ' edffile ' events']);
    system(['edf2asc -ns ' edffile ' ' edffile(1:end-4) '_e']); %-ns for no samples, so these are just the events
    
    disp(['working on ' edffile ' samples']);
    system(['edf2asc -ne ' edffile ' ' edffile(1:end-4) '_s']); %-ne for no events
    
    
    movefile([edffile(1:end-4) '_e.asc'], [wrtdir 'events\'] )
    movefile([edffile(1:end-4) '_s.asc'], [wrtdir 'samples\'])
    
    delete('edf2asc.exe','edfapi.dll')
    
    
end



