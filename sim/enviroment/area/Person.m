classdef Person<handle
    %Container class for person's attributes
    
    properties
        center;   % [x;y;z;] coordinates of the person center
        bb;       % bounding box defined columnwise in, tl,tr,bl,br
    end
    
    methods (Access = public)
        function obj = Person(center,psize)
            % constructor
            obj.center = center;
            obj.bb = repmat(center,1,4)+0.5*[ psize psize -psize -psize;
                -psize psize -psize  psize;
                0     0      0      0];
        end
        
        function obj = setCenter(obj,center)
            % updates the cneter without changing the bounding box
            obj.bb = obj.bb - repmat(obj.center,1,4);
            obj.center = center;
            obj.bb = repmat(center,1,4)+obj.bb;
        end
    end
    
end

