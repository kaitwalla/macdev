install_app() {
	if [ "$1" == "dmg" ]; then
		install_dmg "$2" "$3" "$4" "$5"
	fi;
	if [ "$1" == "script" ]; then
		install_sh "$2" "$3"
	fi;
	if [ "$1" == "zip" ]; then
		install_zip "$2" "$3" "$4"
	fi;
	if [ "$1" == "manul" ]; then
		download_manual "$2" "$3"
	fi;
}

install_zip () {
	curl -L $1 --output $2
	unzip $2
	mv "$3" /Applications
	rm $2
}

install_dmg () {
	curl -L $1 --output $2
	hdiutil mount "$2"
	cp -r /Volumes/"$4"/"$3" /Applications
	hdiutil detach /Volumes/"$4"
	rm $2
}

install_script () {
	curl -fsSL $1 --output $2
	chmod +x ./$2
	./$2
	rm $2
}

download_manual () {
	curl -L $1 --output $2
}

install_homebrew () {
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh --output homebrew.sh
	chmod +x ./homebrew.sh
	echo | echo 'cognition' |  ./homebrew.sh
	rm homebrew.sh

	brew install php php@8.0 php@7.4 mysql caddy mailhog php-cs-fixer go
	go install github.com/mailhog/mhsendmail@9e70164f299c9e06af61402e636f5bbdf03e7dbb
	mv ~/go/bin/mhsendmail /usr/local/bin
	
	brew remove go
	sudo rm -rf ~/go
}

install_xcode_tools () {
	os=$(sw_vers -productVersion | awk -F. '{print $1 "." $2}')
	if softwareupdate --history | grep --silent "Command Line Tools.*${os}"; then
	    echo 'Command-line tools already installed.'
	else
	    echo 'Installing Command-line tools...'
	    in_progress=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
	    touch ${in_progress}
	    product=$(softwareupdate --list | awk "/\* Command Line.*${os}/ { sub(/^   \* /, \"\"); print }")
	    softwareupdate --verbose --install "${product}" || echo 'Installation failed.' 1>&2 && rm ${in_progress} && exit 1
	    rm ${in_progress}
	    echo 'Installation succeeded.'
	fi
}

install_omz () {
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_nvm () {
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
}

install_composer () {
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
	php composer-setup.php
	php -r "unlink('composer-setup.php');"
	sudo mv composer.phar /usr/local/bin/composer
}

install_wp_cli () {
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp
}

create_directories () {
	mkdir ~/Sites
	mkdir ~/.dev
	touch ~/Dev/Caddyfile
}

set_customizations () {
	# Change PHP listen ports
	sed -i '' 's/127\.0\.0\.1\:9000/127\.0\.0\.1\:9074/g' /usr/local/etc/php/7.4/php-fpm.d/www.conf
	sed -i '' 's/127\.0\.0\.1\:9000/127\.0\.0\.1\:9080/g' /usr/local/etc/php/8.0/php-fpm.d/www.conf
	sed -i '' 's/127\.0\.0\.1\:9000/127\.0\.0\.1\:9081/g' /usr/local/etc/php/8.1/php-fpm.d/www.conf

	echo "php_admin_value[memory_limit] = 256M" >> /usr/local/etc/php/7.4/php-fpm.d/www.conf
	echo "php_admin_value[upload_max_filesize] = 4096M" >> /usr/local/etc/php/7.4/php-fpm.d/www.conf
	echo "php_admin_value[post_max_size] = 4096M" >> /usr/local/etc/php/7.4/php-fpm.d/www.conf

	echo "php_admin_value[memory_limit] = 256M" >> /usr/local/etc/php/8.0/php-fpm.d/www.conf
	echo "php_admin_value[upload_max_filesize] = 4096M" >> /usr/local/etc/php/8.0/php-fpm.d/www.conf
	echo "php_admin_value[post_max_size] = 4096M" >> /usr/local/etc/php/8.0/php-fpm.d/www.conf

	echo "php_admin_value[memory_limit] = 256M" >> /usr/local/etc/php/8.1/php-fpm.d/www.conf
	echo "php_admin_value[upload_max_filesize] = 4096M" >> /usr/local/etc/php/8.1/php-fpm.d/www.conf
	echo "php_admin_value[post_max_size] = 4096M" >> /usr/local/etc/php/8.1/php-fpm.d/www.conf

	# Add sendmail path
	echo "sendmail_path = /usr/local/bin/mhsendmail" >> /usr/local/etc/php/7.4/php.ini
	echo "sendmail_path = /usr/local/bin/mhsendmail" >> /usr/local/etc/php/8.0/php.ini
	echo "sendmail_path = /usr/local/bin/mhsendmail" >> /usr/local/etc/php/8.1/php.ini

	#Download script
	curl -s https://bitbucket.org/cognitionstudio/scripts/raw/HEAD/cog.sh > ~/.dev/cog.sh
	chmod +x ~/.dev/cog.sh

	# Add to path
	fileLocation="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
	codePath="export \"PATH=\$PATH:$fileLocation\""
	echo "$codePath" >> ~/.zprofile
	echo "alias cog=~/.dev/cog.sh" >> ~/.zprofile
	echo 'export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"' >> ~/.zprofile
	ln -s "/Applications/Sublime Merge.app/Contents/SharedSupport/bin/smerge" /usr/local/bin/smerge
}

cleanup() {
	#rm -rf ~/install.sh // Depends on if we need to download the file to the remote before executing it
	rm -rf ~/Install/downloads.csv
}

cd ~/
mkdir Install
cd Install

curl -L https://bitbucket.org/cognitionstudio/dev-computer-setup/raw/main/downloads.csv --output downloads.csv

while IFS=$'\,' read -r type url download app mount ; do
	install_app "$type" "$url" "$download" "$app" "$mount"
done < downloads.csv

open ~/Install

install_xcode_tools
install_homebrew
install_composer
install_omz
install_wp_cli

create_directories

set_customizations

cleanup
