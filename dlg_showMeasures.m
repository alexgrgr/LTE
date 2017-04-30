classdef dlg_showMeasures < dialogmgr.DCTableReadout
    % Implement 5G RF readout dialog.

    properties (SetObservable)
        Values = [1000 2 0.5 0.009 0.0164 1.92e6]
    end
    
    methods
        function dlg = dlg_showMeasures
            dlg.Name = 'Measurements';
        end
        
        function testDialog(dlg)
            update(dlg);
        end
    end
    
    methods (Access=protected)
        function initReadout(dlg)
            % Initialize directivity pattern info
            dlg.InitialText = { ...
                'Type','Value','Units';
                '---','---','---';
                'Packet:','00000','';
                'Modulation:','00000','';
                'Coding Rate:','00000','';
                'PER:','0.00','';
                'BER:','0.00','';
                'Data Rate:','0',''};
            
            dlg.NumHeaderRows = 2;
            dlg.InterColumnSpacing = 8;  % Between adjacent columns
            dlg.InterRowSpacing    = 2;  % Between adjacent rows
            dlg.InnerBorderSpacing = 2;  % Around dialog perimeter within border
            dlg.DecimalAlignment = [false false false];
            
            %dlg.ColumnWidths = {[100 100],[60 inf],[40 40]};
            %dlg.ColumnWidths = {[-1 -1],[-1 inf],[-1 -1]};
            %dlg.ColumnWidths = {'min',[60 150],'max'};
            dlg.ColumnWidths = {'min','max','min'};
            
            dlg.HorizontalAlignment = {'right','left','left'};
        end
    end
    
    methods
        function update(dlg)
            % Update readout
            %   values = [frame# ber evm aclr]
            values = dlg.Values;
            prm.Mod=bits2mod(values(2));
            prm.Cod=num2str(values(3));
            dlg.updateColumn(2, { ...
                sprintf('%d',values(1)), ...
                sprintf('%s',prm.Mod), ...
                sprintf('%s',prm.Cod), ...
                sprintf('%8.6f',values(4)), ...
                sprintf('%8.6f',values(5)), ...
                sprintf('%g',values(6))});
            
        end
    end
end