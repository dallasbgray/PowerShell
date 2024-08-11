#!/usr/bin/zsh

# TODO add option to update all, -u or --update-all
# echo "parameter 1 $1"

cd ~/Build

# check if package already exists
# if so run git pull & then rebuild
# git pull

if  ! git clone https://aur.archlinux.org/$1.git; then
    # if  cloning throws an error check the HTTP status of the package's aur page & exit
    comm -23 <(pacman -Qqm | sort) <(curl https://aur.archlinux.org/packages.gz | gzip -cd | sort)
    echo "git clone failed"
    exit
fi

cd $1

# verify PKGBUILD manually
less PKGBUILD
echo "Continue? y/n"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

# make & install the package
# if signature is present in PKGBUILD, makepkg tries to automatically verify it
makepkg --syncdeps --install --clean

# only needed if --install flag is not passed to makepkg
# pacman -U $1*.pkg.tar.zst
