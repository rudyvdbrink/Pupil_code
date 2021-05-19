% Script for extracting pupil and event data from -ascii eye-tracker files
% and creating .mat files

% This script requires two things:
%     (1) -ascii files containing event information
%     (2) -ascii files containing the event information 

clear 
close all
clc

%% add paths and set folder structure

%root directory for this project
homedir = 'C:\DATA\Pupil_code\';

%data folders
rawdir     = [homedir 'data\raw\imported\'];
wrtdir     = [homedir 'data\converted\'];
pupildir   = [rawdir  'samples\'];
eventsdir  = [rawdir  'events\' ];

%start up EEGLAB
addpath(genpath('C:\DATA\Programs\eeglab14_1_1b'))
eeglab, close

if ~exist(wrtdir,'dir'); mkdir(wrtdir); end

%% get files for this participant

%get list of files to process
filz = dir([eventsdir '*.asc']);

%sample rate of the pupil data
srate = 1000;

%% extracting event information 

for fi = 1:length(filz) % looping through all files to process
    
    %% file checking
    filename    = filz(fi).name; %file to read
    outfilename = [filename(1:end-6) '.mat']; %file to write
   
    %skip files if they're done already
    if exist([wrtdir outfilename],'file'); disp(['skipping file: ' filename]); continue; end
    disp(['workig on file: ' filename])
    
    %% now get event information
    
    %code in this cell will generate the variable 'events' that contains
    %information about stimulus presentation and response information etc.
    %It is of size n x 2, with n being the number of trials. The three
    %columns indicate 1) timing of the event (in seconds) and 2) type of 
    %event (e.g. which button was pressed)
            
    cd(eventsdir);   % changing directory
    events_name = filename;
    
    fid = fopen(events_name);
    event_text = textscan(fid,'%s%s%s%s%s%s%s%s%s%s%s','Headerlines',23,'ReturnOnError',0);
    fclose(fid);
    
    % extracting starting time
    samples = size(event_text{1,1},1);
    firstsample_time = str2num(cell2mat(event_text{1,2}(1)));
    for i = 1:samples
        %this finds the time at which the experimental block started, using
        %an event in the data that signals it
        if strcmp(cell2mat(event_text{1,3}(i)),'Start') == 1 % -> this may need to be modified depending on what you sent as a start recording marker 
            start_time = str2num(cell2mat(event_text{1,2}(i)));
        end
    end
    
    trl = 0;
    events = [];
    for i = 1:samples
        trlmarker = cell2mat(event_text{1,3}(i));
        if isempty(str2num(trlmarker)); continue, end %skip calibration, validation, etc markers
        if strcmp(cell2mat(event_text{1,1}(i)),'MSG') == 1 %if this is a trigger message            
            events(size(events,1)+1,1) = (str2num(cell2mat(event_text{1,2}(i)))-start_time)/1000; %event latency 
            events(size(events,1),2) = str2num(trlmarker); %event type
            trl = trl +1;            
        end
    end  
    
    
    %% extracting pupil data 

    %the code in this cell will generate the variable 'final_pupil', which
    %is a 3 x n matrix where n is samples. The three colums are 1) pupil
    %diameter, 2) gaze x position, and 3) gaze y position.    
    
    cd(pupildir); % changing to pupil data directory
    pupil_name = [filename(1:end-5) 's.asc']; % file with data (sample) information
    
    fid = fopen(pupil_name);
    try
        pupil_text = textscan(fid,'%n%s%s%n%s','Headerlines',0,'ReturnOnError',0);
    catch ME
        pupil_text = textscan(fid,'%n%s%s%n%s%s%s%s%s','Headerlines',0,'ReturnOnError',0);
    end
    fclose(fid);
    
    % isolating pupil data which is before 'start_time'
    prestart_pupil = zeros(size(pupil_text{1,1},1),1);
    full_gaze_x = zeros(size(pupil_text{1,1},1),1);
    full_gaze_y = zeros(size(pupil_text{1,1},1),1);
    for i = 1:length(prestart_pupil)
        if (pupil_text{1,1}(i)) < start_time %see previous cell for finding the start time of the recording
            prestart_pupil(i) = 1;
        end
        if ~strcmp(pupil_text{1,2}(i),'.')
            full_gaze_x(i) = str2num(pupil_text{1,2}{i});
        end
        if ~strcmp(pupil_text{1,3}(i),'.')
            full_gaze_y(i) = str2num(pupil_text{1,3}{i});
        end
    end
    
    cutoff_sample = sum(prestart_pupil);
    
    final_pupil      = ((pupil_text{1,4}(cutoff_sample+1:length(prestart_pupil))))';
    final_pupil(2,:) = full_gaze_x(cutoff_sample+1:length(prestart_pupil))';
    final_pupil(3,:) = full_gaze_y(cutoff_sample+1:length(prestart_pupil))';    

    %% creating EEGLAB dataset and saving to file
    
    clear EEG ALLEEG
    
    % importing data from variables created earlier
    EEG = pop_importdata( 'dataformat', 'array', 'data', 'final_pupil', 'setname', outfilename, 'srate', srate, 'pnts',0, 'xmin',0, 'nbchan',3);
    EEG = eeg_checkset( EEG );
    EEG = pop_importevent( EEG, 'event',events,'fields',{'latency' 'type' },'timeunit',1);
    EEG = eeg_checkset( EEG );
    
    ALLEEG = EEG;
    
    pop_eegplot(EEG);
    save([wrtdir outfilename],'EEG');


end




