%%Select a Point Cloud Region for Display

% Start by selecting a smaller region around a vehicle and configuring the
% <matlab:doc('pcplayer'); |pcplayer|> to display it.
% To load the pointclouds only change the source directory.

%clear space, set parameters, load/convert pclouds
clc; clear all; tic;   
file_type   =   'mat';
source_dir  =   'path/to/files';
pcloud      =   batch_load(source_dir, file_type);

%% Set the Scene
% To highlight the environment around the vehicle, concentrate on a region
% of interest that spans a user specified area laterally and longitudinally

% Set the region of interest (in meters)
xBound  = 70;  %20% lateral
yBound  = 250; %50% longitudinal
xlimits = [-xBound, xBound];
ylimits = [10, yBound];
zlimits = [-5,20];

%uncomment either axes for different views
axes = [-45,30]; %top down
% axes = [0,10];   %ego-centric

fig=figure('Name','LIDAR Plots','units','normalized',...
           'outerposition',[0 0 1 1],'NumberTitle','off');
p1 = subplot(2,2,[1 4]);
player1 = pcplayerKac(xlimits, ylimits, zlimits,'Figure',fig,'Axes',p1);
player1.Axes.View = axes;

%% Process the Point Cloud Sequence
% Now that we have the point cloud player configured let's process the
% entire point cloud sequence.
for j = 1:length(pcloud)%which part of the clouds to play
    fprintf('Playing file %d/%d\n', j, length(pcloud));
    for k = 1:size(pcloud(j).pc,2)
        pc = pcloud(j).pc{1,k};    
        % Crop the data to ROI.
        indices = find(pc.Location(:, 2) >= -yBound ...
                     & pc.Location(:, 2) <=  yBound ...
                     & pc.Location(:, 1) >= -xBound ...    
                     & pc.Location(:, 1) <=  xBound);
        pc = select(pc, indices);     
        
        % Plot the results.
        view(player1, pc);
        title(player1.Axes, 'Raw Point Cloud');
        pause(0.03);
    end
end
disp('**************************');
disp('Reached end of recording.');
