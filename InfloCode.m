% Load Snapshot All Channels And Channel Map

load('blueprint.mat');
filename='snapshot_20160402-161433_planetEarth.h5';
h5two = 'impedance_20160402-161721_inbrain.h5';

%Load Colormap
map = linear_bmy_10_95_c71_n256;

% Convert to Microvolts
% 0.195 uV per bit
CONVERT_RAW_TO_UV = 0.195;

% Read Data and Apply Impedance Threshold
D = h5read(filename,'/channel_data');
M = 1024;
N = length(D)/M;
dex = h5read(h5two,'/impedanceMeasurements')<1e6;
data=double(reshape(D,M,N));
sample_index = h5read(filename,'/sample_index');

data(~dex, :)= 0;
datatokeep = data;

% High-Pass Filter
Fstop = 200;
Fpass = 300;
Astop = 65;
Apass = 0.5;
Fs = 3e4;
Hd = designfilt('highpassfir','StopbandFrequency',Fstop, ...
  'PassbandFrequency',Fpass,'StopbandAttenuation',Astop, ...
  'PassbandRipple',Apass,'SampleRate',Fs,'DesignMethod','equiripple');
% fvtool(Hd)

filter_data = zeros(size(datatokeep));
for i=1:1024
    
    % 0 <= raw data <= 2^16
    raw_data = datatokeep(i,:);
    % time in msec
    time = [1:length(raw_data)]/30;

    
    % filter data
    zero_mean = datatokeep(i,:)-mean(datatokeep(i,:));
    filter_data(i,:) = filter(Hd,zero_mean);
end

% Visualization of Filtered Data

figure;
for t=1:length(filter_data(1,:))
        % color map
        cdata=filter_data(:,t);
        cdata=cdata - min(cdata);
        cdata=cdata / max(cdata);
        cdata(~dex, :)= 0.01;
        cdata(cdata<=0.01) = 0.01;       
        sz = length(map);
        bdata = round(cdata.*sz); 
        
        if t==1  
            % probe image
            I = imread('shanksfinal.png');
            image('CData', I, 'XData',[-2 23],'YData', [-10 120])    
            hold on;
            % axes and title
            xlim([-2 23])
            ylim([-10 110])
            set(gca,'XTickLabel',{})
            set(gca,'YTickLabel',{})
            title('Inflorescence Neural Activity')          
        end
        
    for ch=1:1024
        if t==1  
            x = bdata(ch);
            h(ch)= plot(blueprint(ch,1)*5+blueprint(ch,3), blueprint(ch,2),'.','color',[map(x,1) map(x,2) map(x,3)], 'MarkerSize', 20);
            hold on;
            
        else 
            x = bdata(ch);
            set(h(ch),'color',[map(x,1) map(x,2) map(x,3)]);
          
        end

    end
 pause(0.02)
end
