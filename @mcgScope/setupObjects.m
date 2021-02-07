% These are all the instruments seen by the automation GUI
% Ensure they are consistent with the /core/mcUserInput.m

function setupObjects(gui)

    % Grab data from user instrument definitions
    instr = mcUserInput.defaultConfig(); 

    gui.objects.piezos(1) = mcaDAQ(instr.axesGroups{1, 2}{1, 2}.config);
    gui.objects.piezos(2) = mcaDAQ(instr.axesGroups{1, 2}{1, 3}.config);
    gui.objects.piezos(3) = mcaDAQ(instr.axesGroups{1, 2}{1, 4}.config);

    gui.objects.galvos(1) = mcaDAQ(instr.axesGroups{1, 3}{1, 2}.config);
    gui.objects.galvos(2) = mcaDAQ(instr.axesGroups{1, 3}{1, 3}.config);

    configCounter= mciDAQ.counterConfig();
    gui.objects.counter   = mciDAQ(configCounter);

    gui.objects.isSetup = true;
end