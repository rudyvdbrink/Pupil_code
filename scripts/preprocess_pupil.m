%This script preprocesses pupil data. An iterative algorithm runs through
%the data to find samples at which the difference between two consecutive 
%samples is too large, and it sets those samples to zero. Then, all samples
%that are set at zero are interpolated across with piece-wise cubic
%interpolation. Note that periods during which the participant blinked or
%the eye-tracker lost track of the pupil for other reasons are already set
%to zero by the EyeLink. 
%
%This script does not run all the way through, but instead it crashes just
%before saving the data. This is to ensure that you look at the
%interpolation algorithm's performance. In cases where the first or last
%samples of a recording are artifactual the interpolation will sometimes 
%introduce a large spike at the start / end of the recording. In that case,
%manually set the first (or last) sample to the mean of the recording and
%it'll interpolate properly.
%
%Note also that you could use linear interpolation instead of cubic
%interpolation. It won't interpolate smooth curves but it's what people
%conventionally do. 
%
%The script opens up a plot of the data of the three blocks (left) and of
%the gaze x and y data corresponding to those blocks (right). The raw
%(before interpolation) data is plotted in red, the clean data is overlayed in
%blue. If the performance of the interpolation algorithm is fine (and it
%should be for this example), run the last cell in the script and it'll save 
%the data.
%
%Please cite van den Brink, Murphy, & Nieuwenhuis (2016) Pupil diameter
%tracks lapses of attention. PLoS ONE 11(10): e0165274 when using this code
%for a publication

%%
clear all
close all
clc
%%
driveLetter = cd;
driveLetter = driveLetter(1:7);

%% get files 

rootdir = cd;

rawdir = [rootdir '\data\raw\converted\']; %this is where the raw data (EEGLAB format) gets read from
wrtdir = [rootdir '\data\processed\']; %this is where the processed data are stored

cd(rawdir)
sublist = dir('*_imported.mat');
sublist = {sublist.name};

%% define interpolation settings
ninterps = 200; %the number of iterations for the interpolation algorithm
delta = 25;  %the slope (in pixels) that we consider to be artifactually large  
%both the above variables would need to be changed if the sample rate is
%not 1000 Hz, or if the units of the pupil aren't in pixels. Also, it's
%best to tailor this for each participant so that all artifacts are
%accuratlely identified. 


%just for plotting
ploti = [2 6 10];
plotj = [1 3 5];

%% loop over participants
for subi = 1:length(sublist);  
          
    cd(rawdir);
    %define file name under which the processed data are stored
    outfilename = [sublist{subi}(1:end-12) 'processed.mat'];

    if exist([wrtdir outfilename],'file'); disp(['skipping file: ' sublist{subi}]); continue; end
    disp(['working on file: '  sublist{subi}])
    
    load(sublist{subi});
       
    figure
    title(outfilename)
    %% loop over blocks and interpolate sections of bad data
    for blocki = 1:length(ALLEEG)
        EEG = ALLEEG(blocki);
        disp(['block ' num2str(blocki)])
        y = EEG.data(1,:)';        
        subplot(3,2,plotj(blocki))
        plot(y,'r')
        
        %% interpolate bad sections           
       
        %first,find bad data sections by slope and set them to zero. make
        %multiple passes through the data to find peaks that occur over
        %multiple time-points. note that 'ninterps' assumes a sampling rate
        %of 1000Hz, modify if the sampling rate differs (e.g. at 60 Hz, the
        %equivalent would be ~17 iterations).
        for passi = 1:ninterps
            
            for pointi = 1:length(y)-1
                if diff([y(pointi) y(pointi+1)]) > delta
                    y(pointi) = 0;
                end
            end
            
            %then also set the subsequent and preceding points to zero to get rid
            %of peaky data
            points = find(y == 0);
            
            if isempty(points); [points ~] = min(y); y(points) = 0; end
            
            %remove the first and last point of the 'bad section' variable in
            %case it's bad data
            if points(end) == length(y); points(end) = []; end;
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
        
                
        points = find(y == 0);
        
        %now interpolate bad sections
        temp = y; temp(points) = [];
        interpfirstsample = 0;
        nfactor = 1;

        
        if points(1) == 1;
            temp = [zeros(ninterps*nfactor,1)+mean(temp); temp]; 
            points(1:ninterps*nfactor) = [];
            
            interpfistsample = 1;
        end
        
        x = 1:length(y);
        x(points) = [];
        yi = interp1(x,temp,points,'pchip');
        y(points) = yi;
        
        if interpfirstsample == 1;
            y(1:ninterps*nfactor) = mean(y(ninterps*nfactor:end));
        end
        
        y = double(y);        
        baddata = zeros(1,length(y));
        baddata(points) = 1;        
        allbaddata{blocki,:} = baddata;    
         EEG.data(1,:) = y';
        
        hold on
        plot(y,'b')
        
        %% now do the same for the eye movements
        subplot(6,2,ploti(blocki))
        y = EEG.data(2,:)';
        plot(y,'r')
        
        y(logical(baddata)) = 0;
        points = find(y == 0);
        
        temp = y; temp(points) = [];
        x = 1:length(y);
        x(points) = [];
        yi = interp1(x,temp,points,'pchip');
        y(points) = yi;
        
        EEG.data(2,:) = y';
        
        y = double(y);
        hold on
        plot(y);
        
        
        
        subplot(6,2,ploti(blocki)+2)
        y = EEG.data(3,:)';
        plot(y,'r')
        
        y(logical(baddata)) = 0;
        points = find(y == 0);
        
       
        temp = y; temp(points) = [];
        x = 1:length(y);
        x(points) = [];
        yi = interp1(x,temp,points,'pchip');
        y(points) = yi;
        EEG.data(3,:) = y';
        
        y = double(y);
        hold on
        plot(y);

        ALLEEG(blocki) = EEG;
        
    end %end block loop

    %% stop script
    error('check interpolation performance')
    
    
    %% save data
    clc
    disp('saving data')
    cd(wrtdir)
    save(outfilename,'ALLEEG','allbaddata')
    disp('done')

end %end subject loop


    
    
    
    