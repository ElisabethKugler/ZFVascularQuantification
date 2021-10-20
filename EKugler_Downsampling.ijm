/* Macro Downsampling
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
filelist = getFileList(path);

n = roiManager("count");
r=0;

for (i=0; i< filelist.length; i++) { 
	if (endsWith(filelist[i], ".tif")) {
		open(filelist[i]);
		
		
		run("Invert", "stack");
		roiManager("Select", r);
		setBackgroundColor(0, 0, 0);
		run("Clear Outside", "stack");
		setTool("point");
		makePoint(508, 4, "small yellow hybrid");
		run("Invert", "stack");
		r++; // counter for ROI in ROIset
		// get depth aka # slices
		getDimensions(width, height, channels, slices, frames);
		// conversion for # slices after conversion
		DownsampledSlices = round(slices/3.75);

		run("Scale...", "x=- y=- z=1.0 width=512 height=512 depth=" + DownsampledSlices + " interpolation=Bilinear average process create");
		saveAs("Tiff", path + "/512x512/" + filelist[i]);
		setThreshold(123, 255);
		setOption("BlackBackground", false);
		run("Make Binary", "method=Default background=Default");
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("Jpeg", path + "/512x512/" + "MAX_" + filelist[i]);
		run("Close");
		close();
		close();
	}
}

showMessage("Macro is finished"); 