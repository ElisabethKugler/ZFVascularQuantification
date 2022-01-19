# ZVQ - Zebrafish Vascular Quantification
Image analysis pipeline to perform 3D quantification of the total or regional zebrafish brain vasculature using the image analysis software Fiji (https://fiji.sc/).

Publication: Elisabeth C Kugler, James Frost, Vishmi Silva, Karen C Plant, Karishma Chhabria, Timothy James Chico, and Paul Armitage, Development dev.199720. https://doi.org/10.1242/dev.199720 (Jan 2022)

I2K Tutorial: https://www.youtube.com/watch?v=Hb3tDVJ4KXU&t=0s

Example data: 10.5281/zenodo.4108660; https://zenodo.org/record/4108660#.X47XU9BKizc

DOI: https://doi.org/10.5281/zenodo.3978278

Queries: kugler.elisabeth[at]gmail.com

Pre-print https://www.biorxiv.org/content/10.1101/2020.08.06.239905v2 \
"3D quantification of zebrafish cerebrovascular architecture by automated image analysis of light sheet fluorescence microscopy datasets" by
Elisabeth C Kugler, James Frost, Vishmi Silva, Karen C Plant, Karishma Chhabria, Timothy James Chico, and Paul Armitage; doi: https://doi.org/10.1101/2020.08.06.239905

Step 1: .czi to .tiff conversion \
Step 2: Motion Correction \
Step 3: Tubular filtering, i.e. vessel enhancement \
Step 4: Segmentation and vascular volume measurements \
Step 5: Inter-sample registration \
Step 6: Intra-sample symmetry quantification \
Step 7: Quantification of vascular properties (i.e. volume, surface voxels, density, branching points, network length, network radius, and network complexity)

Optimized for the transgenic fluorescent reporter line Tg(kdrl:HRAS-mCherry).

REFERENCES <br/>
[Image understanding and segmentation] <br/>
(1) Kugler, Chico, Armitage (2018) Image Analysis in Light Sheet Fluorescence Microscopy Images of Transgenic Zebrafish Vascular Development. In Nixon M., Mahmoodi S., Zwiggelaar R. (eds) Medical Image Understanding and Analysis. MIUA 2018.; Springer, Cham, 2018; Vol. Communications in Computer and Information Science, vol 894, pp. 343–353.
https://link.springer.com/chapter/10.1007/978-3-319-95921-4_32

(2) Kugler, Plant, Chico and Armitage (2019), Enhancement and Segmentation Workflow for the Developing Zebrafish Vasculature, J. Imaging 2019, 5(1), 14; https://doi.org/10.3390/jimaging5010014

(3) Kugler, Chico, and Armitage. Validating Segmentation of the Zebraﬁsh Vasculature. In Yalin Zheng, Bryan M. Williams, and Ke Chen, editors, Medical Image Understanding and Analysis, Communications in Computer and Information Science, pages 270–281, Cham, 2020. Springer International Publishing. ISBN 9783-030-39343-4. https://link.springer.com/chapter/10.1007/978-3-030-39343-4_23

(4) Preprint: Elisabeth C. Kugler, Andrik Rampun,  Timothy J.A. Chico, Paul A. Armitage, Segmentation of the Zebrafish Brain Vasculature from Light Sheet Fluorescence Microscopy Datasets, doi: https://doi.org/10.1101/2020.07.21.213843 (https://www.biorxiv.org/content/10.1101/2020.07.21.213843v1)

[Documentation/papers of used Plugins and mathematical justifications] <br/>
(1) SIFT - Linear Stack Alignment:  
https://imagej.net/Linear_Stack_Alignment_with_SIFT
Lowe, David G. (2004) Distinctive Image Features from Scale-Invariant Keypoints, International Journal of Computer Vision. 60 (2): 91–110. CiteSeerX 10.1.1.73.2924.

(2) Sato Vessel Enhancement Filter:
https://www.longair.net/edinburgh/imagej/tubeness/
Sato, Nakajima, Atsumi, Koller, Gerig, Yoshida and Kikinis (1997) 3D multi-scale line filter for segmentation and visualization of curvilinear structures in medical images, International Conference on Computer Vision, Virtual Reality, and Robotics in Medicine, CVRMed 1997, MRCAS 1997: CVRMed-MRCAS'97 pp 213-222.

(3) Otsu Thresholding: https://imagej.net/Auto_Threshold
N Otsu. A threshold selection method from gray-level histograms. Trans. Sys.Man., 9(1):62–66, 1979.

(4) Vascular Surface: https://imagej.nih.gov/ij/docs/menus/process.html#find
Canny, J., A Computational Approach To Edge Detection, IEEE Transactions on Pattern Analysis and Machine Intelligence, 8(6):679–698, 1986.

(5) 3D skeletonization: https://imagej.net/Skeletonize3D
T. C. Lee, R. L. Kashyap, and C. N. Chu. Building Skeleton Models via 3-D Medial Surface Axis Thinning Algorithms. CVGIP: Graphical Models and Image Processing, 56(6):462–478, November 1994.

(6) Euclidean Distance Map (EDM): https://imagej.net/Distance_Transform_3D
Gunilla Borgefors. On Digital Distance Transforms in Three Dimensions. Computer Vision and Image Understanding, 64(3):368–376, November 1996. ISSN 1077-3142. doi: 10.1006/cviu.1996.0065. URL http://www.sciencedirect.com/science/article/ pii/S107731429690065X.

[Vessel nomenclature] <br/>
(1) Isogai, Horiguchi, and Weinstein (2001) The Vascular Anatomy of the Developing Zebrafish: An Atlas of Embryonic and Early Larval, Development Developmental Biology 230, 278–301. 
https://pdfs.semanticscholar.org/59e9/3cb024a2c570da5be958ceb5949c87bab3df.pdf


