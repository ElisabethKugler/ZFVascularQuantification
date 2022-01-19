/* GUI for zebrafish vasculature analysis
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
 * 		select which steps should be performed and whether parameters need to be changed
 * 		select input folder (path to .czi files)
 * 		select output folder (path for .tiff and MIPs)
 * 		when Macro is done - popup window will say "Macro is finished."
 * contact: kugler.elisabeth@gmail.com

* update 17.10.2020
	* line 397 deselection of pointROI for TH/density/surface
	* minor GUI changes to make it more intuitive
	* closing edge tiff
	* line 563 "TH_template" to "template"
	
* update 26.10.2020 
* 	correct histogram count [allow 0 or 255 to be vascular; whichever is smaller]

* update 02.12.2020
* 	FScale over-write issue; write selected input and output folder into Log;
* 	only print the steps that were selected into log
* 	
* 	more user feedback needed to decide whether to write MIPs into seperate folder;
* 	ToDo Mac vs windows - Mac doesn't show "input folder" etc; 

* update 15.08.2021 (Thanks to Nick Condon - Github comments)
* 	file name input with and without space
*	line 197 - falsely included link to github
*	
* update 19.01.2022 (Thanks to Guy Malkinson - pers comm)
* 	ROI was required for segmentation > included option to run without; 
* 	solved issue with downsampling after segmentation without ROI
* 	512x512 (x,y) downsampling was hard-coded > needs to be made user input
 */
 
// GUI for selection of steps
Dialog.create("ZVQ - Zebrafish Vascular Quantification");

// parameters / choices
choices = newArray("No", "Yes");
singleMulti = newArray("Single-colour", "Dual-Colour");
// czi to tiff conversion
	Dialog.addChoice("(1) Czi to tiff conversion:", choices);
	Dialog.addChoice("Single- or Multiple Channels:", singleMulti);
//	Dialog.addMessage("(Check output Vasc (C=1) and NonVasc (C=0) are correct.)");

// Linear Stack Alignment using SIFT
	Dialog.addChoice("(2) Motion Correction:", choices);

// Tubeness Filter
	Dialog.addChoice("(3) Tubular Filtering for Vessel Enhancement:", choices);
	Dialog.addNumber("Sigma Size [um]:", 10.6848); // empirical measure of optimum pending

// Segmentation and Vascular Volume Measurement
	Dialog.addChoice("(4) Segmentation >> vascular volume, surface, and density:", choices);
	Dialog.addChoice("'RoiSet.zip' * exists:", choices);
	Dialog.addChoice("Do you want to perform downsampling?:", choices)

// Inter-sample registration
	Dialog.addChoice("(5) Inter-sample registration:", choices);
	Dialog.addChoice("Template exists ('template' * should be in folder 'TH'):", choices);

// Intra-sample symmetry
	Dialog.addChoice("(6) Intra-sample symmetry ('RoiSetLine.zip' * should be in the same folder):", choices);
	Dialog.addChoice("Are the data registered (provide 'TemplateLineROI.roi' *)?:", choices);

// Vasculature Quantification
	Dialog.addChoice("(7) Vasculature Quantification >> length, branching points, diameter:", choices);
	Dialog.addChoice("Are the data downsamples?:", choices);
	Dialog.addChoice("Are the data registered (provide 'TemplateROI.roi' *)?:", choices);

Dialog.addMessage("Manuscript: Kugler et al., 2022; Development https://doi.org/10.1242/dev.199720");
Dialog.addMessage("GitHub: https://github.com/ElisabethKugler/ZFVascularQuantification");
Dialog.addMessage("Contact: kugler.elisabeth[at]gmail.com");

Dialog.addMessage("* case-sensitive");

// create dialog
Dialog.show();

///// parse choices and input /////
// czi to tiff conversion
	cziConv = Dialog.getChoice(); 
	Colours = Dialog.getChoice(); 
// Motion Correction
	MC = Dialog.getChoice(); 
	MCScale = 8; 	// Steps per Scale Octave (4-8 recommended)
	imgSize = 1920; // Image size 
	MCDescr = 8; 	// Feature Descriptor Size (4-8 recommended)
	MCCtN = 0.98; 	// Feature closest-to-next ratio (0.92-0.98 recommended)
	MCError = 10; 	// Maximal Alignment Error Consensus Filter (3-10px recommended)
// Tubeness filter
	TF = Dialog.getChoice(); 
	TFScale = Dialog.getNumber();
// Segmentation and Vascular Volume Measurement
	TH = Dialog.getChoice(); 
	THROIs = Dialog.getChoice(); 
	DS = Dialog.getChoice(); 
// Inter-sample registration
	InterSReg = Dialog.getChoice(); 
	regTemplate = Dialog.getChoice(); 
// Intra-sample symmetry
	IntraSym = Dialog.getChoice(); 
	RegForSym = Dialog.getChoice(); 
// Vasculature Quantification
	VascQ = Dialog.getChoice(); 
	downSampled = Dialog.getChoice();
	RegForQuant = Dialog.getChoice();

path = getDirectory("Input Folder");
filelist = getFileList(path);
print("Selected input folder: " + path);

// this is where we set foreground and background colour
setForegroundColor(255, 255, 255); 
setBackgroundColor(255, 255, 255);

// Calling individual steps and parsing parameter input
///// czi to tiff conversion /////
if (cziConv==choices[1]){
	print("Running .czi to .tiff conversion");
 
	VascDir = path + "/VascTiff/"; 
	File.makeDirectory(VascDir);
	print("Output folder: " + VascDir);
	filelistTiff = getFileList(path);
	
	if (Colours==singleMulti[0]) {			//single colour
			for (i=0; i< filelistTiff.length; i++) {   
				if (endsWith(filelistTiff[i], ".czi")) {
			// Import czi with Bioformater
					"Bio-Formats Importer", "open=[" + path + filelist[i] + "] autoscale color_mode=Default split_channels view=Hyperstack stack_order=XYCZT"
			// MIP with Contrast Enhancement
					run("Z Project...", "projection=[Max Intensity]");
			        run("Color Balance...");
			        run("Enhance Contrast", "saturated=0.35");
			        run("Enhance Contrast", "saturated=0.35");
					saveAs("Jpeg", VascDir + "MAX_" + filelistTiff[i]);
			        run("Close");
			// Save as Tiff Stack
					selectWindow(filelistTiff[i]);
					saveAs("Tiff", VascDir + filelistTiff[i]);
					run("Close");
					}
			 }
			
 	}else{									// multiple colours
		NonVascDir = path + "/NonVascTiff/"; // folder for non-vascular output needed
		File.makeDirectory(NonVascDir);
		print("Running double-channel .czi to .tiff conversion");		// need to split channels .. save vascular in correct folder -- add at later time-point		
				for (i=0; i< filelist.length; i++) {   
					if (endsWith(filelist[i], ".czi")) {
						
				// czi import using Bioformats with splitting channels so they can be saved individually (ie vascular and non-vascular)
						run("Bio-Formats Importer", "open=" + path + filelist[i] + " autoscale color_mode=Default split_channels view=Hyperstack stack_order=XYCZT");
				     
				// Save as tiff stack
						selectWindow(filelist[i] + " - C=0"); 			// green
						saveAs("Tiff", NonVascDir + filelist[i]);
						run("Z Project...", "projection=[Max Intensity]");
						run("Color Balance...");
						run("Enhance Contrast", "saturated=0.35");
						run("Enhance Contrast", "saturated=0.35");
						saveAs("Jpeg", path + "MAX_" + filelist[i]);
						//		selectWindow(filelist[i]);
						close();
						selectWindow(filelist[i] + " - C=1"); 			// red
						saveAs("Tiff", VascDir + filelist[i]);
						run("Z Project...", "projection=[Max Intensity]");
						saveAs("Jpeg", path + "MAX_" + filelist[i]);
						close();
				
						close();
						}
				 }
	}

	while(nImages>0){								// close all windows
		selectImage(nImages);
		close();
		}
	
} // end czi-to-tiff conversion

///// LINEAR STACK ALIGNMENT USING SIFT
// aka Motion Correction using Scale Invariant Feature Transformation
if (MC==choices[1]){
	print("Running Motion Correction.");
	// input and output path
	if(cziConv==choices[1]){
		print("Opening images from .tiff folder.");
		path = VascDir;
		filelistMC = getFileList(path); 
	}else{
		filelistMC = getFileList(path); 
		}

	SIFTDir = path + "/SIFT/"; 
	File.makeDirectory(SIFTDir);
	print("Output folder: " + SIFTDir);
	
	for (i=0; i< filelistMC.length; i++) {   
		if (endsWith(filelistMC[i], ".tif")) {
			open(path + filelistMC[i]);
			selectWindow(filelistMC[i]);
	//get image properties
			getDimensions(width, height, channels, slices, frames);
			preChannels = channels;
			preSlices = slices;
			preFrames = frames;
	// get voxel properties
			getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
			prePixelWidth =pixelWidth;
			prePixelHeight = pixelHeight;
			preVoxelDepth = voxelDepth;
	// Intrastack Linear Stack Alignment using SIFT algorithm		
			run("Linear Stack Alignment with SIFT", "initial_gaussian_blur=1.60 steps_per_scale_octave=" + MCScale + " minimum_image_size=64 maximum_image_size=" + imgSize + " feature_descriptor_size=8 feature_descriptor_orientation_bins=" + MCDescr + " closest/next_closest_ratio=" + MCCtN + " maximal_alignment_error=" + MCError + " inlier_ratio=0.05 expected_transformation=Rigid interpolate");	
	// re-set original image values
			run("Properties...", "channels=" + preChannels + " slices=" + preSlices + " frames=" + preFrames +" unit=µm pixel_width=" + prePixelWidth + " pixel_height=" + prePixelHeight + " voxel_depth=" + preVoxelDepth);
	// get MIP of SIFT-aligned stack
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("PNG", SIFTDir + "MAX_SIFTAligned_" + filelistMC[i]);
			run("Close");
	// Save SIFt-aligned stack as tiff stack
			saveAs("Tiff", SIFTDir + "SIFTAligned_" + filelistMC[i]);
			close();
		}
	}
//	close();
	
	while(nImages>0){								// close all windows
		selectImage(nImages);
		close();
		}
} // end SIFT

///// TUBULAR FILTERING aka SATO ENHANCEMENT SECTION
if (TF==choices[1]){
	print("Opening images for vascular enhancement.");
	if(cziConv==choices[1]){    					// yes czi con
			if(MC==choices[1]){						// yes MC
				path = SIFTDir;
				filelistTF = getFileList(path); 
			}else{									// no MC		
				path = VascDir;
				filelistTF = getFileList(path); 
				}
	}else{											// no czi conv
			if(MC==choices[1]){						// yes MC
				path = SIFTDir;
				filelistTF = getFileList(path); 
			}else{									// no MC
				filelistTF = getFileList(path); 
				}
	}
	print("Running Vessel Enhancement.");
	
	// Create output folders
	TFDir = path + "/TF/"; 							// output folder
	File.makeDirectory(TFDir);						// make output folder
	TFMIPDir = path + "/TF/MIP/"; 							// output folder
	File.makeDirectory(TFMIPDir);
	
	print("Output folder for enhancement (TF): " + TFDir);


	// open images for TF
	for (i=0; i< filelistTF.length; i++) {   
		if (endsWith(filelistTF[i], ".tif")) { // input needs to be .tiff files
			open(path + filelistTF[i]);
			selectWindow(filelistTF[i]);
	//get image properties
			getDimensions(width, height, channels, slices, frames);
			preChannels = channels;
			preSlices = slices;
			preFrames = frames;
	// get voxel properties
			getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
			prePixelWidth =pixelWidth;
			prePixelHeight = pixelHeight;
			preVoxelDepth = voxelDepth;
	// Run Plugins > Analyze > Tubeness Filter (Frangi Vessel Enhancement Implementation)
			run("Tubeness", "sigma=" + TFScale); 			// scale size to be changed depending on data
	// re-set original image values
			run("Properties...", "channels=" + preChannels + " slices=" + preSlices + " frames=" + preFrames +" unit=µm pixel_width=" + prePixelWidth + " pixel_height=" + prePixelHeight + " voxel_depth=" + preVoxelDepth);
	// get MIP of vessel enhanced stack and save it
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("PNG", TFMIPDir + "MAX_TF_" + filelistTF[i]);
			run("Close"); 
	// Save enhanced stack as tiff stack
			saveAs("Tiff", TFDir + "TF_" + filelistTF[i]);
			close();
		}
	}

	while(nImages>0){								// close all windows
		selectImage(nImages);
		close();
		}
} // end TF aka Sato enhancement
	
	
///// SEGMENTATION and Vascular Volume Measurement
if (TH==choices[1]){ // yes TH
	print("Running Segmentation and Volume Measurement.");
	if(cziConv==choices[1]){    					// yes czi con
			if(MC==choices[1]){						// yes MC
				if (TF==choices[1]){				// yes TF
					path = TFDir;
					filelistTF = getFileList(path);
				}else{								// no TF
					showMessage("Need pre-processed data for segmentation.");
				}
			}else{									// no MC		
				if (TF==choices[1]){				// yes TF
					path = TFDir;
					filelistTF = getFileList(path); 
				}else{								// no TF
					showMessage("Need pre-processed data for segmentation."); 
				}
			}
	}else{											// no czi conv
			if(MC==choices[1]){						// yes MC
				if (TF==choices[1]){				// yes TF
					path = TFDir;
					filelistTF = getFileList(path);
				}else{								// no TF
					showMessage("Need pre-processed data for segmentation.");
				}
			}else{									// no MC
				if (TF==choices[1]){				// yes TF
					path = TFDir;
					filelistTF = getFileList(path);
				}else{								// no TF
					filelistTF = getFileList(path);					// ONLY segmentation run... get path to files from user
				} 
			}
	}
	THDir = path + "/TH/"; 							// output folder
	File.makeDirectory(THDir);						// make output folder
	print("Output folder segmentation: " + THDir);

	EdgeDir = path + "/Edges/"; 							// output folder
	File.makeDirectory(EdgeDir);
	print("Output folder edges: " + EdgeDir);

	while(nImages>0){								// close all windows
		selectImage(nImages);
		close();
	}

// ROI selection
	if(THROIs==choices[1]){								// ROI set exists
		filelistTH = getFileList(path);					// ROIs in the folder where enhanced (TF) images are; given in initial user prompt
		// create file to write volume measurements
		f = File.open(path + "VascVolResults.txt");

		// ask WHERE RoiSet is; if "RoiSet exists" selected
		pathROIs = getDirectory("Tell me in which folder I can find the 'RoiSet.zip' ...");
		
		roiManager("Open", pathROIs + "RoiSet.zip");
	
		//open ROI set 
		n = roiManager("count");
		r=0; 											// counter for ROIset

		// colourSetting needed for clearing outside for vascular volume quantification
		setForegroundColor(255, 255, 255); 
		setBackgroundColor(255, 255, 255);
		// start processing of files
		for (i=0; i< filelistTH.length; i++) {   
				if (endsWith(filelistTH[i], ".tif")) {
					run("Set Measurements...", "area mean standard min perimeter bounding fit stack redirect=None decimal=3"); // 25062019
					open(path + filelistTH[i]);
			// segmentation	
					selectWindow(filelistTH[i]);
					
			//get image properties
					getDimensions(width, height, channels, slices, frames);
					preWidth = width;
					preHeight = height;
					preChannels = channels;
					preSlices = slices;
					preFrames = frames;
					
					getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
					prePixelWidth = pixelWidth;
					prePixelHeight = pixelHeight;
					preVoxelDepth = voxelDepth;
			
					voxelVol= (prePixelWidth * prePixelHeight * preVoxelDepth);
					
					run("8-bit");
					setSlice(50);
					setAutoThreshold("Default dark");
					run("Threshold...");
					setThreshold(4, 255); // threshold to be changed if other image acquisition settings
					setOption("BlackBackground", false);
					run("Make Binary", "method=Default background=Light");
				
				// re-set original image values
					run("Properties...", "channels=" + preChannels + " slices=" + preSlices + " frames=" + preFrames +" unit=µm pixel_width=" + prePixelWidth + " pixel_height=" + prePixelHeight + " voxel_depth=" + preVoxelDepth);

				//iterate through ROI set 
					roiManager("Select", r);
					run("Measure"); 						// for density
					AreaUm = getResult("Area"); 			// for density
					
				// clear outside
					//run("Invert", "stack");
					roiManager("Select", r);
					setBackgroundColor(255, 255, 255);
					run("Clear Outside", "stack");
					run("RGB Color");
					run("8-bit");
				
				// Save segmented stack as tiff stack
					saveAs("Tiff", THDir + "TH_" + filelistTH[i]);
					run("Invert", "stack");
				// create MIP
					run("Z Project...", "projection=[Max Intensity]");
					run("Invert");
					roiManager("Select", r);
					run("Clear Outside");
					saveAs("Jpeg", THDir + "MAX_TH_" + filelistTH[i]);
					run("Close");	
					run("Invert", "stack");
					
					if (DS==choices[1]){ // perform downsampling here 
						selectWindow("TH_" + filelistTH[i]);
						
						DownSampleDir = path + "/Downsampled/"; 							// output folder
						File.makeDirectory(DownSampleDir);

												// prompt user for what the output height should be
						Dialog.create("Select ... ");
						Dialog.addNumber("Image output height [voxels]:", 512);
						Dialog.show();
						ImageOutSize = Dialog.getNumber(); 
									
						getDimensions(width, height, channels, slices, frames);
						// conversion for # slices after conversion
						if(height <= ImageOutSize){
							print("Image input smaller than the selected output height.");
						}else {
							factor = height / ImageOutSize;
							
							DownsampledWidth = round(width/factor);
							DownsampledSlices = round(slices/factor);
					
							// actual downsampling step
							run("Scale...", "x=- y=- z=1.0 width=" + DownsampledWidth + " height=" + ImageOutSize + " depth=" + DownsampledSlices + " interpolation=Bilinear average process create");
							
							setThreshold(123, 255);
							setOption("BlackBackground", false);
							run("Make Binary", "method=Default background=Default");
							
							saveAs("Tiff", DownSampleDir + "Downsampled_" + filelistTH[i]);
							run("Invert", "stack");
							run("Z Project...", "projection=[Max Intensity]");
							run("Invert");
							saveAs("Jpeg", DownSampleDir + "MAX_Downsampled_" + filelistTH[i]);
							close();
						}
								
					}
	
			        
				//vascular volume [vx] quantification - ROI from MIPs
			        selectWindow("TH_" + filelistTH[i]);
				// histogram count black 
					roiManager("Select", r); // 02112020
					run("Histogram", "stack");
				// [255] is VascVox
					Plot.getValues(values, counts);
					//VascVox=counts[255];
					VascVoxVal1 = counts[0];
					VascVoxVal2 = counts[255];
					if(VascVoxVal1 < VascVoxVal2){
						VascVox = VascVoxVal1;
					}else{
						VascVox = VascVoxVal2;
					}
					
					close(); // histogram			
					VascVol = voxelVol * VascVox;

		// vascular density
					selectWindow("TH_" + filelistTH[i]);
					AreaVx = AreaUm / voxelVol; // change um to vx
					FullVox = AreaVx * slices;				
					dens = FullVox / VascVox; // min 0, max 1

		// vascular surface
					selectWindow("TH_" + filelistTH[i]);
					run("Find Edges", "stack");
					run("Invert", "stack");
					saveAs("Tiff", EdgeDir + "Edges_" + filelistTH[i]);
					run("Invert", "stack");
					run("Z Project...", "projection=[Max Intensity]");
					run("Invert");
					roiManager("Select", r);
					run("Clear Outside");
					saveAs("Jpeg", EdgeDir + "MAX_Edges_" + filelistTH[i]);
			   		run("Close");
			   		selectWindow("Edges_" + filelistTH[i]);    				
			   		run("Invert", "stack");
				// histogram count black 
					run("Histogram", "stack");
				// [255] is VascVox
					Plot.getValues(values, counts);
				//	EdgeVox=counts[255];
					EdgeVoxVal1 = counts[0];
					EdgeVoxVal2 = counts[255];
					if(EdgeVoxVal1 < EdgeVoxVal2){
						EdgeVox = EdgeVoxVal1;
					}else{
						EdgeVox = EdgeVoxVal2;
					}
					
					EdgeVol = voxelVol * EdgeVox;
				//	print(EdgeVox + " " + AreaVx + " " + FullVox + " " + dens); // debug 02112020
					print(f, filelistTH[i] + "  \t" + "VascVox" + "\t" + VascVox + "\t" + "VascVol" + "\t" + VascVol + "\t" + "EdgeVox" + "\t" + EdgeVox + "\t" + "EdgeVol" + "\t" + EdgeVol + "\t" + "density" + "\t"+ dens);
				
					r++; // counter for ROI in ROIset
				close();			// processed tiff
				close();			// processed tiff Oct 2020
				}
			}
		
	}else{											// ROI set does NOT exist
		Dialog.create("Do you want to ... ");
// debug
		THChoices = newArray("Cancel.", "Stop after segmentation.");
		
		Dialog.addChoice("What do you want to do after the segmentation?:", THChoices);
		Dialog.show();
		whatAboutTH = Dialog.getChoice(); 



		if(whatAboutTH==THChoices[0]){	
			print("You chose to cancel.");	
			exit; 
			
		}else{ // stop after segmentation
			print("You chose to stop after segmentation");
			filelistTH = getFileList(path);					// ROIs in the folder where enhanced (TF) images are; given in initial user prompt
			// create file to write volume measurements
			f = File.open(path + "VascVolResults.txt");
	
			// segment
			// colourSetting needed for clearing outside for vascular volume quantification
			setForegroundColor(255, 255, 255); 
			setBackgroundColor(255, 255, 255);
			
			for (i=0; i< filelistTH.length; i++) {   
					if (endsWith(filelistTH[i], ".tif")) {
						open(path + filelistTH[i]);
				// segmentation	
						selectWindow(filelistTH[i]);
				//get image properties
						getDimensions(width, height, channels, slices, frames);
						preWidth = width;
						preHeight = height;
						preChannels = channels;
						preSlices = slices;
						preFrames = frames;
						
						getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
						prePixelWidth = pixelWidth;
						prePixelHeight = pixelHeight;
						preVoxelDepth = voxelDepth;
				
						voxelVol= (prePixelWidth * prePixelHeight * preVoxelDepth);
						
						run("8-bit");
						setSlice(50);
						setAutoThreshold("Default dark");
						run("Threshold...");
						setThreshold(4, 255); // threshold to be changed if other image acquisition settings
						setOption("BlackBackground", false);
						run("Make Binary", "method=Default background=Light");
			
					// re-set original image values
						run("Properties...", "channels=" + preChannels + " slices=" + preSlices + " frames=" + preFrames +" unit=µm pixel_width=" + prePixelWidth + " pixel_height=" + prePixelHeight + " voxel_depth=" + preVoxelDepth);
					// Save segmented stack as tiff stack
						THtiff = "TH_" + filelistTH[i];
						saveAs("Tiff", THDir + "TH_" + filelistTH[i]);
					// create MIP
						run("Z Project...", "projection=[Max Intensity]");
						saveAs("Jpeg", THDir + "MAX_TH_" + filelistTH[i]);

				//vascular volume [vx] quantification - without ROIs
			        selectWindow("TH_" + filelistTH[i]);
				// histogram count black 
					run("Histogram", "stack");
				// [255] is VascVox
					Plot.getValues(values, counts);
					//VascVox=counts[255];
					VascVoxVal1 = counts[0];
					VascVoxVal2 = counts[255];
					if(VascVoxVal1 < VascVoxVal2){
						VascVox = VascVoxVal1;
					}else{
						VascVox = VascVoxVal2;
					}
					
					close(); // histogram			
					VascVol = voxelVol * VascVox;


				if (DS==choices[1]){ // perform downsampling here 
						selectWindow("TH_" + filelistTH[i]);
						run("Duplicate...", "title=forDS duplicate");
						selectWindow("forDS");
						
						DownSampleDir = path + "/Downsampled/"; 							// output folder
						File.makeDirectory(DownSampleDir);

						// prompt user for what the output height should be
						Dialog.create("Select ... ");
						Dialog.addNumber("Image output height [voxels]:", 512);
						Dialog.show();
						ImageOutSize = Dialog.getNumber(); 
									
						getDimensions(width, height, channels, slices, frames);
						// conversion for # slices after conversion
						if(height <= ImageOutSize){
							print("Image input smaller than the selected output height.");
						}else {
							factor = height / ImageOutSize;
							
							DownsampledWidth = round(width/factor);
							DownsampledSlices = round(slices/factor);
					
							// actual downsampling step
							run("Scale...", "x=- y=- z=1.0 width=" + DownsampledWidth + " height=" + ImageOutSize + " depth=" + DownsampledSlices + " interpolation=Bilinear average process create");
							
							setThreshold(123, 255);
							setOption("BlackBackground", false);
							run("Make Binary", "method=Default background=Default");
							
							saveAs("Tiff", DownSampleDir + "Downsampled_" + filelistTH[i]);
							run("Invert", "stack");
							run("Z Project...", "projection=[Max Intensity]");
							run("Invert");
							saveAs("Jpeg", DownSampleDir + "MAX_Downsampled_" + filelistTH[i]);
							close();
						}
							
					}
	

		// vascular density
					selectWindow("TH_" + filelistTH[i]);
					// AreaUm - in this case whole slice size - i.e. no ROI
					AreaUmFull = preWidth * preHeight;
					AreaVx = AreaUmFull / voxelVol; // change um to vx
					FullVox = AreaVx * slices;				
					dens = FullVox / VascVox; // min 0, max 1

		// vascular surface
					selectWindow("TH_" + filelistTH[i]);
					run("Find Edges", "stack");
				//	run("Invert", "stack");
					saveAs("Tiff", EdgeDir + "Edges_" + filelistTH[i]);
					run("Invert", "stack");
					run("Z Project...", "projection=[Max Intensity]");
					run("Invert");

					saveAs("Jpeg", EdgeDir + "MAX_Edges_" + filelistTH[i]);
			   		run("Close");
			   		selectWindow("Edges_" + filelistTH[i]);    				
			   		run("Invert", "stack");
				// histogram count black 
					run("Histogram", "stack");
				// [255] is VascVox
					Plot.getValues(values, counts);
				//	EdgeVox=counts[255];
					EdgeVoxVal1 = counts[0];
					EdgeVoxVal2 = counts[255];
					if(EdgeVoxVal1 < EdgeVoxVal2){
						EdgeVox = EdgeVoxVal1;
					}else{
						EdgeVox = EdgeVoxVal2;
					}
					
					EdgeVol = voxelVol * EdgeVox;
				//	print(EdgeVox + " " + AreaVx + " " + FullVox + " " + dens); // debug 02112020
					print(f, filelistTH[i] + "  \t" + "VascVox" + "\t" + VascVox + "\t" + "VascVol" + "\t" + VascVol + "\t" + "EdgeVox" + "\t" + EdgeVox + "\t" + "EdgeVol" + "\t" + EdgeVol + "\t" + "density" + "\t"+ dens);
				
				close();			// processed tiff
				close();			// processed tiff Oct 2020

						
						}		     
					}
				

			} // else stop segm
		} // else ROI doesnt exist
	
	while(nImages>0){								// close all windows
		selectImage(nImages);
		close();
		}
		
} // end segmentation

///// Inter-sample registration
if (InterSReg==choices[1]){

	if (regTemplate==choices[1]){ // template exists
		// get template 
		path = THDir;
		filelistReg = getFileList(path); 

		open(path + "template.tif"); // Oct 2020
		template=getTitle();
		getDimensions(width, height, channels, slices, frames);
		preSlicesTemplate = slices;
	}else { // template does not exist
		// prompt for template selection
		
		//filelistReg = getFileList(path);
		// FileNameReg = File.openDialog("Choose a template file");
  		// duplicate and rename the selected file and save as "template"
		open();
		// run("Duplicate...", "duplicate");
		saveAs("Tiff", path + "template.tif");
		filelistReg = getFileList(path); 
		template=getTitle();
		getDimensions(width, height, channels, slices, frames);
		preSlicesTemplate = slices;
	}

	print("Running Inter-Sample Registration.");


	RegDir = path + "/Reg/"; 								// output folder
	File.makeDirectory(RegDir);								// make output folder
	print("Output folder registration: " + RegDir);
	

	for (i=0; i< filelistReg.length; i++) {   
			if (endsWith(filelistReg[i], ".tif")){
				open(path + filelistReg[i]);
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
				
				// measure similarity before registration
				
				repTemplate = replace(template, ".tif", "");
				repMoving = replace(filelistReg[i], ".tif", "");     
				
				run("Label Overlap Measures", "source=" + repMoving + " target=" + repTemplate + " overlap jaccard dice");
				saveAs("Results",  RegDir + repMoving + "_Unregistered_JacDicOv.csv");

				// registration
				selectWindow(filelistReg[i]);
				run("Rigid Registration", "initialtransform=[] n=1 tolerance=20 level=7 stoplevel=4 materialcenterandbbox=[] showtransformed template=" + template + " measure=Euclidean");
				selectWindow("transformed");
				run("Invert", "stack");
				//setThreshold(0, 132);
				setOption("BlackBackground", false);
				run("Make Binary", "method=Default background=Default");
				// set image/voxel properties
				run("Properties...", "channels=" + preChannels + " slices=" + preSlicesTemplate + " frames=" + preFrames + " unit=" + preUnit + " pixel_width=" + prePixelWidth + " pixel_height=" + prePixelHeight + " voxel_depth=" + preVoxelDepth);
				saveAs("Tiff", RegDir + "InterSReg_" + filelistReg[i]);
				
				repMovingAfter = replace("InterSReg_" + filelistReg[i], ".tif", "");    
			 
				run("Label Overlap Measures", "source=" + repMovingAfter + " target=" + repTemplate + " overlap jaccard dice");
				saveAs("Results",  RegDir + repMovingAfter + "_Registered_JacDicOv.csv");
				
				// create MIP
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("Jpeg", RegDir + "MAX_InterSReg_" + filelistReg[i]);
				close();
				close();
			}
	}
run("Close All");
}

///// Intra-sample symmetry
if (IntraSym==choices[1]){
run("Set Measurements...", "area mean standard min perimeter bounding fit stack redirect=None decimal=3");
	
// WHAT IF registered before... can we skip the bit of line ROIs rotation and midline ROI for all of them
// just get the one for the initial template? 
	if(TH==choices[1]){					// segmentation was selected - we can use this path
		if(InterSReg==choices[1]){		// inter-sample registration
			path = RegDir;
			filelistSym = getFileList(path); 
		}else{							// NO inter-sample registration
			path = THDir;
			filelistSym = getFileList(path); 
		}
	}else{								// segmentation was not selected; need to prompt for path to find these files 
		filelistSym = getFileList(path);
	}

	
	print("Running Intra-Sample Symmetry Assessment.");

	SymDir = path + "/Sym/"; 							// output folder
	File.makeDirectory(SymDir);
	print("Output folder symmetry: " + SymDir);

	
	// create file to write quantification outputs
	f = File.open(path + "IntraSampleSymmetryResults.txt");
	
	//open ROI set 
//	roiManager("Open", path + "RoiSetLine.zip");
		pathROIs = getDirectory("Tell me in which folder I can find the 'RoiSetLine.zip' ...");
		if(RegForSym==choices[0]){ // samples not registered	
			roiManager("Open", pathROIs + "RoiSetLine.zip");
		}else { // samples registered
			roiManager("Open", pathROIs + "TemplateLineROI.roi");
		}

	n = roiManager("count");
	t=0; // counter for RoiSetLine

	// intra-sample symmetry
	///// ROTATION /////
	for (i=0; i< filelistSym.length; i++) {   
		if (endsWith(filelistSym[i], ".tif")) {
			run("Set Measurements...", "area mean standard min perimeter bounding fit stack redirect=None decimal=3"); // 25062019
			open(path + filelistSym[i]);
			selectWindow(filelistSym[i]);
	
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
		
			roiManager("Select", t);
			
			if(RegForSym==choices[0]){ // samples not registered
				t++; // counter for ROI in ROIset
			}
			
			run("Measure"); // measure the angle of line ROI for rotation
	
			MeasAngle = getResult("Angle"); // measured angle from LineROI
			
			//debug
			print(MeasAngle);
			
			if (MeasAngle<0){
				betrag = abs(MeasAngle);
				rot = -(90 + betrag);
			}else if (MeasAngle>0){ 
				betrag = abs(MeasAngle);
				rot = -(90 - betrag);
			}else{
				rot=90;
			}


			//debug
			print(rot);
			setSlice(50);
			run("Invert", "stack");
			run("Rotate... ", "angle=" + rot + " grid=1 interpolation=Bilinear stack"); // rotate image based on line ROI from MIPs
			
	// BINARIZE	 images (rotation does change it)
			//setThreshold(128, 255);
			setOption("BlackBackground", false);
			run("Make Binary", "method=Default background=Light");
		//	run("Invert", "stack");
	// Save segmented stack as tiff stack
			saveAs("Tiff", SymDir + "Rot_" + filelistSym[i]);
	// create MIP
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("Jpeg", SymDir + "MAX_rot_" + filelistSym[i]);
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
waitForUser("Draw line ROI along midline of rotated images (need to be in order). \n 'Add' to ROI manager. \n Press 'ok'.");
n=0; // counter for ROIsetMiddle

// open rotated images
filelistMidline = getFileList(SymDir);

LRDir = path + "/LRVol/"; 
File.makeDirectory(LRDir);


for (m=0; m< filelistMidline.length; m++) {   
	if (endsWith(filelistMidline[m], ".tif")) {
		run("Set Measurements...", "area mean standard min perimeter bounding fit stack redirect=None decimal=3"); // 25062019
			open(SymDir + filelistMidline[m]);
			selectWindow(filelistMidline[m]);
	
	//get image properties for L and R box dimensions to be drawn
			getDimensions(width, height, channels, slices, frames);
			VolWidth = width;
			HalfWidth = width / 2;

			//print(HalfWidth);
			VolHeight = height;

			getPixelSize(unit,pixelWidth,pixelHeight,voxelDepth);
			LRPixelWidth = pixelWidth;
			LRprePixelHeight = pixelHeight;
			LRpreVoxelDepth = voxelDepth;

			LRvoxelVol= (prePixelWidth * prePixelHeight * preVoxelDepth);

			roiManager("Select", n);
			if(RegForSym==choices[0]){ // samples not registered
				n++; // counter for ROI in ROIsetMiddle
			}
			run("Measure"); // measure the angle of line ROI for splitting L R box

			MeasX = getResult("BX"); // measured X-position from LineROI for L and R box
			MeasXvx = MeasX / LRPixelWidth;
						
			RBoxWidth = width - MeasXvx;
			RStart = width - (RBoxWidth * 2);
			
	// box can only be that big.. L/R smaller/bigger - take smaller one and extend to both sides.. 
			if(MeasXvx<HalfWidth){ // sample is more to the left -> left side taken for box size
				setTool("rectangle");
				makeRectangle(0, 0, MeasXvx, VolHeight); // x,y,w,h
				////// LEFT BOX ////// 
				run("Duplicate...", "duplicate");
				// quant L vol
				// histogram count black 
				run("Histogram", "stack");
				// [255] is VascVox
				Plot.getValues(values, counts);
			//	LVascVox=counts[255];			
				LVascVoxVal1 = counts[0];
				LVascVoxVal2 = counts[255];
				if(LVascVoxVal1 < LVascVoxVal2){
					LVascVox = LVascVoxVal1;
				}else{
					LVascVox = LVascVoxVal2;
				}
						

			
				LVascVol = LRvoxelVol * LVascVox;
				close(); // close histogram
				// save as tiff
				saveAs("Tiff", LRDir + "LVol_" + filelistMidline[m]);
				// create MIP
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("Jpeg", LRDir + "MAX_LVol_" + filelistMidline[m]);
      			close(); // close MIPs
				
				
				//////  RIGHT BOX ////// 
				selectWindow(filelistMidline[m]);
				// make right box
				setTool("rectangle");
				makeRectangle(MeasXvx, 0, MeasXvx, VolHeight); // x,y,w,h
				run("Duplicate...", "duplicate");
				// TRANSFORMATION
				run("Flip Horizontally", "stack");
				// quant R vol
				// histogram count black 
				run("Histogram", "stack");
				// [255] is VascVox
				Plot.getValues(values, counts);
			//	RVascVox=counts[255];			
				RVascVoxVal1 = counts[0];
				RVascVoxVal2 = counts[255];
				if(RVascVoxVal1 < RVascVoxVal2){
					RVascVox = RVascVoxVal1;
				}else{
					RVascVox = RVascVoxVal2;
				}
					
			
				RVascVol = LRvoxelVol * RVascVox;
				close(); // close histogram
				// save as tiff		
				saveAs("Tiff", LRDir + "RVol_" + filelistMidline[m]);
				// create MIP
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("Jpeg", LRDir + "MAX_RVol_" + filelistMidline[m]);
      			close(); // close MIPs

///// SIMILARITY MEASUREMENTS /////
				// get them
				rep = replace(filelistMidline[m], ".tif", "");     
				run("Label Overlap Measures", "source=" + "RVol_" + rep + " target=" + "LVol_" + rep + " overlap jaccard dice");
				saveAs("Results",  LRDir + rep + "JacDicOv.csv");
				//close();

///// Skeletonization: network length
// left box
				selectWindow("LVol_" + filelistMidline[m]);
				// skel vol tiff
				run("Skeletonize (2D/3D)");
				// get skel voxel
				run("Histogram", "stack");
				Plot.getValues(values, counts);
				//LSkelVox=counts[255];
				LSkelVoxVal1 = counts[0];
				LSkelVoxVal2 = counts[255];
					if(LSkelVoxVal1 < LSkelVoxVal2){
						LSkelVox = LSkelVoxVal1;
					}else{
						LSkelVox = LSkelVoxVal2;
					}
					
				
				LSkelVol = LRvoxelVol * LSkelVox;
				close(); // close histogram
				
// right box
				selectWindow("RVol_" + filelistMidline[m]);
					// skel vol tiff
				run("Skeletonize (2D/3D)");
				// get skel voxel
				run("Histogram", "stack");
				Plot.getValues(values, counts);
				//RSkelVox=counts[255];
				RSkelVoxVal1 = counts[0];
				RSkelVoxVal2 = counts[255];
					if(RSkelVoxVal1 < RSkelVoxVal2){
						RSkelVox = RSkelVoxVal1;
					}else{
						RSkelVox = RSkelVoxVal2;
					}
				
				RSkelVol = LRvoxelVol * RSkelVox;
				close(); // close histogram
							
				// write everything into output/results file
				print(f, filelistMidline[m] + "  \t" + "LVascVox" + "\t" + LVascVox + "\t" + "RVascVox" + "\t" + RVascVox + "\t" + "LVascVol" + "\t" + LVascVol + "\t" + "RVascVol" + "\t" + RVascVol + "\t" + "LSkelVox" + "\t" + LSkelVox + "\t" + "RSkelVox" + "\t" + RSkelVox + "\t" + "LSkelVol" + "\t"+ LSkelVol + "\t" + "RSkelVol" + "\t"+ RSkelVol);
				
			}
			else{ // sample is more to the right -> right side taken for box size
				//////  RIGHT BOX ////// 
				selectWindow(filelistMidline[m]);
				setTool("rectangle");	
				makeRectangle(MeasXvx, 0, RBoxWidth, VolHeight); // x,y,w,h
				run("Duplicate...", "duplicate");
				// quant R vol
				// TRANSFORMATION
				run("Flip Horizontally", "stack");
				// histogram count black 
				run("Histogram", "stack");
				// [255] is VascVox
				Plot.getValues(values, counts);
				// RVascVox=counts[255];			
				RVascVoxVal1 = counts[0];
				RVascVoxVal2 = counts[255];
				if(RVascVoxVal1 < RVascVoxVal2){
					RVascVox = RVascVoxVal1;
				}else{
					RVascVox = RVascVoxVal2;
				}
				
				RVascVol = LRvoxelVol * RVascVox;
				close(); // close histogram
				// save as tiff		
				saveAs("Tiff", LRDir + "RVol_" + filelistMidline[m]);
				// create MIP
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("Jpeg", LRDir + "MAX_RVol_" + filelistMidline[m]);
      			close(); // close MIPs
			
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
				//LVascVox=counts[255];	
				LVascVoxVal1 = counts[0];
				LVascVoxVal2 = counts[255];
					if(LVascVoxVal1 < LVascVoxVal2){
						LVascVox = LVascVoxVal1;
					}else{
						LVascVox = LVascVoxVal2;
					}
						
				LVascVol = LRvoxelVol * LVascVox;
				close(); // close histogram
				// save as tiff
				saveAs("Tiff", LRDir + "LVol_" + filelistMidline[m]);
				// create MIP
				run("Z Project...", "projection=[Max Intensity]");
				saveAs("Jpeg", LRDir + "MAX_LVol_" + filelistMidline[m]);
      			close(); // close MIPs

///// SIMILARITY MEASUREMENTS /////
				rep = replace(filelistMidline[m], ".tif", "");     
				run("Label Overlap Measures", "source=" + "RVol_" + rep + " target=" + "LVol_" + rep + " overlap jaccard dice");
				saveAs("Results",  LRDir + rep + "JacDicOv.csv");
				//close();


///// Skeletonization: network length
// left box
				selectWindow("LVol_" + filelistMidline[m]);
				// skel vol tiff
				run("Skeletonize (2D/3D)");
				// get skel voxel
				run("Histogram", "stack");
				Plot.getValues(values, counts);
				//LSkelVox=counts[255];
				LSkelVoxVal1 = counts[0];
				LSkelVoxVal2 = counts[255];
					if(LSkelVoxVal1 < LSkelVoxVal2){
						LSkelVox = LSkelVoxVal1;
					}else{
						LSkelVox = LSkelVoxVal2;
					}

				
				LSkelVol = LRvoxelVol * LSkelVox;
				close(); // close histogram
				
// right box
				selectWindow("RVol_" + filelistMidline[m]);
					// skel vol tiff
				run("Skeletonize (2D/3D)");
				// get skel voxel
				run("Histogram", "stack");
				Plot.getValues(values, counts);
				//RSkelVox=counts[255];
				RSkelVoxVal1 = counts[0];
				RSkelVoxVal2 = counts[255];
					if(RSkelVoxVal1 < RSkelVoxVal2){
						RSkelVox = RSkelVoxVal1;
					}else{
						RSkelVox = RSkelVoxVal2;
					}
				RSkelVol = LRvoxelVol * RSkelVox;
				close(); // close histogram
				
				// write everything into output/results file
				print(f, filelistMidline[m] + "  \t" + "LVascVox" + "\t" + LVascVox + "\t" + "RVascVox" + "\t" + RVascVox + "\t" + "LVascVol" + "\t" + LVascVol + "\t" + "RVascVol" + "\t" + RVascVol + "\t" + "LSkelVox" + "\t" + LSkelVox + "\t" + "RSkelVox" + "\t" + RSkelVox + "\t" + "LSkelVol" + "\t"+ LSkelVol + "\t" + "RSkelVol" + "\t"+ RSkelVol);
				
			}
close();
	}
}

	while(nImages>0){								// close all windows
		selectImage(nImages);
		close();
	}

// ----------------------------------------------
while(nImages>0){								// close all windows
	selectImage(nImages);
	close();
	}
		
}
	
///// Vasculature Quantification
if (VascQ==choices[1]){
	print("Running Vascular Quantification.");
// folder input selection
	if (TH==choices[1]) {
		pathQuant = THDir; // if segmentation was not seleced, take input from there
	}else{
		pathQuant = path;
	}
	filelistQuant = getFileList(pathQuant);
	analysisDir = pathQuant; 
	print("Output folder qauntification: " + analysisDir);
	
///// Downsampling /////
	if(downSampled==choices[0]){ // data are not down-sampled 
		// -> run downsampling
		DownSampleDir = path + "/Downsampled/"; 							// output folder
		File.makeDirectory(DownSampleDir);
		// prompt to open ROIset 
		pathROIs = getDirectory("Tell me in which folder I can find the ROIset for down-sampling...");
		
			if(RegForQuant==choices[0]){
					roiManager("Open", pathROIs + "RoiSet.zip");
			}else{
				roiManager("Open", pathROIs + "TemplateROI.roi");
			}
		
		n = roiManager("count");
		r=0;

		for (d=0; d< filelistQuant.length; d++) { 
			if (endsWith(filelistQuant[d], ".tif")) {
				open(filelistQuant[d]);
					run("Invert", "stack");
					setSlice(50);
					roiManager("Select", r);
					setBackgroundColor(0, 0, 0);
					run("Clear Outside", "stack");
					run("RGB Color");
					run("8-bit");
					setTool("point");
					makePoint(508, 4, "small yellow hybrid");
					run("Invert", "stack");

					if(RegForQuant==choices[0]){ // data are not registered 
						r++; // counter for ROI in ROIset
					}
					
					// get depth aka # slices
					getDimensions(width, height, channels, slices, frames);
					// conversion for # slices after conversion

					// prompt user for what the output height should be
					Dialog.create("Select ... ");
					Dialog.addNumber("Image output height [voxels]:", 512);
					Dialog.show();
					ImageOutSize = Dialog.getNumber(); 
									
					getDimensions(width, height, channels, slices, frames);
					// conversion for # slices after conversion
					if(height <= ImageOutSize){
							print("Image input smaller than the selected output height.");
						}else {
							factor = height / ImageOutSize;
							
							DownsampledWidth = round(width/factor);
							DownsampledSlices = round(slices/factor);
					
							// actual downsampling step
							run("Scale...", "x=- y=- z=1.0 width=" + DownsampledWidth + " height=" + ImageOutSize + " depth=" + DownsampledSlices + " interpolation=Bilinear average process create");
							
							setThreshold(123, 255);
							setOption("BlackBackground", false);
							run("Make Binary", "method=Default background=Default");
							
							saveAs("Tiff", DownSampleDir + "Downsampled_" + filelistTH[i]);
							run("Invert", "stack");
							run("Z Project...", "projection=[Max Intensity]");
							run("Invert");
							saveAs("Jpeg", DownSampleDir + "MAX_Downsampled_" + filelistTH[i]);
							close();
						}

			}
		}
}

///// Quantification /////
// data are down-sampled -> run analysis
// check input folders with and without downsampling
		if(downSampled==choices[0]){ // data are not down-sampled 	
			pathQuant = DownSampleDir;
			}else{
			pathQuant = path;
			}

	
	filelistQuant = getFileList(pathQuant);
	analysisDir = pathQuant;
	
	filelistAnalysis = getFileList(analysisDir); // input

	AnalysisOutputDir = analysisDir + "/analysis/"; // output folder
	File.makeDirectory(AnalysisOutputDir);

	// create file to write quantification outputs
	q = File.open(AnalysisOutputDir + "DiametersAndNetworkLength.txt");

	// diameter / radius
	for (a=0; a< filelistAnalysis.length; a++) {   
		if (endsWith(filelistAnalysis[a], ".tif")) {
			open(pathQuant + filelistAnalysis[a]);
			selectWindow(filelistAnalysis[a]); // later to be changed to iterate through all and embed into code GUI.ijm
			setSlice(50);
			setOption("BlackBackground", false);
			run("Make Binary", "method=Default background=Light");
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
			saveAs("Tiff", AnalysisOutputDir + "MAX_" + short + "_EDT"); // save 2D distance map
			
			///// skeletonize original tresholded image in 3D /////
			selectWindow("ForSkel"); // duplicate from original thresholded image; to skeletonize in 3D
		//	run("Make Binary", "method=Default background=Default"); //TAKE OUT
			run("Skeletonize (2D/3D)");
			rename("Skel_");

			// network length / skeleton voxels
			run("Histogram", "stack");
			// [255] is VascVox
			Plot.getValues(values, counts);
			//vascVox=counts[255];
			VoxVal1 = counts[0];
			VoxVal2 = counts[255];
				if(VoxVal1 < VoxVal2){
					vascVox = VoxVal1;
				}else{
					vascVox = VoxVal2;
				}

			
			close(); // histogram

		//	run("Summarize Skeleton");
		//	selectWindow("Skeleton Stats");
		//	saveAs("Results", AnalysisOutputDir + meep + "Skeleton Stats.csv");
			
			selectWindow("Skel_");
			run("Duplicate...", "title=ForEDMSkel duplicate");
			
			///// save skeletonized image /////
			saveAs("Tiff", AnalysisOutputDir + "Skel_" + short);  // stack
			run("Z Project...", "projection=[Max Intensity]");
			run("Skeletonize (2D/3D)"); // remove spurious branches in 2D 
			saveAs("Tiff", AnalysisOutputDir + "MAX_Skel_" + short); // MIP
			
			///// merge 2D skel and 2D distance map for diameter measurements /////
			imageCalculator("AND create", "MAX_" + short + "_EDT.tif","MAX_Skel_" + meep);
			run("Fire");
			saveAs("Tiff", AnalysisOutputDir + "MAX_LUTFire_EDM_Skel_" + short);  // stack
			rename("LUTFire_EDM");

			///// quantify diameters /////
			/////// average diameter for whole 2D image - iterate through whole image in (x,y)
				counter = 0;
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
			
					average = (total/counter); // 
					saveAs("Tiff", AnalysisOutputDir + "MAX_Dia_" + short);  // stack

				print(q , filelistAnalysis[a] + "  \t" + average + "  \t" + vascVox);
			///// need to close everything
					run("Close All");
			
			}
	
			///// need to close everything
					run("Close All");
			
		}

///// summarize skeleton to get # junctions information
		skelDir = getFileList(AnalysisOutputDir);
			for (s=0; s< skelDir.length; s++) {   
				if ( startsWith(skelDir[s], "Skel_")) {
					open(AnalysisOutputDir + skelDir[s]);
					// segmentation	
					selectWindow(skelDir[s]);
					run("Summarize Skeleton");
				}
			}
			saveAs("Results", AnalysisOutputDir + "Skeleton Stats.csv");
			run("Close All");
	
	
}

showMessage("Macro is finished"); 
