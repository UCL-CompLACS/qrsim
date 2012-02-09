classdef GyroscopeGForTesting<GyroscopeG
    %ACCELEROMETERGFORTESTING Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj =  GyroscopeGForTesting(objparams)
           obj = obj@GyroscopeG(objparams);
        end
        
        function s = getSigma(obj)
           s = obj.SIGMA;           
        end
    end
    
end

