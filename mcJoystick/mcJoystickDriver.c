#include <mex.h>
#define WIN32_LEAN_AND_MEAN
#include <pthread.h>
#include <Windows.h>
#include <mmsystem.h>

#define VERBOSE 1

#define deadZoneTrigger 32
#define deadZoneThumb 4096
    
bool shouldContinue = true;
    
const char* fields[] =  {"id", "type", "axis", "value"};
mwSize dims[1] = { 1 };
    
void notifyMatlabOfEvent(mxArray* matlab, int id, int type, int axis, float value) {
    mxArray* src = mxCreateDoubleScalar(id);
    
    mxArray* event = mxCreateStructArray((mwSize)1, dims, 4, fields);
    mxSetField(event, 0, "id",      mxCreateDoubleScalar(id));      // Event id =       Joystick id
    mxSetField(event, 0, "type",    mxCreateDoubleScalar(type));    // Event type =     { 0=debug, 1=button, 2=POV, 3=axis, 4=throttle }
    mxSetField(event, 0, "axis",    mxCreateDoubleScalar(axis));    // Event axis =     { buttons: 1-16, triggers: 1-2, axes: 1-4 }
    mxSetField(event, 0, "value",   mxCreateDoubleScalar(value));   // Event value =    { buttons: 0 or 1, POV: -, axes: (-1)-(-.125) or .125-1 }
    
    mxArray* plhs[3] = {matlab, src, event};
    mxArray* prhs[1];
    
    mexCallMATLAB(1, prhs, 3, plhs, "feval");
    double* data = mxGetPr(prhs[0]);
    
    shouldContinue = data[0];
//     mexPrintf("Continuing? %d\n", shouldContinue);
}

void axesFunc(mxArray* matlab, int id, int axis, int value, int valuePrev){
    if (abs(value - 32767) > deadZoneThumb){
        notifyMatlabOfEvent(matlab, id, 3, axis, ((axis == 2)?(-1):(1))*max((float)-1, (((float)value)-32767.)/32767.));
    } else if  (abs(valuePrev - 32767) > deadZoneThumb) {
        notifyMatlabOfEvent(matlab, id, 3, axis, 0);
    }
}

void* loop(void* argin){
    shouldContinue = true;          // For some reason, this variable persists after first execution. So it must be set again. Odd.
    
    int i = 0;
    int j = 0;
    int id = -1;
    int counter = 0;
    JOYINFOEX state;
    
    DWORD  dwButtonsPrev = 0;
    DWORD  dwPOVPrev = 0;
    DWORD  dwZpos = 0;
    DWORD  dwXpos = 0;
    DWORD  dwYpos = 0;
    DWORD  dwRpos = 0;
    
    mxArray* matlab = (mxArray*)argin;
    
    state.dwSize = sizeof(JOYINFOEX);
    state.dwFlags = JOY_RETURNALL | JOY_RETURNCENTERED;
    
    while (shouldContinue) {                    // Infinite loop
//         mexCallMATLAB(0, NULL, 0, NULL, "drawnow");
//         mexCallMATLAB(0, NULL, 0, NULL, "pause(.016);");
//         mexCallMATLAB(0, NULL, 0, NULL, "disp('frame');");
        
        mexEvalString("drawnow limitrate;");
//         mexEvalString("disp(.016);");
        
//         Sleep(16);                              // 60Hz
        
        i = -1;
        
        while ( id == -1 && shouldContinue){    // While a controller has not been found, check every 1 second for a controller.
            if (i == 0){
                Sleep(1000);
            } else {
                i++;
            }
            
            while (i < 15 && id == -1){         // Apparently, for loops are not allowed...
                if (joyGetPosEx(i, &state) == JOYERR_NOERROR) { id = i; }
                
                i++;
            }
            notifyMatlabOfEvent(matlab, id, 0, id != -1, 0);
            i = 0;
        }
        
        counter++;
        if (!(counter % 60)){ notifyMatlabOfEvent(matlab, id, 0, 1, 0); }   // Continuously update MATLAB about whether everthing is alright...
        
        if (joyGetPosEx(id, &state) != JOYERR_NOERROR){     // If getting the state was unsuccessful...
            id = -1;                                        // ...return to polling for a connection.
        }
        else {                                              // Otherwise, check for changes in the state.
            //// Buttons ////
            WORD buttonChanged = dwButtonsPrev ^ state.dwButtons;
            if (buttonChanged) {                // If there has been a change in the buttons...
                j = 1;
                i = 1;
                while (i <= 32) {               // Apparently, for loops are not allowed...
                    if (buttonChanged & j) {    // If button i has changed,...
                        notifyMatlabOfEvent(matlab, id, 1, i, (state.dwButtons & j) > 0);
                    }
                    j *= 2;
                    i++;
                }
            }
            dwButtonsPrev = state.dwButtons;  // Remember what the button state is so that we can check for changes next time.
            
//             //// Triggers ////
//             if (state.Gamepad.bLeftTrigger > deadZoneTrigger)   // If the left trigger is pressed enough...
//                 notifyMatlabOfEvent(matlab, id, 2, 1, state.Gamepad.bLeftTrigger/255);
//             if (state.Gamepad.bRightTrigger > deadZoneTrigger)  // If the right trigger is pressed enough...
//                 notifyMatlabOfEvent(matlab, id, 2, 2, state.Gamepad.bRightTrigger/255);
            
            if (state.dwPOV != dwPOVPrev){
                notifyMatlabOfEvent(matlab, id, 2, 1, ((float)state.dwPOV)/100.);
                dwPOVPrev = state.dwPOV;
            }
            
            //// Thumb Axes ////
            axesFunc(matlab, id, 1, state.dwXpos, dwXpos);  //X
            axesFunc(matlab, id, 2, state.dwYpos, dwYpos);  //Y, negative for some reason...
            axesFunc(matlab, id, 3, state.dwRpos, dwRpos);  //Z
            
            dwXpos = state.dwXpos;
            dwYpos = state.dwYpos;
            dwRpos = state.dwRpos;
            
            if (state.dwZpos != dwZpos){        // Throttle
                notifyMatlabOfEvent(matlab, id, 4, 1, ((float)state.dwZpos)/65535.);
                dwZpos = state.dwZpos;
            }
            
//             axesFunc(matlab, id, 3, state.dwZpos);
//             axesFunc(matlab, id, 5, state.dwUpos);
//             axesFunc(matlab, id, 6, state.dwVpos);
        }
    }
    
    notifyMatlabOfEvent(matlab, -1, 0, -1, 0);
}

/* The gateway function - think of it as main() */
void mexFunction(int nlhs, mxArray *plhs[],         // Number-of/Array-for output (left-side) arguments.
                 int nrhs, const mxArray *prhs[])   // Number-of/Array-for of input (right-side) arguments.
{
    loop((void*)prhs[0]);
}

