% https://github.com/optospinlab/simple_modularControl
% Check github repo for updates, bug reports and issues 
% Modified Feb-07-2021 by Srivatsa

% Dependencies:  This code requires Matlab 2016b (not compatible with newer veersions!)

%This is the main function of the mcScope code
%Please note that this is a simplified fork of https://github.com/optospinlab/modularControl
% !!! Ensure that the instruments (inc. DAQ) are at idle (not locked by other GUI) !!!

function mcScope

clc; close all; clear all

%Ensure that the current folder and sub-folders are in the MATLAB path for
%the current session
addpath(genpath([pwd,'\']))

% For manual instrument control (gotoXX, etc.) and monitoring, define the instruments attached to the microscope
input = mcUserInput();

    %Monitor instrument status
    input.openListener(); 
    disp('  Opened mcUserInput listeners...')

    % For automated instrument control (confocal scan, optimization, etc.)
    % Inherit instruments from the manual controls defined above
    mcgScope(); % Open the GUI for scans, etc.
    disp('  Opened mcgScope...')
end



