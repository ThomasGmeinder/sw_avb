Simple AVB Endpoint Demo
========================

:scope: Example
:description: A simple 1722.1 example endpoint application
:keywords: avb, simple, 1722.1, example
:boards: XR-AVB-LC-BRD

A simple 1722.1 example endpoint application

Tested configurations for 16ch in / 16ch out with TDM
=====================================================
Note: See Makefile for details on the naming convention.

Between two XMOS EPs
--------------------
Test Instructions:
******************
   - Two XMOS Single-port EPs connected via a switch.
   - The Mac running UNOS is also connected to the Switch. UNOS is used to connect streams.

Results: 
********
3 out of 4 16-channel configs are working between two XMOS EPs:
   - 1t1s16ch_1l1s16ch_TDM
   - 1t2s16ch_1l2s16ch_TDM
   - 1t4s16ch_1l4s16ch_TDM

On the Mac:
-----------
Test/Demo Instructions:
***********************
   - The demo shows: 
       * XMOS EP enumerated on Mac Maverics as: XMOS AVB Endpoint 16 in / 16 out
       * 2 x 8 channel TDM audio loopback
   - For TDM loopback modify the XMOS AVB Endpoint like this: 
       * Using Jumper Wires, connect SDATA_OUT0 to SDATA_IN0 and SDATA_OUT1 to SDATA_IN1
       * Remove jumper J12 to disconnect ADC from SDATA_IN0
   - Connect XMOS EP to a Mac running Maverics. Select “XMOS AVB Endpoint” in the Network Device Browser
     Note: Now the Audio Devices Window should show a new device: XMOS AVB Endpoint 16 in/ 16 out
   - Use Audacity to output audio to the EP (limit is two) and record 16 channels from the EP
       * Generate a tone at 48kHz sampling rate for 60 seconds.
       * Set both the Output and Input to XMOS AVB Endpoint
       * Click Record. 
   - Press the channel select button on the EP to cycle the 2 output channels through the 16 input channels.
     Note: The Audacity Window should look like the example in MAC_demo_audacity_loopback_recording.png

Result:
*******
   - Only 1 out of 4 is working on the Mac: 1t1s16ch_1l1s16ch_TDM

Known limitations:
==================
   - On the MAC: Limit is currently 4 streams. That means the 1t8s16ch_1l8s16ch_TDM configuration can not be tested
   - 1t2s16ch_1l2s16ch_TDM only works when 5 cores are running

Known issues:
=============
   - 1t1s16ch_1l1s16ch_TDM only works when the min delay of sending a Talker packet is reduced slightly. See Bug 14812
   - Between two XMOS EPs: 1t8s16ch_1l8s16ch_TDM looses lock when the 8th stream is connected. See Bug 14811
   - On the MAC: Any config wtih > 1 Stream per EP doesn’t work because of a 1722.1 descriptor issue. See Bug 14679
  
