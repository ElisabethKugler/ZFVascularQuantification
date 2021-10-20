/* Macro Diameter Measurement 
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

*/

path = getDirectory("Input Folder");
outputFolder = getDirectory("Output Folder");
SeletonList = getFileList(path);
filelist = getFileList(path);

q = File.open(outputFolder + "DiametersAndNetworkLength.txt");

for (i=0; i< filelist.length; i++) {   
	if (endsWith(filelist[i], ".tif")) {					
		open(path + filelist[i]);
		selectWindow(filelist[i]); // later to be changed to iterate through all and embed into code GUI.ijm
		meep = getTitle();
		short = replace(meep, ".tif", "");
		getDimensions(width, height, channels, slices, frames);
		getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
		
		///// create MIP and Distance Map for diameters /////
		selectWindow(meep); // select original thresholded image
		run("Duplicate...", "title=ForSkel duplicate"); // for skeletonization later
		run("Duplicate...", "title=For3DEDM duplicate");
		selectWindow(meep); 
		// need to run it on 2D to get exact values
		run("Z Project...", "projection=[Max Intensity]");
		run("Geometry to Distance Map", "threshold=1");
		saveAs("Tiff", outputFolder + "MAX_" + short + "_EDT"); // save 2D distance map
		
		///// skeletonize original tresholded image in 3D /////
		selectWindow("ForSkel"); // duplicate from original thresholded image; to skeletonize in 3D
		run("Skeletonize (2D/3D)");
		rename("Skel_");

		// network length / skeleton voxels
		run("Histogram", "stack");
		// [255] is VascVox
		Plot.getValues(values, counts);
		vascVox=counts[255];
		close(); // histogram
		
		selectWindow("Skel_");	
		run("Duplicate...", "title=ForEDMSkel duplicate");
		
		///// save skeletonized image /////
		saveAs("Tiff", outputFolder + "Skel_" + short);  // stack
		run("Z Project...", "projection=[Max Intensity]");
		run("Skeletonize (2D/3D)"); // remove spurious branches in 2D 
		saveAs("Tiff", outputFolder + "MAX_Skel_" + short); // MIP
		
		///// merge 2D skel and 2D distance map for diameter measurements /////
		imageCalculator("AND create", "MAX_" + short + "_EDT.tif","MAX_Skel_" + meep);
		run("Fire");
		saveAs("Tiff", outputFolder + "MAX_LUTFire_EDM_Skel_" + short);  // stack
		rename("LUTFire_EDM");
		
		///// quantify diameters /////
		/////// NUMBER 1 - average diameter for whole 2D image - iterate through whole image in (x,y)
			counter = 0;0
			value = 0;
			total = 0;
			avgLength = 0;
				
			selectWindow("LUTFire_EDM");
			
		// .. use image properties and brightness/intensity to quantify width at the respective vx in microns	
			for (y = 0; y < height; y++) {
				for (x = 0; x < width; x++) {
						properties = getPixel(x, y);
						if (properties != 0){ 				 // skip if intensity value under 30-ish?
							 		counter++;
							 		total += properties; 
									//value = properties * 1.15;
									//setPixel(x, y, value);
							}
					}
				}
		
				average = (total/counter); // multiply with conversionFactor!!!!!!!!!!!!!!!!! // don't think a conversion factor is needed -- will need to double-check
				saveAs("Tiff", outputFolder + "MAX_Dia_" + short);  // stack
				print(q , filelist[i] + "  \t" + average + "  \t" + vascVox);
				///// need to close everything
				run("Close All");									// debug
		
		
		///// quantify whole 3D network length in voxel /////
			selectWindow("Skel_" + meep); 
			run("Histogram", "stack");
			Plot.getValues(values, counts);
			NetworkVoxel=counts[255];
			close(); // histogram
		
		// write BP and EP numbers into it.... 
			// print(skeletonFile, short + "\t" + average);
			print(average);
			close(); // histogram
			
		///// need to close everything
				run("Close All");

				}
				run("Close All");
			}
///// summarize skeleton to get # junctions information
skelDir = getFileList(outputFolder);
	for (s=0; s< skelDir.length; s++) {   
		if ( startsWith(skelDir[s], "Skel_")) {
				open(outputFolder + skelDir[s]);
				// segmentation	
				selectWindow(skelDir[s]);
				run("Summarize Skeleton");
			}
		}
saveAs("Results", outputFolder + "Skeleton Stats.csv");
run("Close All");
		
///// tell me when it's done - ie email / pop-up
showMessage("Macro is finished"); 
