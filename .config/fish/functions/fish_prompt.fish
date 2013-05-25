function border
    set_color -o normal
    set_color $argv[1]
    if [ $argv[2] = tty ]
        echo -n $argv[3]
    else
        echo -n $argv[4]
    end
end

function user_host_size

end

function fish_right_prompt
    set_color cyan
    echo -n (date "+%H:%M:%S|%Z ")
end

function fish_prompt
	and set retc blue; or set retc red
    tty|grep -q tty; and set tty tty; or set tty pts

    # Vertical Bar
    set_color $retc
    echo -n "━━┯"
    for col in (seq (expr $COLUMNS - 4))
        echo -n '━'
    end
    echo ""

    border $retc $tty ".-'" '╭─╯'
    #border $retc $tty ']-[' '┠─┨'

    # PWD
    set_color -o white
    set tmp ' '(pwd|sed "s=$HOME=~=")
    echo -n $tmp
    set nPath (echo -n $tmp | wc -c)

    # Mercurial QTop
    set nMercurial 0
    if [ (hg qtop 2> /dev/null) ]
        border $retc $tty '  |' '  ╰'
        set_color magenta
        echo -n (hg qtop)
        border $retc $tty '|' '╯'
        set nMercurial (echo -n "  |"(hg qtop)"|" | wc -c)
    end

    # Battery status.
    set nBat 0
    if [ (acpi -a 2> /dev/null | grep off) ]
        border $retc $tty '  |' '  ╰'
        set_color -o red
        set tmp (acpi -b|cut -d' ' -f 4-)
        echo -n $tmp
        border $retc $tty '|' '╯'
        set nBat (echo -n "  |"$tmp"|" | wc -c)
    end

    # COMMAND TIME
    #set now (date +%s)
    #if [ $_PRIOR_CLI_TIME ]
    #    set diff (expr $_PRIOR_CLI_TIME - $now)
    #    echo -n $diff
    #end
    #set -g _PRIOR_CLI_TIME $now

    set nUserHost (echo -n $USER@(hostname) | wc -c)

    for col in (seq (math $COLUMNS - 3 - $nPath - $nMercurial - $nBat - $nUserHost - 1))
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
        border $retc $tty '; ' '┃ '
        set_color brown
        echo $job
    end

    # And draw the prompt.
    border $retc $tty "'-|" '╰─> '
end
