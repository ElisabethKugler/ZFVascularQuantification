/*  Macro for .czi to .tiff conversion and automatic MIP creation
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

 * 
 * USE:
 * 		hit run
 * 		select input folder (path to .czi files)
 * 		select output folder (path for .tiff and MIPs)
 * 		when Macro is done - popup window will say "Macro is finished."
 * 	contact: kugler.elisabeth@gmail.com
 */

// input and output path
path = getDirectory("Input Folder");
filelist = getFileList(path); 
VascDir = path + "/VascTiff/"; 
File.makeDirectory(VascDir);


for (i=0; i< filelist.length; i++) {   
	if (endsWith(filelist[i], ".czi")) {
// Import czi with Bioformater
		run("Bio-Formats Importer", "open=" + path + filelist[i] + " autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
		
// MIP with Contrast Enhancement
		run("Z Project...", "projection=[Max Intensity]");
        run("Color Balance...");
        run("Enhance Contrast", "saturated=0.35");
//		run("Apply LUT");
//		resetMinAndMax();
		saveAs("Jpeg", VascDir + "MAX_" + filelist[i]);
        run("Close");
 	   
// Save as Tiff Stack
		selectWindow(filelist[i]);
		saveAs("Tiff", VascDir + filelist[i]);
		run("Close");
		}
 }
close();

showMessage("Macro is finished."); 