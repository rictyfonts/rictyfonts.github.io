#!/bin/sh

#
# Ricty Generator
ricty_version="3.2.1"
#
# Author: Yasunori Yusa
#
# This script is for generating ``Ricty'' font from Inconsolata and Migu 1M.
# It requires 2-5 minutes to generate Ricty. Owing to SIL Open Font License
# Version 1.1 section 5, it is PROHIBITED to distribute the generated font.
# This script supports following versions of inputting fonts.
# * Inconsolata Version 001.010
# * Migu 1M     Version 20111002
#                       20120411
#                       20121030
#
# How to use:
# 1. Install FontForge
#    Debian/Ubuntu: # apt-get install fontforge
#    Fedora/CentOS: # yum install fontforge
#    OpenSUSE:      # zypper install fontforge
#    Other Linux:   Get from http://fontforge.sourceforge.net/
# 2. Get Inconsolata.otf
#    from http://levien.com/type/myfonts/inconsolata.html
# 3. Get migu-1m-regular/bold.ttf
#    from http://mix-mplus-ipa.sourceforge.jp/
# 4. Run this script
#    % sh ricty_generator.sh auto
#    or
#    % sh ricty_generator.sh Inconsolata.otf migu-1m-regular.ttf migu-1m-bold.ttf
# 5. Install Ricty
#    % cp -f Ricty*.ttf ~/.fonts/
#    % fc-cache -vf
#

# set familyname
ricty_familyname="Ricty"
ricty_addfamilyname=""

# set ascent and descent (line width parameters)
ricty_ascent=835
ricty_descent=215

# set bold width of ASCII glyphs
ascii_regular_width=0
ascii_bold_width=30

# set path to fontforge command
fontforge_cmd="fontforge"

# set redirection of stderr
redirection_stderr="/dev/null"

# set fonts directories used in auto flag
fonts_dirs=". ${HOME}/.fonts /usr/local/share/fonts /usr/share/fonts ${HOME}/Library/Fonts /Library/Fonts /cygdrive/c/Windows/Fonts"

# set zenkaku space glyph
zenkaku_space_glyph=""

# set flags
leaving_tmp_flag="false"
fullwidth_ambiguous_flag="true"
scaling_down_flag="true"

# set filenames
modified_inconsolata_generator="modified_inconsolata_generator.pe"
modified_inconsolata_regu="Modified-Inconsolata-Regular.sfd"
modified_inconsolata_bold="Modified-Inconsolata-Bold.sfd"
modified_migu1m_generator="modified_migu1m_generator.pe"
modified_migu1m_regu="Modified-migu-1m-regular.sfd"
modified_migu1m_bold="Modified-migu-1m-bold.sfd"
ricty_generator="ricty_generator.pe"

########################################
# pre-process
########################################

# print information message
cat << _EOT_
Ricty Generator ${ricty_version}

Author: Yasunori Yusa

This script is for generating \`\`Ricty'' font from Inconsolata and Migu 1M.
It requires 2-5 minutes to generate Ricty. Owing to SIL Open Font License
Version 1.1 section 5, it is PROHIBITED to distribute the generated font.

_EOT_

# display help
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
    echo "  -n string              Set additional fontfamily name (\`\`Ricty string'')"
    echo "  -w                     Widen line space"
    echo "  -W                     Widen line space extremely"
    echo "  -b                     Make bold-face ASCII glyphs more bold"
    echo "  -B                     Make regular-/bold-face ASCII glyphs more bold"
    echo "  -Z unicode             Set visible zenkaku space copied from another glyph"
    echo "  -z                     Disable visible zenkaku space"
    echo "  -a                     Disable fullwidth ambiguous charactors"
    echo "  -s                     Disable scaling down Migu 1M"
    exit 0
}

# get options
while getopts hVf:vln:wWbBZ:zas OPT
do
    case $OPT in
        "h" )
            ricty_generator_help
            ;;
        "V" )
            exit 0
            ;;
        "f" )
            echo "Option: Set path to fontforge command: ${OPTARG}"
            fontforge_cmd="$OPTARG"
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
            echo "Option: Set additional fontfamily name: ${OPTARG}"
            ricty_addfamilyname=`echo $OPTARG | sed -e 's/ //g'`
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
        "b" )
            echo "Option: Make bold-face ASCII glyphs more bold"
            ascii_bold_width=`expr $ascii_bold_width + 30`
            ;;
        "B" )
            echo "Option: Make regular-/bold-face ASCII glyphs more bold"
            ascii_regular_width=`expr $ascii_regular_width + 30`
            ascii_bold_width=`expr $ascii_bold_width + 30`
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
        *   )
            exit 1
            ;;
    esac
done
shift `expr $OPTIND - 1`

# check fontforge existence
which $fontforge_cmd > /dev/null 2>&1
if [ $? -ne 0 ]
then
    echo "Error: ${fontforge_cmd} command not found" >&2
    exit 1
fi

# get input fonts
if [ $# -eq 1 -a "$1" = "auto" ]
then
    # check dirs existence
    tmp=""
    for i in $fonts_dirs
    do
        [ -d "$i" ] && tmp="$tmp $i"
    done
    fonts_dirs=$tmp
    # search Inconsolata
    input_inconsolata=`find $fonts_dirs -follow -name Inconsolata.otf | head -n 1`
    if [ -z "$input_inconsolata" ]
    then
        echo "Error: Inconsolata.otf not found" >&2
        exit 1
    fi
    # search Migu 1M
    input_migu1m_regu=`find $fonts_dirs -follow -iname migu-1m-regular.ttf | head -n 1`
    input_migu1m_bold=`find $fonts_dirs -follow -iname migu-1m-bold.ttf    | head -n 1`
    if [ -z "$input_migu1m_regu" -o -z "$input_migu1m_bold" ]
    then
        echo "Error: migu-1m-regular/bold.ttf not found" >&2
        exit 1
    fi
elif [ $# -eq 3 ]
then
    # get args
    input_inconsolata=$1
    input_migu1m_regu=$2
    input_migu1m_bold=$3
    # check file existence
    if [ ! -r "$input_inconsolata" ]
    then
        echo "Error: ${input_inconsolata} not found" >&2
        exit 1
    elif [ ! -r "$input_migu1m_regu" ]
    then
        echo "Error: ${input_migu1m_regu} not found" >&2
        exit 1
    elif [ ! -r "$input_migu1m_bold" ]
    then
        echo "Error: ${input_migu1m_bold} not found" >&2
        exit 1
    fi
    # check filename
    [ "$(basename $input_inconsolata)" != "Inconsolata.otf" ] \
        && echo "Warning: ${input_inconsolata} is really Inconsolata?" >&2
    [ "$(basename $input_migu1m_regu)" != "migu-1m-regular.ttf" ] \
        && echo "Warning: ${input_migu1m_regu} is really Migu 1M Regular?" >&2
    [ "$(basename $input_migu1m_bold)" != "migu-1m-bold.ttf" ] \
        && echo "Warning: ${input_migu1m_bold} is really Migu 1M Bold?" >&2
else
    ricty_generator_help
fi

# make tmp
if [ -w "/tmp" -a "$leaving_tmp_flag" = "false" ]
then
    tmpdir=`mktemp -d /tmp/ricty_generator_tmpdir.XXXXXX` || exit 2
else
    tmpdir=`mktemp -d ./ricty_generator_tmpdir.XXXXXX`    || exit 2
fi

# remove tmp by trapping
if [ "$leaving_tmp_flag" = "false" ]
then
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files'; rm -rf $tmpdir; echo 'Abnormal terminated'; fi; exit 3" HUP INT QUIT
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files'; rm -rf $tmpdir; echo 'Abnormal terminated'; fi" EXIT
else
    trap "if [ -d \"$tmpdir\" ]; then echo 'Abnormal terminated'; fi; exit 3" HUP INT QUIT
    trap "if [ -d \"$tmpdir\" ]; then echo 'Abnormal terminated'; fi" EXIT
fi

########################################
# generate script for modified Inconsolata
########################################

cat > ${tmpdir}/${modified_inconsolata_generator} << _EOT_
#!$fontforge_cmd -script

# print message
Print("Generate modified Inconsolata.")

# open Inconsolata
Print("Find ${input_inconsolata}.")
Open("${input_inconsolata}")

# scale to standard glyph size
ScaleToEm(860, 140)

# remove ambiguous glyphs
if ("$fullwidth_ambiguous_flag" == "true")
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
endif

# pre-process for merging
SelectWorthOutputting()
ClearInstrs(); UnlinkReference()

# save regular-face
Print("Save ${modified_inconsolata_regu}.")
Save("${tmpdir}/${modified_inconsolata_regu}")

# make glyphs bold
Print("While making Inconsolata bold, wait a moment...")
SelectWorthOutputting()
ExpandStroke(${ascii_bold_width}, 0, 0, 0, 1)
Select(0u003e); Copy()           # >
Select(0u003c); Paste(); HFlip() # <
RoundToInt(); RemoveOverlap(); RoundToInt()

# save bold-face
Print("Save ${modified_inconsolata_bold}.")
Save("${tmpdir}/${modified_inconsolata_bold}")
Close()

# open regular-face and make it bold
if ($ascii_regular_width != 0)
    Open("${tmpdir}/${modified_inconsolata_regu}")
    Print("While making regular-face Inconsolata bold, wait a moment...")
    SelectWorthOutputting()
    ExpandStroke(${ascii_regular_width}, 0, 0, 0, 1)
    Select(0u003e); Copy()           # >
    Select(0u003c); Paste(); HFlip() # <
    RoundToInt(); RemoveOverlap(); RoundToInt()
    Save("${tmpdir}/${modified_inconsolata_regu}")
    Close()
endif

Quit()
_EOT_

########################################
# generate script for modified Migu 1M
########################################

cat > ${tmpdir}/${modified_migu1m_generator} << _EOT_
#!$fontforge_cmd -script

# print message
Print("Generate modified Migu 1M.")

# set parameters
input_list  = ["${input_migu1m_regu}",    "${input_migu1m_bold}"]
output_list = ["${modified_migu1m_regu}", "${modified_migu1m_bold}"]

# begin loop of regular and bold
i = 0; while (i < SizeOf(input_list))
    # open Migu 1M
    Print("Find " + input_list[i] + ".")
    Open(input_list[i])
    # scale Migu 1M to standard glyph size
    ScaleToEm(860, 140)
    SelectWorthOutputting()
    ClearInstrs(); UnlinkReference()
    if ("$scaling_down_flag" == "true")
        Print("While scaling " + input_list[i]:t + ", wait a little...")
        SetWidth(-1, 1); Scale(91, 91, 0, 0); SetWidth(110, 2); SetWidth(1, 1)
        Move(23, 0); SetWidth(-23, 1)
    endif
    RoundToInt(); RemoveOverlap(); RoundToInt()
    # save modified Migu 1M
    Save("${tmpdir}/" + output_list[i])
    Print("Save " + output_list[i] + ".")
    Close()
i += 1; endloop
Quit()
_EOT_

########################################
# generate script for Ricty
########################################

cat > ${tmpdir}/${ricty_generator} << _EOT_
#!$fontforge_cmd -script

# print message
Print("Generate Ricty.")

# set parameters
inconsolata_list  = ["${tmpdir}/${modified_inconsolata_regu}", \\
                     "${tmpdir}/${modified_inconsolata_bold}"]
migu1m_list       = ["${tmpdir}/${modified_migu1m_regu}", \\
                     "${tmpdir}/${modified_migu1m_bold}"]
fontfamily        = "$ricty_familyname"
addfontfamily     = "$ricty_addfamilyname"
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
                  + "IPA Font License Agreement v1.0 " \\
                  + "(http://ipafont.ipa.go.jp/ipa_font_license_v1.html)"
version           = "${ricty_version}"

# begin loop of regular and bold
i = 0; while (i < SizeOf(fontstyle_list))
    # open new file
    New()
    # set encoding to Unicode-bmp
    Reencode("unicode")
    # set configuration
    if (addfontfamily != "")
        SetFontNames(fontfamily + addfontfamily + "-" + fontstyle_list[i], \\
                     fontfamily + " " + addfontfamily, \\
                     fontfamily + " " + addfontfamily + " " + fontstyle_list[i], \\
                     fontstyle_list[i], \\
                     copyright, version)
    else
        SetFontNames(fontfamily + "-" + fontstyle_list[i], \\
                     fontfamily, \\
                     fontfamily + " " + fontstyle_list[i], \\
                     fontstyle_list[i], \\
                     copyright, version)
    endif
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
          + " with " +migu1m_list[i]:t + ", wait a little more...")
    MergeFonts(inconsolata_list[i])
    MergeFonts(migu1m_list[i])
    # edit zenkaku space (from ballot box and heavy greek cross)
    if ("$zenkaku_space_glyph" == "")
        Select(0u2610); Copy(); Select(0u3000); Paste()
        Select(0u271a); Copy(); Select(0u3000); PasteInto()
        OverlapIntersect()
    else
        Select(${zenkaku_space_glyph}); Copy(); Select(0u3000); Paste()
    endif
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
    PasteWithOffset(200, 0); PasteWithOffset(-200, 0)
    OverlapIntersect()
    # edit em dash
    Select(0u2014); Copy()
    PasteWithOffset(320, 0); PasteWithOffset(-320, 0)
    Select(0u007c); Copy(); Select(0u2014); PasteInto()
    OverlapIntersect()
    # detach and remove .notdef
    Select(".notdef")
    DetachAndRemoveGlyphs()
    # post-process
    SelectWorthOutputting()
    RoundToInt(); RemoveOverlap(); RoundToInt()
    # generate Ricty
    if (addfontfamily != "")
        Print("Save " + fontfamily + addfontfamily + "-" + fontstyle_list[i] + ".ttf.")
        Generate(fontfamily + addfontfamily + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    else
        Print("Save " + fontfamily + "-" + fontstyle_list[i] + ".ttf.")
        Generate(fontfamily + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    endif
    Close()
i += 1; endloop
Quit()
_EOT_

########################################
# generate Ricty
########################################

# generate
$fontforge_cmd -script ${tmpdir}/${modified_inconsolata_generator} \
    2> $redirection_stderr || exit 4
$fontforge_cmd -script ${tmpdir}/${modified_migu1m_generator} \
    2> $redirection_stderr || exit 4
$fontforge_cmd -script ${tmpdir}/${ricty_generator} \
    2> $redirection_stderr || exit 4

# remove tmp
if [ "$leaving_tmp_flag" = "false" ]
then
    echo "Remove temporary files."
    rm -rf $tmpdir
fi

# generate Ricty Discord (if the script exists)
path2discord_patch=`dirname $0`/ricty_discord_patch.pe
if [ -r "$path2discord_patch" ]
then
    $fontforge_cmd -script $path2discord_patch \
        ${ricty_familyname}${ricty_addfamilyname}-Regular.ttf \
        ${ricty_familyname}${ricty_addfamilyname}-Bold.ttf \
        2> $redirection_stderr || exit 4
fi

# exit
echo "Succeeded to generate Ricty!"
exit 0
