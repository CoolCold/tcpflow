#!/bin/sh

#this script gonna test result produced by tcpflow
#since real test isn't easy, we'll use reading from previously
#captured tcpdump output from file

#set -x

#making the room clean
export LC_ALL=C LC_CTYPE=C LANG=C

tfbin="src/tcpflow"
tdsample="tcpdump.sample.dump"

#tests count
testscount="1 2 3"

#setting values
testinfo_name[1]="original tcpflow"
testinfo_md5shouldbe[1]="535554877234163917e1ac01895db3a0"
testinfo_md5got[1]=""
testinfo_result[1]="unknown yet"
testinfo_outfname[1]=""
testinfo_iserror[1]=""
testinfo_cmdopts[1]="$tfbin -c -r $tdsample"


testinfo_name[2]="\\n converted into \".\""
testinfo_md5shouldbe[2]="1e5e28c4a9fe2224c77d2c81cc191b25"
testinfo_md5got[2]=""
testinfo_result[2]="unknown yet"
testinfo_outfname[2]=""
testinfo_iserror[2]=""
testinfo_cmdopts[2]="$tfbin -c -o -r $tdsample"

testinfo_name[3]="with timestamp"
testinfo_md5shouldbe[3]="47cb18f4bbf844009b06194d59af1e82"
testinfo_md5got[3]=""
testinfo_result[3]="unknown yet"
testinfo_outfname[3]=""
testinfo_iserror[3]=""
testinfo_cmdopts[3]="$tfbin -c -t -r $tdsample"

function myexit() {
    echo "we failed because of: $2"
    exit $1
}


function checkerror() {
    msg="$1"
    if [ -z "$msg" ];then msg="unspecified action";fi
    if [ "x$iserror" = "xYES" ];then
        echo "error(s) while $msg:"
        for i in $testscount;do
            if [ "x${testinfo_iserror[$i]}" = "xYES" ];then
                echo "${testinfo_name[$i]} - ${testinfo_result[$i]}"
            fi
        done
        myexit 2 ""
    fi
}

echo "creating temporary files to store data.."
iserror="no"
for i in $testscount;do
    tfile=`mktemp -t tcpflowtest.XXXXX 2>&1`
    tfile_res=$?
    if [ $tfile_res -ne 0 ];then
        testinfo_iserror[$i]="YES"
        iserror="YES"
        testinfo_result[$i]="$tfile"
    else
        testinfo_outfname[$i]="$tfile"
        echo "  ${testinfo_outfname[$i]} created"
    fi
done
checkerror "creating temporary files"

echo "creating output from tcpdump sample..."
iserror="no"
for i in $testscount;do

    # i was wondered when it turned out - bash ( and sh ) eats newlines
    # in command substitution, see man bash / "trailing newlines"
    # so using output to files ...

    echo "producing data for \"${testinfo_name[$i]}\" with command: \"${testinfo_cmdopts[$i]}\""
    tfile=`${testinfo_cmdopts[$i]} 2>&1|tee ${testinfo_outfname[$i]}`
    tfile_res=$?
    testinfo_result[$i]="$tfile"
    if [ $tfile_res -ne 0 ];then
        testinfo_iserror[$i]="YES"
        iserror="YES"
    fi
done

checkerror "creating output from tcpdump sample"

#producing md5sums
echo "producing md5sums..."
iserror="no"
for i in $testscount;do
    tfile=`md5sum ${testinfo_outfname[$i]}|cut -f 1 -d " " 2>&1`
    tfile_res=$?
    testinfo_md5got[$i]="$tfile"
    if [ $tfile_res -ne 0 ];then
        testinfo_iserror[$i]="YES"
        iserror="YES"
        testinfo_result[$i]="$tfile"
    fi
done

checkerror "getting md5sums"

echo "comparing md5sums..."
iserror="no"
for i in $testscount;do
    if [ "x${testinfo_md5got[$i]}" != "x${testinfo_md5shouldbe[$i]}" ];then
        iserror="YES"
        testinfo_iserror[$i]="YES"
        echo "test for ${testinfo_name[$i]} failed:"
        echo "md5sum expected to be: ${testinfo_md5shouldbe[$i]} , md5sum we got: ${testinfo_md5got[$i]}"
    else
        echo "test for ${testinfo_name[$i]} is ok"
    fi
done

if [ "x$iserror" = "xYES" ];then
    echo "not deleting temporary files due to test failure"
    exit 1
else
    echo "all is ok, deleting temporary files"
    for i in $testscount;do
        rm "${testinfo_outfname[$i]}"
    done
    exit 0
fi

