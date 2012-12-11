classdef CameraObservation
    % simple class to gather all the data returned by thecamera
    %
    % patches on the ground visible by the camera and the associated log likelihood
    % differences (reconducible to likelihood ratios) computed by the classifier.
    %
    % Note:
    % the corner points of the ground patches are layed out in a regular
    % gridDims(1) x gridDims(2) grid pattern, we return them stored in a
    % 3*N matrix obtained scanning the grid left to right and top to bottom.
    % this means that the 4 cornes of window i,j
    % are wg(:,(i-1)*(gridDims(1)+1)+j+[0,1,gridDims(1)+1,gridDims(1)+2])
    
    properties (Access=public)
        llkd;       % log-likelihood difference for each gound patch
        wg;         % list of corner points for the ground patches
        gridDims;   % dimensions of the grid of measurements
    end
    
    methods
        function obj = CameraObservation()
            % constructor
            obj.llkd = [];
            obj.wg = [];
            obj.gridDims = [0,0];
        end
    end   
end

