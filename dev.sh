# 1.0.2

COMMANDS=('dev site [new|create|add]' 'dev site [edit|change|modify]' 'dev site [delete|remove|destroy]' 'dev [start|load|up] [" "/php/caddy/mysql/mailhog]' 'dev [restart|reload|reup] [" "/php/caddy/mysql/mailhog]' 'dev [stop|unload|down] [" "/php/caddy/mysql/mailhog]' 'dev php [version/up/down/restart]' 'dev php [switch|use] [7.4/8.0/8.1]' 'dev config [hosts/caddy]' 'dev config php [7.4/8.0/8.1]' 'dev [log|tail] [php/caddy]' 'dev info' 'dev status' 'dev update')

function usage_error {
  echo "Usage: dev [command] [parameters]"
  echo "Valid commands:\n"
  for ((i=0;i<${#COMMANDS[@]};i++)); do
    echo ${COMMANDS[${i}]}
  done
  exit
}

if [ -z "$1" ]; then 
    usage_error
fi

version=1

function load_caddy {
    sudo caddy start --config ~/.dev/Caddyfile
}

function unload_caddy {
    sudo caddy stop
}

function reload_caddy {
    unload_caddy
    load_caddy
}

function edit_config {
    case "$1" in
        hosts)
            subl /etc/hosts
        ;;
        caddy)
            subl ~/.dev/Caddyfile
        ;;
        script)
            code ~/.dev/dev.sh
        ;;
        php)
            case "2" in
                7.4|74)
                    subl /usr/local/etc/php/7.4/php-fpm.d/www.conf
                ;;
                8|8.0|80)
                    subl /usr/local/etc/php/8.0/php-fpm.d/www.conf
                ;;
                8.1|81)
                    subl /usr/local/etc/php/8.1/php-fpm.d/www.conf
                ;;
                *) usage_error
                ;;
            esac
        ;;
    esac
}

function tail {
    case "$1" in
        php)
            zsh -i -c "tail -f /usr/local/var/log/php-fpm.log"
        ;;
        caddy)
            zsh -i -c "tail -f /usr/local/var/log/caddy.log"
        ;;
        *) usage_error
        ;;
    esac
}

function reload {
    reload_php
    brew services restart mysql
    reload_caddy
    exit
}

function reload_php {
    brew services restart php
    brew services restart php@8.0
    brew services restart php@7.4
}

function load_php {
    brew services start php
    brew services start php@8.0
    brew services start php@7.4
}

function unload_php {
    brew services stop php
    brew services stop php@8.0
    brew services stop php@7.4
}

function load {
    load_php
    brew services start mysql
    brew services start mailhog
    load_caddy
    exit
}

function unload {
    unload_php
    brew services stop mysql
    brew services stop mailhog
    unload_caddy
    exit
}

function update_script {
    curl -s https://github.com/kaitwalla/macdev/raw/HEAD/cog.sh > ~/.dev/dev.sh
    chmod +x ~/.dev/dev.sh
    exit
}

function create_site_template {
    echo "What is the URL you want to use?"
    read -r url

    echo "What is the location of the web folder (leave blank for current directory)?"
    read -r location

    if [ -z "$location" ]; then
        location=$PWD
    fi

    echo "Does this site need php?"
    read -r phpReq

    case "$phpReq" in
        y|Y|yes|Yes|YES)
            echo "What version of PHP do you want to use (8.1, 8.0 or 7.4)?"
            read -r php
            if [ -z "$php" ]; then
                phpversion="9074"
            elif [ $php == "8.1" ]; then
                phpversion="9081"
            elif [ $php == "8.0" ]; then
                phpversion="9080"
            else
                phpversion="9074"
            fi        
            read -r -d '' SITE_TEMPLATE << EOM
#START SITEURL
SITEURL {
    tls internal
    root * PUBLIC_FOLDER
    php_fastcgi 127.0.0.1:PHP_PORT
	file_server
    log {
        output file /usr/local/var/log/caddy.log
        level error
    }
}
#END SITEURL

EOM
        SITE_TEMPLATE="${SITE_TEMPLATE//"PHP_PORT"/$phpversion}"
        ;;
        *)
            read -r -d '' SITE_TEMPLATE << EOM
#START SITEURL
SITEURL {
    tls internal
    root * PUBLIC_FOLDER
	file_server
    log {
        output file /usr/local/var/log/caddy.log
        level error
    }
}
#END SITEURL
EOM
        ;;
    esac
    SITE_TEMPLATE="${SITE_TEMPLATE//"SITEURL"/$url}"
    SITE_TEMPLATE="${SITE_TEMPLATE//"PUBLIC_FOLDER"/$location}"
    
    if [[ -s "$1" && -z "$(tail -c 1 "/etc/hosts")" ]]; then
        echo "" | sudo tee -a /etc/hosts
    fi
    if [[ -s "$1" && -z "$(tail -c 1 "~/.dev/Caddyfile")" ]]; then
        echo "" | tee -a ~/.dev/Caddyfile
    fi
    
    echo "$SITE_TEMPLATE" >> ~/.dev/Caddyfile
    echo "127.0.0.1   $url" | sudo tee -a /etc/hosts
}

function switch_php {
    case "$1" in
        7|7.4|74)
            phpversion="php@7.4"
        ;;
        8|8.0|80)
            phpversion="php@8.0"
        ;;
        8.1|81)
            phpversion="php@8.1"
        ;;
        *) usage_error
        ;;
    esac
    echo "$phpversion"
    brew unlink php@7.4
    brew unlink php@8.0
    brew unlink php@8.1
    brew link --force "$phpversion"
}

function delete_site {
    if [ -z "$oldurl" ]; then
        echo "What is the URL of the site you want to remove?"
        read -r oldurl
    fi
    
    if [ ! -z "$oldurl" ]; then
        sudo sed -i ''  "/$oldurl/d" /etc/hosts
        sed -i '' "/#START $oldurl/,/#END $oldurl/d" ~/.dev/Caddyfile
    fi
}

function edit_site_template {
    echo "What is the URL of the site you want to change?"
    read -r oldurl

    delete_site $oldurl

    create_site_template
}

case "$1" in
    site)
        case "$2" in
            new|create|add)
                create_site_template
                reload_caddy
            ;;
            delete|destroy|remove)
                if  [ ! -z "$3" ]; then
                    oldurl="$3"
                fi
                delete_site
                reload_caddy
            ;;
            change|edit)
                edit_site_template
                reload_caddy
            ;;
            *) usage_error
            ;;
        esac
    ;;
    reload|reup|restart)
        if [ -z "$2" ]; then
            reload
        else
            case "$2" in
                php)
                    reload_php
                ;;
                caddy)
                    reload_caddy
                ;;
                mailhog)
                    brew services restart mailhog
                ;;
                mysql)
                    brew services restart mysql
                ;;
                *) usage_error
                ;;
            esac
        fi
    ;;
    up|load|start)
        if [ -z "$2" ]; then
            load
        else
            case "$2" in
                php)
                    load_php
                ;;
                caddy)
                    load_caddy
                ;;
                mailhog)
                    brew services start mailhog
                ;;
                mysql)
                    brew services start mysql
                ;;
                *) usage_error
                ;;
            esac
        fi
    ;;
    down|unload|stop)
        if [ -z "$2" ]; then
            unload
        else
            case "$2" in
                php)
                    unload_php
                ;;
                caddy)
                    unload_caddy
                ;;
                mailhog)
                    brew services stop mailhog
                ;;
                mysql)
                    brew services stop mysql
                ;;
                *) usage_error
                ;;
            esac
        fi
    ;;
    php)
        case "$2" in
            switch)
                if [ -z "$3" ]; then
                    echo "What version of PHP do you want to use?"
                    read -r php
                    switch_php "$php"
                else
                    switch_php "$3"
                fi
            ;;
            version)
                php -v
            ;;
            up|load|start)
                load_php
            ;;
            down|unload|stop)
                unload_php
            ;;
            reup|reload|restart)
                reload_php
            ;;
            *) usage_error
            ;;
        esac
    ;;
    status) 
        brew services
    ;;
    update)
        update_script
    ;;
    info)
        echo 'Dev version 1.1.3'
    ;;
    config)
        edit_config $2 $3
    ;;
    tail|log)
        tail $2
    ;;
    *) usage_error
    ;;
esac
