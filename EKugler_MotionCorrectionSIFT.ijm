/* Macro for motion correction using Scale Invariant Feature Transform (SIFT)
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

// Intrastack Linear Stack Alignment using SIFT algorithm		
		run("Linear Stack Alignment with SIFT", "initial_gaussian_blur=1.60 steps_per_scale_octave=5 minimum_image_size=64 maximum_image_size=1920 feature_descriptor_size=8 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.95 maximal_alignment_error=5 inlier_ratio=0.05 expected_transformation=Rigid interpolate");

// re-set original image values
		run("Properties...", "channels=" + preChannels + " slices=" + preSlices + " frames=" + preFrames +" unit=µm pixel_width=" + prePixelWidth + " pixel_height=" + prePixelHeight + " voxel_depth=" + preVoxelDepth);

// get MIP of SIFT-aligned stack
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("PNG", outputFolder + "SIFTAligned_" + filelist[i]);
		run("Close");

// Save SIFt-aligned stack as tiff stack
		saveAs("Tiff", outputFolder + "SIFTAligned_" + filelist[i]);
		run("Close");
	}
}
close();

showMessage("Macro is finished."); 