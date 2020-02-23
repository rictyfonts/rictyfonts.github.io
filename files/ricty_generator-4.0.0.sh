#!/bin/sh

#
# Ricty Generator
ricty_version="4.0.0"
#

#
# Copyright (c) 2011-2015, Yasunori Yusa
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

#
# This script is to generate ``Ricty'' font from Inconsolata and Migu 1M.
# It requires 2-5 minutes to generate Ricty. Owing to SIL Open Font License
# Version 1.1 section 5, it is PROHIBITED to distribute the generated font.
# This script supports following versions of inputting fonts.
# * Inconsolata Version 1.016 or later
# * Migu 1M     Version 2015.0712 or later
#
# Usage:
#
# 1. Install FontForge
#    Debian/Ubuntu: # apt-get install fontforge
#    Fedora/CentOS: # yum install fontforge
#    OpenSUSE:      # zypper install fontforge
#    Other distros: Get from https://fontforge.github.io/
#
# 2. Get Inconsolata-Regular/Bold.otf
#    from https://www.google.com/fonts/specimen/Inconsolata (release)
#    or from https://github.com/google/fonts/tree/master/ofl/inconsolata (upstream)
#
# 3. Get migu-1m-regular/bold.ttf
#    from http://mix-mplus-ipa.osdn.jp/
#
# 4. Run this script
#        % sh ricty_generator.sh auto
#    or
#        % sh ricty_generator.sh Inconsolata-Regular.ttf Inconsolata-Bold.ttf migu-1m-regular.ttf migu-1m-bold.ttf
#
# 5. Install Ricty
#        % cp -f Ricty*.ttf ~/.fonts/
#        % fc-cache -vf
#

# Set familyname
ricty_familyname="Ricty"
ricty_familyname_suffix=""

# Set ascent and descent (line width parameters)
ricty_ascent=835
ricty_descent=215

# Set path to fontforge command
fontforge_command="fontforge"

# Set redirection of stderr
redirection_stderr="/dev/null"

# Set fonts directories used in auto flag
fonts_directories=". ${HOME}/.fonts /usr/local/share/fonts /usr/share/fonts ${HOME}/Library/Fonts /Library/Fonts /c/Windows/Fonts /cygdrive/c/Windows/Fonts"

# Set zenkaku space glyph
zenkaku_space_glyph=""

# Set flags
leaving_tmp_flag="false"
fullwidth_ambiguous_flag="true"
scaling_down_flag="true"

# Set filenames
modified_inconsolata_generator="modified_inconsolata_generator.pe"
modified_inconsolata_regular="Modified-Inconsolata-Regular.sfd"
modified_inconsolata_bold="Modified-Inconsolata-Bold.sfd"
modified_migu1m_generator="modified_migu1m_generator.pe"
modified_migu1m_regular="Modified-migu-1m-regular.sfd"
modified_migu1m_bold="Modified-migu-1m-bold.sfd"
ricty_generator="ricty_generator.pe"

########################################
# Pre-process
########################################

# Print information message
cat << _EOT_
Ricty Generator ${ricty_version}

Copyright (c) 2011-2015, Yasunori Yusa
All rights reserved.

This script is to generate \`\`Ricty'' font from Inconsolata and Migu 1M.
It requires 2-5 minutes to generate Ricty. Owing to SIL Open Font License
Version 1.1 section 5, it is PROHIBITED to distribute the generated font.

_EOT_

# Define displaying help function
ricty_generator_help()
{
    echo "Usage: ricty_generator.sh [options] auto"
    echo "       ricty_generator.sh [options] Inconsolata.otf migu-1m-regular.ttf migu-1m-bold.ttf"
    echo ""
    echo "Options:"
    echo "  -h                     Display this information"
    echo "  -V                     Display version number"
    echo "  -f /path/to/fontforge  Set path to fontforge command"
    echo "  -v                     Enable verbose mode (display fontforge's warnings)"
    echo "  -l                     Leave (NOT remove) temporary files"
    echo "  -n string              Set fontfamily suffix (\`\`Ricty string'')"
    echo "  -w                     Widen line space"
    echo "  -W                     Widen line space extremely"
    echo "  -Z unicode             Set visible zenkaku space copied from another glyph"
    echo "  -z                     Disable visible zenkaku space"
    echo "  -a                     Disable fullwidth ambiguous charactors"
    echo "  -s                     Disable scaling down Migu 1M"
    exit 0
}

# Get options
while getopts hVf:vln:wWbBZ:zas OPT
do
    case "$OPT" in
        "h" )
            ricty_generator_help
            ;;
        "V" )
            exit 0
            ;;
        "f" )
            echo "Option: Set path to fontforge command: ${OPTARG}"
            fontforge_command="$OPTARG"
            ;;
        "v" )
            echo "Option: Enable verbose mode"
            redirection_stderr="/dev/stderr"
            ;;
        "l" )
            echo "Option: Leave (NOT remove) temporary files"
            leaving_tmp_flag="true"
            ;;
        "n" )
            echo "Option: Set fontfamily suffix: ${OPTARG}"
            ricty_familyname_suffix=`echo $OPTARG | tr -d ' '`
            ;;
        "w" )
            echo "Option: Widen line space"
            ricty_ascent=`expr $ricty_ascent + 128`
            ricty_descent=`expr $ricty_descent + 32`
            ;;
        "W" )
            echo "Option: Widen line space extremely"
            ricty_ascent=`expr $ricty_ascent + 256`
            ricty_descent=`expr $ricty_descent + 64`
            ;;
        "Z" )
            echo "Option: Set visible zenkaku space copied from another glyph: ${OPTARG}"
            zenkaku_space_glyph="0u${OPTARG}"
            ;;
        "z" )
            echo "Option: Disable visible zenkaku space"
            zenkaku_space_glyph="0u3000"
            ;;
        "a" )
            echo "Option: Disable fullwidth ambiguous charactors"
            fullwidth_ambiguous_flag="false"
            ;;
        "s" )
            echo "Option: Disable scaling down Migu 1M"
            scaling_down_flag="false"
            ;;
        * )
            exit 1
            ;;
    esac
done
shift `expr $OPTIND - 1`

# Check fontforge existance
if ! which $fontforge_command > /dev/null 2>&1
then
    echo "Error: ${fontforge_command} command not found" >&2
    exit 1
fi

# Get input fonts
if [ $# -eq 1 -a "$1" = "auto" ]
then
    # Check existance of directories
    tmp=""
    for i in $fonts_directories
    do
        [ -d "$i" ] && tmp="$tmp $i"
    done
    fonts_directories=$tmp
    # Search Inconsolata
    input_inconsolata_regular=`find $fonts_directories -follow -name Inconsolata-Regular.ttf | head -n 1`
    input_inconsolata_bold=`find $fonts_directories -follow -name Inconsolata-Bold.ttf | head -n 1`
    if [ -z "$input_inconsolata_regular" -o -z "$input_inconsolata_bold" ]
    then
        echo "Error: Inconsolata-Regular.ttf and/or Inconsolata-Bold.ttf not found" >&2
        exit 1
    fi
    # Search Migu 1M
    input_migu1m_regular=`find $fonts_directories -follow -iname migu-1m-regular.ttf | head -n 1`
    input_migu1m_bold=`find $fonts_directories -follow -iname migu-1m-bold.ttf    | head -n 1`
    if [ -z "$input_migu1m_regular" -o -z "$input_migu1m_bold" ]
    then
        echo "Error: migu-1m-regular.ttf and/or migu-1m-bold.ttf not found" >&2
        exit 1
    fi
elif [ $# -eq 4 ]
then
    # Get arguments
    input_inconsolata_regular=$1
    input_inconsolata_bold=$2
    input_migu1m_regular=$3
    input_migu1m_bold=$4
    # Check existance of files
    if [ ! -r "$input_inconsolata_regular" ]
    then
        echo "Error: ${input_inconsolata_regular} not found" >&2
        exit 1
    elif [ ! -r "$input_inconsolata_bold" ]
    then
        echo "Error: ${input_inconsolata_bold} not found" >&2
        exit 1
    elif [ ! -r "$input_migu1m_regular" ]
    then
        echo "Error: ${input_migu1m_regular} not found" >&2
        exit 1
    elif [ ! -r "$input_migu1m_bold" ]
    then
        echo "Error: ${input_migu1m_bold} not found" >&2
        exit 1
    fi
    # Check filename
    [ "$(basename $input_inconsolata_regular)" != "Inconsolata-Regular.ttf" ] \
        && echo "Warning: ${input_inconsolata_regular} is really Inconsolata Regular?" >&2
    [ "$(basename $input_inconsolata_bold)" != "Inconsolata-Bold.ttf" ] \
        && echo "Warning: ${input_inconsolata_regular} is really Inconsolata Bold?" >&2
    [ "$(basename $input_migu1m_regular)" != "migu-1m-regular.ttf" ] \
        && echo "Warning: ${input_migu1m_regular} is really Migu 1M Regular?" >&2
    [ "$(basename $input_migu1m_bold)" != "migu-1m-bold.ttf" ] \
        && echo "Warning: ${input_migu1m_bold} is really Migu 1M Bold?" >&2
else
    ricty_generator_help
fi

# Make temporary directory
if [ -w "/tmp" -a "$leaving_tmp_flag" = "false" ]
then
    tmpdir=`mktemp -d /tmp/ricty_generator_tmpdir.XXXXXX` || exit 2
else
    tmpdir=`mktemp -d ./ricty_generator_tmpdir.XXXXXX`    || exit 2
fi

# Remove temporary directory by trapping
if [ "$leaving_tmp_flag" = "false" ]
then
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files.'; rm -rf $tmpdir; echo 'Abnormally terminated.'; fi; exit 3" HUP INT QUIT
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files.'; rm -rf $tmpdir; echo 'Abnormally terminated.'; fi" EXIT
else
    trap "echo 'Abnormally terminated.'; exit 3" HUP INT QUIT
fi

########################################
# Generate script for modified Inconsolata
########################################

cat > ${tmpdir}/${modified_inconsolata_generator} << _EOT_
#!$fontforge_command -script

# Print message
Print("Generate modified Inconsolata.")

# Set parameters
input_list  = ["${input_inconsolata_regular}",    "${input_inconsolata_bold}"]
output_list = ["${modified_inconsolata_regular}", "${modified_inconsolata_bold}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
    # Open Inconsolata
    Print("Find " + input_list[i] + ".")
    Open(input_list[i])

    # Scale to standard glyph size
    ScaleToEm(860, 140)

    # Remove ambiguous glyphs
    if ("$fullwidth_ambiguous_flag" == "true")
        Select(0u00a4); Clear() # currency
        Select(0u00a7); Clear() # section
        Select(0u00a8); Clear() # dieresis
        Select(0u00ad); Clear() # soft hyphen
        Select(0u00b0); Clear() # degree
        Select(0u00b1); Clear() # plus-minus
        Select(0u00b4); Clear() # acute
        Select(0u00b6); Clear() # pilcrow
        Select(0u00d7); Clear() # multiply
        Select(0u00f7); Clear() # divide
        Select(0u2018); Clear() # left '
        Select(0u2019); Clear() # right '
        Select(0u201c); Clear() # left "
        Select(0u201d); Clear() # right "
        Select(0u2020); Clear() # dagger
        Select(0u2021); Clear() # double dagger
        Select(0u2026); Clear() # ...
        Select(0u2122); Clear() # TM
        Select(0u2191); Clear() # uparrow
        Select(0u2193); Clear() # downarrow
    endif

    # Pre-process for merging
    SelectWorthOutputting()
    ClearInstrs(); UnlinkReference()

    # Save modified Inconsolata
    Print("Save " + output_list[i] + ".")
    Save("${tmpdir}/" + output_list[i])
i += 1
endloop

Quit()
_EOT_

########################################
# Generate script for modified Migu 1M
########################################

cat > ${tmpdir}/${modified_migu1m_generator} << _EOT_
#!$fontforge_command -script

# Print message
Print("Generate modified Migu 1M.")

# Set parameters
input_list  = ["${input_migu1m_regular}",    "${input_migu1m_bold}"]
output_list = ["${modified_migu1m_regular}", "${modified_migu1m_bold}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
    # Open Migu 1M
    Print("Find " + input_list[i] + ".")
    Open(input_list[i])

    # Scale Migu 1M to standard glyph size
    ScaleToEm(860, 140)
    SelectWorthOutputting()
    ClearInstrs(); UnlinkReference()
    if ("$scaling_down_flag" == "true")
        Print("While scaling " + input_list[i]:t + ", wait a little...")
        SetWidth(-1, 1); Scale(91, 91, 0, 0); SetWidth(110, 2); SetWidth(1, 1)
        Move(23, 0); SetWidth(-23, 1)
    endif
    RoundToInt(); RemoveOverlap(); RoundToInt()

    # Save modified Migu 1M
    Print("Save " + output_list[i] + ".")
    Save("${tmpdir}/" + output_list[i])
    Close()
i += 1
endloop

Quit()
_EOT_

########################################
# Generate script for Ricty
########################################

cat > ${tmpdir}/${ricty_generator} << _EOT_
#!$fontforge_command -script

# Print message
Print("Generate Ricty.")

# Set parameters
inconsolata_list  = ["${tmpdir}/${modified_inconsolata_regular}", \\
                     "${tmpdir}/${modified_inconsolata_bold}"]
migu1m_list       = ["${tmpdir}/${modified_migu1m_regular}", \\
                     "${tmpdir}/${modified_migu1m_bold}"]
fontfamily        = "$ricty_familyname"
fontfamilysuffix  = "$ricty_familyname_suffix"
fontstyle_list    = ["Regular", "Bold"]
fontweight_list   = [400,       700]
panoseweight_list = [5,         8]
copyright         = "Copyright (c) 2011-2015 Yasunori Yusa\n" \\
                  + "Copyright (c) 2006-2012 Raph Levien\n" \\
                  + "Copyright (c) 2011-2012 Cyreal (cyreal.org)\n" \\
                  + "Copyright (c) 2006-2015 itouhiro\n" \\
                  + "Copyright (c) 2002-2015 M+ FONTS PROJECT\n" \\
                  + "Copyright (c) 2003-2011 Information-technology Promotion Agency, Japan (IPA)\n" \\
                  + "SIL Open Font License Version 1.1 (http://scripts.sil.org/ofl)\n" \\
                  + "IPA Font License Agreement v1.0 (http://ipafont.ipa.go.jp/ipa_font_license_v1.html)"
version           = "${ricty_version}"

# Begin loop of regular and bold
i = 0
while (i < SizeOf(fontstyle_list))
    # Open new file
    New()

    # Set encoding to Unicode-bmp
    Reencode("unicode")

    # Set configuration
    if (fontfamilysuffix != "")
        SetFontNames(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i], \\
                     fontfamily + " " + fontfamilysuffix, \\
                     fontfamily + " " + fontfamilysuffix + " " + fontstyle_list[i], \\
                     fontstyle_list[i], \\
                     copyright, version)
    else
        SetFontNames(fontfamily + "-" + fontstyle_list[i], \\
                     fontfamily, \\
                     fontfamily + " " + fontstyle_list[i], \\
                     fontstyle_list[i], \\
                     copyright, version)
    endif
    SetTTFName(0x409, 2, fontstyle_list[i])
    SetTTFName(0x409, 3, "FontForge 2.0 : " + \$fullname + " : " + Strftime("%d-%m-%Y", 0))
    ScaleToEm(860, 140)
    SetOS2Value("Weight", fontweight_list[i]) # Book or Bold
    SetOS2Value("Width",                   5) # Medium
    SetOS2Value("FSType",                  0)
    SetOS2Value("VendorID",           "PfEd")
    SetOS2Value("IBMFamily",            2057) # SS Typewriter Gothic
    SetOS2Value("WinAscentIsOffset",       0)
    SetOS2Value("WinDescentIsOffset",      0)
    SetOS2Value("TypoAscentIsOffset",      0)
    SetOS2Value("TypoDescentIsOffset",     0)
    SetOS2Value("HHeadAscentIsOffset",     0)
    SetOS2Value("HHeadDescentIsOffset",    0)
    SetOS2Value("WinAscent",             $ricty_ascent)
    SetOS2Value("WinDescent",            $ricty_descent)
    SetOS2Value("TypoAscent",            860)
    SetOS2Value("TypoDescent",          -140)
    SetOS2Value("TypoLineGap",             0)
    SetOS2Value("HHeadAscent",           $ricty_ascent)
    SetOS2Value("HHeadDescent",         -$ricty_descent)
    SetOS2Value("HHeadLineGap",            0)
    SetPanose([2, 11, panoseweight_list[i], 9, 2, 2, 3, 2, 2, 7])

    # Merge fonts
    Print("While merging " + inconsolata_list[i]:t \\
          + " with " + migu1m_list[i]:t + ", wait a little...")
    MergeFonts(inconsolata_list[i])
    MergeFonts(migu1m_list[i])

    # Edit zenkaku space (from ballot box and heavy greek cross)
    if ("$zenkaku_space_glyph" == "")
        Select(0u2610); Copy(); Select(0u3000); Paste()
        Select(0u271a); Copy(); Select(0u3000); PasteInto()
        OverlapIntersect()
    else
        Select(${zenkaku_space_glyph}); Copy(); Select(0u3000); Paste()
    endif

    # Edit zenkaku comma and period
    Select(0uff0c); Scale(150, 150, 100, 0); SetWidth(1000)
    Select(0uff0e); Scale(150, 150, 100, 0); SetWidth(1000)

    # Edit zenkaku colon and semicolon
    Select(0uff0c); Copy(); Select(0uff1b); Paste()
    Select(0uff0e); Copy(); Select(0uff1b); PasteWithOffset(0, 400)
    CenterInWidth()
    Select(0uff1a); Paste(); PasteWithOffset(0, 400)
    CenterInWidth()

    # Edit zenkaku brackets
    Select(0u0028); Copy(); Select(0uff08); Paste(); Move(250, 0); SetWidth(1000) # (
    Select(0u0029); Copy(); Select(0uff09); Paste(); Move(250, 0); SetWidth(1000) # )
    Select(0u005b); Copy(); Select(0uff3b); Paste(); Move(250, 0); SetWidth(1000) # [
    Select(0u005d); Copy(); Select(0uff3d); Paste(); Move(250, 0); SetWidth(1000) # ]
    Select(0u007b); Copy(); Select(0uff5b); Paste(); Move(250, 0); SetWidth(1000) # {
    Select(0u007d); Copy(); Select(0uff5d); Paste(); Move(250, 0); SetWidth(1000) # }
    Select(0u003c); Copy(); Select(0uff1c); Paste(); Move(250, 0); SetWidth(1000) # <
    Select(0u003e); Copy(); Select(0uff1e); Paste(); Move(250, 0); SetWidth(1000) # >

    # Edit en dash
    Select(0u2013); Copy()
    PasteWithOffset(200, 0); PasteWithOffset(-200, 0)
    OverlapIntersect()

    # Edit em dash
    Select(0u2014); Copy()
    PasteWithOffset(490, 0); PasteWithOffset(-490, 0)
    OverlapIntersect()

    # Detach and remove .notdef
    Select(".notdef")
    DetachAndRemoveGlyphs()

    # Post-proccess
    SelectWorthOutputting()
    RoundToInt(); RemoveOverlap(); RoundToInt()

    # Save Ricty
    if (fontfamilysuffix != "")
        Print("Save " + fontfamily + fontfamilysuffix + "-" + fontstyle_list[i] + ".ttf.")
        Generate(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    else
        Print("Save " + fontfamily + "-" + fontstyle_list[i] + ".ttf.")
        Generate(fontfamily + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    endif
    Close()
i += 1
endloop

Quit()
_EOT_

########################################
# Generate Ricty
########################################

# Generate Ricty
$fontforge_command -script ${tmpdir}/${modified_inconsolata_generator} \
    2> $redirection_stderr || exit 4
$fontforge_command -script ${tmpdir}/${modified_migu1m_generator} \
    2> $redirection_stderr || exit 4
$fontforge_command -script ${tmpdir}/${ricty_generator} \
    2> $redirection_stderr || exit 4

# Remove temporary directory
if [ "$leaving_tmp_flag" = "false" ]
then
    echo "Remove temporary files."
    rm -rf $tmpdir
fi

# Generate Ricty Discord (if the script exists)
path2discord_converter=$(dirname $0)/ricty_discord_converter.pe
if [ -r "$path2discord_converter" ]
then
    $fontforge_command -script $path2discord_converter \
        ${ricty_familyname}${ricty_familyname_suffix}-Regular.ttf \
        ${ricty_familyname}${ricty_familyname_suffix}-Bold.ttf \
        2> $redirection_stderr || exit 4
fi

# Exit
echo "Succeeded in generating Ricty!"
exit 0
