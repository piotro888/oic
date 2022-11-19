#!/bin/bash

#OIC TEST

COMPILE_FLAGS="-std=c++17 -DOIC -Wall -Wextra -Wshadow -pedantic -O2"

if [ $# -lt 1 ]; then
    echo "ERROR: missing parameter"
    exit 2
fi

DIR=$(pwd)

CCPROG=$1
[ "$CCPROG" = --help ] && exit 2;
shift

t=""; d=""; c=""; ow=0; tl=3600; ml=300; tlf=0; pd=0; ban=0; tf=0; cmo=0; oc=0; q=0; cc=""; oif=0; ma=0; ct=0;

while [ -n "$1" ] ; do
    case "$1" in
        -t) t=$2; if [ -z "$2" ]; then echo "ERROR: missing $1 value"; exit 1; fi; shift;;
        -d) d=$2; if [ -z "$2" ]; then echo "ERROR: missing $1 value"; exit 1; fi; shift;;
        -c) c=$2; if [ -z "$2" ]; then echo "ERROR: missing $1 value"; exit 1; fi; shift;;
        -oc) oc=1;;
        -ow) ow=1;;
        -tl) tl=$2; if [ -z "$2" ]; then echo "ERROR: missing $1 value"; exit 1; fi; shift;;
        -ml) ml=$2; if [ -z "$2" ]; then echo "ERROR: missing $1 value"; exit 1; fi; shift;;
        -tlf) tlf=1;;
        -pd) pd=1;;
        -tf) tf=1;;
        -cmo) cmo=1;;
        -q) q=1;;
        -ban) ban=1;;
        -san) COMPILE_FLAGS="$COMPILE_FLAGS -fsanitize=address -fsanitize=undefined -fno-sanitize-recover";;
        -cc) cc=$2; if [ -z "$2" ]; then echo "ERROR: missing $1 value"; exit 1; fi; shift;;
	    -oif) oif=1;;
        -ct) ct=1;;
        -massif) ma=1;;
        --help) exit 2;;
        *) echo "ERROR: invalid option $1";;
    esac
    shift
done

if [ ! -z $t ] && [ ! -z $d ]; then
    echo "ERROR: -t and -d specified"
    exit 1
fi

#if [ ! -d "tmp" ]; then
[ $q = 0 ] && echo 
[ $q = 0 ] && echo "Making temporary directories"
rm -rf tmp
mkdir tmp
mkdir tmp/bin
mkdir tmp/tin
mkdir tmp/tout
mkdir tmp/out
#fi

[ $q = 0 ] && echo
echo "* Compiling $(basename -- $CCPROG)"

if [ $q = 1 ]; then g++ $CCPROG -o tmp/bin/out $COMPILE_FLAGS 2> /dev/null 
else g++ $CCPROG -o tmp/bin/out $COMPILE_FLAGS; fi

if [ $? -ne 0 ]; then
    echo "COMPILATION FAILED"
    exit 1
fi;

[ $q = 0 ] && echo "Compilation successfull"

if [ ! -z $c ]; then
    [ $q = 0 ] && echo
    echo "* Compiling $(basename -- $c)"

    g++ $c -o tmp/bin/outgen

    if [ $? -ne 0 ]; then
        echo "COMPILATION ERROR!"
        exit 1
    fi;

    [ $q = 0 ] && echo "Compilation successfull"
fi;

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

[ $q = 0 ] && echo
echo "* Checking tests"

#testdir="$DIR/$d"
testdir=$d
[ $oif = 1 ] && testdir="$testdir/in"

if [ ! -z $t ]; then
    if [ ! -f $t ]; then
        echo "Eror: Invalid test file"
        exit
    fi

    mkdir tmp/single
    
    basename=$(basename -- $t)
    testname=${basename%.*}
    out=${t%.*}.out
    echo $out

    cp $t tmp/single/$testname.in
    cp $out tmp/single/$testname.out 2> /dev/null

    testdir="tmp/single"
fi


if [ ! -d $testdir ] ; then echo "ERROR: Invalid test directory: $testdir"; exit 1; fi
if [ $oif = 1 ] && [ ! -d "$(dirname $testdir)/out" ] ; then echo "ERROR: Invalid test directory:$(dirname $testdir)/out (oif flag)"; exit 1; fi

testdir=$(realpath $testdir)

if [ $ma = 0 ]; then
for i in $testdir/*.in; do
    [ -f "$i" ] || break
    
    basename=$(basename -- $i)
    testname=${basename%.in}

    ccbase=$(basename -- $CCPROG)
    [ $tf = 1 ] && [[ ${ccbase%.*} = $testname* ]] && continue

    [ $ct = 1 ] && cp $i tmp/tin/$testname.in
    [ $ct = 0 ] && ln -f -s $i tmp/tin/$testname.in

    out=${i%.in}.out
    [ $oif = 1 ] && out="$(dirname $(dirname $i))/out/$testname.out"

    if [ -z $cc ] && ([ ! -f "$out" ] || [ $oc = 1 ] || [ $ow = 1 ]); then
        if [ -z $c ];  then  
            echo "WARNING: Test $testname: no $(basename -- $out) file or -ow, -oc  and -c option not specifed, ignoring"
            rm tmp/tin/$testname.in
        else 
            [ $q = 0 ] &&  echo -n "Test $testname: Generating $(basename -- $out)"
            ./tmp/bin/outgen < tmp/tin/$testname.in > tmp/tout/$testname.out

            if [ $? -ne 0 ]; then
                echo -e "\n\nERROR: Generator crashed"
                exit 1
            fi;
            [ $q = 0 ] &&  echo -n " OK"

            if [ $cmo = 1 ] || [ $ow = 1 ]; then
                [ ! -f "$out" ] && echo -n " CREATING"
                [ ! -f "$out" ] || echo -n " OVERWRITING"
                [ $ct = 1 ] && cp tmp/tout/$testname.out $d/$testname.out
                [ $ct = 0 ] && ln -s -f tmp/tout/$testname.out $d/$testname.out
            fi;
            echo ""
        fi
    else
        [ $q = 0 ] && [ -z $cc ] && echo "Test $testname: OK"
        [ $q = 0 ] && [ ! -z $cc ] && echo "Test $testname: OK. Using -cc - ignoring copying/generating out files"
        [ -z $cc ] && [ $ct = 1 ] && cp $out tmp/tout/$testname.out #ln
        [ -z $cc ] && [ $ct = 0 ] && ln -s -f $out tmp/tout/$testname.out #ln
    fi
done
fi

tdir_in="tmp/tin"
tdir_pout="tmp/out"
tdir_out="tmp/tout"

[ $ma = 1 ] && echo "SKIP checking test files"
[ $ma = 1 ] && tdir_in=$testdir
[ $ma = 1 ] && [ $oif = 0 ] && tdir_out=$testdir
[ $ma = 1 ] && [ $oif = 1 ] && tdir_out="$(dirname $tdir_in)/out"

function traphandler(){
    echo -e "\n\n  ***Received SIGINT, aborting test\n"
    (kill -SIGKILL $1 2>/dev/null)& #pass pid as parameter
    wait $1 2>/dev/null #here to suppress message
    intbreak=1
}

[ $q = 0 ] && echo
echo "* Running tests"
echo

numtests=($tdir_in/*.in)
numtests=${#numtests[@]}

ac=1
testcnt=0
accnt=0
tlecnt=0
recnt=0
wacnt=0
table="| TN | _RES_ | __TIME__ | _U+S T_ | ___MEM___ | NAME\n"
intbreak=0

kblimit=$((ml*1000));
#ulimit  -v $kblimit #unfortuatly it cant be done to only checked process in bash with use of time and this structure :(
# maybe next in c++?

# sort files in more obvious order
filelist=$(ls -1 $tdir_in/*.in | sort -V)

#for i in tmp/tin/*.in; do
for i in $filelist; do
    # resolve symlinks
    [ -L "$i" ] && i=$(readlink -f $i)

    [ -f "$i" ] || break

    basename=$(basename -- $i)
    testname=${basename%.in}

    testcnt=$((testcnt+1))

    [ $q = 0 ] && echo "Running test $testcnt/$numtests, name: $testname"
    [ $q = 1 ] && echo -n "Test $testcnt/$numtests ($testname): "

    starttime=$(date +%s%3N)
    [ $q = 0 ] &&  echo -n "ST: $starttime"

    #timeout --preserve-status -k 5 -s SIGKILL $tl"s" ./tmp/bin/out < tmp/tin/$testname.in > tmp/out/$testname.out - can't exit with ctrl+c :( and less control so writed custom
    
    #run in bg and save pid
    ( /usr/bin/time -v tmp/bin/out < $tdir_in/$testname.in > $tdir_pout/$testname.out  2> $tdir_pout/err) & 
    timepid=$!
    ppid=""
#    ps
    while [ -z $ppid ] && ps -p $timepid > /dev/null; do #pgerp somtimes need to be executed couple of times
        ppid=$(pgrep -P $timepid) #pid of child. child of time is executed program
    done

    trap "traphandler $ppid" SIGINT  #set to abort test not program

    timekillpid=-1
    if ps -p $timepid > /dev/null; then
       	prlimit --pid $ppid --as=$((ml*1000000)) #memory limit globally by ulimit
	#echo -e "\n"
	#prlimit --pid $ppid --rss
        #run in bg sleep and kill. send sigterm first sigkill after
        #ps #nice debug
        (sleep $tl && kill -SIGTERM $ppid 2> /dev/null && sleep 1 && kill -SIGKILL $ppid 2> /dev/null) & 
        timekillpid=$!
        [ $q = 0 ] && echo -n " TPID: $timepid PPID: $ppid"
        #prlimit --pid $pid --as=$((ml*1000)) #fixthis
        #waits for pid - tested program. if time less than $tle finished itself in other case killed by signal
    else
        [ $q = 0 ] && echo -n " !Exited too fast. TIMEPID: $timepid" #ended before limit, timeout set. unknown pid of process
    fi
    wait $timepid 2> /dev/null > /dev/null
    retcode=$? #wait also returns exit code of waiting process

    endtime=$(date +%s%3N)

    [ $timekillpid = -1 ] || kill $timekillpid > /dev/null 2> /dev/null

    deltatime=$((endtime-starttime))
    timereadable="$(printf %02d $((deltatime/1000))).$(printf %03d $((deltatime%1000))) s"
    [ $q = 0 ] && echo " ET: $endtime DT: $deltatime RT: $retcode"
    head -n -24 $tdir_pout/err
    usrtimeout=$(tail -n -24 $tdir_pout/err)
    
    maxmem=$(echo $usrtimeout | sed -E  's/.*Maximum resident set size \(kbytes\): ([0-9]+).*/\1/')
    usrtime=$(echo $usrtimeout | sed -E  's/.*User time \(seconds\): ([0-9]+.[0-9]+).*/\1/')
    systime=$(echo $usrtimeout | sed -E  's/.*System time \(seconds\): ([0-9]+.[0-9]+).*/\1/')
    ustime=$(echo "$usrtime + $systime" | bc 2>/dev/null) 
    # UNCOMMENT SED LINES FOR DIFFERENT LOCALES WHEN PRINNTF TAKES , INSTEAD OF .
    #ustime=$(echo $ustime | sed 's/\./,/')
    memmb=$(echo "scale=3; $maxmem / 1000" | bc 2>/dev/null) 
    #memmb=$(echo $memmb | sed 's/\./,/')
    memreadable=$(printf "%06.2f MB" $memmb)
    ustimereadable="$(printf "%05.2f s" $ustime)"
    timeok=$(echo "scale=0; ($tl*1000)/1" | bc)
    #parse
    if [ $deltatime -ge $timeok ]; then
        echo -e "\033[1;33m[TLE]\033[0m Time Limit Excedeed $timereadable"
        ac=0
        table=$table"|   $(printf %02d $testcnt)   | \033[1;33m[TLE]\033[0m  |  $timereadable  | $ustimereadable  | $memreadable | $testname\n"
        tlecnt=$((tlecnt+1))
    elif [ $retcode -gt 128 ] && [ $retcode -lt 160 ]; then
        codeval=$(($retcode-128))
        recnt=$((recnt+1))
        case "$codeval" in
        1) codename="SIGHUP";;
        2) codename="SIGINT";;
        3) codename="SIGQUIT";;
        4) codename="SIGILL";;
        5) codename="SIGTRAP";;
        6) codename="SIGABRT";;
        7) codename="SIGBUS";;
        8) codename="SIGFPE";;
        9) codename="SIGKILL";;
        11) codename="SIGSEGV";;
        14) codename="SIGALRM";;
        13) codename="SIGPIPE";;
        15) codename="SIGTERM";;
        17) codename="SIGCHLD";;
        18) codename="SIGCONT";;
        19) codename="SIGSTOP";;
        23) codename="SIGURG";;
        24) codename="SIGXCPU";;
        27) codename="SIGPROF";;
        29) codename="SIGIO";;
        30) codename="SIGPWR";;
        31) codename="SIGSYS";;
        *) codename="SIG nr. $codeval";;
        esac
        echo -e "\033[0;34m[RE]_\033[0m Runtime exception: KILLED BY $codename"
        ac=0
        table=$table"|   $(printf %02d $testcnt)   | \033[0;34m[RE]_\033[0m  |  $timereadable  | $ustimereadable  | $memreadable | $testname\n"
    elif [ $retcode -ne 0 ]; then
        recnt=$((recnt+1))
        echo -e "\033[0;34m[RE]_\033[0m Non-zero exit code: $retcode"
        ac=0
        table=$table"|   $(printf %02d $testcnt)   | \033[0;34m[RE]_\033[0m  |  $timereadable  | $ustimereadable  | $memreadable | $testname\n"
    else
        ccint=$(cat $tdir_in/$testname.in)"\n\n\n"$(cat $tdir_pout/$testname.out)"\n"
        if [ -z $cc ]; then diff -bwq --strip-trailing-cr $tdir_pout/$testname.out $tdir_out/$testname.out > /dev/null 
        else echo -e $ccint | tmp/bin/customchecker  > /dev/null; fi
        dr=$?

        if [ $dr = 0 ]; then 
            accnt=$((accnt+1))
            echo -e "\033[0;32m[AC]_\033[0m Accepted"
            [ $pd = 1 ] && echo -n "Checker out: "
            [ $pd = 1 ] && [ -z $cc ] && diff --strip-trailing-cr $tdir_pout/$testname.out $tdir_out/$testname.out
            [ $pd = 1 ] && [ ! -z $cc ] && echo -e $ccint | tmp/bin/customchecker
            table=$table"|   $(printf %02d $testcnt)   | \033[0;32m[AC]_\033[0m  |  $timereadable  | $ustimereadable  | $memreadable | $testname\n"
        else
            wacnt=$((wacnt+1))
            echo -e "\033[0;31m[WA]_\033[0m Wrong Answer"
            ac=0
            [ $pd = 1 ] && echo -n "Checker out: "
            [ $pd = 1 ] && [ -z $cc ] && diff --strip-trailing-cr $tdir_pout/$testname.out $tdir_out/$testname.out
            [ $pd = 1 ] && [ ! -z $cc ] && echo -e $ccint | tmp/bin/customchecker
            table=$table"|   $(printf %02d $testcnt)   | \033[0;31m[WA]_\033[0m  |  $timereadable  | $ustimereadable  | $memreadable | $testname\n"
        fi
    fi

    if [ $intbreak = 1 ]; then break; fi
done

trap - SIGINT #set back to deafault

echo
echo
echo "* Test results"
echo

[ $q = 0 ] && echo -e $table

echo
if [ $ac = 1 ]; then
    echo "[ACACAC] ALL TESTS ACCEPTED"
    [ $ban = 1 ] && cat ban/acban1.txt
else
    echo "[NAC] NOT ACCEPTED :("
fi

echo
echo "TOTAL TESTS: $testcnt "
echo "AC: $accnt WA: $wacnt TLE: $tlecnt RE: $recnt"
echo

[ $ac = 1 ] && exit 0
exit 1

# TODO: --Use soft links--, add option to preserve test dir if running on the same tests
