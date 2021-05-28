function Y = HP_filt(X,Fs,highpass)
%usage: Y = HP_filt(X,Fs,highpass)
%
%   High pass filter data using a FIR filter.
%
%   X is the signal
%   Fs is the sampling rate
%   highpass is the high-pass filter cut-off

%%

nyq = Fs/2;
order = 3*fix(Fs/highpass);

%generate kernel
kernel = fir1(order,highpass/nyq,'high');     

%filter
Y = filtfilt(kernel,1,double(X)')';
% 
% if trimx
%     Y(1:xlength*3) = [];
%     Y(xlength+1:end) = [];
% end
% 
% if flipx
%     Y = Y';
% end

%figure,plot(Y)

end




%%
%% plot time-domain filter kernel
% figure
% plot((1:order+1)/Fs,kernel/(max(kernel)))
% title('Time-domain kernel')
% xlabel('Time (s)')
% ylabel('Amplitude')
% xlim([0 (order+1)/Fs])
% 
% %% plot frequency-domain filter kernel
% T = 1/Fs;
% L = order+1;
% NFFT = 2^nextpow2(L); % Next power of 2 from length of y
% Y = fft(kernel,NFFT)/L;
% f = Fs/2*linspace(0,1,NFFT/2+1);
% freqkernel = 2*abs(Y(1:NFFT/2+1)) / max(2*abs(Y(1:NFFT/2+1)));
% 
% % Plot single-sided amplitude spectrum.
% figure
% plot(f,freqkernel) 
% title('Frequency-domain kernel')
% xlabel('Frequency (Hz)')
% ylabel('|Y(f)|')
% xlim([0 2*lowpass])
% ylim([-0.2 1.2])



%,chebwin(order+1,500));
%kernel = fir1(order,[10 30]/nyq)%,chebwin(order+1,500));