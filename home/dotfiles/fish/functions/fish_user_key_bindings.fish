function _zoxide_quote_bind
    if test -z (commandline)
        commandline --insert 'z '
    else
        commandline --insert "'"
    end
end

function fish_user_key_bindings
    bind "'" _zoxide_quote_bind
end
