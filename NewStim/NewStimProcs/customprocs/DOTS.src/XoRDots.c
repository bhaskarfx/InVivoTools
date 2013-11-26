/* XorDots.c COPYRIGHT:  Copyright Michael Shadlen and the University of Washington, 1995.  This file may be distributed freely as long as this notice accompanies  it and any changes are noted in the source.  It is distributed as is,  without any warranty implied or provided.  We accept no liability for  any damage or loss resulting from the use of this software.PURPOSE:  MEX routine to show random dot motion. For now, I'm playing with passing actual	dot locaitions.  I started with David Brainard's SCREENBlitImage and   modified it.  This module is intended to work in a stand alone mex file.HISTORY:	8/22/95		mns		fiddling	12/6/95  	mns		add offsets to respect aperture	2/10/96		dhb,mns small mods for stand-alone call, renamed.  2/20/96		mns made dot size smaller (3,3)  was (4,4)  2/22/96   mns adding vbl stuff here..(lifted from Brainard's ERGClutMovie.c*/// INCLUDES#include "GetSetPixXor.h"// default dot color (white)#define DOT_COLOR 160// default dot size#define DOT_SIZE 3// ROUTINE PROTOTYPESvoid XorDots(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);/*ROUTINE: XorDots*/void XorDots(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){	double *tmp, w4;	int m, n, w4vbl;	register double *dots_x, *dots_y;	register int j, xoff, yoff;	PsychTable *psychTable = GetPsychTable();	WindowPtr 	window 		 = GetTheWindow(psychTable->windowPtrArgument);  unsigned long *theCurrentValue, *theNewValue;  int currDotSize=0;  int maxDotSize=0;	// Start the timer	//	double start_time = Seconds();	// Check arguments	if ((nrhs == 0) || (nrhs > 4)) 		PrintfExit("XorDots: takes an input matrix, location offset, vblankopt and wentflag");	// INPUT #1 is the matrix of dot positions	if(!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0]) || !mxIsDouble(prhs[0]))		PrintfExit("XorDots: input matrix has bad type");	// we have not specified anything	if(nrhs == 1) {		xoff			= 0;		yoff			= 0;		w4vbl			= 0;	// we have specified a location offset	} else if(nrhs == 2) {		tmp 			= mxGetPr(prhs[1]);		xoff 			= (int) tmp[0];		yoff 			= (int) tmp[1];		w4vbl 		= 0;	// we have specified a location offset	// we are waiting for a vertical blank	} else {		tmp 			= mxGetPr(prhs[1]);		xoff 			= (int) tmp[0];		yoff 			= (int) tmp[1];		w4 				= WaitBlanking(GetWindowDevice(window), (long) mxGetScalar(prhs[2]));	}	// return the # of frames since last wait	if(nlhs == 1) {		plhs[0] = mxCreateDoubleMatrix(1,  1, mxREAL);		tmp 		= mxGetPr(plhs[0]);		tmp[0] 	= (int) 0.;	}	// send a WENT flag	if (nrhs == 4) {		mxArray *input_array[2];					m = mxGetM(prhs[3]);		if(m) {			input_array[0] = mxCreateString("send");			input_array[1] = mxCreateString("Went");			mexCallMATLAB(0, NULL, 2, input_array, "pcmsg");		}	}	// set up variables for the loop	m 		 = mxGetM(prhs[0]);	dots_x = mxGetPr(prhs[0]);	dots_y = dots_x + m;	// No color or dotsize given	if((n = mxGetN(prhs[0])) == 2) {		// XOR the dots		SetWindow(window);		theCurrentValue = (unsigned long*)malloc(sizeof(unsigned long)*DOT_SIZE);		theNewValue = (unsigned long*)malloc(sizeof(unsigned long)*DOT_SIZE); 		for(j=m;j>0;j--)			GetSetPixXor((int) (*dots_x++) + xoff, 	// x position of upper left corner of dot									 (int) (*dots_y++) + yoff,	// y position of upper left corner of dot									 DOT_COLOR,									// bitmap value of a dot written on a 0 background									 DOT_SIZE,theCurrentValue,theNewValue);	// size of the dot (sz x sz pixels)	 	UnsetWindow();    free((void*)theCurrentValue);		free((void*)theNewValue);	// color given	} else if(n == 3) {		register double *colorP = dots_x + 2*m;		// XOR the dots		SetWindow(window);		theCurrentValue = (unsigned long*)malloc(sizeof(unsigned long)*DOT_SIZE);		theNewValue = (unsigned long*)malloc(sizeof(unsigned long)*DOT_SIZE); 		for(j=m;j>0;j--)			GetSetPixXor((int) (*dots_x++) + xoff, 	// x position of upper left corner of dot									 (int) (*dots_y++) + yoff,	// y position of upper left corner of dot									 (int) (*colorP++),					// bitmap value of a dot written on a 0 background									 DOT_SIZE,theCurrentValue,theNewValue);	// size of the dot (sz x sz pixels)	 	UnsetWindow();    free((void*)theCurrentValue);		free((void*)theNewValue);	// color and dotsize given	} else if(n == 4) {		register double *colorP = dots_x + 2*m,										*sizeP  = dots_x + 3*m;		// XOR the dots		SetWindow(window);    for(j=m-1;j>0;j--) {			currDotSize=(int)(*sizeP++);			if (currDotSize>maxDotSize) maxDotSize = currDotSize;		}    sizeP = dots_x+3*m;		theCurrentValue = (unsigned long*)malloc(sizeof(unsigned long)*maxDotSize);		theNewValue = (unsigned long*)malloc(sizeof(unsigned long)*maxDotSize); 		for(j=m;j>0;j--)			GetSetPixXor((int) (*dots_x++) + xoff, 	// x position of upper left corner of dot									 (int) (*dots_y++) + yoff,	// y position of upper left corner of dot									 (int) (*colorP++),					// bitmap value of a dot written on a 0 background									 (int) (*sizeP++),theCurrentValue,theNewValue);// size of the dot (sz x sz pixels)	 	UnsetWindow();    free((void*)theCurrentValue);		free((void*)theNewValue);	// bad input matrix	} else {		PrintfExit("XorDots: requires an m by 2, 3 or 4 input matrix");	}	// Check the timer	//	Printf("Time: %lf\n", Seconds() - start_time);}