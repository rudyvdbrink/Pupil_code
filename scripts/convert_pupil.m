% Script for extracting pupil and event data from -ascii eye-tracker files
% from the Random Dot Motion Task and creating .set files from these data

% ONLY ONE PARTICIPANT'S DATA AT A TIME

% IMPORTANT: this script requires three things:
%     (1) -ascii files containing event information, raw pupil data, and
%         pupil scaling information must be put into DIFFERENT FOLDERS,
%         all located under the same directory;
%     (2) -ascii files containing the event information should be loaded
%         first
%     (3) a separate folder named 'Converted' should be created under the
%         same directory -- the script output will be saved here

clear all
close all
clc
%%
driveLetter = cd;
driveLetter = driveLetter(1:7);

%start up EEGLAB
addpath(genpath('eeglab folder'))
eeglab

%% get files for this participant

%this will will open a file selection window, in which you select event
%information for one participant (so all event files that are supplied 
%with this example code)
[filename, pathname, filterindex] = uigetfile('*.asc','MultiSelect', 'on');
filename=cellstr(filename);
pathname=cellstr(pathname);

Id = [];
for name = 1:size((filename),2)
    filenamechar = char(filename{1,name});
    Id{1,name} =  filenamechar(:,1:size(filenamechar,2)-4); % isolating participant ID/name + block number
end

pathnamechar = char(pathname);

eventsdir = pathname{1,1};
pupildir = [eventsdir(1:length(eventsdir)-7),'\samples'];
writdir = [eventsdir(1:length(eventsdir)-7),'converted\'];

%sample rate of the pupil data
srate = 1000;

%% extracting event information 

for blocki = 1:size(filename,2);  % looping through all blocks for the participant
    
    %% file checking
    
    if blocki == 1;
        subno = str2num(filename{blocki}(3));        
        %define file name under which the final imported data are stored
        outfilename = ['PD_' num2str(subno) '_imported.mat'];
        
    end   
    
    %skip files if they're done already
    if exist([writdir outfilename],'file'); disp(['skipping file: ' filename{blocki}]); continue; end
    disp(['workig on file: ' filename{blocki}])
    
    %% now get event information
    
    %code in this cell will generate the variable 'events' that contains
    %information about stimulus presentation and response information etc.
    %It is of size n x 3, with n being the number of trials. The three
    %columns indicate 1) timing of the event (in seconds) 2) type of event 
    %(e.g. which button was pressed), and 3) if the event is a stimulus or
    %response.
    
    %in case you do not use .edf files, then you can generate such a matrix
    %manually with your own custom code    
    
    events = [];
    
    cd(eventsdir);   % changing directory
    events_name = filename{blocki};
    
    fid = fopen(events_name);
    event_text = textscan(fid,'%s%s%s%s%s%s%s%s%s%s%s','Headerlines',23,'ReturnOnError',0);
    fclose(fid);
    
    % extracting starting time
    samples = size(event_text{1,1},1);
    firstsample_time = str2num(cell2mat(event_text{1,2}(1)));
    for i = 1:samples;
        %this finds the time at which the experimental block started, using
        %an event in the data that signals it
        if strcmp(cell2mat(event_text{1,3}(i)),['BLOCK_' num2str(blocki)]) == 1;
            start_time = str2num(cell2mat(event_text{1,2}(i)));
        end
    end
    
    trl = 0;
    events = [];
    
    for i = 1:samples;
        trlmarker = cell2mat(event_text{1,3}(i));
        if strcmp(trlmarker,'!CAL'), continue, end;
        if strcmp(cell2mat(event_text{1,1}(i)),'MSG') == 1 && strcmp(trlmarker(1:4),'STIM') == 1 % && ~strcmp(trlmarker(end-4:end-2),'ACC');
            
            events(size(events,1)+1,1) = (str2num(cell2mat(event_text{1,2}(i)))-start_time)/1000;
            
            trl = trl +1;
            
            events(size(events,1),2) = str2num(trlmarker(10)); %the stimulus type
            events(size(events,1),3) = 1; %this is a stimulus marker
            
        elseif strcmp(cell2mat(event_text{1,1}(i)),'MSG') == 1 && strcmp(trlmarker(1:4),'RESP') == 1;
            events(size(events,1)+1,1) = (str2num(cell2mat(event_text{1,2}(i)))-start_time)/1000;
            
            events(size(events,1),2) = str2num(trlmarker(10:11)); %response type (32 is space bar)
            events(size(events,1),3) = 2; %this is a response marker
            
        end
    end  
    
    

    %% extracting pupil data 

    %the code in this cell will generate the variable 'final_pupil', which
    %is a 3 x n matrix where n is samples. The three colums are 1) pupil
    %diameter, 2) gaze x position, and 3) gaze y position.
    
    %again, if you don't work with .edf files, its best to format you data
    %with custom code
    
    cd(pupildir); % changing to pupil data directory
    pupil_name = filename{1,blocki}; % pupil_name here is the same as events_name earlier, though they refer to different files in diferent directories
    
    fid = fopen(pupil_name);
    try
        pupil_text = textscan(fid,'%n%s%s%n%s','Headerlines',0,'ReturnOnError',0);
    catch ME;
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
    
    final_pupil = ((pupil_text{1,4}(cutoff_sample+1:length(prestart_pupil))))';
    final_pupil(2,:) = full_gaze_x(cutoff_sample+1:length(prestart_pupil))';
    final_pupil(3,:) = full_gaze_y(cutoff_sample+1:length(prestart_pupil))';
    

    %% creating .set (EEGLAB) dataset 

    
    clear EEG
    
    % importing data from variables created earlier
    EEG = pop_importdata( 'dataformat', 'array', 'data', 'final_pupil', 'setname', ['block' num2str(blocki)], 'srate', srate, 'pnts',0, 'xmin',0, 'nbchan',3);
    %[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'gui', 'off');
    EEG = eeg_checkset( EEG );
    EEG = pop_importevent( EEG, 'event','events','fields',{'latency' 'type' 'RT'},'timeunit',1);[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    
    ALLEEG(blocki) = EEG;
    

end

EEG = ALLEEG(1);
%eeglab redraw
close all

cd(writdir);

save(outfilename,'ALLEEG','EEG');



