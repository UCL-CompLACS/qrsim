classdef AHARSPelicanForTesting<AHARSPelican
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Sealed,Access=public)
        function obj = AHARSPelicanForTesting(objparams)
            obj = obj@AHARSPelican(objparams);
        end
        
        function accelerometer = getAccelerometer(obj)
            accelerometer = obj.accelerometer;
        end
        
        function altimeter = getAltimeter(obj)
            altimeter = obj.altimeter;
        end
        
        function gyroscope = getGyroscope(obj)
            gyroscope = obj.gyroscope;
        end
        
        function orientationEstimator = getOrientationEstimator(obj)
            orientationEstimator = obj.orientationEstimator;
        end
    end
    
end

