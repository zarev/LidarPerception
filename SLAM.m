%% 3-D Point Cloud Registration and Stitching
% This example shows how to combine multiple point clouds to reconstruct a
% 3-D scene using Iterative Closest Point (ICP) algorithm.

% Copyright 2014 The MathWorks, Inc.

%% Overview
% This example stitches together a collection of point clouds that was
% captured with Kinect to construct a larger 3-D view of the scene. The
% example applies ICP to two successive point clouds. This type of
% reconstruction can be used to develop 3-D models of objects or build 3-D
% world maps for simultaneous localization and mapping (SLAM).

%% Register Two Point Clouds
% pcloud = load('\banbury00012');

% Extract two consecutive point clouds and use the first point cloud as
% reference
xBound  = 30; %40;  % lateral, in meters
yBound  = 50; %300; % longitudinal, in meters
yOffset = -5; %in meters to deal with laser source noise
loopRng = [200, 250];
% Crop the data to ROI.

indices = find(pcloud(1).pc{1,loopRng(1)}.Location(:, 2) >=  yOffset ...
             & pcloud(1).pc{1,loopRng(1)}.Location(:, 2) <=  yBound ...
             & pcloud(1).pc{1,loopRng(1)}.Location(:, 1) >= -xBound ...    
             & pcloud(1).pc{1,loopRng(1)}.Location(:, 1) <=  xBound);
ptcRef = select(pcloud(1).pc{1,loopRng(1)}, indices);
% Crop the data to ROI.
indices = find(pcloud(1).pc{1,loopRng(1)+1}.Location(:, 2) >= yOffset ...
             & pcloud(1).pc{1,loopRng(1)+1}.Location(:, 2) <=  yBound ...
             & pcloud(1).pc{1,loopRng(1)+1}.Location(:, 1) >= -xBound ...    
             & pcloud(1).pc{1,loopRng(1)+1}.Location(:, 1) <=  xBound);
ptcCurr = select(pcloud(1).pc{1,loopRng(1)+1}, indices);

maxDistance = 0.295; % in meters
referenceVector = [0, 0, 1];
[~, inPlanePointIndices, outliers] = pcfitplane(ptcRef, maxDistance, referenceVector);
ptcRef = select(ptcRef, outliers);
[~, inPlanePointIndices, outliers] = pcfitplane(ptcCurr, maxDistance, referenceVector);
ptcCurr = select(ptcCurr, outliers);

%%
% The quality of registration depends on data noise and initial settings of
% the ICP algorithm. You can apply preprocessing steps to filter the noise
% or set initial property values appropriate for your data. Here,
% preprocess the data by downsampling with a box grid filter and set the
% size of grid filter to be 10cm. The grid filter divides the point cloud
% space into cubes. Points within each cube are combined into a single
% output point by averaging their X,Y,Z coordinates.

%%
gridSize = 0.2;
fixed = pcdownsample(ptcRef, 'gridAverage', gridSize);
moving = pcdownsample(ptcCurr, 'gridAverage', gridSize);

% Note that the downsampling step does not only speed up the registration,
% but can also improve the accuracy.

%% 
% To align the two point clouds, we use the ICP algorithm to estimate the
% 3-D rigid transformation on the downsampled data. We use the first point
% cloud as the reference and then apply the estimated transformation to the
% original second point cloud. We need to merge the scene point cloud with
% the aligned point cloud to process the overlapped points.

%%
% Begin by finding the rigid transformation for aligning the second point
% cloud with the first point cloud. Use it to transform the second point
% cloud to the reference coordinate system defined by the first point
% cloud.

%%
tform = pcregrigid(moving, fixed, 'Metric','pointToPlane','Extrapolate', true);
ptCloudAligned = pctransform(ptcCurr,tform);

%%
% We can now create the world scene with the registered data. The
% overlapped region is filtered using a 1.5cm box grid filter. Increase the
% merge size to reduce the storage requirement of the resulting scene point
% cloud, and decrease the merge size to increase the scene resolution.

%%
mergeSize = 0.015;
ptCloudScene = pcmerge(ptcRef, ptCloudAligned, mergeSize);

%% Stitch a Sequence of Point Clouds
% To compose a larger 3-D scene, repeat the same procedure as above to
% process a sequence of point clouds. Use the first point cloud to
% establish the reference coordinate system. Transform each point cloud to
% the reference coordinate system. This transformation is a multiplication
% of pairwise transformations.

% Store the transformation object that accumulates the transformation.
accumTform = tform; 

figure
hAxes = pcshow(ptCloudScene, 'VerticalAxis','Y', 'VerticalAxisDir', 'Down');
title('Lidar Map')
% Set the axes property for faster rendering
hAxes.CameraViewAngleMode = 'auto';
hScatter = hAxes.Children;
tic
for i = loopRng(1):loopRng(2)-1%length(pcloud.pc)
    
    ptcCurr = pcloud(1).pc{1,i};

    % Crop the data to ROI.
    indices = find(ptcCurr.Location(:, 2) >= yOffset ...
                 & ptcCurr.Location(:, 2) <=  yBound ...
                 & ptcCurr.Location(:, 1) >= yOffset ...    
                 & ptcCurr.Location(:, 1) <=  xBound);
    ptcCurr = select(ptcCurr, indices);

    [~, inPlanePointIndices, outliers] = pcfitplane(ptcCurr, maxDistance, referenceVector);
    ptcCurr = select(ptcCurr, outliers);
    % Use previous moving point cloud as reference.
    fixed = moving;
    moving = pcdownsample(ptcCurr, 'random', 0.2);
    
    % Apply ICP registration.
    tform = pcregrigid(moving, fixed, 'Metric','pointToPlane','Extrapolate', true);

    % Transform the current point cloud to the reference coordinate system
    % defined by the first point cloud.
    accumTform = affine3d(tform.T * accumTform.T);
    ptCloudAligned = pctransform(ptcCurr, accumTform);
    
    % Update the world scene.
    ptCloudScene = pcmerge(ptCloudScene, ptCloudAligned, mergeSize);
    gridSize = 0.2;
    ptCloudScene = pcdownsample(ptCloudScene, 'gridAverage', gridSize);
    
%     indices = find(ptCloudScene.Location(:, 2) >= -yBound ...
%                  & ptCloudScene.Location(:, 2) <=  yBound ...
%                  & ptCloudScene.Location(:, 1) >= -xBound ...    
%                  & ptCloudScene.Location(:, 1) <=  xBound);
%     ptCloudScene = select(ptCloudScene, indices);

    hScatter.XData = ptCloudScene.Location(:,1);
    hScatter.YData = ptCloudScene.Location(:,2);
    hScatter.ZData = ptCloudScene.Location(:,3);
    hScatter.CData = ptCloudScene.Color;
    hScatter.CData = zeros(size(ptCloudScene.Location(:,1)));
    drawnow('limitrate')
    
    disp(i);
end
toc;
% pcshow(ptCloudScene, 'VerticalAxis','Y', 'VerticalAxisDir', 'Down', ...
%         'Parent', hAxes)
pcshow(ptCloudScene, 'VerticalAxis','Y', 'VerticalAxisDir', 'Up', ...
        'Parent', hAxes)
title('Lidar Map')
xlabel('X (m)')
ylabel('Y (m)')
zlabel('Z (m)')
