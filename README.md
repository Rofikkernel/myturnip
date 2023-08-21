In this repository, you will find a shell script to build freedreno/turnip driver for android as a magisk module.




### How to build locally?
- Pick up the [turnip_builder.sh](https://raw.githubusercontent.com/ilhan-athn7/freedreno_turnip-CI/main/turnip_builder.sh)
- You must be in a linux environment;
- Open terminal and navigate to the directory of script and run this command ```sh turnip_builder.sh```
- You can edit **turnip_builder.sh** to add a break or skip some steps, this is also a good way when you want to try something that is not merged in to mesa repository.


###Rofik/XiaomiPocoMod Changelog
-add Debug build mode for Dev 
-add manual run build by @ilhan-athn7
-change auto build time

Notes
use command 
bash turnip_builder.sh (For some system instead sh command)

### References

- https://forum.xda-developers.com/t/getting-freedreno-turnip-mesa-vulkan-driver-on-a-poco-f3.4323871/

- https://gitlab.freedesktop.org/mesa/mesa/-/issues/6802
- https://gitlab.freedesktop.org/mesa/mesa/-/issues/7033#note_1621646
