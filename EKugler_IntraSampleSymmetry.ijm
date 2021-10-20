/* Macro intrasample symmetry
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
 * 	contact: kugler.elisabeth@gmail.com
 * 	
 */

// input and output path
path = getDirectory("Input Folder"); 
outputFolder = getDirectory("Output Folder");
filelist = getFileList(path);

// create file to write quantification outputs
f = File.open(path + "IntraSampleSymmetryResults.txt");

//open ROI set 
roiManager("Open", path + "RoiSetLine.zip");
n = roiManager("count");
r=0; // counter for RoiSetLine

// prompt - to check if images are aligned 

// prompt - if they are aligned - are they aligned by registration - can a template be used to split them?

// if images are not aligned ask user to draw line roi

// start processing of files

///// ROTATION /////
for (i=0; i< filelist.length; i++) {   
	if (endsWith(filelist[i], ".tif")) {
		open(path + filelist[i]);
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
	
		roiManager("Select", r);
		r++; // counter for ROI in ROIset
		
		run("Measure"); // measure the angle of line ROI for rotation

		MeasAngle = getResult("Angle"); // measured angle from LineROI
		if (MeasAngle<0){
			betrag = abs(MeasAngle);
			rot = -(90 + betrag);
		}else if (MeasAngle>0){ 
			betrag = abs(MeasAngle);
			rot = -(90 - betrag);
		}else{
			rot=90;
		}
		run("Rotate... ", "angle=" + rot + " grid=1 interpolation=Bilinear stack"); // rotate image based on line ROI from MIPs

// BINARIZE	 images (rotation does change it)
		//setThreshold(128, 255);
		setOption("BlackBackground", false);
		run("Make Binary", "method=Default background=Default");
// Save segmented stack as tiff stack
		saveAs("Tiff", outputFolder + "Rot_" + filelist[i]);
// create MIP
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("Jpeg", outputFolder + "MAX_rot_" + filelist[i]);
      //  close(); // keep MIPs open to draw midline ROI

close();
	}
}

// delete all ROIs from ROILinesSet
arrayLines = newArray("0");; 
for (k=1;k<roiManager("count");k++){ 
        arrayLines = Array.concat(arrayLines,k); 
} 
roiManager("select", arrayLines); 
roiManager("Delete");

selectWindow("Results"); // close RoiSetLine results table
run("Close");

////// L R symmetry	/////
// prompt input for midline ROIs
waitForUser("Draw line ROI along midline of rotated images (need to be in order). \n 'Add' to ROI manager. \n Close image. \n Press 'ok'.");
n=0; // counter for ROIsetMiddle

// open rotated images
filelistMidline = getFileList(outputFolder);

LRDir = path + "/LRVol/"; 
File.makeDirectory(LRDir);


for (m=0; m< filelistMidline.length; m++) {   
	if (endsWith(filelistMidline[m], ".tif")) {
			open(outputFolder + filelistMidline[m]);
			selectWindow(filelistMidline[m]);
	
	//get image properties for L and R box dimensions to be drawn
			getDimensions(width, height, channels, slices, frames);
			VolWidth = width;
			HalfWidth = width / 2;
			VolHeight = height;

			getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
			LRPixelWidth = pixelWidth;
			LRprePixelHeight = pixelHeight;
			LRpreVoxelDepth = voxelDepth;

			LRvoxelVol= (prePixelWidth * prePixelHeight * preVoxelDepth);

			roiManager("Select", n);
			n++; // counter for ROI in ROIsetMiddle
			run("Measure"); // measure the angle of line ROI for splitting L R box

			MeasX = getResult("BX"); // measured X-position from LineROI for L and R box
			RBoxWidth = width - MeasX;
			RStart = width - (RBoxWidth * 2);
	// box can only be that big.. L/R smaller/bigger - take smaller one and extend to both sides.. 
			if(MeasX<HalfWidth){ // sample is more to the left -> left side taken for box size
				setTool("rectangle");
				makeRectangle(0, 0, MeasX, VolHeight); // x,y,w,h
				////// LEFT BOX ////// 
				run("Duplicate...", "duplicate");
				// quant L vol
				// histogram count black 
				run("Histogram", "stack");
				// [255] is VascVox
				Plot.getValues(values, counts);
				LVascVox=counts[255];			
				LVascVol = LRvoxelVol * LVascVox;
				close(); // close histogram
				// save as tiff
				saveAs("Tiff", LRDir + "LVol_" + filelistMidline[m]);
				// create MIP
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("Jpeg", LRDir + "MAX_LVol_" + filelistMidline[m]);
      			close(); // close MIPs
				// skel vol tiff
				run("Skeletonize (2D/3D)");
				// get skel voxel
				run("Histogram", "stack");
				Plot.getValues(values, counts);
				LSkelVox=counts[255];
				LSkelVol = LRvoxelVol * LSkelVox;
				close(); // close histogram
				
				//////  RIGHT BOX ////// 
				selectWindow(filelistMidline[m]);
				// make right box
				setTool("rectangle");
				makeRectangle(MeasX, 0, MeasX, VolHeight); // x,y,w,h
				run("Duplicate...", "duplicate");
				// TRANSFORMATION
				run("Flip Horizontally", "stack");
				// quant R vol
				// histogram count black 
				run("Histogram", "stack");
				// [255] is VascVox
				Plot.getValues(values, counts);
				RVascVox=counts[255];			
				RVascVol = LRvoxelVol * RVascVox;
				close(); // close histogram
				// save as tiff		
				saveAs("Tiff", LRDir + "RVol_" + filelistMidline[m]);
				// create MIP
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("Jpeg", LRDir + "MAX_RVol_" + filelistMidline[m]);
      			close(); // close MIPs
				// skel vol tiff
				run("Skeletonize (2D/3D)");
				// get skel voxel
				run("Histogram", "stack");
				Plot.getValues(values, counts);
				RSkelVox=counts[255];
				RSkelVol = LRvoxelVol * RSkelVox;
				close(); // close histogram


///// SIMILARITY MEASUREMENTS /////
				// get them
				s = replace(filelistMidline[m], ".tif", "");     
				run("Label Overlap Measures", "source=" + "RVol_" + s + " target=" + "LVol_" + s + " overlap jaccard dice");
				saveAs("Results",  LRDir + s + "JacDicOv.csv");
				close();	
				// write everything into output/results file
				print(f, filelistMidline[m] + "  \t" + "LVascVox" + "\t" + LVascVox + "\t" + "RVascVox" + "\t" + RVascVox + "\t" + "LVascVol" + "\t" + LVascVol + "\t" + "RVascVol" + "\t" + RVascVol + "\t" + "LSkelVox" + "\t" + LSkelVox + "\t" + "RSkelVox" + "\t" + RSkelVox + "\t" + "LSkelVol" + "\t"+ LSkelVol + "\t" + "RSkelVol" + "\t"+ RSkelVol);
				
			}
			else{ // sample is more to the right -> right side taken for box size
				//////  RIGHT BOX ////// 
				selectWindow(filelistMidline[m]);
				setTool("rectangle");	
				makeRectangle(MeasX, 0, RBoxWidth, VolHeight); // x,y,w,h
				run("Duplicate...", "duplicate");
				// quant R vol
				// TRANSFORMATION
				run("Flip Horizontally", "stack");
				// histogram count black 
				run("Histogram", "stack");
				// [255] is VascVox
				Plot.getValues(values, counts);
				RVascVox=counts[255];			
				RVascVol = LRvoxelVol * RVascVox;
				close(); // close histogram
				// save as tiff		
				saveAs("Tiff", LRDir + "RVol_" + filelistMidline[m]);
				// create MIP
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("Jpeg", LRDir + "MAX_RVol_" + filelistMidline[m]);
      			close(); // close MIPs
				// skel vol tiff
				run("Skeletonize (2D/3D)");
				// get skel voxel
				run("Histogram", "stack");
				Plot.getValues(values, counts);
				RSkelVox=counts[255];
				RSkelVol = LRvoxelVol * RSkelVox;
				close(); // close histogram
				
				////// LEFT BOX //////
				selectWindow(filelistMidline[m]);
				setTool("rectangle");	
				makeRectangle(RStart, 0, RBoxWidth, VolHeight); // x,y,w,h
				run("Duplicate...", "duplicate");
				// quant L vol
				// histogram count black 
				run("Histogram", "stack");
				// [255] is VascVox
				Plot.getValues(values, counts);
				LVascVox=counts[255];			
				LVascVol = LRvoxelVol * LVascVox;
				close(); // close histogram
				// save as tiff
				saveAs("Tiff", LRDir + "LVol_" + filelistMidline[m]);
				// create MIP
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("Jpeg", LRDir + "MAX_LVol_" + filelistMidline[m]);
      			close(); // close MIPs
				// skel vol tiff
				run("Skeletonize (2D/3D)");
				// get skel voxel
				run("Histogram", "stack");
				Plot.getValues(values, counts);
				LSkelVox=counts[255];
				LSkelVol = LRvoxelVol * LSkelVox;
				close(); // close histogram

///// SIMILARITY MEASUREMENTS /////
				s = replace(filelistMidline[m], ".tif", "");     
				run("Label Overlap Measures", "source=" + "RVol_" + s + " target=" + "LVol_" + s + " overlap jaccard dice");
				saveAs("Results",  LRDir + s + "JacDicOv.csv");
				close();
				// write everything into output/results file
				print(f, filelistMidline[m] + "  \t" + "LVascVox" + "\t" + LVascVox + "\t" + "RVascVox" + "\t" + RVascVox + "\t" + "LVascVol" + "\t" + LVascVol + "\t" + "RVascVol" + "\t" + RVascVol + "\t" + "LSkelVox" + "\t" + LSkelVox + "\t" + "RSkelVox" + "\t" + RSkelVox + "\t" + "LSkelVol" + "\t"+ LSkelVol + "\t" + "RSkelVol" + "\t"+ RSkelVol);
				
			}
close();
	}
}

close();
close();


showMessage("Macro is finished."); 
