needs util/tasks

| This will run for about three seconds, then stop
ms@ variable, start
: idle yield idle ;
:: 'a emit  ms@ start @ - 3000 >if cr ." Good bye!" cr bye then ; >task
:: 'b emit  ; >task
task: 'c emit  ;

| Start the idle loop
idle
