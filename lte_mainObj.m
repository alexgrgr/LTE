classdef lte_mainObj < hgsetget % handle
    %App for RF LTE test
    %
    % Use:
    %   h = wlan_lte_5g;
    %   updateMetrics(h,[150 1e-4 0.012 78.5]); drawnow
    %
    %   h.Dialogs(1).Bandwidth
    %   h.Dialogs(1).Model
    %   h.Dialogs(1).CenterFrequency
    %
    %   To get System Parameter values,
    %     val = h.Dialogs(1).<propertyName>;
    
    properties (AbortSet)  % <- stops calling of .set when same data entered
        % Cell array of data
        %   - 4 elements are required for this app
        DataSet = {}
    end
    
    properties (SetAccess=private)
        DP           % handle to DialogPresenter
        Dialogs      % vector of handles to all Dialogs
        Listeners
    end
    
    properties % (Access=private)
        hFig         % handle to HG figure
        hTop         % handle to top-level uicontainer
        hTheDamnLines  % vector of handles to the lines, one per subplot
    end
    
    methods
        function dt = lte_mainObj(varargin)
            % Pass one or more dialogs to the constructor:
            %   dt = DialogTester(dlg1,dlg2,...)
            %   dt = DialogTester([dlg1 dlg2 ...])
            %
            % Set property values for the DialogPresenter by passing them
            % as trailing arguments to the constructor:
            %    dt = DialogTester(...,'Param',value,...)
            %
            % To identify DialogPresenter properties, look at:
            %    dt.DP
            
            % instantiate all of our dialogs here:
            %  xxx add EVM readout later
            dt.Dialogs = [dlg_getParams dlg_showMeasures];
%             dt.Dialogs = [dlg_getParams dlg_showMeasures];
%             dt.Dialogs = [dlg_getParams dlg_showMeasures dlg_Accelerate];
            init(dt);
        end
        
        function set.DataSet(obj,val)
            % called whenever DataSet property changes.
            
            %validateattributes();
            
            obj.DataSet = val; % store the new value
            
            % Call a side-effect:
            updateThePlots(obj);
        end
    end
    
    methods (Access=private)
        function init(dt)
            % Initialize overall UI
            % - create dialog panel
            % - create app body with simple plot
            
            % Create UI
            fig = figure( ...
                'NumberTitle','off', ...
                'Name','LTE/LTE-A Testbench', ...
                'IntegerHandle','off', ...
                'menubar','none', ...
                'pos', [422 2 850 700]);
            
            dt.hFig = fig;
            hHigher = uicontainer( ...
                'parent',fig, ...
                'tag','DialogTester_hTop_Parent', ...
                'pos',[0 0 1 1]);
            dt.hTop = uicontainer( ...
                'parent',hHigher, ...
                'tag','DialogTester_hTop', ...
                'pos',[0 0 1 .98]);
            
            createDP(dt);
            addDialogs(dt);
            
            createAppBody(dt);
            finalizeDialogs(dt); % makes DialogPanel visible when finished
            initListeners(dt);
            
            % Enable UI
            setVisible(dt.DP,true);
        end
        
        function initListeners(dt)
            % Create listeners in disabled state.
            
            % Suppress keypresses (ordinarily, keypresses over the app
            % would echo to the command window)
            hfig = dt.hFig;
            hfig.KeyPressFcn = @(~,~)[];
            
            lis.MouseMotion  = addlistener(hfig,'WindowMouseMotion', @(h,e)mouseMove(dt,h,e));
            lis.MousePress   = addlistener(hfig,'WindowMousePress',  @(~,~)mouseDown(dt));
            lis.MouseRelease = addlistener(hfig,'WindowMouseRelease',@(~,~)mouseUp(dt));
            lis.ScrollWheel  = addlistener(hfig,'WindowScrollWheel', @(~,e)wheelMove(dt,e));
            dt.Listeners = lis;
        end
        
        function createAppBody(obj)
            % This is the test app
            
            theDP = obj.DP;        % Get handle to DialogPanel
            obj.hFig = theDP.hFig; % copy for convenience
            parent = theDP.hBodyPanel;
            
            % App 2: multiple axes
            for i = 1:2
                hax_i = subplot(2,1,i,'parent',parent);
                hline(i) = line('parent',hax_i, ...
                    'xdata',[], ...
                    'ydata',[]);
            end
            obj.hTheDamnLines = hline;
            
        end
        
        function createDP(dt)
            % Create DPVerticalPanel object that is owned by tester.
            % Panel is left invisible until after dialogs are added.
            
            % Suppress automatic call to init() by not passing hTop as
            % input arg. Just call init() manually after properties are
            % set.
            theDP = dialogmgr.DPVerticalPanel;
            
            % Ordered list of names of visible dialogs
            theDP.DockedDialogNamesInit = {dt.Dialogs.Name};
            theDP.DialogBorderFactory = @dialogmgr.DBTopBar;
            theDP.DialogVerticalGutter = 8;
            theDP.DialogHorizontalGutter = 8;
            theDP.Animation = true;
            theDP.PanelMinWidth = 200;
            theDP.PanelMaxWidth = 450;
            theDP.PanelWidth = 250;
            theDP.BodyMinHeight = 100;
            %theDP.BodyMinWidth = 100;
            theDP.DialogBorderDecoration = ...
                {'TitlePanelBackgroundColorSource','Custom', ...
                'TitlePanelBackgroundColor',[.1 .1 .8]};
            
            % Cross-reference DialogTester and DialogPresenter
            dt.DP = theDP;
            theDP.UserData = dt;
            
            init(theDP,dt.hTop);
        end
        
        function addDialogs(dt)
            % Create application dialogs and add to Dialog Manager.
            
            dlgs = dt.Dialogs;
            N = numel(dlgs);
            for i = 1:N
                d_i = dlgs(i);
                createAndRegisterDialog(dt.DP,d_i);
                
                % For each dialog, any change to a control can call a
                % function.  It can be a different function for each
                % dialog.  For simplicity, we call the SAME function for
                % ALL dialogs in this test app:
                onPropertyChange(d_i, @(h,ev)valuesUpdated(dt,ev));
            end
            
            % Dialogs(2) is the dlg_metrics readout
            metrics = dt.Dialogs(2);
            %onPropertyChange(metrics, @(h,ev)update(metrics))
            onPropertyChange(metrics, @(h,ev)disp('change'));
        end
        
        function finalizeDialogs(dt)
            % Leaves GUI ready for user interaction, but invisible
            
            theDP = dt.DP;
            
            % First step of init is to finalize dialogs for dialog panel
            % -> no more dialogs should be registered after this point!
            finalizeDialogRegistration(theDP);
            
            % true: show panel
            % false: no animation
            setDialogPanelVisible(theDP,true,false);
            
            % Initialize pointer
            setptr(theDP.hFig,'arrow');
            
            % Add a resize callback if desired:
            % set(theDP.hBodyPanel,'ResizeFcn',@resizeFcn);
        end
    end
    
    % Mouse interaction
    %
    methods (Access=private)
        function wheelMove(dt,ev)
            % Mouse scroll wheel modified/moved
            
            % Allow DialogPanel to handle wheel events in its area
            handled = mouseScrollWheel(dt.DP,ev);
            if ~handled
                % Do something useful here!
            end
        end
        
        function mouseDown(dt)
            % Mouse button pressed
            
            % Let DialogPanel handle any mouseDown events of its own first
            motionFcn = mouseDown(dt.DP);
            if ~isempty(motionFcn)
                % Allow DialogManager to install its own motion:
                dt.Listeners.MouseMotion.Callback = motionFcn;
            else
                % For this app, when clicking, replace the vertical-bar
                % cursor with a single dot on the data value.
                %
                % Shut down motion while button is down:
                dt.Listeners.MouseMotion.Enabled = false;
                
                % xxx do nothing
            end
        end
        
        function mouseUp(dt)
            % Invoked when the mouse button has been released
            
            % DialogPanel handles mouse up event first.
            % If it doesn't need it, it passes control to the app:
            handled = mouseUp(dt.DP);
            if handled
                % DialogManager took the mouse listeners previously, so we
                % re-install ours now:
                dt.Listeners.MouseMotion.Callback = @(h,e)mouseMove(dt,h,e);
            else
                % xxx do nothing
            end
            
            % Our app disables motion in mouseDown, so we must
            % re-enable motion in mouseUp
            dt.Listeners.MouseMotion.Enabled = true;
        end
        
        function mouseMove(dt,hFig,ev)
            % Give feedback to user while mouse is in motion.
            
            if nargin > 2
                hFig.CurrentPoint = ev.Point;
            end
            
            % Let DialogPanel handle mouse move events first
            handled = mouseMove(dt.DP);
            if ~handled
                % xxx do nothing
            end
        end
    end
    
    methods (Access=private)
        function valuesUpdated(dt,ev)
            % Do whatever the App wants to do in response to a change in
            % dialog parameters.
            
            % Here's how to get the specific property that changed, and its
            % new value:
            theDialog = ev.Source;
            theProperty = ev.Property;
            newValue = theDialog.(theProperty);
            
            % Show the change in the command window:
            valueStr = mat2str(newValue);
            %fprintf('Property "%s" changed to %s\n',theProperty,valueStr);
        end
    end
    
    methods
        function updateThePlots(obj)
            % Update the line plots
            
            ds = obj.DataSet;
            hlines = obj.hTheDamnLines;
            N = numel(ds);
            for i = 1:N
                data_i = ds{i};
                Nx = numel(data_i);
                hlines(i).XData = (1:Nx);
                hlines(i).YData = data_i;
            end
            drawnow expose
        end
        
        function updateMetrics(dt,values)
            % updateMetrics(h,values) updates RF Metrics readout.
            %
            % 1 to 4 values may be passed in a vector:
            %
            %    values = [Frame# BER EVM ACLR]
            %           = [Frame# BER EVM]
            %           = [Frame# BER]
            %           = [Frame#]
            % Note that EVM is a fraction, not a percent.
            
            metricsDlg = dt.Dialogs(2);
            metricsDlg.Values(1:numel(values)) = values;
            update(metricsDlg);
        end
    end
end
