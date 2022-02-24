# macdev
A script for managing PHP development environments on the Mac

## YOU SHOULD ONLY USE THIS SCRIPT IF YOU KNOW WHAT YOU'RE DOING

I got tired of Valet and DNSMasq eating it all the time, so I wrote a Bash script that handles setting up local dev environments. It has everything you need to get your Mac up and running a dev environment for PHP 7.4, 8.0 and 8.1, as well as Node and NPM. Uses Caddyserver as the host.

Use install.sh in conjunction with downloads.csv in order to ensure you have all the appropriate applications installed. (Customize it as you please, I have it set to my favorite applications.) The installer script is designed to run on a clean install, so no guarantees what happens if it hits something that's already half-configured.

Run dev.sh with the commands as instructed in the bash script. I would advise adding an alias to your .zprofile file to just be able to run it as "dev," but you do you (also, if you use the installer script it'll do it for you. Yay!)
