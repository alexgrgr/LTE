classdef dlg_getParams < dialogmgr.DCTableForm
    % Implement input dialog for RF LTE for Houman
    
    properties (SetObservable)
        Tool % the tool
        SNR = 10
        stopSim = 0
        profile='EPA'
        doppler=5
        corrProfile='Low'
    end
    
    methods
        function obj = dlg_getParams(tool,name)
            if nargin < 2
                name = 'LTE/LTE-A Simulation Parameters';
            end
            if nargin < 1
                tool = [];
            end
            obj.Name = name;
            obj.UserData = tool;
        end
    end
    
    methods (Access=protected)
        function initTable(obj)
            obj.InterColumnSpacing = 2;
            obj.InterRowSpacing = 2;
            obj.InnerBorderSpacing = 4;
            obj.ColumnWidths = {'max','min','max'};
            obj.HorizontalAlignment = {'left','left','right'};
            
            uipushbutton(obj,...
                 'Set LTE parameters','Callback','lteui');
            obj.newrow
            % Doppler
            c5 = uislider(obj,[0 70],'label','doppler');
            c5.Tag = 'Doppler shift';
            d5 = uieditv(obj,0);
            connectPropertyAndSliderAndEdit(obj,'doppler',c5,d5);
            obj.newrow
            % Channel profile
            c1 = uipopup(obj,{'EPA', 'EVA', 'ETU'},'label','profile');
            connectPropertyAndControl(obj,'profile',c1)
            obj.newrow
            % Bandwidth
            c2 = uipopup(obj,{'Low', 'Medium', 'High'},'label','corrProfile');
            connectPropertyAndControl(obj,'corrProfile',c2)
            obj.newrow
            
            % SNR
            c6 = uislider(obj,[0 40],'label','SNR');
            c6.Tag = 'SNR';
            d6 = uieditv(obj,0);
            connectPropertyAndSliderAndEdit(obj,'SNR',c6,d6);
            obj.newrow
            
            uipushbutton(obj,...
                 'Run simulation','Callback','lte_app');
            obj.newrow
            p1=uipushbutton(obj,...
                'Stop simulation','Callback','lteStopSimulation');
            connectPropertyAndControl(obj,'stopSim',p1)
            obj.newrow
            uipushbutton(obj,...
                'Clean up','Callback','lteCleanUp');
            uipushbutton(obj,...
                'Edit','Callback','edit lteTxChRx');

        end
    end
end

