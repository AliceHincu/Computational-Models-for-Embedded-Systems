mtype = {ConditionChangeDetected, NoConditionChange, SendDataForAnalysis, NoDataAvailable, AnomalyDetected, MinorChangeDetected, ConditionsNormal}

chan signal = [0] of {mtype};

bool conditionChangeDetected = false;
bool dataIsRecording = false;
bool serverSendsAlert = false;
bool managerChecksData = false;

active proctype Sensor() {
    pollSensorValue: atomic {
        if
            ::true -> atomic {
                printf("The sensor detected a change in environmental conditions.\n");
                conditionChangeDetected = true;
                signal!ConditionChangeDetected;
            }
            ::true -> atomic {
                printf("The sensor did not detect any change in environmental conditions.\n");
                conditionChangeDetected = false;
                signal!NoConditionChange;
            }
        fi;
    }
}

active proctype DataLogger() {
    waitingActivation: atomic {
        if
            ::signal?ConditionChangeDetected -> atomic {
                printf("The data logger has been activated and will start recording data.\n");
                dataIsRecording = true;
                signal!SendDataForAnalysis;
            }
            ::signal?NoConditionChange -> atomic {
                printf("The data logger will not activate and record because there are no changes in conditions.\n");
                dataIsRecording = false;
                signal!NoDataAvailable;
            }
        fi;
    }
}

active proctype AnalysisServer() {
    waitingData: atomic {
        if
            ::signal?SendDataForAnalysis -> atomic {
                printf("The server received data and will start analyzing it.\n");
                if
                    ::true -> atomic {
                        printf("An anomaly in environmental conditions has been detected, will alert the environmental manager.\n");
                        serverSendsAlert = true;
                        signal!AnomalyDetected;
                    }
                    ::true -> atomic {
                        printf("Minor changes in environmental conditions detected, will inform the environmental manager.\n");
                        serverSendsAlert = true;
                        signal!MinorChangeDetected;
                    }
                fi;
            }
            ::signal?NoDataAvailable -> atomic {
                printf("There is no data to analyze by the server.\n");
                serverSendsAlert = false;
                signal!ConditionsNormal;
            }
        fi;
    }
}

active proctype EnvironmentalManager() {
    waitingAlert: atomic {
        if
            ::signal?AnomalyDetected -> atomic {
                printf("The environmental manager received an alert about an anomaly in conditions.\n");
                printf("The manager will check the recorded data.\n");
                managerChecksData = true;
            }
            ::signal?MinorChangeDetected -> atomic {
                printf("The environmental manager received information about minor changes in conditions.\n");
                printf("The manager will check the recorded data.\n");
                managerChecksData = true;
            }
            ::signal?ConditionsNormal -> atomic {
                printf("The environmental manager did not receive any alert because conditions are normal.\n");
                printf("The manager will not check the recorded data.\n");
                managerChecksData = false;
            }
        fi;
    }
}

//ltl { [](dataIsRecording -> X serverSendsAlert) }
//ltl { [](serverSendsAlert -> <> managerChecksData) }
//ltl { [](!conditionChangeDetected -> ! [] managerChecksData) }
