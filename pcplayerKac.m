%PCPLAYER Player for visualizing streaming 3-D point cloud data
% player = PCPLAYER(xlimits, ylimits, zlimits) returns a player for
% visualizing 3-D point cloud data streams. The xlimits, ylimits, and
% zlimits inputs specify the X, Y, and Z axis limits of the player. Specify
% the limits as two-element vectors of the form [min max]. Point cloud data
% outside these limits are not displayed. Use this player to visualize 3-D
% point cloud data from devices such as Microsoft Kinect(TM).
%
% player = PCPLAYER(..., 'Name','Value') specifies additional name-value
% pair arguments described below:
%
%   'MarkerSize'       A positive scalar specifying the approximate
%                      diameter of the point marker in points, a unit
%                      defined by MATLAB graphics.
%
%                      Default: 6
%
%   'VerticalAxis'     A string specifying the vertical axis, whose value
%                      is 'X', 'Y' or 'Z'.
%
%                      Default: 'Z'
%
%   'VerticalAxisDir'  A string specifying the direction of the vertical
%                      axis, whose value is 'Up' or 'Down'.
%
%                      Default: 'Up'
%
% PCPLAYER properties:
%  Axes - Handle to the player axes.
%
% PCPLAYER methods:
%  view   - View point cloud data.
%  show   - Turn on the visibility of point cloud player figure.
%  hide   - Turn off the visibility of the point cloud player figure.
%  isOpen - Returns true if the player is visible, otherwise returns false.
%
% Notes
% -----
% 1) Points with NaN or Inf coordinates will not be plotted.
% 2) A 'MarkerSize' greater than 6 points may reduce rendering performance.
% 3) cameratoolbar will be automatically turned on in the player.
%
% Example - View rotating 3-D point cloud
% ---------------------------------------
% ptCloud = pcread('teapot.ply');
%               
% % Define a rotation matrix and 3-D transform
% x = pi/180; 
% R = [ cos(x) sin(x) 0 0
%      -sin(x) cos(x) 0 0
%       0         0   1 0
%       0         0   0 1];
% 
% tform = affine3d(R);
% 
% % Compute proper x-y limits to ensure rotated teapot is not clipped.
% maxLimit = max(abs([ptCloud.XLimits ptCloud.YLimits]));
% 
% xlimits = [-maxLimit maxLimit];
% ylimits = [-maxLimit maxLimit];
% zlimits = ptCloud.ZLimits;
%
% % Create the player
% player = PCPLAYER(xlimits, ylimits, zlimits);
%        
% % Customize player axis labels
% xlabel(player.Axes, 'X (m)');
% ylabel(player.Axes, 'Y (m)');
% zlabel(player.Axes, 'Z (m)');
%
% % Rotate the teapot around the z-axis
% for i = 1:360      
%     ptCloud = pctransform(ptCloud, tform);  
%     view(player, ptCloud);     
% end
%
% See also pcplayer>view, pcshow, pointCloud, plot3, scatter3,
%          cameratoolbar

classdef pcplayerKac < vision.internal.EnforceScalarHandle
    % ---------------------------------------------------------------------    
    properties(GetAccess = public, SetAccess = protected, Transient) 
        % Axes - Handle to the player axes
        Axes
    end
    
    % ---------------------------------------------------------------------
    properties(Hidden, Access = protected)
        MarkerSize  
        VerticalAxis
        VerticalAxisDir                
        XLimits
        YLimits
        ZLimits     
        ptCloudThreshold
    end 
    
    % ---------------------------------------------------------------------
    properties(Hidden, Access = protected, Transient) 
        IsInitialized = false    
        Figure
        Primitive
    end
        
    % ---------------------------------------------------------------------
    methods
        
        function this = pcplayerKac(varargin)
            
            params = pcplayerKac.parseParameters(varargin{:});
                        
            initialize(this, params);            
        end
        
        % -----------------------------------------------------------------
        function view(this, varargin)
            % VIEW(player, ptCloud) displays points with locations and
            % colors stored in the pointCloud object, ptCloud.
            %
            % VIEW(player, xyzPoints) displays points at the locations
            % that are contained in an M-by-3 or M-by-N-by-3 xyzPoints
            % matrix. The matrix, xyzPoints, contains M or M-by-N [x,y,z]
            % points. The color of each point is determined by its Z value,
            % which is linearly mapped to a color in the current colormap.
            %
            % VIEW(player,xyzPoints,C) displays points at the locations
            % that are contained in the M-by-3 or M-by-N-by-3 xyzPoints
            % matrix with colors specified by C. To specify the same color
            % for all points, C must be a color string or a 1-by-3 RGB
            % vector. To specify a different color for each point, C must
            % be one of the following: 
            % - A vector or M-by-N matrix containing values that are 
            %   linearly mapped to a color in the current colormap.            
            % - An M-by-3 or M-by-N-by-3 matrix containing RGB values for
            %   each point.
            %
            % Example - View noisy 3-D point cloud
            % ------------------------------------
            %   ptCloud = pcread('teapot.ply');
            %
            %   xlimits = ptCloud.XLimits;
            %   ylimits = ptCloud.YLimits;
            %   zlimits = ptCloud.ZLimits;
            %
            %   % Create the player
            %   player = pcplayer(xlimits, ylimits, zlimits);
            %
            %   for i = 1:360                        
            %       % add noise to point cloud
            %       xyzPoints = ptCloud.Location + 0.1 * randn(ptCloud.Count,3);            
            %       VIEW(player, xyzPoints);
            %   end
            
            narginchk(2, 3);
            
            [X,Y,Z,C] = pcplayerKac.parseInputs(varargin{:});
                       
            if ~ishandle(this.Axes)                                                       
                % player is in an invalid state. initialize again.                
                cleanupFigure(this);                
                initialize(this);           
            end
            updateViewer(this, X, Y, Z, C);
        end
        
        % -----------------------------------------------------------------
        function tf = isOpen(this)
            % isOpen(player) returns true while the player figure window is
            % open.
            %
            % Example - Terminating a point cloud processing loop.
            % ----------------------------------------------------
            % player = pcplayer([0 1], [0 1], [0 1]);
            %
            % disp('Terminate while-loop by closing pcplayer figure window.')
            %
            % while isOpen(player) 
            %    ptCloud = pointCloud(rand(1000, 3, 'single'));
            %    view(player, ptCloud);           
            % end            
            if ishandle(this.Figure) && strcmpi(this.Figure.Visible,'on')
                tf = true;
            else
                tf = false;
            end
        end
        
        % -----------------------------------------------------------------
        function delete(this)
            cleanupFigure(this);
        end               
        
        % -----------------------------------------------------------------
        function show(this)
            % SHOW(player) makes the player figure window visible.
            makeVisible(this);
        end
        
        % -----------------------------------------------------------------        
        function hide(this)
            % HIDE(player) makes the player figure window invisible.            
            makeInvisible(this);
        end    
        
        % -----------------------------------------------------------------
        function s = saveobj(this)
            s.MarkerSize      = this.MarkerSize;
            s.VerticalAxis    = this.VerticalAxis;
            s.VerticalAxisDir = this.VerticalAxisDir;
            s.XLimits         = this.XLimits;
            s.YLimits         = this.YLimits;
            s.ZLimits         = this.ZLimits;             
            s.IsOpen          = isOpen(this);
        end                
    end
   
    % ---------------------------------------------------------------------
    methods(Hidden, Access = protected)
        
        function initialize(this, varargin)
            if nargin == 2
                if isfield(varargin{1},'Figure')
                    if isa(varargin{1}.Figure,'matlab.ui.Figure')
                        fig = varargin{1}.Figure;
                        this.Figure = fig;
                        axes = varargin{1}.Axes;
                        this.Axes = axes;
                        %createFigure(this)
                    else
                        this.Figure = figure('Visible','off',...
                                 'HandleVisibility','callback',...
                                 'Name','Point Cloud Player');
                        createFigure(this);
                    end
                else
                    this.Figure = figure('Visible','off',...
                                 'HandleVisibility','callback',...
                                 'Name','Point Cloud Player');
                    createFigure(this);
                end
            else
                this.Figure = figure('Visible','off',...
                                 'HandleVisibility','callback',...
                                 'Name','Point Cloud Player');
                createFigure(this);
            end
            if nargin == 2
                setParams(this, varargin{1});
            end
            
            initializeFigure(this);
                       
            this.Figure.Visible = 'on';
        end
        
        % -----------------------------------------------------------------
        function makeInvisible(this, varargin)           
            % proceed if figure exists, else leave it be.
            if ishandle(this.Figure)             
                this.Figure.Visible = 'off';            
                drawnow;
            end            
        end
        
        % -----------------------------------------------------------------
        function makeVisible(this)     
            if ishandle(this.Figure)                                     
                this.Figure.Visible = 'on';
                figure(this.Figure); % bring to front
            else                
                % player is in an invalid state. initialize again.                
                cleanupFigure(this);                
                initialize(this);     
            end
            drawnow;
        end   
        
        % -----------------------------------------------------------------
        function createFigure(this)        
            % Create figure to draw into          
            
            this.Axes   = newplot(this.Figure);    
        end
        
        % -----------------------------------------------------------------
        function initializeFigure(this)
            
            checkRenderer(this);
                        
            % create an nice empty axes
            initializeScatter3(this); 
            
            % Lower and upper limit of auto downsampling.
            this.ptCloudThreshold = [1920*1080, 1e8];
            
            % Initialize point cloud viewer controls.
            vision.internal.pc.initializePCSceneControl(...
                this.Figure, this.Axes, this.VerticalAxis, this.VerticalAxisDir,...
                this.ptCloudThreshold,true);
            
            % set axes limits to manual
            this.Axes.XLimMode = 'manual';
            this.Axes.YLimMode = 'manual';
            this.Axes.ZLimMode = 'manual'; 
            
            % set view angle to auto to ensure a pleasant view point
            % after setting axis limits.
            this.Axes.CameraViewAngleMode = 'auto';
            
            % set limits
            xlim(this.Axes, this.XLimits);
            ylim(this.Axes, this.YLimits);
            zlim(this.Axes, this.ZLimits);                    
            
            drawnow; % to make sure camera position changes take effect
            
            % Decorate axes
            xlabel(this.Axes, 'X');
            ylabel(this.Axes, 'Y');
            zlabel(this.Axes, 'Z');
            
            grid(this.Axes, 'on');
            
            attachCallbacks(this);
            
            makeVisible(this);
            
            % save the current view. This allows cameratoolbar's reset
            % button to restore the original view.
            resetplotview(this.Axes,'SaveCurrentView');
            
            this.IsInitialized = true;
        end                        
        
        % -----------------------------------------------------------------
        function updateViewer(this, X, Y, Z, C)            
            if this.isOpen                                
                checkRenderer(this);                       
                updateScatter3(this, X, Y, Z, C);               
            end
        end
        
        % ------------------------------------------------------------------
        function attachCallbacks(this)
            this.Figure.CloseRequestFcn = @pcplayerKac.makeFigureInvisible;           
        end
               
        % ------------------------------------------------------------------
        function cleanupFigure(this)
            delete(this.Axes);
            delete(this.Figure);
            drawnow;            
        end
        
        % ------------------------------------------------------------------
        function setParams(this, params)
            this.MarkerSize      = double(params.MarkerSize);
            this.VerticalAxis    = params.VerticalAxis;
            this.VerticalAxisDir = params.VerticalAxisDir;
            
            this.XLimits = double(params.XLimits);
            this.YLimits = double(params.YLimits);
            this.ZLimits = double(params.ZLimits);
        end       
        
        % -----------------------------------------------------------------
        function checkRenderer(this)             
            if strcmpi(this.Figure.Renderer, 'painters')
                error(message('vision:pointcloud:badRenderer'));
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % scatter3 based implementation
    % ---------------------------------------------------------------------
    methods(Hidden, Access = protected)
                
        function initializeScatter3(this)
            
            % produce an empty initial axes
            this.Primitive = scatter3(this.Axes, nan, nan, nan, ...
                this.MarkerSize, nan, '.');                        
            
            % Prevent extent checks when limits are not automatically
            % adjusted.
            this.Primitive.XLimInclude = 'off';
            this.Primitive.YLimInclude = 'off';
            this.Primitive.ZLimInclude = 'off';
        end
        
        % -----------------------------------------------------------------
        function updateScatter3(this, X, Y, Z, C)
            
            this.Primitive.XData = X;
            this.Primitive.YData = Y;
            this.Primitive.ZData = Z;
            
            if isempty(C)
                % use Z for false coloring
                this.Primitive.CData = Z;
            else
                this.Primitive.CData = C;
            end
            
            % maximize frame rate while handling mouse events
            drawnow('limitrate'); 
        end                
    end
    
    % ---------------------------------------------------------------------
    methods(Static,Hidden)
        function this = loadobj(s)
            this = pcplayer(s.XLimits, s.YLimits, s.ZLimits, ...
                'MarkerSize', s.MarkerSize, 'VerticalAxis', s.VerticalAxis, ...
                'VerticalAxisDir', s.VerticalAxisDir);
            
            if ~s.IsOpen
                hide(this);
            end                            
        end
        % -----------------------------------------------------------------
        function makeFigureInvisible(varargin)
            % callback attached to figure close request function                        
            set(gcbo,'Visible','off');
            drawnow;
        end
    end
    
    % ---------------------------------------------------------------------
    methods(Hidden, Static, Access = protected)
        
        function [X, Y, Z, C] = parseInputs(varargin)              
            
            if isa(varargin{1}, 'pointCloud')
                narginchk(1,1);
                [X, Y, Z, C] = vision.internal.pc.validateAndParseInputsXYZC(mfilename, varargin{1});
            else
                narginchk(1,2);
                [X, Y, Z, C] = vision.internal.pc.validateAndParseInputsXYZC(mfilename, varargin{:});
            end
            
            if ischar(C)                
                C = vision.internal.pc.colorspec2RGB(C);
            end
          
        end               
        
        % ------------------------------------------------------------------
        function params = parseParameters(varargin)
            
            parser = vision.internal.pc.getSharedParamParser(mfilename);            
            
            parser.addRequired('XLimits', @(x)pcplayerKac.checkLimits('XLimits',x));
            parser.addRequired('YLimits', @(x)pcplayerKac.checkLimits('YLimits',x));
            parser.addRequired('ZLimits', @(x)pcplayerKac.checkLimits('ZLimits',x));
            parser.addParameter('Figure',0);
            parser.addParameter('Axes',0);
            
            parser.parse(varargin{:});
            
            params = parser.Results;
            
        end                
        
        % ------------------------------------------------------------------
        function checkLimits(varname, range)
            validateattributes(range, {'numeric'}, ...
                {'vector', 'numel', 2, 'finite', 'real', 'nonsparse', 'increasing'}, ...
                mfilename, varname);
        end
               
    end
    
end
