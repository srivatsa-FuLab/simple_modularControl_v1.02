classdef mcInstrumentManager
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        f = [];
        t = [];
    end
    
    methods
        function m = mcInstrumentManager()
            m.f = mcInstrumentHandler.createFigure(m, 'none');
            m.t = uitable(m.f, 'Units', 'Normalized', 'Position', [0 0 1 1]);
            
            m.makeTable();
            
            m.f.Visible = 'on';
        end
        
        function makeTable(m)
            m.t.ColumnName =    {'Axis',    'Position', 'Unit', 'Get', 'Goto Position', 'Unit', 'Goto', 'isOpen',   'inUse',    'inEmulation'};
            
            m.t.ColumnEditable = [true,     false,      false,  false, true,            false,  false,  false,      false,      false];
            m.t.Data = {'Some Axis', 0, 'V', '---', 0, 'V', '---', true, true, true};
        end
    end
    
end

