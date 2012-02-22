classdef Orbits < handle
    % Class that handles the orbits of the satellite vehicles.
    %
    % Orbits Properties:
    %   INTERVAL                   - time interval of one set of coefficients [seconds](Constant)
    %   POLYORDER                  - number of coefficients in polynoms (Constant)
    %   FITINT                     - interval used to fit the data [seconds](Constant)
    %
    % Orbits methods:
    %   Orbits()                    - constructs the orbit object
    %   parseTime(varargin)         - performs conversions to gpstime from various other
    %                                 date formats
    %   getSatCoord(prn, t)         - computes satellite's coordinates and clock correction
    %   readSP3(sp3FileName)        - reads sp3 file containing precise ephemeris
    %   findEn(vt, t)               - finds index number of epoch t in the vector vt (Static)
    %   findInt(t, tb, interval, b) - finds vector interval that corresponds to the fit
    %                                 interval (Static)
    %   tValidLimits()              - returns begin and end time within which the interpolation
    %                                 of the sp3 is valid
    %
    % Note:
    % This class implement the interpolation algorithm described in
    % M. Horemuz,J.V. Andersson "Polynomial interpolation of GPS satellite coordinates"
    % GPS Solutions, Volume 10, Number 1, February 2006, pages 67-72
    %
    properties (Constant)
        INTERVAL = 2*3600;         % time interval of one set of coefficients [seconds]
        FITINT = 4*3600;           % interval used to fit the data; FitInt >= INTERVAL [seconds]
        POLYORDER = 16;            % number of coefficients in polynoms
    end
    
    properties (Access=private)
        X=[];                      % satellite X coords [m]
        Y=[];                      % satellite Y coords [m]
        Z=[];                      % satellite Z coords [m]
        tBeg = [];                 % time of beginning [seconds]
        tEnd = [];                 % time of end [seconds]
        XCoef = [];                % matrix of coefficients for X coordinate
        YCoef = [];                % matrix of coefficients for Y coordinate
        ZCoef = [];                % matrix of coefficients for Z coordinate
        timeSet = [];              % vector containing time of start of interval [seconds]
        Xmu = zeros(1,1,2);        % mean and std of the points used in the X fitting
        Ymu = zeros(1,1,2);        % mean and std of the points used in the Y fitting
        Zmu = zeros(1,1,2);        % mean and std of the points used in the Z fitting
        iPRN = [];                 % satellite numbers; if iPRN == 0, no data for the satellite
        dtTime = [];               % vector containing time of clock corrections stored in dDts
        dDts = [];                 % vector of satellite clock corrections, clock correction
                                   % for a given epoch is linearly interpolated
        time=0;                    % vector of epochs [seconds]
    end
    
    methods (Sealed,Access=public)
        function obj=Orbits()
            % constructs the orbit object
            %
            % Example:
            %
            %   obj = Orbits();
            %
            obj.XCoef = zeros(1,1,1+obj.POLYORDER);
            obj.YCoef = zeros(1,1,1+obj.POLYORDER);
            obj.ZCoef = zeros(1,1,1+obj.POLYORDER);
        end
        
        function obj = readSP3(obj,sp3FileName)
            % reads in the sp3 file containing the precise ephemeris
            % The SP3 format [1] is currently the only supported.
            % Example:
            %
            %   obj.readSP3(sp3FileName)
            %       sp3FileName - path to the sp3 file
            %
            % [1] http://igscb.jpl.nasa.gov/igscb/data/format/sp3_docu.txt
            %
            i = 1; %counter of epochs for which the satellite coordinates are listed in PE
            
            %read header
            first ='1'; % variable for testing end of  header
            
            fid=fopen(sp3FileName); %open file
            if fid < 1
                error('Could not open sp3 file %s', sFileName);
            end
            
            %read header
            tline = fgetl(fid);
            tline(1:3) = [];  %delete the first 3 characters
            epoch = sscanf(tline,'%f');
            Time0 = obj.parseTime(epoch);
            tline = fgetl(fid); %skip 2 tline
            tline = fgetl(fid);
            tline(1) = [];  %delete + character
            MofSat = sscanf(tline, '%i'); %read number of satellites
            
            while first ~= '*'
                tline = fgetl(fid);
                if length(tline) < 3
                    error('Not a valid sp3 file');
                end
                first = tline(1);
            end
            
            first ='1'; % variable for testing the line with time
            while feof(fid) == 0 && tline(1) ~= 'E';
                tline(1) = [];  %delete * character
                epoch = sscanf(tline,'%f');
                obj.time(i) = obj.parseTime(epoch(1), epoch(2), epoch(3), epoch(4), epoch(5), epoch(6));
                tline = fgetl(fid);
                while first ~= '*'
                    if tline(2) == 'R' %read in only GPS satellites
                        tline = fgetl(fid);
                        first = tline(1);
                        if first == 'E'
                            break;
                        end
                        continue;
                    end
                    tline(1:2) = []; %delete PG
                    prn = sscanf(tline(1:2), '%d'); %satellite number
                    epoch = sscanf(tline,'%f');
                    obj.iPRN(prn,i) = epoch(1);
                    obj.X(prn,i) = epoch(2)*1000;  %convert to [m]
                    obj.Y(prn,i) = epoch(3)*1000;
                    obj.Z(prn,i) = epoch(4)*1000;
                    obj.dDts(prn,i) = epoch(5)/1e6; %convert to [s]
                    tline = fgetl(fid);
                    if tline(1) == 'E'
                        break;
                    end
                    first = tline(1);
                end
                i = i+1;
                first ='1';
            end
            fclose(fid);
        end
        
        function obj = compute(obj)
            % computes polynomial coefficients
            % Goes through the precise ephemeris file and for all satellites available
            % computes the polynomial coefficients of the orbits.
            %
            % Example:
            %
            %   obj.compute();
            %
            % Note: This is genrally called only once after reading in the SP3 file
            %
            ne = length(obj.time);     %number of epochs
            tb = obj.time(1);          %first epoch, for which the coordinates are given
            te = obj.time(ne);         %last epoch
            tm = (obj.FITINT - obj.INTERVAL)/2; %lead-in and lead-out interval
            Nint = floor((te - tb - 2*tm)/obj.INTERVAL); %number of fit intervals
            m = 1;
            for i = 1:Nint
                obj.timeSet(i) = tb + tm + (i-1)*obj.INTERVAL; %time of start of interval
                
                [m, n] = obj.findInt(obj.time, obj.timeSet(i)-tm, obj.FITINT, m); %find vector interval (indexes m,n) that corresponds to the fit interval
                if n < 0     %it was not possible to find data for current interval
                    obj.timeSet(i) = [];
                    break;
                end
                tt = (obj.time(m:n) - obj.timeSet(i));  %reduce time to get better numerical stability
                for j = 1:size(obj.X,1) %loop over satellites
                    if obj.iPRN(j, n) < 1  %no data for satellite j
                        coef = zeros(1,size(obj.XCoef,3));
                        obj.XCoef(j,i,:) =  coef;   %placeholder for satellite
                        obj.YCoef(j,i,:) =  coef;
                        obj.ZCoef(j,i,:) =  coef;
                        continue;
                    end
                    [coef, ~, mu] = polyfit(tt, obj.X(j,m:n), obj.POLYORDER);
                    obj.XCoef(j,i,:) =  coef;
                    obj.Xmu(j,i,:) =  mu';
                    
                    [coef, ~, mu] = polyfit(tt, obj.Y(j,m:n), obj.POLYORDER);
                    obj.Ymu(j,i,:) =  mu';
                    obj.YCoef(j,i,:) =  coef;
                    
                    [coef, ~, mu] = polyfit(tt, obj.Z(j,m:n), obj.POLYORDER);
                    obj.ZCoef(j,i,:) =  coef;
                    obj.Zmu(j,i,:) =  mu';
                end
            end
            %interval, for which the obj. orbit is valid
            obj.tBeg = obj.timeSet(1); %begin
            obj.tEnd = obj.timeSet(end) + obj.INTERVAL;  %end
        end
        
        function pos = getSatCoord(obj, prn, t)
            % computes satellite's coordinates and clock correction for a given epoch
            %
            % Example:
            %   pos = obj.getSatCoord(prn, t)
            %         prn - satellite number
            %         t - epoch
            %         pos - satellite position in ECEF coords [m]
            %
            if (t - obj.tBeg) < 0  || (t - obj.tEnd) > 0
                obj.tBeg
                obj.tEnd
                error('Given epoch is outside of the ephemeris from the sp3 file');
            end
            
            en = obj.findEn(obj.timeSet, t);  %Finds epoch number en
            
            if en < 1
                error('Given epoch is outside of the ephemeris from the sp3 file');
            end
            
            coefX = obj.XCoef(prn, en, :);
            
            if abs(coefX(length(coefX))) < 1e-12
                error('No data for given prn %d',prn);
            end
            coefY = obj.YCoef(prn, en, :);
            coefZ = obj.ZCoef(prn, en, :);
            
            xmu = obj.Xmu(prn, en, :);
            ymu = obj.Ymu(prn, en, :);
            zmu = obj.Zmu(prn, en, :);
            
            tt = t - obj.timeSet(en);
            ret.x = polyval(coefX, tt, [], xmu);
            ret.y = polyval(coefY, tt, [], ymu);
            ret.z = polyval(coefZ, tt, [], zmu);
            
            pos=[ret.x;ret.y;ret.z];
        end
        
        function [b, e] = tValidLimits(obj)
            % return begin and end time within which the interpolation of the sp3 is valid
            %
            % Example:
            %
            %   [b,e] = obj.tValidLimits();
            %           b - time of beginning
            %           e - time of end
            %
            b = obj.tBeg;
            e = obj.tEnd;
        end
    end
    
    methods (Static,Access=private)
        function  en = findEn(vt, t)
            % finds index number of epoch t in the vector vt
            %
            % Example:
            %
            %   en = findEn(vt, t);
            %        vt - vector of epochs
            %        t - given epoch
            %        en - index of vt, where t falls
            %
            en = -1;
            lvt = length(vt);
            if lvt < 1
                return;
            end
            if lvt == 1
                en = 1;
                return;
            end
            
            [val, en]=min(abs(vt-t));
            
            if val<0
                en=-1;
            end
            
        end
        
        function [m, n] = findInt(t, tb, interval, b)
            % find vector interval (indexes m,n) that corresponds to the fit interval
            %
            % Example:
            %
            %   [m,n] = findInt(t, tb, interval, mb);
            %           t - vector of epochs
            %           tb - time of beginning
            %           interval - duration of the interval
            %           b - index of vector t from wich the search starts
            %           m - index of vector t that corresponds to just before the beginning
            %               of the interval
            %           n - index of vector t that corresponds to right after the end of
            %               the interval
            %
            n = -1;
            te = tb + interval;  % time of end of interval
            m = b;
            
            for i = m:length(t)
                if (t(i) - tb) <= 0
                    m = i;
                end
                if (t(i) - te) >= 0
                    n = i;
                    return;
                end
            end
        end
    end
    
    methods (Static,Access=public)
        
        function t = parseTime(varargin)
            % performs conversions to gpstime from various other date format
            %
            % Examples:
            %
            %   t = parseTime(year, month, day, hour, min, sec)
            %       year - conventional Julian calendar year
            %       month - conventional Julian calendar month
            %       day - conventional Julian calendar month
            %       hour - conventional hour
            %       min - conventional min
            %       sec - conventional sec
            %
            %   t = parseTime(gw, ws)
            %       gs - GPS week
            %       ws - seconds of GPS week
            %
            %   t = parseTime(t)
            %       t - gpstime
            %
            na = length(varargin);
            switch na
                case 1
                    [t] = deal(varargin{:});
                case 2  %input in GPS week and wsec
                    [gweek, wsec] = deal(varargin{:});
                    t = wsec + (gweek*7.*86400);
                case 6  %input in georgian datum and time of day
                    [y, mo, d, ho, min, sec] = deal(varargin{:});
                    
                    if mo <= 2
                        y = y - 1;
                        mo = mo + 12;
                    end
                    a = 365.25*y;
                    b = (mo+1)*30.6001;
                    dh = ho + min/60 + sec/3600;  %hours in day
                    jd = floor(a) + floor(b) + d + 1720981.5;  %+ dh/24
                    a = (jd - 2444244.5)/7;
                    
                    gweek = floor(a);
                    tmpwsec = (a - gweek)*7.*86400.;  % seconds of the week - not sufficient precision
                    dweek = round(tmpwsec/86400.);
                    wsec = dweek*86400 + dh*3600;     % seconds of the week -  sufficient precision
                    t = wsec + (gweek*7.*86400);
                otherwise
                    error('parseTime: Incorrect number of arguments');
            end
        end
        
    end
    
end
