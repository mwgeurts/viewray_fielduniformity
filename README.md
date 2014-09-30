ViewRay Field Uniformity-Timing Check
===========

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2014, University of Wisconsin Board of Regents

FieldUniformity.m loads Monte Carlo treatment planning data from the ViewRay Treatment Planning System and compares it to measured Sun Nuclear IC Profiler data to compare the field uniformity (field size, flatness, symmetry, etc) and evaluate the source positioning and timing accuracy.  Because the ViewRay system uses Cobalt-60, variations flatness and symmetry are the result of changes in source shuttling. Beam flatness is computed as the difference in maximum and minimum signal divided by the sum of the maximum and minimum over the central 80% of the field defined by the Full Width Half Maximum (FWHM) along the MLC X and Y central axes. Beam symmetry is computed as the difference in area under the central 80% profile (MLC X or MLC Y) to the right and left of field center, divided by twice the sum of the right and left areas. 

When measuring data with IC Profiler, it is assumed that the profiler will be positioned with the electronics pointing toward IEC+Z for a 90 degree gantry angle. The Monte Carlo data assumes that a symmetric 27.3 cm x 27.3 cm is delivered through the front of the IC Profiler.  The IC Profiler data must be saved in Multi-Frame format.

The following steps illustrate how to acquire and process 90 degree measurements.  Similar measurements may be acquired at different gantry angles using the same reference profile so long as the IC Profiler is set up the same way relative to the beam angle.  

## Set up the IC Profiler

1. Attach the SNC IC Profiler to the IC Profiler jig
2. Connect the IC Profiler to the Physics Workstation using the designated cable
3. Launch the SNC Profiler software on the Physics Workstation
4. Select the most recent Dose calibration from the dropdown box
5. Select the most recent array Calibration from the dropdown box
6. Verify the mode is continuous by clicking the Control menu

## Orient the IC Profiler in the Sagittal Position

1. Place the SNC Profiler jig on the couch at virtual isocenter and orient the jig in the Sagittal orientation, as shown
  1. The top of the profiler will be facing the IEC+X axis
  2. The electronics will be on the facing upwards (IEC+Y axis)
  3. Place an aluminum level on the front face of the IC Profiler as shown
  4. Verify the profiler is parallel with the IEC Sagittal plane
  5. Use the leveling feet on the jig to adjust if necessary
  6. Laterally adjust the jig until the overhead IEC X laser is aligned to the front face of the IC Profiler
  7. Record the current couch position
  8. Use the Couch Control Panel to move the couch and IC Profiler +0.9 cm in the IEC+X direction
  9. The detector plane of the IC Profiler should now be at isocenter
  10. Vertically and Longitudinally align the IC Profiler to the crosshairs using the wall IEC Y and IEC Z laser
  11. Press the ENABLE and ISO buttons on the Couch Control Panel to move the couch from virtual to mechanical isocenter
2. On the ViewRay TPDS, select Tools > QA Procedure and select the Calibration tab
3. Select an arbitrary phantom and click Load Phantom
4. Under Beam Setup and Controls, select Head 3
5. Set Delivery Angle to 90 degrees
6. Under MLC Setup, set the following MLC positions: X1/Y1 = -13.65 cm, X2/Y2 = +13.65 cm
7. Click Set Shape to apply the MLC positions
8. Enter 30 seconds as the Beam-On Time
9. Click Prepare Beam Setup
10. Click Enable Beam On
11. On the Treatment Control Panel, wait for the ready light to appear, then press Beam On
12. In the SNC Profiler software, click Start
13. When asked if the new measurement is continuous, click Yes
14. Wait for the beam to be delivered
15. Click Stop on the Profiler Software
16. Enter the Delivery Parameters and Save the File
  1. Click on the Setup tab
  2. Enter the gantry angle
  3. Set the SSD to 100 cm
  4. Check Symmetric Collimators
  5. Enter the field size as 27.3 cm x 27.3 cm
  6. Click on the General tab
  7. Under Description, type Head #, where # is the head number (1 in this instance)
  8. Click OK
  9. When asked to save the file, choose Multi-Frame type and save the results to _H1 G90 27p3.prm_
17. Repeat for Heads 2 and 3

## Analyze Field Uniformity Data

1. Execute the FieldUniformity.m MATLAB script
2. Under Head 1, click Browse to load the SNC IC Profiler _H1 G90 27p3.prm_ Multi-Frame export
3. Continue to load the remaining heads
4. Review the resulting profile comparisons and statistics, as shown in the example
  1. Verify that each profile looks as expected and that no data points (particularly those in the central 80% of the field) appear distorted due to noise or measurement error
  2. Verify that the MLC X and Y flatness and area symmetry are within +/- 2% of their baseline values for all three heads
5. Verify that the time difference between the Expected and Measured beam on time are within 0.1 seconds


## Compatibility and Requirements

This tool has been tested with ViewRay version 3.5 treatment software, Sun Nuclear IC Profiler software version 3.3.1.31111, and MATLAB R2014a.  The Parallel Computing toolbox and a CUDA-compatible GPU are required to run GPU based interpolation (CPU interpolation is automatically supported if not present).
