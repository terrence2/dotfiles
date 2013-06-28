function border
    set_color -o normal
    set_color $argv[1]
    if [ $argv[2] = tty ]
        echo -n $argv[3]
    else
        echo -n $argv[4]
    end
end

function fish_right_prompt
    set_color cyan
    echo -n (date "+%H:%M:%S|%Z ")
end

function fish_prompt
	and set retc blue; or set retc red
    tty|grep -q tty; and set tty tty; or set tty pts

    # Vertical Bar
    #echo -n "╭──"
    border $retc $tty ".--" "╭──"
    for col in (seq (expr $COLUMNS - 4))
        border $retc $tty "-" '─'
    end
    echo ""

    border $retc $tty "|" '╞'

    # PWD
    set_color -o white
    set tmp ' '(pwd|sed "s=$HOME=~=")
    echo -n $tmp
    set nPath (echo -n $tmp | wc -c)

    # CMD_DURATION tracks last command time if it takes more than 1 sec.
    set nDuration 0
    if test $CMD_DURATION
        border $retc $tty '  | ' '  ╰ '
        set_color magenta
        echo -n $CMD_DURATION
        border $retc $tty ' |' ' ╯'
        set nDuration (echo -n "  | $CMD_DURATION |" | wc -c)

        # CMD_OURATION is a string of form _m _.__s, we want the duration in
        # seconds so that we can only send notifications for commands longer than
        # ~30 seconds.
        set -l taken (echo $CMD_DURATION | perl -ne 'if (m/^((\d+)m )?(\d+\.\d+)s$/) {print $2 * 60 + $3;}')
        if test $taken -gt 30
            notify-send "Finished <something> | $CMD_DURATION"
        end
    end

    # Mercurial QTop
    set nMercurial 0
    set -l hg_qtop (hg qtop 2> /dev/null)
    if [ $hg_qtop ]
        if [ $hg_qtop = "no patches applied" ]
            set hg_qtop ∅
        end
        border $retc $tty '  | ' '  ╰ '
        set_color magenta
        echo -n $hg_qtop
        border $retc $tty ' |' ' ╯'
        set nMercurial (echo -n "  | $hg_qtop |" | wc -c)
    end

    # Battery status.
    set nBat 0
    if [ (acpi -a 2> /dev/null | grep off) ]
        border $retc $tty '  | ' '  ╰ '
        set_color -o red
        set tmp (acpi -b|cut -d' ' -f 4-|sed 's/, discharging at zero rate - will never fully discharge.//')
        echo -n $tmp
        border $retc $tty ' |' ' ╯'
        set nBat (echo -n "  | $tmp |" | wc -c)
    end

    set nUserHost (echo -n $USER@(hostname) | wc -c)

    for col in (seq (math $COLUMNS - 1 - $nPath - $nDuration - $nMercurial - $nBat - $nUserHost - 1))
        echo -n ' '
    end

    # USER
    if [ $USER = root ]
        set_color -o red
    else
        set_color -o green
    end
    echo -n $USER

    set_color -o white
    echo -n @

    # HOST
    if [ -z "$SSH_CLIENT" ]
        set_color -o blue
    else
        set_color -o cyan
    end
    echo -n (hostname)

    # List all jobs.
    echo
    set_color normal
    for job in (jobs)
        border $retc $tty '; ' '│ '
        set_color brown
        echo $job
    end

    # And draw the prompt.
    border $retc $tty "'> " '╰> '
end
