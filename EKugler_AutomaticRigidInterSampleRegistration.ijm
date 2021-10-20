/* Macro for automatic rigid inter-sample registration
 *  Author: Elisabeth Kugler 2020
 *  contact: kugler.elisabeth@gmail.com
 
BSD 3-Clause License

Copyright (c) [2020], [Elisabeth C. Kugler, The University of Sheffield, United Kingdom]
All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 * USE:
 * 		*** important *** one file needs to be called "template"
 * 		hit run
 * 		select input folder (path to .czi files)
 * 		when Macro is done - popup window will say "Macro is finished."
 * 	contact: kugler.elisabeth@gmail.com
 */

// input and output path
path = getDirectory("Input Folder"); 
// user prompt to select template image
// template = XXX; 

	filelistReg = getFileList(path); 

	open(path + "template.tif");
	template=getTitle();
	print("Running Inter-Sample Registration.");

	RegDir = path + "/Reg/"; 							// output folder
	File.makeDirectory(RegDir);						// make output folder
	
	// inter-sample registration	

	// get image/voxel properties
	getDimensions(width, height, channels, slices, frames);
		preChannels = channels;
		preSlices = slices;
		preFrames = frames;
	getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
		preUnit=unit;
		prePixelWidth =pixelWidth;
		prePixelHeight = pixelHeight;
		preVoxelDepth = voxelDepth;

	for (i=0; i< filelistReg.length; i++) {   
			if (endsWith(filelistReg[i], ".tif")){
				open(path + filelistReg[i]);
				// segmentation	
				selectWindow(filelistReg[i]);
				run("Rigid Registration", "initialtransform=[] n=1 tolerance=20 level=7 stoplevel=4 materialcenterandbbox=[] showtransformed template=" + template + " measure=Euclidean");
				run("Invert", "stack");
				//setThreshold(0, 132);
				setOption("BlackBackground", false);
				run("Make Binary", "method=Default background=Default");
				// set image/voxel properties
				run("Properties...", "channels=" + preChannels + " slices=" + preSlices + " frames=" + preFrames + " unit=" + preUnit + " pixel_width=" + prePixelWidth + " pixel_height=" + prePixelHeight + " voxel_depth=" + preVoxelDepth);
				saveAs("Tiff", RegDir + "InterSReg_" + filelistReg[i]);
				// create MIP
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("Jpeg", RegDir + "MAX_InterSReg_" + filelistReg[i]);
				close();
				close();
			}
	}
	close();
	close();

showMessage("Macro is finished"); 


