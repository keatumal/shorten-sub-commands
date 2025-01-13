use as-cli-arguments:ver<0.0.8+>:auth<zef:lizmat>;

my sub meh($message) { exit note $message }

sub EXPORT(&target) {
    die "Target &{&target.name} must be a multi"
      unless &target.is_dispatcher;

    my @sub-commands = &target.candidates.map({
        if .signature.params -> @params {
            my $sub-command := @params.head;
            $sub-command.constraint_list.head
              if !$sub-command.name
              && !$sub-command.named
              &&  $sub-command.type ~~ Str | Numeric
              &&  $sub-command.constraint_list == 1
        }
    }).sort.List;

    &target.add_dispatchee: my sub (Str:D $command, |c) is hidden-from-USAGE {
        meh("Must specify a sub-commmand") unless $command;

        my @matches = @sub-commands.grep: -> $sub-command {
            $sub-command.starts-with($command)
        }
        if @matches == 1 {
            with $*RECURSIVE-SHORT-SUB-COMMAND -> $from {
                my $params := as-cli-arguments c;
                $params    := " $params" if $params;
                meh $command eq $from
                  ?? "'$from$params' recurses"
                  !! "'$from$params' recurses into '$command'";
            }
            else {
                my $*RECURSIVE-SHORT-SUB-COMMAND := $command;
                target(@matches[0], |c);
            }
        }
        else {
            @matches
              ?? meh("'$command' is ambiguous, matches: @matches[]")
              !! meh("'$command' is not recognized as sub-command:
Known sub-commands: @sub-commands[]")
        }
    }

    Map.new
}

# vim: expandtab shiftwidth=4
