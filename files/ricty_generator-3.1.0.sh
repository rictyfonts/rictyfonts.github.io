#!/bin/sh

########################################
# Ricty Generator 3.1.0
#
# Last modified: ricty_generator.sh on Sun, 19 Jun 2011.
#
# Author: Yasunori Yusa
#
# This script is for generating ``Ricty'' font from Inconsolata and Migu 1M.
# It requires 2-5 minutes to generate Ricty. Owing to SIL Open Font License
# Version 1.1 section 5, it is PROHIBITED to distribute the generated font.
# This script supports following versions of inputting fonts.
# * Inconsolata Version 001.010
# * Migu 1M     Version 20110418
#                       20110514
#                       20110610
#
# How to use:
# 1. Install FontForge
#    Debian/Ubuntu: # apt-get install fontforge
#    Fedora:        # yum install fontforge
#    Other Linux:   Get from http://fontforge.sourceforge.net/
# 2. Get Inconsolata.otf
#    Debian/Ubuntu: # apt-get install ttf-inconsolata
#    Other Linux:   Get from http://levien.com/type/myfonts/inconsolata.html
# 3. Get Migu-1M-regular/bold.ttf
#                   Get from http://mix-mplus-ipa.sourceforge.jp/
# 4. Run this script
#    % sh ricty_generator.sh auto
#    or
#    % sh ricty_generator.sh \
#      Inconsolata.otf Migu-1M-regular.ttf Migu-1M-bold.ttf
# 5. Install Ricty
#    % cp Ricty-{Regular,Bold}.ttf ~/.fonts/
#    % fc-cache -vf
########################################

# set version
ricty_version="3.1.0"

# set ascent and descent (parameters concerning line height)
ricty_ascent="815"
ricty_descent="215"

# set fonts directories used in auto flag
fonts_dirs=". ${HOME}/.fonts /usr/local/share/fonts /usr/share/fonts"

# set filenames
modified_inconsolata_generator="modified_inconsolata_generator.pe"
modified_inconsolata_regu="Modified-Inconsolata-Regular.sfd"
modified_inconsolata_bold="Modified-Inconsolata-Bold.sfd"
modified_migu1m_generator="modified_migu1m_generator.pe"
modified_migu1m_regu="Modified-Migu-1M-regular.sfd"
modified_migu1m_bold="Modified-Migu-1M-bold.sfd"
ricty_generator="ricty_generator.pe"

########################################
# preprocess
########################################

# print information message
cat << _EOT_
Ricty Generator ${ricty_version}

Copyright (c) 2011 Yasunori Yusa

This script is for generating \`\`Ricty'' font from Inconsolata and Migu 1M.
It requires 2-5 minutes to generate Ricty. Owing to SIL Open Font License
Version 1.1 section 5, it is PROHIBITED to distribute the generated font.

_EOT_

# check fontforge existance
if [ ! "$(which fontforge)" ]
then
    echo "Error: fontforge command not found" 1>&2
    exit 1
fi

# get input fonts
if [ $# -eq 1 -a "$1" = "auto" ]
then
    # check dirs existance
    tmp=""
    for i in $fonts_dirs
    do
	if [ -d $i ]; then tmp="$tmp $i"; fi
    done
    fonts_dirs=$tmp
    # search Inconsolata
    input_inconsolata=`find $fonts_dirs -follow -name Inconsolata.otf | head -n 1`
    if [ ! "$input_inconsolata" ]
    then
	echo "Error: Inconsolata.otf not found" 1>&2
	exit 1
    fi
    # search Migu 1M
    input_migu1m_regu=`find $fonts_dirs -follow -name Migu-1M-regular.ttf | head -n 1`
    input_migu1m_bold=`find $fonts_dirs -follow -name Migu-1M-bold.ttf    | head -n 1`
    if [ ! "$input_migu1m_regu" -o ! "$input_migu1m_bold" ]
    then
	echo "Error: Migu-1M-regular/bold.ttf not found" 1>&2
	exit 1
    fi
elif [ $# -eq 3 ]
then
    # get args
    input_inconsolata=$1
    input_migu1m_regu=$2
    input_migu1m_bold=$3
    # check file existance
    if [ ! -r $input_inconsolata ]
    then
	echo "Error: $input_inconsolata not found" 1>&2
	exit 1
    elif [ ! -r $input_migu1m_regu ]
    then
	echo "Error: $input_migu1m_regu not found" 1>&2
	exit 1
    elif [ ! -r $input_migu1m_bold ]
    then
	echo "Error: $input_migu1m_bold not found" 1>&2
	exit 1
    fi
    # check filename
    if [ "$(basename $input_inconsolata)" != "Inconsolata.otf" ]
    then
	echo "Warning: $input_inconsolata is really Inconsolata?" 1>&2
    fi
    if [ "$(basename $input_migu1m_regu)" != "Migu-1M-regular.ttf" ]
    then
	echo "Warning: $input_migu1m_regu is really Migu 1M Regular?" 1>&2
    fi
    if [ "$(basename $input_migu1m_bold)" != "Migu-1M-bold.ttf" ]
    then
	echo "Warning: $input_migu1m_bold is really Migu 1M Bold?" 1>&2
    fi
else
    echo "Usage: ricty_generator.sh auto"
    echo "       ricty_generator.sh" \
	"Inconsolata.otf Migu-1M-regular.ttf Migu-1M-bold.ttf"
    exit 0
fi

# make tmp
if [ -w /tmp ]
then
    tmpdir=`mktemp -d /tmp/ricty_generator_tmpdir.XXXXXX` || exit 2
else
    tmpdir=`mktemp -d ./ricty_generator_tmpdir.XXXXXX`    || exit 2
fi

# remove tmp by trapping
trap "if [ -d $tmpdir ]; then echo 'Remove temporary files'; rm -rf $tmpdir; echo 'Abnormal terminated'; fi; exit 3" HUP INT QUIT
trap "if [ -d $tmpdir ]; then echo 'Remove temporary files'; rm -rf $tmpdir; echo 'Abnormal terminated'; fi" EXIT

########################################
# generate script for modified Inconsolata
########################################

cat > ${tmpdir}/${modified_inconsolata_generator} << _EOT_
# print
Print("Generate modified Inconsolata")

# open
Print("Open ${input_inconsolata}")
Open("${input_inconsolata}")

# scale
ScaleToEm(860, 140)

# remove ambiguous
Select(0u00a2); Clear() # cent
Select(0u00a3); Clear() # pound
Select(0u00a4); Clear() # currency
Select(0u00a5); Clear() # yen
Select(0u00a7); Clear() # section
Select(0u00a8); Clear() # dieresis
Select(0u00ac); Clear() # not
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
Select(0u2212); Clear() # minus
Select(0u2423); Clear() # open box

# process for merging
SelectWorthOutputting()
ClearInstrs(); UnlinkReference()

# save regular
Save("${tmpdir}/${modified_inconsolata_regu}")
Print("Generated ${modified_inconsolata_regu}")

# bold-face regular
Print("While bold-facing Inconsolata, wait a bit, maybe a bit...")
SelectWorthOutputting()
ExpandStroke(30, 0, 0, 0, 1)
Select(0u003e); Copy()           # >
Select(0u003c); Paste(); HFlip() # <
RemoveOverlap(); RoundToInt()

# save bold
Save("${tmpdir}/${modified_inconsolata_bold}")
Print("Generated ${modified_inconsolata_bold}")
Close()
Quit()
_EOT_

########################################
# generate script for modified Migu 1M
########################################

cat > ${tmpdir}/${modified_migu1m_generator} << _EOT_
# print
Print("Generate modified Migu 1M")

# parameters
input_list  = ["${input_migu1m_regu}",    "${input_migu1m_bold}"]
output_list = ["${modified_migu1m_regu}", "${modified_migu1m_bold}"]

# regular and bold loop
i = 0; while (i < SizeOf(input_list))
    # open
    Print("Open " + input_list[i])
    Open(input_list[i])
    # scale Migu 1M
    Print("While scaling " + input_list[i]:t + ", wait a little...")
    ScaleToEm(860, 140)
    SelectWorthOutputting()
    ClearInstrs(); UnlinkReference()
    SetWidth(-1, 1); Scale(91, 91, 0, 0); SetWidth(110, 2); SetWidth(1, 1)
    Move(23, 0); SetWidth(-23, 1)
    RemoveOverlap(); RoundToInt()
    # save
    Save("${tmpdir}/" + output_list[i])
    Print("Generated " + output_list[i])
    Close()
i += 1; endloop
Quit()
_EOT_

########################################
# generate script for Ricty
########################################

cat > ${tmpdir}/${ricty_generator} << _EOT_
# print
Print("Generate Ricty")

# parameters
inconsolata_list  = ["${tmpdir}/${modified_inconsolata_regu}", \\
                     "${tmpdir}/${modified_inconsolata_bold}"]
migu1m_list       = ["${tmpdir}/${modified_migu1m_regu}", \\
                     "${tmpdir}/${modified_migu1m_bold}"]
fontfamily        = "Ricty"
fontstyle_list    = ["Regular", "Bold"]
fontweight_list   = [400,       700]
panoseweight_list = [5,         8]
copyright         = "Ricty Generator Author: Yasunori Yusa\n" \\
                  + "Copyright (c) 2006-2011 Raph Levien\n" \\
                  + "Copyright (c) 2006-2011 itouhiro\n" \\
                  + "Copyright (c) 2002-2011 M+ FONTS PROJECT\n" \\
                  + "Copyright (c) 2003-2011 " \\
                  + "Information-technology Promotion Agency, Japan (IPA)\n" \\
                  + "Licenses:\n" \\
                  + "SIL Open Font License Version 1.1 " \\
                  + "(http://scripts.sil.org/OFL)\n" \\
                  + "M+ FONTS LICENSE " \\
                  + "(http://mplus-fonts.sourceforge.jp/mplus-outline-fonts/#license)\n" \\
                  + "IPA Font License Agreement v1.0 " \\
                  + "(http://ipafont.ipa.go.jp/ipa_font_license_v1.html)"
version           = "${ricty_version}"

# regular and bold loop
i = 0; while (i < SizeOf(fontstyle_list))
    # new file
    New()
    # set encoding to Unicode-bmp
    Reencode("unicode")
    # set configs
    SetFontNames(fontfamily + "-" + fontstyle_list[i], \\
                 fontfamily, \\
                 fontfamily + " " + fontstyle_list[i], \\
                 fontstyle_list[i], \\
                 copyright, version)
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
    # merge fonts
    Print("While merging " + inconsolata_list[i]:t \\
          + " and " +migu1m_list[i]:t + ", wait a little more...")
    MergeFonts(inconsolata_list[i])
    MergeFonts(migu1m_list[i])
    # edit zenkaku space (from ballot box and heavy greek cross)
    Select(0u2610); Copy(); Select(0u3000); Paste()
    Select(0u271a); Copy(); Select(0u3000); PasteInto(); OverlapIntersect()
    # edit zenkaku comma and period
    Select(0uff0c); Scale(150, 150, 100, 0); SetWidth(1000)
    Select(0uff0e); Scale(150, 150, 100, 0); SetWidth(1000)
    # edit zenkaku colon and semicolon
    Select(0uff0c); Copy(); Select(0uff1b); Paste()
    Select(0uff0e); Copy(); Select(0uff1b); PasteWithOffset(0, 400)
    CenterInWidth()
    Select(0uff1a); Paste(); PasteWithOffset(0, 400)
    CenterInWidth()
    # edit en dash
    Select(0u2013); Copy()
    PasteWithOffset(200, 0); PasteWithOffset(-200, 0); OverlapIntersect()
    # edit em dash and horizontal bar
    Select(0u2014); Copy()
    PasteWithOffset(620, 0); PasteWithOffset(-620, 0)
    Select(0u2010); Copy()
    Select(0u2014); PasteInto()
    OverlapIntersect()
    Copy(); Select(0u2015); Paste()
    # post proccess
    SelectWorthOutputting(); RemoveOverlap(); RoundToInt()
    # generate
    Generate(fontfamily + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    Print("Generated " + fontfamily + "-" + fontstyle_list[i] + ".ttf")
    Close()
i += 1; endloop
Quit()
_EOT_

########################################
# generate Ricty
########################################

# generate modified Inconsolata
fontforge -script ${tmpdir}/${modified_inconsolata_generator} \
    2> /dev/null || exit 4

# generate modified Migu 1M
fontforge -script ${tmpdir}/${modified_migu1m_generator} \
    2> /dev/null || exit 4

# generate Ricty
fontforge -script ${tmpdir}/${ricty_generator} \
    2> /dev/null || exit 4

# remove tmp
echo "Remove temporary files"
rm -rf $tmpdir

# generate Ricty Discord (if the script exists)
path2discord_patch=`dirname $0`/ricty_discord_patch.pe
if [ -r $path2discord_patch ]
then
    fontforge -script $path2discord_patch Ricty-Regular.ttf Ricty-Bold.ttf \
	2> /dev/null || exit 4
fi

# exit
echo "Succeeded to generate Ricty!"
exit 0
