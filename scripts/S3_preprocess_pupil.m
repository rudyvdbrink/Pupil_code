%This script preprocesses pupil data. An iterative algorithm runs through
%the data to find samples at which the difference between two consecutive 
%samples is too large, and it sets those samples to zero. Then, all samples
%that are set at zero are interpolated across linearly.
%
%Note that periods during which the participant blinked or
%the eye-tracker lost track of the pupil for other reasons are already set
%to zero by the EyeLink. 
%
%There is also the option to include deconvolution around blinks as an
%additional cleaning step. This makes a design matrix indicating the start
%and end of blinks, and regresses these events out of the data. It
%increases the computational load for the script quite a bit, and in
%practice might not make a huge difference in data quality, but doesn't
%hurt to include. This step relies on the image processing toolbox, so in
%case you don't have that, just set the option for deconvolution to zero. 
%
%If requested, the script opens up a plot of the diameter data and of
%the gaze x and y data corresponding to those blocks. The raw
%(before interpolation) data is plotted in red, the clean data is overlayed 
%in blue. If deconvolution is set to be included, it also plots the data
%post-deconvolution in black.

clear 
close all
clc

%% get files 

homedir = 'C:\DATA\Pupil_code\';

rawdir = [homedir 'data\converted\']; %this is where the raw data (EEGLAB format) gets read from
wrtdir = [homedir 'data\processed\']; %this is where the processed data are stored
if ~exist(wrtdir,'dir'); mkdir(wrtdir); end

cd(rawdir)
filz = dir('*.mat');

%% plot settings

%if this is set to 1, it'll open up a figure for each file that is
%processed, that shows the performance of the interpolation algorithm
makefig = 1;

%% define interpolation settings
ninterps = 100; %the number of iterations for the interpolation algorithm
delta = 25;  %the slope (in pixels) that we consider to be artifactually large  
%both the above variables would need to be changed if the sample rate is
%not 1000 Hz, or if the units of the pupil aren't in pixels. Also, it's
%best to tailor this for each participant so that all artifacts are
%accuratlely identified. 

%% analysis settings

%this determines if you want to additionally de-convolve the pupil data
%around the start and end of blinks to remove time-locked information
dc  = 1; %if set to 0, deconvolution is skipped
ndc = 1000; %number of samples around the start / end of blinks to remove with deconvolution

%% loop over participants
for fi = 1:length(filz)
    
    cd(rawdir);
    %define file name under which the processed data are stored
    outfilename = [filz(fi).name(1:end-4) '.mat'];
    
    %check of the output file already esists
    if exist([wrtdir outfilename],'file'); disp(['skipping file: ' filz(fi).name]); continue; end
    disp(['working on file: '  filz(fi).name])
    
    load(filz(fi).name); %load the data
 
    %plot the unprocessed data (if requested)
    if makefig
        figure        
        for ci = 1:3
            subplot(3,1,ci)
            hold on
            plot( EEG.data(ci,:),'r')
            
            if ci == 1
                title([outfilename ': diameter'])
                ylabel('Diameter (pixels)')
            elseif ci == 2
                 title([outfilename ': x gaze'])
                ylabel('Gaze x-position (pixels)')
            else
                 title([outfilename ': y gaze'])
                ylabel('Gaze y-position (pixels)')
                
            end
            xlim([1 length(EEG.data(ci,:))]);
            set(gca,'tickdir','out')
            box off
        end
    end
    
    %% find sections of bad data
    
    %first,find bad data sections by slope and set them to zero. make
    %multiple passes through the data to find peaks that occur over
    %multiple time-points. note that 'ninterps' assumes a sampling rate
    %of 1000Hz, modify if the sampling rate differs (e.g. at 60 Hz, the
    %equivalent would be 6 iterations).
    y = EEG.data(1,:)'; %pupil diameter
    
    for passi = 1:ninterps
        
        %find points with an artifactual derivative
        for pointi = 1:length(y)-1
            if diff([y(pointi) y(pointi+1)]) > delta
                y(pointi) = 0;
            end
        end
        
        %then also set the subsequent and preceding points to zero to get rid
        %of peaky data
        points = find(y == 0);        
        if isempty(points); points = min(y); y(points) = 0; end
        
        %remove the first and last point of the 'bad section' variable in
        %case it's bad data
        if points(end) == length(y); points(end) = []; end
        if points(1) == 1; points(1) = []; end        
        y(points+1) = 0;
        y(points-1) = 0;
        
        %set any single point flanked by bad data to zero
        for pointi = 2:length(y)-1
            if y(pointi-1) == 0 &&  y(pointi+1) == 0
                y(pointi) = 0;
            end
        end
    end      
    
    %in case the very end of the recording is bad data, we cannot
    %interpolate across it, so we manually set it to the mean of the
    %recording
    points = find(y == 0);    
    if y(end) == 0
        for ci = 1:3
            EEG.data(ci,end-ninterps:end) = nanmean(nonzeros(EEG.data(ci,:)));
        end
        y(end) = nanmean(nonzeros(y));
        points(end) = [];
    end    
     
    %% interpolate sections of bad data
    
    %now interpolate bad sections
    temp = y; temp(points) = [];
    interpfirstsample = 0;       
    if points(1) == 1
        temp = [zeros(ninterps,1)+mean(temp); temp];
        points(1:ninterps) = [];        
        interpfirstsample = 1;
    end    
    x = 1:length(y);
    x(points) = [];
    yi = interp1(x,temp,points,'linear'); %this performs the interpolation
    y(points) = yi;
    
    %if the first data point needs to be interpolated, we replace it with
    %the mean of the rest of the data, and then interpolate across
    if interpfirstsample == 1
        y(1:ninterps) = mean(y(ninterps:end));
    end    
    y = double(y);
    baddata = zeros(1,length(y));
    baddata(points) = 1;
    EEG.data(1,:) = y';   

    %% now do the same (interpolation) for gaze position
    
    %gaze x
    y = EEG.data(2,:)';
    if interpfirstsample == 1
        y(1:ninterps) = nanmean(y(ninterps:end));
    end  
    y(logical(baddata)) = 0;
    points = find(y == 0);    
    temp = y; temp(points) = [];
    x = 1:length(y);
    x(points) = [];
    yi = interp1(x,temp,points,'linear');
    y(points) = yi;       
    EEG.data(2,:) = y';        
    
    %gaze y
    y = EEG.data(3,:)';  
    if interpfirstsample == 1
        y(1:ninterps) = nanmean(y(ninterps:end));
    end  
    y(logical(baddata)) = 0;
    points = find(y == 0);
    temp = y; temp(points) = [];
    x = 1:length(y);
    x(points) = [];
    yi = interp1(x,temp,points,'linear');
    y(points) = yi;
    EEG.data(3,:) = y';    
    
    %plot the interpolated data (if requested)
    if makefig
        for ci = 1:3
            subplot(3,1,ci)
            hold on
            plot(EEG.data(ci,:));
        end
        
        if dc == 0
            legend('raw','interpolated')
        end
    end
    
    %% run deconvolution (if requested)    
      
    if dc        
        startpoints = zeros(size(baddata));
        endpoints   = zeros(size(baddata));
        
        %find all individual sections of interpolated data
        badsecs = bwlabeln(baddata);
        
        %loop over sections, and find the start and end points
        for si = 1:max(badsecs)
            sidx = find(badsecs==si,1,'first')-(ndc-1); %index of the start of a bad section, minus the number of points to remove
            eidx = find(badsecs==si,1,'last');      %index of the end of a bad section
            
            %if the start and end points fall within the recording, enter a
            %one in the design matrix
            if sidx > 0
                startpoints(sidx) = 1;
            end
            
            if eidx <= length(baddata)
                endpoints(eidx) = 1;
            end
        end
        
        %make full design matrix 
        XX = [];
        for ci = 1:2
            if ci == 1
                s = startpoints; %stick function
            else
                s = endpoints;
            end
            m = length(s); %length of event sequence
            n = ndc; %length of data section to deconvolve            
            X = zeros(m,n); %the design matrix
            temp = s';
            for i=1:n
                X(:,i) = temp;
                temp = [0; temp(1:end-1)];
            end            
            XX = cat(2,XX,X); %this is the design matrix            
        end
        
        %remove events from data using deconvolution
        PX = pinv(XX); %pseudo inverse of the design matrix
        for di = 1:size(EEG.data,1)
            y = detrend(EEG.data(di,:)); %pupil data -> remove linear trend
            y = y-mean(y); %mean center
            es = PX'*(XX'*y'); %calcluate the variance explained by sections of bad data      
            EEG.data(di,:) = EEG.data(di,:) - es'; %data minus the variance due to bad data
        end
        
        %re-interpolate bad sections (after deconvolution, to prevent jumps in the data)
        for ci = 1:3
            y = EEG.data(ci,:)';
            y(logical(baddata)) = 0;
            points = find(y == 0);
            temp = y; temp(points) = [];
            x = 1:length(y);
            x(points) = [];
            yi = interp1(x,temp,points,'linear');
            y(points) = yi;
            EEG.data(ci,:) = y';
            y = double(y);
        end        
        
        % plot the cleaned data (if requested)        
        if makefig
            for ci = 1:3
                subplot(3,1,ci)
                hold on
                plot(EEG.data(ci,:),'k');
            end
            
            legend('raw','interpolated','deconvolved')
        end        
        
    end %end deconvolution conditional
    
    %% save data

    disp('saving data')
    cd(wrtdir)
    save(outfilename,'EEG','baddata')
    disp('done')
    
end %end subject loop


    
    
    
    