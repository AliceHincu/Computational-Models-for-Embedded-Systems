mtype = {TakeProgram, FailProgram, PassProgram}

bool isTakingProgram = false;
bool requestProcessed = false;
bool requestAccepted = false;
bool isPassed = false;

chan signal = [0] of {mtype};

active proctype Educator() {

    waitingToTake: atomic {
        printf("Educator requesting to take Program.\n");
        isTakingProgram = true;
        signal!TakeProgram;
    }

    waitingForAnswer: atomic {
        if
            :: signal?PassProgram -> atomic {
                printf("Educator is better prepared for future generations.\n");
                isPassed = true;
            }
            :: signal?FailProgram -> atomic {
                printf("Educator still has a lot to learn.\n");
                isPassed = false;
            }
        fi;
    }

}

active proctype Program() {

    waitingForTakeRequests: atomic {
        if
            :: signal?TakeProgram -> atomic {
                printf("Program received request from educator to join.\n");
                if
                    :: true -> atomic {
                        printf("Program passes the educator.\n");
                        requestProcessed = true;
                        requestAccepted = true;
                        signal!PassProgram;
                    }
                    :: true -> atomic {
                        printf("Program fails the educator.\n");
                        requestProcessed = true;                        
                        requestAccepted = false;
                        signal!FailProgram;
                    }
                fi;
            }
        fi;
    }

}

ltl { [](isTakingProgram->requestProcessed) }
ltl { [](requestProcessed->(isPassed||!isPassed)) }
ltl { [](requestProcessed->!(isPassed&&!isPassed)) }
