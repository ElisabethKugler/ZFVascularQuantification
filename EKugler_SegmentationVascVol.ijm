/* Macro for vascular segmentation and volume quantification
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
 * 		hit run
 * 		select input folder (path to .czi files)
 * 		select output folder (path for .tiff and MIPs)
 * 		when Macro is done - popup window will say "Macro is finished."
*/

// input and output path
path = getDirectory("Input Folder"); 
outputFolder = getDirectory("Output Folder");
filelist = getFileList(path); 

// create file to write volume measurements
f = File.open(path + "VascVolResults.txt");

EdgeDir = path + "/Edges/"; 							// output folder
File.makeDirectory(EdgeDir);

//open ROI set 
roiManager("Open", path + "RoiSet.zip");
n = roiManager("count");
r=0; // counter for ROIset

// colourSetting needed for clearing outside for vascular volume quantification
setForegroundColor(255, 255, 255); 
setBackgroundColor(255, 255, 255);

// start processing of files
for (i=0; i< filelist.length; i++) {   
	if (endsWith(filelist[i], ".tif")) {
		open(path + filelist[i]);
// segmentation	
		selectWindow(filelist[i]);
		
//get image properties
		getDimensions(width, height, channels, slices, frames);
		preChannels = channels;
		preSlices = slices;
		preFrames = frames;
		
		getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
		prePixelWidth =pixelWidth;
		prePixelHeight = pixelHeight;
		preVoxelDepth = voxelDepth;

		voxelVol= (prePixelWidth * prePixelHeight * preVoxelDepth);
		
		run("8-bit");
		setAutoThreshold("Default dark");
		run("Threshold...");
		setThreshold(4, 255); // threshold to be changed if other image acquisition settings
		setOption("BlackBackground", false);
		run("Convert to Mask", "method=Default background=Dark");
	
	// re-set original image values
		run("Properties...", "channels=" + preChannels + " slices=" + preSlices + " frames=" + preFrames +" unit=µm pixel_width=" + prePixelWidth + " pixel_height=" + prePixelHeight + " voxel_depth=" + preVoxelDepth);
	// Save segmented stack as tiff stack
		saveAs("Tiff", outputFolder + "TH_" + filelist[i]);
	// create MIP
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("Jpeg", outputFolder + filelist[i]);
        run("Close");

//vascular volume [vx] quantification - ROI from MIPs
        selectWindow("TH_" + filelist[i]);
	//iterate through ROI set 
		roiManager("Select", r);
		run("Measure"); 						// for density
		AeaUm = getResult("Area"); 	
		r++; // counter for ROI in ROIset
	// clear outside
		run("Clear Outside", "stack");
	// histogram count black 
		run("Histogram", "stack");
	// [255] is VascVox
		Plot.getValues(values, counts);
		VascVox=counts[255];			
		VascVol = voxelVol * VascVox;// vascular density
		selectWindow("TH_" + filelistTH[i]);
		AreaVx = AreaUm / voxelVol; // change um to vx
		FullVox = AreaVx * slices;				
		density = AreaVx / FullVox; // min 0, max 1

		// vascular surface
			selectWindow("TH_" + filelistTH[i]);
			run("Find Edges", "stack");
			saveAs("Tiff", EdgeDir + "Edges_" + filelistTH[i]);
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("Jpeg", EdgeDir + "MAX_Edges_" + filelistTH[i]);
			run("Close");
			selectWindow("Edges_" + filelistTH[i]); 
			// histogram count black 
			run("Histogram", "stack");
			// [255] is VascVox
			Plot.getValues(values, counts);
			EdgeVox=counts[255];
			
			EdgeVol = voxelVol * EdgeVox;
			print(f, filelistTH[i] + "  \t" + "VascVox" + "\t" + VascVox + "\t" + "VascVol" + "\t" + VascVol + "\t" + "EdgeVox" + "\t" + EdgeVox + "\t" + "EdgeVol" + "\t" + EdgeVol + "\t" + "density" + "\t"+ density);
	close();
	}
}
close();

showMessage("Macro is finished."); 