classdef mcPID < handle
% Simple PID of the form: y = mcPID.compute(x), where y is the output and x is the feedback var
    
    properties
        Kp = .05;
        Ki = .0005;
        Kd = 0;
        
        ePrev = NaN;
        int = 0;
        
        xt = 0;
        y = 0;
        
        yInfo = [];
        yIsAxis = false;
    end
    
    methods
        function pid = mcPID(varin)
            if nargin == 1
                firstvar = varin;
            else
                firstvar = varin{1};
            end
            
            if isa(firstvar, 'mcAxis')
                pid.yInfo = firstvar;
                pid.yIsAxis = true;
                
                if nargin > 1
                    pid.xt = varin{2};
                end
            else
                switch nargin
                    case 0
                        pid.xt = 0;
                        pid.yInfo.limits = [-Inf, Inf];
                    case 1
                        pid.xt = varin;
                        pid.yInfo.limits = [-Inf, Inf];
                    case 2
                        pid.xt = varin{1};
                        pid.yInfo.limits = varin{2};
                end
            end
        end
        
        function setTarget(pid, xt)
            pid.xt = xt;
        end
        
        function l = limits(pid)
            if pid.yIsAxis
                l = pid.yInfo.config.kind.extRange;
            else
                l = pid.yInfo.limits;
            end
        end
        
        function y = compute(pid, x)
            e = pid.xt - x;
            pid.int = pid.int + e;
            
            if pid.yIsAxis
                pid.yInfo.read();
%                 pid.yInfo.name()
                pid.y = pid.yInfo.getX();
%                 y = pid.y
            end
            
            dy = pid.Kp*e + pid.Kd*(e - pid.ePrev) + pid.Ki*pid.int;
            
            if ~isnan(dy)
                pid.y = pid.y + dy;
            end
            
%             disp(['P: ' num2str(e)...
%                   '  I: ' num2str(pid.int)...
%                   '  D: ' num2str(pid.ePrev - e)...
%                   '  dy: ' num2str(dy)]);
            
            pid.ePrev = e;
            
            if  pid.y < min(pid.limits());
                pid.y = min(pid.limits());
            end
            if  pid.y > max(pid.limits());
                pid.y = max(pid.limits());
            end
%             y = pid.y
            
            if pid.yIsAxis
                pid.yInfo.goto(pid.y);
            end
        end
    end
    
end

