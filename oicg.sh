#!/bin/bash

#OIC TEST

COMPILE_FLAGS="-std=c++17 -DOIC -Wall -Wextra -Wshadow -pedantic -O3"

[ "$1" = --help ] || [ "$2" = --help ] || [ "$3" = --help ] && exit 2;

if [ $# -lt 3 ]; then
    echo "ERROR: missing parameters"
    exit 2
fi

DIR=$(pwd)

CCPROG=$1
COMPPROG=$2
GENPROG=$3
shift; shift; shift;
mt=0; mf=0; s=0; oit=0; pd=0; cc="";

MACROGEN=""

while [ -n "$1" ] ; do
    case "$1" in
        -mt) mt=$2; if [ -z "$2" ]; then echo "ERROR: missing $1 value"; exit 1; fi; shift;;
        -mf) mf=$2; if [ -z "$2" ]; then echo "ERROR: missing $1 value"; exit 1; fi; shift;;
        -s) s=1;;
        -oit) oit=1;;
        -D) MACROGEN="$MACROGEN -D$2"; if [ -z "$2" ]; then echo "ERROR: missing $1 value"; exit 1; fi; shift;;
        -pd) pd=1;;
        -bell) bell=1;;
        -cc) cc=$2; if [ -z "$2" ]; then echo "ERROR: missing $1 value"; exit 1; fi; shift;;
        --help) exit 2;;
        *) echo "ERROR: invalid option $1";;
    esac
    shift
done

if [ $mf = 0 ]; then mf=$mt; fi

echo 
echo "Making temporary directories"
rm -rf tmp
mkdir tmp
mkdir tmp/bin
mkdir tmp/t

if [ $s = 1 ] || [ $oit = 1 ]; then
    rm -rf oicgen
    mkdir oicgen
fi

[ $oit = 0 ] && echo
[ $oit = 0 ] && echo "* Compiling $(basename -- $CCPROG)"

[ $oit = 0 ] && g++ $CCPROG -o tmp/bin/out $COMPILE_FLAGS

if [ $? -ne 0 ] && [ $oit = 0 ]; then
    echo "COMPILATION FAILED"
    exit 1
fi;

[ $oit = 0 ] && echo "Compilation successfull"

     echo
    echo "* Compiling $(basename -- $COMPPROG)"

    g++ $COMPPROG -o tmp/bin/comp -O3

    if [ $? -ne 0 ]; then
        echo "COMPILATION ERROR!"
        exit 1
    fi;

    echo "Compilation successfull"

     echo
    echo "* Compiling $(basename -- $GENPROG)"

    g++ $GENPROG -o tmp/bin/gen $MACROGEN

    if [ $? -ne 0 ]; then
        echo "COMPILATION ERROR!"
        exit 1
    fi;

     echo "Compilation successfull"

if [ ! -z $cc ]; then
    [ $q = 0 ] && echo
    echo "* Compiling $(basename -- $cc)"

    g++ $cc -o tmp/bin/customchecker

    if [ $? -ne 0 ]; then
        echo "COMPILATION ERROR!"
        exit 1
    fi;

    [ $q = 0 ] && echo "Compilation successfull"
fi;

echo
echo "* TESTING"

testcnt=0
failcnt=0
ac=1
while [ $testcnt -lt $mt ]; do
    [ $failcnt -ge $mf ] && break

    testcnt=$((testcnt+1))

    echo -n "*Running test $testcnt/$mt."
    [ $oit = 0 ] && echo " Failed $failcnt/$mf"
    [ $oit = 0 ] || echo

    echo -n "  Generating random test."
    ./tmp/bin/gen > tmp/t/t.in

    [ ! $? = 0 ] && echo "*****GENERATOR CRASHED!" && ac=0 && break

    echo -n "  Running correct output genearator."
    ./tmp/bin/comp > tmp/t/tc.out < tmp/t/t.in

    [ ! $? = 0 ] && echo "*****CORRECT OUTPUT GENERATOR CRASHED!" && ac=0 && break
    
    [ $oit = 0 ] && echo "  Running tested program."
    [ $oit = 0 ] && ./tmp/bin/out > tmp/t/t.out < tmp/t/t.in

    [ $oit = 0 ] && [ ! $? = 0 ] && echo "*****TESTED PROGRAM CRASHED!" && ac=0

    if [ $oit = 0 ]; then
        ccint=$(cat tmp/t/t.in)"\n\n\n"$(cat tmp/t/t.out)"\n"
        if [ -z $cc ]; then diff tmp/t/t.out tmp/t/tc.out > /dev/null
        else echo -e $ccint | tmp/bin/customchecker  > /dev/null; fi
        dr=$?
        if [ $dr = 0 ]; then
            echo "  [AC] ACCEPTED"
            [ $pd = 1 ] && echo -n "Checker out: "
            [ $pd = 1 ] && [ -z $cc ] && diff tmp/t/t.out tmp/t/tc.out
            [ $pd = 1 ] && [ ! -z $cc ] && echo -e $ccint | tmp/bin/customchecker
        else
            echo "  ****[WA] WRONG ANSWER"
            if [ $pd = 1 ]; then diff tmp/t/t.out tmp/t/tc.out; fi
            failcnt=$((failcnt+1))
            ac=0
            [ $pd = 1 ] && echo -n "Checker out: "
            [ $pd = 1 ] && [ -z $cc ] && diff tmp/t/t.out tmp/t/tc.out
            [ $pd = 1 ] && [ ! -z $cc ] && echo -e $ccint | tmp/bin/customchecker
            if [ $s = 1 ]; then
                echo "  Saving as t$testcnt""f"".[in/out]"
                filename="t"$testcnt"f"
                cp tmp/t/t.in oicgen/$filename.in
                cp tmp/t/tc.out oicgen/$filename.out
            fi
        fi
    else
        echo -e "\n  Saving as t$testcnt.[in/out]"
        filename="t"$testcnt
        cp tmp/t/t.in oicgen/$filename.in
        cp tmp/t/tc.out oicgen/$filename.out
    fi
done

if [ $ac = 1 ]; then 
    echo
    [ $oit = 0 ] &&  cat ban/acban0.txt
    [ $oit = 0 ] && echo "[ACACAC] ALL TESTS PASSED"
    [ $oit = 1 ] && echo "[OK] TESTS SUCCESSFULLY GENERATED"
    exit 0
else
    echo
    [ $oit = 0 ] && echo "[NAC] SOME TESTS FAILED :("
    [ $oit = 1 ] && echo "[NOK] SOME TESTS FAILED TO GENERATE :("
    exit 1
fi