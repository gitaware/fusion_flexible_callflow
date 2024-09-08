# fusion_flexible_callflow
Callflows that are controlled by timeconditions  

## Configuration in FusionPBX
If you make a callflow with the same name as a timecondition, the callflow is switched at the same time as the timecondition. The naming is domain specific, so it is possible to have a callflow and timecondition "officehours" in multiple domains.

## BLF
The BLF's for the callflows should update when callflows are automatically switched by timeconditions. Please make sure the BLF button configuration is correct. On some hardware you need to subscribe to the BLF as:
    flow+*<CallFlow EXT>@domain

## Usage
Start by running:
    /usr/bin/fs_cli -x 'lua schedule_call_flow2.lua'

Add to cron:
    @reboot    sleep 300 && /usr/bin/fs_cli -x 'lua schedule_call_flow2.lua'
    0 1 * * *    sleep 300 && /usr/bin/fs_cli -x 'lua schedule_call_flow2.lua'
