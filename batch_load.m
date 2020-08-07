%% Load a batch of files and convert them to a .MAT format
%
% Function expects the source folders, the target extension and
% the action(mode) you are trying to achieve. 
% 
% mode can be 'mat'/'csv'/'pcap'.

function [output] = batch_load(src, md, varargin)   

    srcDir  = src;      % e.g. 'C:\Users\me\src\'
    mode    = md;       % e.g. 'mat'/'csv'/'pcap'
    ext     = {'*.pcap', '*.mat', '*.csv'};
    outDir  = [src,'mat\']; tic
    fileExt = [];
    pcloud  = [];
    output  = [];
    
    %make sure the source folder is valid
    if ~isdir(srcDir)disp('Error: folder does not exist');return;end
    disp('Source folder loaded successfully.');

    % Get a list of all files in the folder with the desired file name pattern.
    % '*.pcap' when converting, '*.mat' when loading existing pcloud
    if strcmp(mode,'pcap') fileExt = fullfile(srcDir, cell2mat(ext(1)));end
    if strcmp(mode,'mat')  fileExt = fullfile(srcDir, cell2mat(ext(2)));end
    if strcmp(mode,'csv')  fileExt = fullfile(srcDir, cell2mat(ext(3)));end
    
    files = dir(fileExt);
    %handles custom loop range; range is all the files by default
    %the first vararg is for the lower limit of the loop
    %while the second vararg is for the loop-end condition
    min = 1; max = length(files);
    if (length(varargin) >= 1) min = cell2mat(varargin(1));end
    if (length(varargin) == 2) max = cell2mat(varargin(2));end
    
    %iterate trough the PCAP files and read into Matlab
    %the columns for csvread depend on the structure of the incoming
    %pointcloud, change indices accordingly
    disp('Looking for recordings...');
    for i = min : max 
      baseFileName = files(i).name;
      fullFileName = fullfile(srcDir, baseFileName);
      disp(fullFileName);
      fprintf(1, 'Loading %s, file %d/%d.\n', baseFileName, i, max);  
      %save output
      if strcmp(mode,'pcap') PCAP2MAT();end
      if strcmp(mode,'mat')  pcloud = [pcloud;load(fullFileName)];end
      if strcmp(mode,'csv')  pcloud = [pcloud;csvread(fullFileName,1,2)];
          if(i==max)pcloud = [pcloud;csvread(fullFileName,1,2)];end
      end
    end
    output = pcloud;
    disp("batch_load complete"); toc
end