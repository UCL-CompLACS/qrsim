classdef AccelerometerGForTesting<AccelerometerG
    %ACCELEROMETERGFORTESTING Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj =  AccelerometerGForTesting(objparams)
           obj = obj@AccelerometerG(objparams);
        end
        
        function s = getSigma(obj)
           s = obj.SIGMA;           
        end
    end
    
end

