%converting .edf files to separate .asc files for events and samples

%% clear contents
clear 
close all
clc
%% add paths and set folder structure
currentdir = cd;
driveLetter = currentdir(1:7);

%data folders
rawdir = [driveLetter '\NORET\data\raw\'];
wrtdir = [driveLetter '\NORET\data\processed\'];
edf2ascdir = [driveLetter '\Programs\edf2asc\'];

edf2ascexe = [edf2ascdir 'edf2asc.exe'];
edfapidll  = [edf2ascdir 'edfapi.dll'];


%add and start SPM
% spmdir = [driveLetter '\Programs\SPm8\spm8\' ];
% addpath(genpath(spmdir))
% spm fmri

sublist = { 'NORET003';
            'NORET004';
            'NORET005';
            'NORET006';
            'NORET007';
            'NORET008';
            'NORET009';
            'NORET010';
            'NORET011';
            'NORET012';
            'NORET013';
            'NORET014';
            'NORET015';
            'NORET016';
            'NORET017';
            'NORET018';
            'NORET019';
            'NORET020';
            'NORET021';
%             'NORET022';
            'NORET023';
            'NORET024';
             'NORET025';
             'NORET026';
             'NORET027';
             'NORET028';
            };



%% loop over subjects, sessions and scans

for subi = 1:length(sublist) %participants loop
    rawsubdir = [rawdir sublist{subi}];
    wrtsubdir = [wrtdir sublist{subi}];
    
    for session = 1:2        %session loop
        for scan = 1:2       %scan loop (pre- or post-drug)
            
            %set subject/session/scan-specific folder
            if scan == 1;  pupildir = [rawsubdir '\session' num2str(session) '\RSpre\PUPIL\']; else  pupildir = [rawsubdir '\session' num2str(session) '\RSpost\PUPIL']; end %folder with raw data
            if scan == 1;  outdir = [wrtsubdir '\session' num2str(session) '\RSpre\PUPIL\']; else  outdir = [wrtsubdir '\session' num2str(session) '\RSpost\PUPIL\']; end %write folder
            if ~exist(outdir,'dir'); mkdir(outdir); end %create write folder if it doesn't already exist
            cd(pupildir)
         
            %% get pupil file and check file naming
            edffile = dir('*.edf'); 
            
            %skip if there's no pupil data for this subject, session and
            %scan
            if isempty(edffile); disp(['missing edf file NORE0' num2str(subi+3) num2str(scan) ', session ' num2str(session)]); continue; end 
            edffile = edffile.name;
            
            %skip if imported files already exist
            if exist([outdir edffile(1:end-4) '_e.asc'], 'file') && exist([outdir edffile(1:end-4) '_s.asc'], 'file'); disp(['skipping ' sublist{subi} ' session ' num2str(session) ' scan ' num2str(scan)]);  continue; end
            
            if strcmpi(edffile,['NORE0' num2str(subi+2) num2str(scan)]); disp(['mislabled edf file ' edffile]); end
            
            
            %% place the conversion program in the pupil folder
            
            copyfile(edf2ascexe,pupildir);
            copyfile(edfapidll, pupildir);

            %% convert EDF to ASCII file and put in correct folder
            
            disp(['working on ' edffile ' events']);
            system(['edf2asc -ns ' edffile ' ' edffile(1:end-4) '_e']); %-ns for no samples, so these are just the events
            
            disp(['working on ' edffile ' samples']);            
            system(['edf2asc -ne ' edffile ' ' edffile(1:end-4) '_s']); %-ne for no events
           

            movefile([edffile(1:end-4) '_e.asc'], outdir)
            movefile([edffile(1:end-4) '_s.asc'], outdir)
            
            delete('edf2asc.exe','edfapi.dll')

            %ls outdir
            
        end %end scan loop (pre- or post-drug scan)
    end %end session loop (drug or placebo)
end %end subject loop


























