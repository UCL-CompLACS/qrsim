classdef Person
    %PERSON Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        center;
        bb; % bounding box defined columnwise in, tl,tr,bl,br
    end
    
    methods
        function obj = Person(center,psize)
           obj.center = center;
           obj.bb = repmat(center,1,4)+0.5*[ psize psize -psize -psize;
                                            -psize psize -psize  psize;
                                                 0     0      0      0];            
        end    
    end
    
end

