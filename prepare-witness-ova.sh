#! /bin/bash

show_help() {
cat << EOF

Usage: ${0##*/} [[-f] witness-ova-file.ova]

    Convert a VSAN Witnss OVA to OVF format and remove the property
    requirements normally present when deploying it. This allows deploying
    the appliance to VMware Fusion, where OVF properties aren't supported.

    This creates an OVF file and attendant data files that are packaged inside
    the OVA. These will be created in a folder located in the same directory as
    the OVA file, with the same name as the OVA minus the extension.

    Note this does necessitate modifying the VMX file once you've imported
    the OVF. See William Lam's blog about this, which is where all the
    clever bits of this script came from: http://j.mp/vsanwitnessfusion

    It should go without saying, but this script and what it does is NOT
    offically supported by VMware. Use at your own risk, and not in production!
    This script is MIT licensed.

        -h, -?, --help  display this help and exit

        -f, --file      The OVA file of the VSAN witness appliance. The
                        flag is optional; '${0##*/} witness-ova-file.ova'
                        will also work.

                        If a file isn't specified, a search will be performed
                        for an OVA file named like '*VirtualSAN-Witness*'
                        within the current directory.
EOF
}

file=

# Loop through all the provided arguments, setting the current iteration to the
# first position on each iteration
while :; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit
        ;;
        -f|--file)
            if [ -n "$2" ]; then
                file=$2
                shift
            else
                printf 'ERROR: "--file" requires a non-empty option argument.\n' >&2
                exit 1
            fi
        ;;
        --file=?*)
            file=${1#*=}
        ;;
        --file=)
            printf 'ERROR: "--file" requires a non-empty option argument.\n' >&2
            exit 1
        ;;
        -v|--verbose)
            verbose=$((verbose + 1))
        ;;
        --) # handle cases where a GNU style argument has been passed
            shift
            break
        ;;
        -?*) # any option not listed above
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
        ;;
        *) # catch-all, determine if just a file was specified
            if [[ "$1" = *.ova && -f "$1" ]]; then
                file=$1
            fi

            break
    esac

    shift
done

# If no file was provided, see if a likely OVA exists in the PWD and use that
if [[ -z $file ]]; then
    shopt -s nullglob dotglob
    vsanova=(*VirtualSAN-Witness*.ova)

    if [[ ${#vsanova[@]} -gt 1 ]]; then
        printf 'ERROR: "file" was not specified and there are multiple VSAN witness OVA files present.\n' >&2
        printf 'Re-run this script and specify which OVA to use with the --file parameter.\n'
    elif [[ ${#vsanova[@]} -eq 1 && -f "$vsanova" ]]; then
        file=$vsanova
    else
        printf 'ERROR: "--file" was not specified and no suitable VSAN Witness OVA was found.\n' >&2
    fi
fi

outputdir=$(echo "$file" | sed 's/\.[^.][^.]*$//')

# Create a file for the resulting OVF and attendant files
if [[ ! -d "$outputdir" ]]; then
    mkdir "$outputdir"
else
    while [[ -d "$outputdir" ]]; do
      echo $outputdir
      read -p "$outputdir exists. Please enter an alternate output path:"$'\n' outputdir
      if [[ ! -d "$outputdir" ]]; then
        mkdir "$outputdir"
        break
      fi
    done
fi

basename=$(echo "$outputdir" | sed 's/.*\///')
ovffile=$outputdir/$basename.ovf

# Unpackage the OVA, only returning any errors
# TODO: add quality error handling around ovftool's operations
"/Applications/VMware OVF Tool/ovftool" "$file" "$ovffile"

# Remove the manifest, as the checksum won't be correct after altering the OVF
rm "$outputdir"/*.mf

# Set the required property to false so Fusion can import this
sed -i.original 's/ProductSection ovf:class="vsan" ovf:required="true"/ProductSection ovf:class="vsan" ovf:required="false"/' $ovffile

# TODO: Add verification testing of the edited OVF file with ovftool?
rm $ovffile.original

if [[ -f "$ovffile" ]]; then
    printf '\nDone. Import %s into Fusion, and edit the VMX file as per http://j.mp/vsanwitnessfusion\n' "$ovffile"
fi
