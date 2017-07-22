# Prepare Witness OVA

## Prepare a VSAN 6.2 Witness OVA File for Use with VMware Fusion
The purpose of this Bash script is to allow use of the VSAN 6.2 Witness Appliance with VMware Fusion, as per [William Lam's excellent writeup on the matter](http://j.mp/vsanwitnessfusion). This completes steps 2 and 3 in his article. The steps are quoted below:
> Step 2 - We need to make a few minor adjustments to the OVF file before we can import it into VMware Fusion/Workstation. Before we do so, we need to first convert the OVA to an OVF using ovftool...
...Once the conversion has completed, you should see a total of 8 files (6 VMDK files, 1 manifest & 1 OVF file). Before moving onto the next step, you will need to delete the manifest file (extension ending in .mf). We need to do this because the checksum will no longer be valid after we edit the OVF and the upload will fail.
Step 3 - The first edit that we need to make in the OVF is to change the required OVF parameter for specifying the password to the VSAN Witness Appliance from "true" to "false" since both Fusion/Workstation do not support OVF properties.

## Caveats
As William notes, this methodology for deploying the VSAN Witness Appliance is unsupported. Use at your own risk, and not in production! This script is also unsupported, provided under the MIT license. If you have questions or encounter issues, please open a GitHub issue.
