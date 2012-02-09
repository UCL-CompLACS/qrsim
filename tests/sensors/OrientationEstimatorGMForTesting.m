classdef OrientationEstimatorGMForTesting<OrientationEstimatorGM
    %ACCELEROMETERGFORTESTING Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj =  OrientationEstimatorGMForTesting(objparams)
           obj = obj@OrientationEstimatorGM(objparams);
        end
        
        function s = getSigma(obj)
           s = obj.SIGMA;           
        end
        
                
        function b = getBeta(obj)
           b = obj.BETA;           
        end
    end
    
end

