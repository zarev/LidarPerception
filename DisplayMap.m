load('C:\Users\mzarev\Desktop\firstMap.mat');
figure
hAxes = pcshow(ptCloudScene, 'VerticalAxis','Y', 'VerticalAxisDir', 'Down');
title('Updated world scene')
% Set the axes property for faster rendering
hAxes.CameraViewAngleMode = 'auto';
hScatter = hAxes.Children;

% Visualize the world scene.
hScatter.XData = ptCloudScene.Location(:,1);
hScatter.YData = ptCloudScene.Location(:,2);
hScatter.ZData = ptCloudScene.Location(:,3);
%     hScatter.CData = ptCloudScene.Color;
hScatter.CData = zeros(size(ptCloudScene.Location(:,1)));
drawnow('limitrate')

pcshow(ptCloudScene, 'VerticalAxis','Y', 'VerticalAxisDir', 'Down', ...
        'Parent', hAxes)
title('Updated world scene')
xlabel('X (m)')
ylabel('Y (m)')
zlabel('Z (m)')