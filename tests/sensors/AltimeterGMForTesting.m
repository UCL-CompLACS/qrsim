classdef AltimeterGMForTesting<AltimeterGM
    %ACCELEROMETERGFORTESTING Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj =  AltimeterGMForTesting(objparams)
           obj = obj@AltimeterGM(objparams);
        end
        
        function s = getSigma(obj)
           s = obj.SIGMA;           
        end
                        
        function b = getTau(obj)
           b = obj.TAU;           
        end
    end
    
end

